# proxy-api Design Spec

**Date:** 2026-04-18
**Author:** Dylan
**Status:** Draft (pending review)

---

## 1. Goal

Build a self-hosted **Claude-first API relay** that aggregates multiple Anthropic-compatible upstream sources (official API keys, third-party relays, IDE-subscription-based sources like Antigravity and Cursor) and exposes a single Anthropic-native `/v1/messages` endpoint to downstream clients.

The product starts as a private/small-group service and is designed to graduate to a public offering with branded UI.

## 2. Non-Goals

- **Not** building an LLM aggregator from scratch — we fork [sub2api](https://github.com/Wei-Shaw/sub2api) and stand on its shoulders.
- **Not** supporting OpenAI, Gemini, or other model families in the first cut. Anthropic Claude only.
- **Not** building a billing/payment system from scratch — sub2api ships with one; we use it as-is.
- **Not** implementing a Cursor adapter from scratch — we run [7836246/cursor2api](https://github.com/7836246/cursor2api) as a sidecar.
- **Not** rewriting the backend in another language. Go stays.
- **Not** redesigning the frontend's information architecture. We re-skin only.

## 3. Scope

### In Scope (MVP)

- Fork sub2api into this repository via `git subtree`.
- Add a **design system layer** (`frontend/src/design/`) and re-skin every visible view to a black-and-white minimalist aesthetic (Linear / Vercel / Raycast lineage).
- Compose a multi-service deployment (sub2api + cursor2api + Postgres + Redis + Caddy) via `docker-compose`.
- Wire cursor2api in as a regular Anthropic-compatible upstream registered inside sub2api's admin UI.
- Provide a `Phase 0 → Phase 3` rollout path from local dev to public service.

### Out of Scope (Future Phases)

- Custom upstream adapters beyond what sub2api and cursor2api already provide.
- Multi-region deployment.
- SSO / OAuth login for end users (sub2api's built-in auth suffices initially).
- Mobile-native client.

## 4. Architecture

### 4.1 Service Topology

```
Client (Claude Code SDK / curl / IDE plugin)
   │
   ▼
Caddy :443                         (TLS, basic rate limit)         [Phase 2+]
   │
   ▼
sub2api :8080                      (auth / routing / billing / group isolation)
   │
   ├──► api.anthropic.com          (official API key pool)
   ├──► <third-party relay>        (HTTP API key, Anthropic-compatible)
   ├──► Antigravity                (sub2api's built-in OAuth adapter)
   └──► cursor2api :3000           (sidecar, presents itself as Anthropic upstream)
            │
            └──► api2.cursor.sh    (ConnectRPC over HTTP/2, Cursor session token)
```

**Key insight:** sub2api never knows cursor2api is special. From its perspective, cursor2api is just another `/v1/messages`-speaking upstream with an API key.

### 4.2 Repository Layout

```
proxy-api/
├── README.md
├── .env.example                    # POSTGRES_*, REDIS_*, sub2api admin seed, cursor2api tokens
├── docker-compose.yml              # all services orchestrated here
├── Caddyfile                       # reverse proxy + auto TLS (Phase 2+)
│
├── sub2api/                        # git subtree from upstream Wei-Shaw/sub2api
│   ├── (upstream code, intentionally untouched outside frontend/src/design/)
│   ├── frontend/src/design/        # ← our reskin layer (NEW)
│   ├── frontend/src/branding/      # ← logo / favicon / product name (NEW)
│   └── ...
│
├── docs/
│   └── superpowers/specs/2026-04-18-proxy-api-design.md   # this file
│
└── scripts/
    ├── dev.sh                      # `docker-compose up` for local
    ├── update-sub2api.sh           # `git subtree pull` from upstream
    └── deploy.sh                   # production deploy helper
```

### 4.3 Why git subtree (not submodule)

- We modify sub2api's frontend daily — submodule's "pointer + separate history" adds friction for a single-developer workflow.
- subtree puts code directly in our repo; `git log` shows everything in one timeline.
- Upstream sync is `git subtree pull --prefix=sub2api …` on demand.

## 5. Frontend Re-skin: Design System Layer

### 5.1 Why a Layer (not in-place edits)

We will move from private to public, where a brand refresh is likely. A design-system layer makes the second refresh a token swap rather than a rewrite. It also localizes upstream-merge conflicts to a single directory.

### 5.2 Directory Structure

```
sub2api/frontend/src/design/
├── tokens.css                  # CSS vars: color / spacing / type / radius / shadow / motion (light + dark)
├── tailwind.preset.js          # exposes tokens to tailwind config
├── primitives/                 # headless behavior layer (Radix Vue)
│   ├── Dialog.vue
│   ├── Dropdown.vue
│   └── Tooltip.vue
├── components/                 # styled atoms
│   ├── Button.vue              # variants: primary | ghost | danger | link
│   ├── Card.vue
│   ├── Input.vue
│   ├── Textarea.vue
│   ├── Select.vue
│   ├── Table.vue
│   ├── Tag.vue / Badge.vue
│   ├── Modal.vue / Drawer.vue
│   ├── Toast.vue
│   ├── EmptyState.vue
│   ├── Skeleton.vue
│   └── Stat.vue                # dashboard number cards
├── layouts/
│   ├── AppShell.vue            # sidebar + topbar + content
│   └── AuthShell.vue           # login / register
└── icons/                      # lucide-vue-next wrapper
```

### 5.3 Design Tokens

| Dimension | Value | Note |
|---|---|---|
| Neutrals | `#0A0A0A` ink, `#FAFAFA` paper, `#FFFFFF` pure white | only color axis |
| Accent | single dark grey (`#1F1F1F`) — no brand color in MVP | restraint = premium |
| Status | grey-dominant; small color dot for success / warn / error | no saturated blocks |
| Type | `Inter` (UI) + `JetBrains Mono` (code) via `@fontsource/*`; `PingFang SC` and `system-ui` as CSS-stack fallbacks for CN / system | no CDN deps |
| Radius | `4px / 8px / 12px` only | no 24px+ web2 bubbles |
| Shadow | `0 1px 2px rgba(0,0,0,0.04)`, prefer 1px borders for separation | soft only |
| Spacing | multiples of 4; dense (this is a dashboard) | |
| Motion | 150ms ease-out default | restraint |
| Dark mode | required from day one (tokens duplicated) | trivial in B/W |

### 5.4 View Restyle Priorities

| Priority | Views |
|---|---|
| **P0** | AppShell, Dashboard home, API Key list, Upstream account list (all upstream types — official keys, third-party relays, OAuth-based subscriptions), Login |
| **P1** | User / carpool group management, Billing page, Settings |
| **P2** | Install wizard, 404 / 403, error states |

### 5.5 Hard Rules

- View files **must not** contain raw color hex, raw radius, or raw shadow values. Only design tokens or design components.
- View files keep their original logic, props, emits — only `import` paths and root-level Tailwind classes change.
- New files go under `design/` or `branding/` exclusively.

## 6. Upstream Integration: cursor2api as Sidecar

### 6.1 Decision

Run cursor2api as an **independent container** alongside sub2api. Register it in sub2api's admin UI as a regular Anthropic-compatible relay (with an API key cursor2api itself accepts).

### 6.2 Why Sidecar (not port code into sub2api)

- Zero modification to sub2api Go code → upstream merges stay clean.
- cursor2api's protocol-translation logic stays in its own project, updated independently.
- Failure isolation: if cursor2api crashes or its session token expires, the rest of the system is unaffected.
- We can swap cursor2api for an alternative Cursor proxy without touching sub2api.

### 6.3 Tradeoffs Accepted

- One extra container.
- Two layers of authentication (downstream → sub2api, sub2api → cursor2api).
- Slight added latency (one extra in-cluster hop, sub-millisecond on the same Docker network).

## 7. Dependencies

### 7.1 Core Runtime

| Component | Version | Source |
|---|---|---|
| sub2api | latest `main` at fork time | git subtree |
| cursor2api | upstream Docker image | unmodified |
| PostgreSQL | 15+ | official image |
| Redis | 7+ | official image |
| Caddy | 2.x | official image (Phase 2+) |

### 7.2 Frontend Re-skin Additions

| Package | Purpose |
|---|---|
| `radix-vue` | headless primitives (Dialog, Dropdown, Tooltip) — accessibility done right |
| `lucide-vue-next` | unified icon set |
| `@vueuse/core` | clipboard, dark-mode, hotkey composables |
| `@fontsource/inter` + `@fontsource/jetbrains-mono` | local fonts, no CDN dependency |

Existing chart library (whatever sub2api ships) is preserved.

## 8. Phased Rollout

| Phase | Services | Audience | Notes |
|---|---|---|---|
| **0** Local dev | postgres + redis + sub2api | Dylan only | localhost, no Caddy |
| **1** Trusted users | + cursor2api | small group / friends ("拼车") | sub2api group isolation per upstream pool |
| **2** Public | + Caddy + Cloudflare DNS | open registration | TLS, rate limit, branded landing |
| **3** As needed | optional: monitoring (Uptime Kuma), additional adapters | | only when actually demanded |

## 9. Fork & Upstream Sync Workflow

### 9.1 Initial Fork

```bash
git subtree add --prefix=sub2api https://github.com/Wei-Shaw/sub2api.git main --squash
```

### 9.2 Periodic Upstream Sync

```bash
./scripts/update-sub2api.sh
# wraps: git subtree pull --prefix=sub2api https://github.com/Wei-Shaw/sub2api.git main --squash
```

### 9.3 Conflict Containment

Because all our changes live under `sub2api/frontend/src/design/` and `sub2api/frontend/src/branding/` (new files) plus `import` line edits in existing views, conflicts almost always reduce to import-path resolutions — mechanical, low-risk.

## 10. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Cursor / Antigravity ToS — account ban risk for subscription scraping | Acknowledged. User accepts risk. Group-isolate so a single banned account doesn't cascade. Document account-rotation procedure. |
| Anthropic + Antigravity Claude can't share conversation context | sub2api already enforces this via groups; we surface this clearly in the UI. |
| Upstream sub2api makes breaking schema changes | Subtree squash + small change surface (only design layer + imports) limits blast radius. Pin upstream version in `update-sub2api.sh`. |
| Public phase brings abuse / freeloading | Caddy rate limit + sub2api built-in quota + Cloudflare WAF. |
| Frontend reskin drifts from upstream component changes | Hard rule: views only change `import` and root class. Logic edits go through a separate review. |

## 11. Success Criteria

- **Phase 0:** `docker-compose up` brings the stack online locally (postgres + redis + sub2api); `claude` CLI configured against `localhost:8080` returns a streaming response from at least one Anthropic-API-key upstream and one third-party relay upstream. Re-skinned UI renders correctly in light + dark mode.
- **Phase 1:** 3+ users on the same instance using carpool groups, with cursor2api wired in as one of the upstreams.
- **Phase 2:** Public domain serving requests over TLS; signup → first-request flow works end-to-end with the new visual identity.

## 12. Open Questions

None at spec time. Implementation may surface details (e.g., specific cursor2api env vars, Caddy snippet shape); these are plan-time concerns and will be tracked there.

---

## Appendix A: Reference Projects

- [Wei-Shaw/sub2api](https://github.com/Wei-Shaw/sub2api) — backend + original frontend (forked)
- [7836246/cursor2api](https://github.com/7836246/cursor2api) — Cursor → Anthropic Messages API translator (sidecar)
- [decolua/9router](https://github.com/decolua/9router), [router-for-me/CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) — alternative Cursor / multi-source proxies (reference only)
- [TensorZero: Reverse Engineering Cursor's LLM Client](https://www.tensorzero.com/blog/reverse-engineering-cursors-llm-client/) — protocol background
