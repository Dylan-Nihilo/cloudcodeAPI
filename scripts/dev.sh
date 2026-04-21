#!/usr/bin/env bash
# Bring up the local dev stack.
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  echo "Error: .env not found." >&2
  echo "Run: cp .env.example .env  and fill in POSTGRES_PASSWORD, JWT_SECRET, TOTP_ENCRYPTION_KEY." >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "Error: Docker daemon not reachable. Start Docker Desktop." >&2
  exit 1
fi

docker compose up -d "$@"
echo
echo "Stack starting. Watch logs:  docker compose logs -f sub2api"
echo "UI will be at:               http://localhost:${HOST_PORT:-8080}"
