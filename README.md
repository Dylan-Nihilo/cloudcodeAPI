# proxy-api

Claude-first API relay built on a fork of [sub2api](https://github.com/Wei-Shaw/sub2api), re-skinned with a black-and-white minimalist UI.

- **Spec:** `docs/superpowers/specs/2026-04-18-proxy-api-design.md`
- **Plan:** `docs/superpowers/plans/2026-04-18-proxy-api-implementation.md`

## Quick start

```bash
cp .env.example .env
# Edit .env — set POSTGRES_PASSWORD, JWT_SECRET, TOTP_ENCRYPTION_KEY.
# Generate secrets with: openssl rand -hex 32
./scripts/dev.sh
# open http://localhost:8080
```

## Update the sub2api subtree

```bash
./scripts/update-sub2api.sh        # pull upstream main
./scripts/update-sub2api.sh <ref>  # pin to a specific upstream ref
```

## Production release flow

```bash
git push origin main
```

- GitHub Actions builds `./sub2api` and pushes `ghcr.io/dylan-nihilo/cloudcodeapi:main`
- The server keeps the repo checked out for compose/Caddy/env files
- On the server, deploy with:

```bash
git pull
./scripts/deploy.sh
```
