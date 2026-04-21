# CloudCodeAPI Server Deployment Plan

> **For the executing agent (GPT):** Run the steps in order. Each step has a verification command — DO NOT proceed if verification fails. Treat any "STOP" marker as hard. The user (Dylan) will provide values for `<placeholders>`.

**Goal:** Deploy CloudCodeAPI (forked sub2api with editorial UI + Antigravity gateway) to a production server, behind HTTPS, ready for small-group invitation testing.

**Server (confirmed):** `49.51.187.129` — Santa Clara, CA (Tencent Cloud SV node)
- Direct outbound to Google / Anthropic / OpenAI (no GFW)
- Low latency to China users
- ⚠️ **Memory is tight (~2GB total, OpenClaw already runs there)** — verify free RAM in Step 0

**Repo source:** `/Users/dylanthomas/Desktop/projects/proxy-api` (Dylan's local worktree, latest `main`)

---

## Variables to define

```
SERVER_HOST=49.51.187.129
SERVER_USER=root                       # confirm with Dylan
DOMAIN=49.51.187.129                   # raw IP — self-signed TLS via Caddy
ACME_EMAIL=dylan.thinking.one@gmail.com  # only used if migrating to real domain later
ADMIN_EMAIL=admin@cloudcodeapi.local   # placeholder; ask Dylan in Step 2.5 if he wants different
ADMIN_PASSWORD=                        # ⚠ ASK DYLAN AT STEP 2.5 — DO NOT GENERATE
SERVER_TARGET_DIR=/opt/proxy-api
```

**TLS note:** Because DOMAIN is a raw IP, Caddy uses self-signed TLS (its own internal CA). Friends will see a "Your connection is not private" warning the first time they hit the site — they click **Advanced → Proceed to 49.51.187.129 (unsafe)** and the rest works normally. Antigravity OAuth still works because Google only requires HTTPS, not a CA-signed cert.

---

## STEP 0 — Pre-flight (run on Dylan's local machine)

- [ ] **0.1 Verify SSH reachability**

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 ${SERVER_USER}@${SERVER_HOST} 'echo OK'
```
Expected: `OK`. If fails, ask Dylan for SSH credential / key.

- [ ] **0.2 Verify server has Docker + Docker Compose v2**

```bash
ssh ${SERVER_USER}@${SERVER_HOST} 'docker --version && docker compose version'
```
Expected: docker version >= 24.x, compose version >= v2.x.
If missing, install per https://docs.docker.com/engine/install/

- [ ] **0.3 Verify free memory and disk**

```bash
ssh ${SERVER_USER}@${SERVER_HOST} 'free -h && df -h /'
```
Expected:
- ≥ 1.2 GB free memory (postgres + redis + sub2api + caddy fits in 1 GB but tight)
- ≥ 5 GB free disk

If memory is too tight, **STOP and tell Dylan**. Options he has: (a) restart the server to free OpenClaw RAM, (b) switch to the HK server `103.27.76.223`, (c) accept some swap.

- [ ] **0.4 Verify outbound to Antigravity / Google works from server**

```bash
ssh ${SERVER_USER}@${SERVER_HOST} 'curl -s -o /dev/null -w "google:%{http_code}\n" --max-time 5 https://www.google.com && curl -s -o /dev/null -w "antigravity_oauth:%{http_code}\n" --max-time 5 https://oauth2.googleapis.com/'
```
Expected: both 200 or 404 (404 is fine — means reached, just unauth'd). If timeout, the server can't reach Google — **STOP**.

- [ ] **0.5 (skip when DOMAIN is the raw IP — current case)**

This step only applies when DOMAIN is a real hostname. Since we're using `49.51.187.129` directly, skip and proceed to Step 1.

> **STOP HERE if any of 0.1–0.5 fail.**

---

## STEP 1 — Sync code from local to server

- [ ] **1.1 Ensure local main is committed and pushed (or use rsync)**

Run on Dylan's machine:
```bash
cd /Users/dylanthomas/Desktop/projects/proxy-api
git status -sb
git log -n 3 --oneline
```
Expected: working tree clean, last 3 commits visible.

- [ ] **1.2 Create target directory on server**

```bash
ssh ${SERVER_USER}@${SERVER_HOST} "mkdir -p ${SERVER_TARGET_DIR}"
```

- [ ] **1.3 rsync the repo to the server (excludes data dirs and .env)**

```bash
rsync -av --delete \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='postgres_data' \
  --exclude='redis_data' \
  --exclude='data' \
  --exclude='.env' \
  --exclude='sub2api/frontend/node_modules' \
  --exclude='sub2api/backend/internal/web/dist' \
  /Users/dylanthomas/Desktop/projects/proxy-api/ \
  ${SERVER_USER}@${SERVER_HOST}:${SERVER_TARGET_DIR}/
```

Verify:
```bash
ssh ${SERVER_USER}@${SERVER_HOST} "ls ${SERVER_TARGET_DIR}/docker-compose.prod.yml ${SERVER_TARGET_DIR}/Caddyfile ${SERVER_TARGET_DIR}/scripts/deploy.sh"
```
Expected: all three files listed.

---

## STEP 2 — Generate production .env on server

- [ ] **2.1 Generate machine-secrets (PG / JWT / TOTP)**

Run on the server. These three secrets the agent generates itself:
```bash
ssh ${SERVER_USER}@${SERVER_HOST} bash <<'EOF'
set -e
mkdir -p /opt/proxy-api  # in case Step 1 hasn't run yet
cd /opt/proxy-api
PG_PW=$(openssl rand -hex 24)
JWT=$(openssl rand -hex 32)
TOTP=$(openssl rand -hex 32)
echo "PG_PASSWORD=${PG_PW}"
echo "JWT_SECRET=${JWT}"
echo "TOTP_ENCRYPTION_KEY=${TOTP}"
echo "${PG_PW}|${JWT}|${TOTP}" > /tmp/proxy-api-secrets.tmp
chmod 600 /tmp/proxy-api-secrets.tmp
EOF
```

Capture the three values and report them back to Dylan **immediately** (so he can save to 1Password) — they cannot be regenerated later without invalidating sessions and 2FA.

- [ ] **2.5 ⚠ ASK DYLAN FOR ADMIN PASSWORD**

**Do not generate the admin password.** Stop and prompt Dylan:

> "Ready to write the production .env. I need:
>   1. ADMIN_EMAIL  (suggest: `admin@cloudcodeapi.local` or your real email — used for login + Let's Encrypt notices later)
>   2. ADMIN_PASSWORD (you generate this — needs to be strong)
>
> Reply with both values and I'll write the .env."

Wait for Dylan's response. If he just says "use openssl", confirm: "Should I generate `openssl rand -base64 24` for you? Then I'll show you the value to save."

- [ ] **2.6 Write .env on the server**

Once Dylan provides ADMIN_EMAIL + ADMIN_PASSWORD:
```bash
ssh ${SERVER_USER}@${SERVER_HOST} bash <<EOF
set -e
cd ${SERVER_TARGET_DIR}
if [ -f .env ]; then
  echo "WARNING: .env already exists. Backing up to .env.bak.\$(date +%s)"
  cp .env .env.bak.\$(date +%s)
fi
IFS='|' read -r PG_PW JWT TOTP < /tmp/proxy-api-secrets.tmp
cat > .env <<INNER
DOMAIN=${DOMAIN}
ACME_EMAIL=${ACME_EMAIL}
POSTGRES_DB=sub2api
POSTGRES_USER=sub2api
POSTGRES_PASSWORD=\${PG_PW}
SERVER_MODE=release
RUN_MODE=standard
TZ=Asia/Shanghai
JWT_SECRET=\${JWT}
TOTP_ENCRYPTION_KEY=\${TOTP}
ADMIN_EMAIL=${ADMIN_EMAIL}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
GATEWAY_ANTIGRAVITY_FORWARD_BASE_URL=prod
REDIS_PASSWORD=
INNER
chmod 600 .env
shred -u /tmp/proxy-api-secrets.tmp || rm -f /tmp/proxy-api-secrets.tmp
echo "OK: .env written and temp secrets file shredded"
EOF
```

---

## STEP 3 — Build + start the stack

- [ ] **3.1 Run the deploy script**

```bash
ssh -t ${SERVER_USER}@${SERVER_HOST} "cd ${SERVER_TARGET_DIR} && ./scripts/deploy.sh"
```

This will:
1. Source `.env` and check required vars
2. Sanity-check DNS resolves to the server
3. `docker compose -f docker-compose.prod.yml up -d --build` (first build takes 5-10 min)
4. Wait up to 60s for sub2api healthcheck
5. `curl https://${DOMAIN}/` and report HTTP code

Expected ending:
```
✓ https://${DOMAIN}/ returned 200
```

If anything fails, capture the failing log line and STOP.

- [ ] **3.2 Verify all containers are healthy**

```bash
ssh ${SERVER_USER}@${SERVER_HOST} "cd ${SERVER_TARGET_DIR} && docker compose -f docker-compose.prod.yml ps"
```
Expected: 4 containers (`sub2api`, `sub2api-postgres`, `sub2api-redis`, `caddy`), all `Up (healthy)`.

- [ ] **3.3 Smoke test the public endpoint from the user's browser perspective**

```bash
curl -s --max-time 10 -o /dev/null -w "%{http_code}\n" https://${DOMAIN}/
```
Expected: `200`. The CloudCodeAPI editorial landing page should load in a browser.

> **STOP HERE if smoke test fails.** Likely causes: TLS issuance pending (wait 60s), DNS not propagated yet, Caddy can't reach sub2api (check `docker compose -f docker-compose.prod.yml logs caddy`).

---

## STEP 4 — First admin login + setup

- [ ] **4.1 Open `https://${DOMAIN}/login` in a browser**

⚠ **Self-signed TLS warning**: Dylan's browser will show "Your connection is not private" / "NET::ERR_CERT_AUTHORITY_INVALID" — that's expected because Caddy uses its own internal CA (no Let's Encrypt for raw IP). Click:
- Chrome / Edge: **Advanced → Proceed to ${DOMAIN} (unsafe)**
- Safari: **Show details → visit this website → Visit Website**
- Firefox: **Advanced → Accept the Risk and Continue**

After accepting once per browser, all subsequent visits are smooth.

Login with `ADMIN_EMAIL` + `ADMIN_PASSWORD`. Expected: redirected to `/admin/dashboard`.

- [ ] **4.2 (Optional) Confirm onboarding tour starts and lets you skip**

The driver.js tour appears on first admin login. Either step through it or close it.

---

## STEP 5 — Add an Antigravity account (OAuth)

This is the load-bearing piece that makes the proxy actually serve Claude requests.

- [ ] **5.1 Navigate to admin Accounts page**

In the side nav: **账号管理** (Accounts). Empty state shown.

- [ ] **5.2 Click "添加账号" / "Add Account"**

A modal opens. In the type selector, choose **Antigravity**.

- [ ] **5.3 Fill account meta**

- Name: `antigravity-dylan-pro` (or whatever Dylan prefers)
- Description: e.g. `Personal Google AI Pro subscription`
- Group: leave default or pick one
- Other fields: defaults are fine

- [ ] **5.4 Click "Authorize" / "授权" — initiates OAuth**

A new browser tab opens to a Google OAuth consent screen. Dylan must:
1. Sign in with the Google account that has Google AI Pro / Antigravity access
2. Approve the requested scopes (cloud-platform, userinfo.*)
3. Get redirected back to `https://${DOMAIN}/admin/accounts` with a success toast

⚠ **Two IP-mode gotchas to watch for:**

(a) **OAuth callback URL must be HTTPS — IP is fine but cert warning may interrupt.** When Google redirects back to `https://49.51.187.129/...`, the browser may show the cert warning AGAIN if Dylan is on a different browser/device than Step 4.1. He must accept the cert warning here too, otherwise the redirect dies and the OAuth flow times out.

(b) **Google may reject `redirect_uri` if it's a raw IP and the OAuth client wasn't pre-configured for it.** If Dylan sees "redirect_uri_mismatch":
  - The built-in sub2api OAuth client probably doesn't have `https://49.51.187.129/...` registered
  - Workarounds: 
    - Use a free DNS like `49-51-187-129.sslip.io` (resolves to the IP, but is a real hostname Google accepts) → update DOMAIN, redeploy
    - Or provide his own GCP OAuth Client with the IP added as authorized redirect URI

If Dylan sees "Access blocked" or "Error 403: org_internal" — the OAuth client used is the **built-in sub2api client**. He can either:
  (a) Use any Google account that's not org-restricted, OR
  (b) Provide his own GCP OAuth Client ID/Secret via env (`ANTIGRAVITY_OAUTH_CLIENT_SECRET`)

- [ ] **5.5 Verify token refresh succeeded**

```bash
ssh ${SERVER_USER}@${SERVER_HOST} "cd ${SERVER_TARGET_DIR} && docker compose -f docker-compose.prod.yml logs --tail 30 sub2api | grep -iE 'antigravity|token'"
```
Expected: lines like `token_refresh.success` or `account_created`. NO `proxy unavailable` or `EOF` errors.

- [ ] **5.6 In admin UI, verify the account row shows Status = green dot (live)**

If degraded/error: re-trigger token refresh from the row's action menu, or re-do OAuth.

---

## STEP 6 — Create a user-facing API key for testing

- [ ] **6.1 Side nav → "API 密钥" (API Keys) → "创建密钥"**

Fill: name = `dylan-self-test`, group = whatever group has the antigravity account. Submit.

- [ ] **6.2 Copy the generated key** (shown ONCE in a modal — copy now or it's gone)

- [ ] **6.3 Test with curl from any machine with internet**

```bash
curl https://${DOMAIN}/v1/messages \
  -H "x-api-key: <THE_KEY>" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-3-5-sonnet-20241022",
    "max_tokens": 64,
    "messages": [{"role": "user", "content": "say hi in 3 words"}]
  }'
```

Expected: a JSON response containing `"content":[{"type":"text","text":"..."}]` with a 3-word greeting.

If you get `401`: the key is wrong. `429`: rate-limited (try Sonnet 3.5 Haiku). `503` or `proxy_unavailable`: the antigravity account isn't healthy — go back to 5.5.

---

## STEP 7 — Invite friends

- [ ] **7.1 Side nav → 用户管理 → 添加用户**

For each friend: enter their email + a temp password. Save.

- [ ] **7.2 Send each friend their credentials**

The brand visible on `https://${DOMAIN}/login` is **CloudCodeAPI** (decoupled from any backend siteName). They log in and create their own API keys under their own account.

- [ ] **7.3 Decide on quota / billing per friend**

In the user's row → 编辑 → set `Balance` (e.g. $5 of credit), `Concurrency limit`, or per-key rate limits.

---

## STEP 8 — Backup + monitoring setup (lightweight)

- [ ] **8.1 Schedule a daily Postgres dump**

```bash
ssh ${SERVER_USER}@${SERVER_HOST} bash <<'EOF'
mkdir -p /var/backups/proxy-api
cat > /etc/cron.daily/proxy-api-backup <<'INNER'
#!/usr/bin/env bash
set -e
TS=$(date +%Y%m%d-%H%M%S)
docker exec sub2api-postgres pg_dump -U sub2api sub2api | gzip > /var/backups/proxy-api/sub2api-${TS}.sql.gz
# keep only last 14 days
find /var/backups/proxy-api -name 'sub2api-*.sql.gz' -mtime +14 -delete
INNER
chmod +x /etc/cron.daily/proxy-api-backup
EOF
```

Verify:
```bash
ssh ${SERVER_USER}@${SERVER_HOST} '/etc/cron.daily/proxy-api-backup && ls -lh /var/backups/proxy-api/'
```
Expected: a `.sql.gz` file ≥ 50KB.

- [ ] **8.2 (Optional) Set up uptime ping**

If Dylan uses uptime-kuma or healthchecks.io, add a check for `https://${DOMAIN}/` every 5 min.

---

## STEP 9 — Handoff document

- [ ] **9.1 Print the deployment summary**

Print the following block back to Dylan:

```
═══════════════════════════════════════════════════════════
 CloudCodeAPI deployment complete
───────────────────────────────────────────────────────────
 URL:                    https://${DOMAIN}
 Admin email:            ${ADMIN_EMAIL}
 Admin password:         (in Dylan's secret store)
 Server:                 ${SERVER_HOST} (Santa Clara, CA)
 Repo on server:         ${SERVER_TARGET_DIR}
 Backup location:        /var/backups/proxy-api/  (daily, 14d retention)

 Antigravity account:    1 added, status = live
 First test API key:     dylan-self-test (saved in 1Password)

 Common ops:
   ssh ${SERVER_USER}@${SERVER_HOST}
   cd ${SERVER_TARGET_DIR}
   docker compose -f docker-compose.prod.yml ps
   docker compose -f docker-compose.prod.yml logs -f sub2api
   docker compose -f docker-compose.prod.yml restart sub2api

 Pull latest code + redeploy:
   (on local) ./scripts/sync-and-deploy.sh    # TODO if Dylan wants
   (on server) cd ${SERVER_TARGET_DIR} && git pull && ./scripts/deploy.sh
═══════════════════════════════════════════════════════════
```

---

## Failure rollback

If the deploy goes sideways AND a previous successful version exists, on the server:

```bash
cd ${SERVER_TARGET_DIR}
docker compose -f docker-compose.prod.yml down
git reset --hard <previous-good-commit>
./scripts/deploy.sh
```

Postgres data persists across `down` (volume on host fs at `./postgres_data`). The schema migrates forward gracefully on first boot.

---

## Files this plan touches

Created on Dylan's local repo by this plan author (already committed in main):
- `docker-compose.prod.yml`
- `Caddyfile`
- `scripts/deploy.sh`
- `.env.production.example`
- `docs/superpowers/plans/2026-04-21-server-deployment.md` (this file)

Created on server by GPT during execution:
- `${SERVER_TARGET_DIR}/.env` (secrets — never commit)
- `${SERVER_TARGET_DIR}/postgres_data/` (DB volume)
- `${SERVER_TARGET_DIR}/redis_data/` (Redis AOF)
- `${SERVER_TARGET_DIR}/data/` (sub2api app data)
- `/etc/cron.daily/proxy-api-backup`

---

## Out of scope (Dylan does later, manually)

- Cursor sidecar integration
- Stripe / payment processing
- Public open-registration (currently admin-invite only)
- Multi-region failover
- CDN in front (Cloudflare proxied vs DNS-only)
