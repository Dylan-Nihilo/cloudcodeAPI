#!/usr/bin/env bash
# proxy-api production deploy on a fresh server.
# Idempotent: safe to re-run.
#
# Pre-conditions (run on server, root or sudo user):
#   - Docker + Docker Compose v2 installed
#   - Repo synced into /opt/proxy-api (or wherever)
#   - .env created from .env.production.example with secrets filled in
#   - SUB2API_IMAGE points at a published registry image
#   - For DOMAIN = real hostname: DNS A record points to server IP
#   - For DOMAIN = raw IP: nothing extra (Caddy uses self-signed TLS)
#
# Usage:  ./scripts/deploy.sh
set -euo pipefail

cd "$(dirname "$0")/.."

# ─── Pre-flight ─────────────────────────────────────────────────────
if [ ! -f .env ]; then
  echo "Error: .env not found. Copy .env.production.example → .env and fill in values." >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "Error: Docker daemon not reachable. Install/start Docker first." >&2
  exit 1
fi

if docker compose version >/dev/null 2>&1; then
  COMPOSE_BIN=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_BIN=(docker-compose)
else
  echo "Error: neither 'docker compose' nor 'docker-compose' is available." >&2
  exit 1
fi

# Source .env so we can sanity-check critical vars
set -a; . ./.env; set +a

: "${DOMAIN:?DOMAIN missing in .env}"
: "${ACME_EMAIL:?ACME_EMAIL missing in .env}"
: "${SUB2API_IMAGE:?SUB2API_IMAGE missing in .env}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD missing in .env}"
: "${JWT_SECRET:?JWT_SECRET missing in .env}"
: "${TOTP_ENCRYPTION_KEY:?TOTP_ENCRYPTION_KEY missing in .env}"
: "${ADMIN_EMAIL:?ADMIN_EMAIL missing in .env}"
: "${ADMIN_PASSWORD:?ADMIN_PASSWORD missing in .env}"

echo "── Deploying $DOMAIN ──"
echo "sub2api image: $SUB2API_IMAGE"

wait_for_health() {
  local container="$1"
  local timeout="$2"
  local label="$3"

  for i in $(seq 1 "$timeout"); do
    status=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container" 2>/dev/null || echo "missing")
    if [ "$status" = "healthy" ] || [ "$status" = "running" ]; then
      echo "$label ready after ${i}s"
      return 0
    fi
    sleep 1
  done

  echo "Error: $label failed to become ready within ${timeout}s" >&2
  docker logs --tail 50 "$container" 2>/dev/null || true
  exit 1
}

if [ -n "${GHCR_USERNAME:-}" ] && [ -n "${GHCR_TOKEN:-}" ]; then
  echo "Logging into ghcr.io as ${GHCR_USERNAME}…"
  printf '%s' "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USERNAME" --password-stdin >/dev/null
fi

# ─── DNS / IP sanity check ──────────────────────────────────────────
# Detect if DOMAIN is a raw IPv4 address. If so, skip DNS resolution
# (there's nothing to resolve) and rely on Caddy's self-signed TLS.
IS_IP=false
if [[ "$DOMAIN" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  IS_IP=true
  echo "DOMAIN is a raw IP — Caddy will use self-signed TLS (browsers will warn)."
fi

if [ "$IS_IP" = false ]; then
  RESOLVED=$(getent hosts "$DOMAIN" | awk '{print $1}' | head -1 || true)
  PUBLIC_IP=$(curl -sfL --max-time 5 https://api.ipify.org || echo unknown)
  echo "DNS:    $DOMAIN → $RESOLVED"
  echo "Server: $PUBLIC_IP"
  if [ -n "$RESOLVED" ] && [ "$PUBLIC_IP" != "unknown" ] && [ "$RESOLVED" != "$PUBLIC_IP" ]; then
    echo "WARNING: DNS does not resolve to this server. Caddy TLS issuance will fail."
    read -rp "Continue anyway? (y/N) " ans
    [ "$ans" = "y" ] || exit 1
  fi
fi

# ─── Pull + start ───────────────────────────────────────────────────
echo "Pulling runtime images…"
docker pull "$SUB2API_IMAGE"
"${COMPOSE_BIN[@]}" -f docker-compose.prod.yml pull postgres redis caddy

echo "Starting postgres + redis…"
"${COMPOSE_BIN[@]}" -f docker-compose.prod.yml up -d postgres redis
wait_for_health sub2api-postgres 90 "postgres"
wait_for_health sub2api-redis 60 "redis"

echo "Recreating sub2api…"
docker rm -f sub2api >/dev/null 2>&1 || true
"${COMPOSE_BIN[@]}" -f docker-compose.prod.yml up -d --no-deps sub2api

# ─── Wait for health ────────────────────────────────────────────────
echo "Waiting for sub2api to become healthy…"
wait_for_health sub2api 120 "sub2api"

echo "Refreshing Caddy…"
"${COMPOSE_BIN[@]}" -f docker-compose.prod.yml up -d caddy

# ─── Smoke tests ────────────────────────────────────────────────────
echo "Smoke testing public endpoint…"
sleep 3
# -k: tolerate self-signed cert when DOMAIN is an IP
HTTP_CODE=$(curl -skfL --max-time 15 -o /dev/null -w "%{http_code}" "https://${DOMAIN}/" || echo "fail")
if [ "$HTTP_CODE" = "200" ]; then
  echo "✓ https://${DOMAIN}/ returned 200"
else
  echo "✗ https://${DOMAIN}/ returned $HTTP_CODE — check '${COMPOSE_BIN[*]} -f docker-compose.prod.yml logs caddy' and 'logs sub2api'"
  exit 1
fi

echo
echo "─────────────────────────────────────"
echo " Deploy complete:"
echo "   URL:       https://${DOMAIN}"
echo "   Admin:     ${ADMIN_EMAIL}"
echo "   Password:  (in .env)"
if [ "$IS_IP" = true ]; then
  echo "   Note:      Self-signed TLS — browsers warn on first visit."
  echo "              Click 'Advanced → Proceed to ${DOMAIN}'."
fi
echo "─────────────────────────────────────"
echo "Next: log in, go to Admin → Accounts, add an Antigravity account via OAuth."
