# proxy-api Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up a self-hosted Claude-first API relay by forking sub2api, then layering a black-and-white minimalist re-skin on its Vue3 frontend, with cursor2api wired in as a sidecar upstream.

**Architecture:** Single git repo containing the full subtree of sub2api. Root-level `docker-compose.yml` orchestrates the multi-service stack (postgres + redis + sub2api + later cursor2api + Caddy). Frontend re-skin lives in `sub2api/frontend/src/design/` as a localized layer that minimizes upstream-merge conflicts.

**Tech Stack:** Go 1.25.7 (sub2api backend, untouched) · Vue 3.4 + Vite 5 + TailwindCSS (existing frontend, re-skinned) · Radix Vue + lucide-vue-next + @vueuse/core (new) · PostgreSQL 15 + Redis 7 · Docker Compose v2 · Caddy 2 (Phase 2+)

**Reference spec:** `docs/superpowers/specs/2026-04-18-proxy-api-design.md`

---

## File Structure

```
proxy-api/                                 # ← this repo (already git init'd)
├── .gitignore                             # NEW (Task 1)
├── README.md                              # NEW (Task 1, brief)
├── .env                                   # gitignored, populated from .env.example
├── .env.example                           # NEW (Task 5)
├── docker-compose.yml                     # NEW (Task 4)
├── docker-compose.override.example.yml    # NEW (Task 4, for cursor2api in Phase 1)
│
├── sub2api/                               # subtree-added in Task 2
│   ├── (upstream code, untouched)
│   ├── frontend/
│   │   ├── package.json                   # MODIFIED in Task 9 (add deps)
│   │   ├── tailwind.config.js             # MODIFIED in Task 11 (use our preset)
│   │   └── src/
│   │       ├── main.ts                    # MODIFIED in Task 10 (import tokens.css + fontsource)
│   │       ├── design/                    # NEW (Tasks 10-13+)
│   │       │   ├── tokens.css
│   │       │   ├── tailwind.preset.js
│   │       │   ├── primitives/Dialog.vue, Dropdown.vue, Tooltip.vue
│   │       │   ├── components/Button.vue, Card.vue, Input.vue, Textarea.vue,
│   │       │   │              Select.vue, Table.vue, Tag.vue, Badge.vue,
│   │       │   │              Modal.vue, Drawer.vue, Toast.vue, EmptyState.vue,
│   │       │   │              Skeleton.vue, Stat.vue
│   │       │   ├── layouts/AppShell.vue, AuthShell.vue
│   │       │   └── icons/index.ts
│   │       └── branding/                  # NEW (Task 13)
│   │           ├── logo.svg
│   │           └── product-meta.ts        # name, tagline, footer text
│   └── (everything else upstream)
│
├── docs/
│   └── superpowers/
│       ├── specs/2026-04-18-proxy-api-design.md   # already committed
│       └── plans/2026-04-18-proxy-api-implementation.md   # this file
│
└── scripts/
    ├── dev.sh                             # NEW (Task 6)
    └── update-sub2api.sh                  # NEW (Task 6)
```

---

## Milestone Overview

| Milestone | What you can show afterwards | Tasks |
|---|---|---|
| **A** Phase 0 stack up | sub2api default UI rendering at `localhost:8080`, login works, you can add an upstream API key and call `/v1/messages` | 1 – 8 |
| **B** Design system foundation | tokens.css applied, first re-skinned component visible (Button) | 9 – 14 |
| **C** Re-skin P0 views | AppShell, Dashboard, API Keys, Upstream accounts, Login all in B/W minimalist | 15 – 22 |
| **D** Phase 1 — add cursor2api sidecar | cursor2api responding via sub2api as one of the upstreams | 23 – 26 |
| **E** P1 + P2 view re-skin | All remaining views consistent | 27 – 30 |
| **F** Phase 2 — public deploy | TLS-enabled deploy via Caddy | 31 – 34 |

The user wants "launch something to see" — **Milestone A is the first show-and-tell**. Stop after A, demo, then continue to B.

---

## Milestone A — Phase 0 Stack Bootstrap

### Task 1: Repo skeleton (gitignore + README)

**Files:**
- Create: `.gitignore`
- Create: `README.md`

- [ ] **Step 1: Write `.gitignore`**

```
# env
.env
.env.local

# OS
.DS_Store
Thumbs.db

# editors
.vscode/
.idea/
*.swp

# node (if we ever lint at root)
node_modules/

# docker volumes
postgres-data/
redis-data/

# build artifacts (sub2api builds inside its dir; this is belt-and-suspenders)
dist/
*.log
```

- [ ] **Step 2: Write minimal `README.md`**

```markdown
# proxy-api

Claude-first API relay built on a fork of [sub2api](https://github.com/Wei-Shaw/sub2api),
re-skinned with a black-and-white minimalist UI.

See `docs/superpowers/specs/2026-04-18-proxy-api-design.md` for the full design.
See `docs/superpowers/plans/2026-04-18-proxy-api-implementation.md` for the build plan.

## Quick start

```bash
cp .env.example .env
# edit .env — set POSTGRES_PASSWORD, JWT_SECRET, TOTP_ENCRYPTION_KEY
./scripts/dev.sh
# open http://localhost:8080
```
```

- [ ] **Step 3: Commit**

```bash
git add .gitignore README.md
git commit -m "chore: add gitignore and README skeleton"
```

---

### Task 2: Subtree-add sub2api

**Files:**
- New directory tree: `sub2api/` (entire upstream repo merged into our history via subtree)

- [ ] **Step 1: Add upstream as a remote (read-only convenience)**

```bash
git remote add sub2api-upstream https://github.com/Wei-Shaw/sub2api.git
git fetch sub2api-upstream
```

Expected: fetch completes, no errors.

- [ ] **Step 2: Subtree add the upstream main branch into `sub2api/`**

```bash
git subtree add --prefix=sub2api sub2api-upstream main --squash
```

Expected: a new commit `Add 'sub2api/' from commit ...`. Browse `sub2api/` and confirm `frontend/`, `backend/`, `Dockerfile`, `docker-compose.yml`, `.env.example` exist.

- [ ] **Step 3: Verify subtree integrity**

```bash
ls sub2api/frontend/src
ls sub2api/backend
test -f sub2api/Dockerfile && echo OK
test -f sub2api/.env.example && echo OK
```

Expected: directory listings show source folders; both `OK` lines print.

- [ ] **Step 4: Verify git log captured the subtree commit**

```bash
git log --oneline -n 5
```

Expected: top entry is the subtree merge commit.

(No additional commit step — `git subtree add` creates its own commit.)

---

### Task 3: Inspect sub2api's bundled docker-compose

This is exploration, not modification. The goal is to ground subsequent tasks in reality before we write our orchestration.

- [ ] **Step 1: Read sub2api's docker-compose**

```bash
cat sub2api/docker-compose.yml
```

Note: service names, image references, port mappings, volume names, dependencies.

- [ ] **Step 2: Read sub2api's `.env.example`**

```bash
cat sub2api/.env.example
```

Note: every required and optional env var. We'll mirror them in our root-level `.env.example`.

- [ ] **Step 3: Read the Dockerfile**

```bash
head -40 sub2api/Dockerfile
```

Note: base image, build stages, exposed port.

(No commit — this is read-only inspection. Findings inform Task 4 and Task 5.)

---

### Task 4: Root-level `docker-compose.yml`

**Files:**
- Create: `docker-compose.yml`
- Create: `docker-compose.override.example.yml`

The root compose orchestrates from our perspective. It builds sub2api from the subtree and includes postgres + redis. cursor2api joins later via the override file (Milestone D).

- [ ] **Step 1: Write `docker-compose.yml`**

```yaml
# proxy-api root orchestration
# Phase 0: postgres + redis + sub2api
# Phase 1+: cursor2api joins via docker-compose.override.yml
# Phase 2+: caddy joins via docker-compose.prod.yml

services:
  postgres:
    image: postgres:15-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-sub2api}
      POSTGRES_USER: ${POSTGRES_USER:-sub2api}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?POSTGRES_PASSWORD must be set in .env}
    volumes:
      - postgres-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-sub2api}"]
      interval: 5s
      timeout: 5s
      retries: 10

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 10

  sub2api:
    build:
      context: ./sub2api
      dockerfile: Dockerfile
    restart: unless-stopped
    depends_on:
      postgres: { condition: service_healthy }
      redis:    { condition: service_healthy }
    environment:
      DATABASE_URL: postgres://${POSTGRES_USER:-sub2api}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB:-sub2api}?sslmode=disable
      REDIS_URL:    redis://redis:6379/0
      JWT_SECRET:   ${JWT_SECRET:?JWT_SECRET must be set in .env}
      TOTP_ENCRYPTION_KEY: ${TOTP_ENCRYPTION_KEY:?TOTP_ENCRYPTION_KEY must be set in .env}
      ADMIN_EMAIL:    ${ADMIN_EMAIL:-}
      ADMIN_PASSWORD: ${ADMIN_PASSWORD:-}
      SERVER_PORT:    ${SERVER_PORT:-8080}
    ports:
      - "${HOST_PORT:-8080}:${SERVER_PORT:-8080}"

volumes:
  postgres-data:
  redis-data:
```

> **Caveat the engineer must verify in Task 7:** sub2api's actual env-var names (e.g. is it `DATABASE_URL` or `DB_HOST`+`DB_PORT`+...?) come from Task 3's inspection. If sub2api uses different names, **edit this file before bringing the stack up**, do NOT guess.

- [ ] **Step 2: Write `docker-compose.override.example.yml` (placeholder for Phase 1)**

```yaml
# Copy to docker-compose.override.yml when wiring cursor2api in Phase 1.
# Docker Compose merges override.yml automatically.

services:
  cursor2api:
    image: ghcr.io/7836246/cursor2api:latest   # verify tag in Milestone D Task 23
    restart: unless-stopped
    environment:
      CURSOR_TOKEN: ${CURSOR_TOKEN:?CURSOR_TOKEN must be set in .env to enable cursor2api}
      API_KEY:      ${CURSOR2API_KEY:?CURSOR2API_KEY must be set in .env}
    # No host port exposed — sub2api reaches it via the docker network at http://cursor2api:3000
```

- [ ] **Step 3: Commit**

```bash
git add docker-compose.yml docker-compose.override.example.yml
git commit -m "feat: root docker-compose for postgres + redis + sub2api"
```

---

### Task 5: `.env.example` at repo root

**Files:**
- Create: `.env.example`

- [ ] **Step 1: Write `.env.example`**

```env
# ─── Postgres ─────────────────────────────────────────────────────────
POSTGRES_DB=sub2api
POSTGRES_USER=sub2api
POSTGRES_PASSWORD=replace_me_with_a_long_random_string

# ─── sub2api ──────────────────────────────────────────────────────────
# Generate: openssl rand -hex 32
JWT_SECRET=replace_me_with_openssl_rand_hex_32
TOTP_ENCRYPTION_KEY=replace_me_with_openssl_rand_hex_32

# Optional: seed admin account on first boot. Leave blank to use install wizard.
ADMIN_EMAIL=
ADMIN_PASSWORD=

# Server port (inside the container). Host port mapped via HOST_PORT.
SERVER_PORT=8080
HOST_PORT=8080

# ─── cursor2api (Phase 1+, only if using docker-compose.override.yml) ─
# Cursor session token (extracted from Cursor app keychain or browser DevTools).
# CURSOR_TOKEN=

# API key cursor2api will require from sub2api (you make this up; sub2api uses it
# when registering cursor2api as an upstream).
# CURSOR2API_KEY=
```

- [ ] **Step 2: Verify .env.example is gitignored target's mirror**

```bash
grep -E '^\.env$' .gitignore && echo "OK: .env is gitignored"
test -f .env.example && echo "OK: .env.example exists"
```

Both lines print.

- [ ] **Step 3: Commit**

```bash
git add .env.example
git commit -m "feat: env var template"
```

---

### Task 6: Helper scripts

**Files:**
- Create: `scripts/dev.sh`
- Create: `scripts/update-sub2api.sh`

- [ ] **Step 1: Write `scripts/dev.sh`**

```bash
#!/usr/bin/env bash
# Bring up the local dev stack.
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  echo "Error: .env not found. Run: cp .env.example .env  and fill in values." >&2
  exit 1
fi

docker compose up -d --build "$@"
echo
echo "Stack starting. UI will be at: http://localhost:${HOST_PORT:-8080}"
echo "Tail logs with:  docker compose logs -f sub2api"
```

- [ ] **Step 2: Write `scripts/update-sub2api.sh`**

```bash
#!/usr/bin/env bash
# Pull the latest upstream sub2api into the subtree.
# Pin a specific upstream commit by passing it as $1 (recommended for reproducibility).
set -euo pipefail

cd "$(dirname "$0")/.."

REF="${1:-main}"

echo "Pulling sub2api upstream at ref: $REF"
git subtree pull --prefix=sub2api sub2api-upstream "$REF" --squash
echo "Done. Review changes with: git log -n 5 --oneline"
```

- [ ] **Step 3: Make scripts executable**

```bash
chmod +x scripts/dev.sh scripts/update-sub2api.sh
ls -l scripts/
```

Expected: both files have `x` permission.

- [ ] **Step 4: Commit**

```bash
git add scripts/
git commit -m "feat: dev and update-sub2api helper scripts"
```

---

### Task 7: Bring up the stack & verify

This is the "show me" moment. No code changes — only bringing the stack up and validating.

- [ ] **Step 1: Create `.env` from template**

```bash
cp .env.example .env
```

- [ ] **Step 2: Generate real secrets and edit `.env`**

```bash
echo "POSTGRES_PASSWORD=$(openssl rand -hex 24)"
echo "JWT_SECRET=$(openssl rand -hex 32)"
echo "TOTP_ENCRYPTION_KEY=$(openssl rand -hex 32)"
```

Manually edit `.env` to substitute the printed values. **Do not commit `.env`** (it's gitignored).

- [ ] **Step 3: Verify Docker is running**

```bash
docker info >/dev/null 2>&1 && echo "OK: Docker daemon up" || { echo "Docker not running — start Docker Desktop"; exit 1; }
```

- [ ] **Step 4: Bring the stack up**

```bash
./scripts/dev.sh
```

Expected: postgres, redis, sub2api containers come up. The first build may take 3–10 minutes (Go compile + frontend build).

- [ ] **Step 5: Watch sub2api logs until it's listening**

```bash
docker compose logs -f sub2api
```

Wait for a line indicating server-listening on port 8080 (the exact text depends on sub2api). Press `Ctrl+C` to stop tailing.

- [ ] **Step 6: Smoke-test the HTTP endpoint**

```bash
curl -fsS -o /dev/null -w "%{http_code}\n" http://localhost:8080/
```

Expected: `200` (or `302` redirect to login).

- [ ] **Step 7: Open the UI in the browser and complete the install wizard**

Navigate to `http://localhost:8080`. If `ADMIN_EMAIL`/`ADMIN_PASSWORD` were set in `.env`, log in directly. Otherwise complete the install wizard.

**Verify:** dashboard loads. (UI is sub2api's stock Vue3+Tailwind look — re-skin happens in Milestone B/C.)

- [ ] **Step 8: Commit the verified state of the world**

(No code changed in Task 7. Just record completion in your task list.)

---

### Task 8: Tag Phase 0 stable

- [ ] **Step 1: Tag the current commit**

```bash
git tag -a phase-0-bootstrap -m "Phase 0: stack bootstrapped, sub2api UI reachable"
git tag -l
```

Expected: tag listed.

---

> **★ STOP HERE for first show-and-tell.** Demo Milestone A. Get user approval before continuing to Milestone B.

---

## Milestone B — Design System Foundation

### Task 9: Install frontend dependencies

**Files:**
- Modify: `sub2api/frontend/package.json`

- [ ] **Step 1: Inspect existing frontend tooling**

```bash
cat sub2api/frontend/package.json | head -50
ls sub2api/frontend
```

Note: package manager (likely `pnpm` per Vite norms — confirm via `pnpm-lock.yaml` or `package-lock.json` presence), Vite version, Vue version.

- [ ] **Step 2: Install new dependencies**

```bash
cd sub2api/frontend
# adjust pnpm/npm/yarn based on which lockfile exists
pnpm add radix-vue lucide-vue-next @vueuse/core @fontsource/inter @fontsource/jetbrains-mono
cd -
```

Expected: lockfile updated, no peer-dep errors.

- [ ] **Step 3: Verify install**

```bash
ls sub2api/frontend/node_modules/radix-vue/package.json
ls sub2api/frontend/node_modules/lucide-vue-next/package.json
```

Both exist.

- [ ] **Step 4: Commit**

```bash
git add sub2api/frontend/package.json sub2api/frontend/pnpm-lock.yaml   # or package-lock.json
git commit -m "feat(frontend): add design-system dependencies"
```

---

### Task 10: Design tokens (`tokens.css` + main.ts wiring)

**Files:**
- Create: `sub2api/frontend/src/design/tokens.css`
- Modify: `sub2api/frontend/src/main.ts` (or `main.js` — confirm in step 1)

- [ ] **Step 1: Locate the frontend entry**

```bash
ls sub2api/frontend/src/main.*
```

Note the exact filename — call it `<MAIN>` below.

- [ ] **Step 2: Write `tokens.css`**

```css
/* design/tokens.css — single source of truth for all visual tokens */

:root {
  /* ─── color: light theme ───────────────────────────────────────── */
  --color-ink:        #0A0A0A;          /* primary text / borders / accents */
  --color-paper:      #FAFAFA;          /* canvas background */
  --color-surface:    #FFFFFF;          /* card / elevated surface */
  --color-muted:      #6B7280;          /* secondary text */
  --color-subtle:     #9CA3AF;          /* tertiary text */
  --color-border:     #E5E7EB;          /* hairline divider */
  --color-border-strong: #1F1F1F;       /* dark accent border */

  --color-success:    #16A34A;
  --color-warning:    #D97706;
  --color-danger:     #DC2626;

  /* ─── radius ───────────────────────────────────────────────────── */
  --radius-sm:  4px;
  --radius-md:  8px;
  --radius-lg:  12px;

  /* ─── shadow ───────────────────────────────────────────────────── */
  --shadow-soft:   0 1px 2px rgba(0,0,0,0.04);
  --shadow-medium: 0 4px 12px rgba(0,0,0,0.06);

  /* ─── motion ───────────────────────────────────────────────────── */
  --ease-out:      cubic-bezier(0.16, 1, 0.3, 1);
  --duration-fast: 150ms;

  /* ─── type ─────────────────────────────────────────────────────── */
  --font-sans: "Inter", "PingFang SC", system-ui, -apple-system, sans-serif;
  --font-mono: "JetBrains Mono", ui-monospace, SFMono-Regular, Menlo, monospace;
}

/* ─── color: dark theme ──────────────────────────────────────────── */
.dark {
  --color-ink:        #FAFAFA;
  --color-paper:      #0A0A0A;
  --color-surface:    #141414;
  --color-muted:      #9CA3AF;
  --color-subtle:     #6B7280;
  --color-border:     #262626;
  --color-border-strong: #FAFAFA;

  --color-success:    #22C55E;
  --color-warning:    #F59E0B;
  --color-danger:     #EF4444;

  --shadow-soft:   0 1px 2px rgba(0,0,0,0.4);
  --shadow-medium: 0 4px 12px rgba(0,0,0,0.5);
}

/* ─── base reset (gentle, doesn't fight tailwind) ────────────────── */
html, body {
  background-color: var(--color-paper);
  color: var(--color-ink);
  font-family: var(--font-sans);
  -webkit-font-smoothing: antialiased;
  text-rendering: optimizeLegibility;
}

code, pre, kbd, samp {
  font-family: var(--font-mono);
}
```

- [ ] **Step 3: Wire it into `<MAIN>`**

Add at the top of the file (after framework imports):

```ts
import "@fontsource/inter/400.css"
import "@fontsource/inter/500.css"
import "@fontsource/inter/600.css"
import "@fontsource/jetbrains-mono/400.css"
import "./design/tokens.css"
```

- [ ] **Step 4: Rebuild the stack so the frontend picks up the new CSS**

```bash
docker compose up -d --build sub2api
```

- [ ] **Step 5: Browser-verify the font + neutral background applied**

Open `http://localhost:8080`, hard-refresh (Cmd+Shift+R). Body should now use Inter and have a near-white background. Open DevTools → Computed styles on `<body>` → confirm `font-family` lists `Inter`.

- [ ] **Step 6: Commit**

```bash
git add sub2api/frontend/src/design/tokens.css sub2api/frontend/src/main.*
git commit -m "feat(design): add design tokens and font wiring"
```

---

### Task 11: Tailwind preset bridging tokens → utility classes

**Files:**
- Create: `sub2api/frontend/src/design/tailwind.preset.js`
- Modify: `sub2api/frontend/tailwind.config.js`

- [ ] **Step 1: Read existing tailwind config to understand current shape**

```bash
cat sub2api/frontend/tailwind.config.js
```

Note: existing `theme.extend`, plugins, content paths.

- [ ] **Step 2: Write the preset**

```js
// design/tailwind.preset.js — tokens exposed as Tailwind theme keys
module.exports = {
  theme: {
    extend: {
      colors: {
        ink:           "var(--color-ink)",
        paper:         "var(--color-paper)",
        surface:       "var(--color-surface)",
        muted:         "var(--color-muted)",
        subtle:        "var(--color-subtle)",
        border:        "var(--color-border)",
        "border-strong": "var(--color-border-strong)",
        success:       "var(--color-success)",
        warning:       "var(--color-warning)",
        danger:        "var(--color-danger)",
      },
      borderRadius: {
        sm: "var(--radius-sm)",
        md: "var(--radius-md)",
        lg: "var(--radius-lg)",
      },
      boxShadow: {
        soft:   "var(--shadow-soft)",
        medium: "var(--shadow-medium)",
      },
      transitionTimingFunction: {
        "out-soft": "var(--ease-out)",
      },
      transitionDuration: {
        fast: "var(--duration-fast)",
      },
      fontFamily: {
        sans: "var(--font-sans)",
        mono: "var(--font-mono)",
      },
    },
  },
  darkMode: "class",
}
```

- [ ] **Step 3: Modify `tailwind.config.js` to consume the preset**

At the top of the existing config object, add:

```js
presets: [require("./src/design/tailwind.preset.js")],
```

(Keep the rest of the config — we're additive, not replacing.)

- [ ] **Step 4: Rebuild and verify**

```bash
docker compose up -d --build sub2api
```

Open the UI, inspect any element. Search for a class like `bg-paper` or `text-ink` in the compiled CSS via DevTools to confirm the preset loaded.

- [ ] **Step 5: Commit**

```bash
git add sub2api/frontend/src/design/tailwind.preset.js sub2api/frontend/tailwind.config.js
git commit -m "feat(design): tailwind preset bridging tokens"
```

---

### Task 12: Build the `Button` atom (representative component)

**Files:**
- Create: `sub2api/frontend/src/design/components/Button.vue`

- [ ] **Step 1: Write `Button.vue`**

```vue
<script setup lang="ts">
import { computed } from "vue"

interface Props {
  variant?: "primary" | "ghost" | "danger" | "link"
  size?: "sm" | "md" | "lg"
  disabled?: boolean
  loading?: boolean
  type?: "button" | "submit" | "reset"
}
const props = withDefaults(defineProps<Props>(), {
  variant: "primary",
  size: "md",
  disabled: false,
  loading: false,
  type: "button",
})
defineEmits<{ click: [MouseEvent] }>()

const variantClasses = computed(() => ({
  primary: "bg-ink text-paper hover:opacity-90 border border-ink",
  ghost:   "bg-transparent text-ink hover:bg-ink/5 border border-border",
  danger:  "bg-danger text-paper hover:opacity-90 border border-danger",
  link:    "bg-transparent text-ink underline-offset-4 hover:underline border-transparent p-0",
}[props.variant]))

const sizeClasses = computed(() => ({
  sm: "h-8 px-3 text-sm rounded-sm",
  md: "h-9 px-4 text-sm rounded-md",
  lg: "h-11 px-6 text-base rounded-md",
}[props.size]))
</script>

<template>
  <button
    :type="type"
    :disabled="disabled || loading"
    :class="[
      'inline-flex items-center justify-center gap-2 font-medium',
      'transition-[background-color,opacity,transform] duration-fast ease-out-soft',
      'disabled:opacity-50 disabled:cursor-not-allowed',
      'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ink/30 focus-visible:ring-offset-2',
      variantClasses,
      sizeClasses,
    ]"
    @click="$emit('click', $event)"
  >
    <span v-if="loading" class="inline-block w-3 h-3 border-2 border-current border-t-transparent rounded-sm animate-spin" />
    <slot />
  </button>
</template>
```

- [ ] **Step 2: Add a one-off route for visual smoke test**

Find sub2api's router file (likely `sub2api/frontend/src/router/index.ts`). Add a temporary route:

```ts
// TEMPORARY — remove after Milestone C is done
{ path: "/__design", component: () => import("@/design/__playground.vue") }
```

- [ ] **Step 3: Create the playground view**

Create `sub2api/frontend/src/design/__playground.vue`:

```vue
<script setup lang="ts">
import Button from "./components/Button.vue"
</script>

<template>
  <div class="min-h-screen bg-paper text-ink p-12">
    <h1 class="text-2xl font-semibold mb-8">Design Playground</h1>

    <section class="space-y-6">
      <div class="space-x-3">
        <Button variant="primary">Primary</Button>
        <Button variant="ghost">Ghost</Button>
        <Button variant="danger">Danger</Button>
        <Button variant="link">Link</Button>
      </div>
      <div class="space-x-3">
        <Button size="sm">Small</Button>
        <Button size="md">Medium</Button>
        <Button size="lg">Large</Button>
      </div>
      <div class="space-x-3">
        <Button disabled>Disabled</Button>
        <Button loading>Loading</Button>
      </div>
    </section>
  </div>
</template>
```

- [ ] **Step 4: Rebuild and visually verify**

```bash
docker compose up -d --build sub2api
```

Open `http://localhost:8080/__design`. All button variants and sizes render in the B/W aesthetic. Toggle dark mode via DevTools (`document.documentElement.classList.add('dark')`) and verify it inverts.

- [ ] **Step 5: Commit**

```bash
git add sub2api/frontend/src/design/components/Button.vue \
        sub2api/frontend/src/design/__playground.vue \
        sub2api/frontend/src/router/
git commit -m "feat(design): Button atom + playground route"
```

---

### Task 13: Build remaining atoms (Card, Input, Tag, Stat)

These four cover the 80% of dashboard surface. Subsequent atoms (Modal, Drawer, Toast, EmptyState, Skeleton) wait until a view actually demands them.

For each component:

**Files:**
- Create: `sub2api/frontend/src/design/components/Card.vue`
- Create: `sub2api/frontend/src/design/components/Input.vue`
- Create: `sub2api/frontend/src/design/components/Tag.vue`
- Create: `sub2api/frontend/src/design/components/Stat.vue`

- [ ] **Step 1: Write `Card.vue`**

```vue
<script setup lang="ts">
interface Props { padded?: boolean }
withDefaults(defineProps<Props>(), { padded: true })
</script>

<template>
  <div class="bg-surface border border-border rounded-md shadow-soft" :class="padded ? 'p-6' : ''">
    <slot />
  </div>
</template>
```

- [ ] **Step 2: Write `Input.vue`**

```vue
<script setup lang="ts">
interface Props { modelValue?: string; placeholder?: string; type?: string; disabled?: boolean }
withDefaults(defineProps<Props>(), { modelValue: "", type: "text", disabled: false })
defineEmits<{ "update:modelValue": [string] }>()
</script>

<template>
  <input
    :type="type"
    :value="modelValue"
    :placeholder="placeholder"
    :disabled="disabled"
    @input="$emit('update:modelValue', ($event.target as HTMLInputElement).value)"
    class="h-9 w-full px-3 text-sm rounded-md
           bg-surface text-ink placeholder:text-subtle
           border border-border
           focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ink/30 focus-visible:border-ink/40
           disabled:opacity-50 disabled:cursor-not-allowed
           transition-[border-color,box-shadow] duration-fast ease-out-soft"
  />
</template>
```

- [ ] **Step 3: Write `Tag.vue`**

```vue
<script setup lang="ts">
interface Props { tone?: "default" | "success" | "warning" | "danger" }
withDefaults(defineProps<Props>(), { tone: "default" })
</script>

<template>
  <span
    :class="[
      'inline-flex items-center gap-1.5 px-2 py-0.5 rounded-sm text-xs font-medium border',
      {
        default: 'bg-paper text-muted border-border',
        success: 'bg-paper text-success border-success/30',
        warning: 'bg-paper text-warning border-warning/30',
        danger:  'bg-paper text-danger  border-danger/30',
      }[tone],
    ]"
  >
    <slot />
  </span>
</template>
```

- [ ] **Step 4: Write `Stat.vue`**

```vue
<script setup lang="ts">
interface Props { label: string; value: string | number; hint?: string }
defineProps<Props>()
</script>

<template>
  <div class="bg-surface border border-border rounded-md p-5">
    <div class="text-xs uppercase tracking-wider text-subtle">{{ label }}</div>
    <div class="mt-2 text-3xl font-semibold tabular-nums">{{ value }}</div>
    <div v-if="hint" class="mt-1 text-xs text-muted">{{ hint }}</div>
  </div>
</template>
```

- [ ] **Step 5: Extend the playground to render them**

Edit `sub2api/frontend/src/design/__playground.vue` — add imports and a section:

```vue
<script setup lang="ts">
import Button from "./components/Button.vue"
import Card from "./components/Card.vue"
import Input from "./components/Input.vue"
import Tag from "./components/Tag.vue"
import Stat from "./components/Stat.vue"
import { ref } from "vue"
const text = ref("")
</script>
```

Add after the Buttons section:

```vue
    <section class="mt-12 grid grid-cols-3 gap-4">
      <Stat label="Requests today" :value="1234" hint="+12% vs yesterday" />
      <Stat label="Tokens consumed" value="9.2M" />
      <Stat label="Active keys" value="7" />
    </section>

    <section class="mt-12 max-w-md space-y-4">
      <Card>
        <h3 class="font-semibold">Card title</h3>
        <p class="text-sm text-muted mt-1">Body copy lives here.</p>
        <div class="mt-4 flex gap-2">
          <Tag>default</Tag>
          <Tag tone="success">healthy</Tag>
          <Tag tone="warning">degraded</Tag>
          <Tag tone="danger">down</Tag>
        </div>
      </Card>

      <Input v-model="text" placeholder="Type something…" />
      <p class="text-xs text-muted">Echo: {{ text }}</p>
    </section>
```

- [ ] **Step 6: Rebuild + visually verify**

```bash
docker compose up -d --build sub2api
```

Visit `http://localhost:8080/__design`. All four components render correctly in light + dark mode.

- [ ] **Step 7: Commit**

```bash
git add sub2api/frontend/src/design/components/ sub2api/frontend/src/design/__playground.vue
git commit -m "feat(design): Card, Input, Tag, Stat atoms"
```

---

### Task 14: Dark-mode toggle wiring (`@vueuse/core`)

**Files:**
- Create: `sub2api/frontend/src/design/composables/useDarkMode.ts`

- [ ] **Step 1: Write the composable**

```ts
import { useDark, useToggle } from "@vueuse/core"

export const useDarkMode = () => {
  const isDark = useDark({
    selector: "html",
    attribute: "class",
    valueDark: "dark",
    valueLight: "",
    storageKey: "proxy-api-theme",
  })
  return { isDark, toggle: useToggle(isDark) }
}
```

- [ ] **Step 2: Add a toggle to the playground**

In `__playground.vue` script:

```ts
import { useDarkMode } from "./composables/useDarkMode"
const { isDark, toggle } = useDarkMode()
```

In template, before the buttons section:

```vue
<div class="mb-8">
  <Button variant="ghost" @click="toggle()">{{ isDark ? "Light" : "Dark" }}</Button>
</div>
```

- [ ] **Step 3: Rebuild + verify**

```bash
docker compose up -d --build sub2api
```

Click the toggle on `/__design`. Theme swaps. Reload the page — preference persists.

- [ ] **Step 4: Commit**

```bash
git add sub2api/frontend/src/design/composables/useDarkMode.ts sub2api/frontend/src/design/__playground.vue
git commit -m "feat(design): dark-mode toggle composable"
```

---

> **★ STOP HERE for second show-and-tell.** Demo the design playground at `/__design`. Confirm aesthetic direction before reskinning the real views.

---

## Milestone C — Re-skin P0 Views (outline)

> **Detail to be filled in after Milestone B is approved.** Each P0 view becomes its own task with this template:
>
> 1. Read the original view file, list every visual class / hex / Element-style component it uses
> 2. Replace imports of upstream UI atoms with our `design/components/*` equivalents
> 3. Replace raw color/radius/shadow classes with token-backed Tailwind classes (`bg-surface` not `bg-white`, `rounded-md` not `rounded-lg`, etc.)
> 4. Keep all script logic, props, emits, store calls untouched
> 5. Rebuild, visually verify in light + dark mode
> 6. Commit

P0 views to address (one task each, in this order):

- **Task 15:** AppShell layout (sidebar + topbar)
- **Task 16:** Login view
- **Task 17:** Dashboard home (Stats + recent requests table)
- **Task 18:** API Key list view
- **Task 19:** Upstream account list view
- **Task 20:** Tag the Phase 0 stable build (`phase-0-reskin-p0`)
- **Task 21:** Remove the temporary `/__design` route
- **Task 22:** Update README screenshots (optional)

---

## Milestone D — cursor2api Sidecar (outline)

- **Task 23:** Verify cursor2api's official Docker image / build instructions; update `docker-compose.override.example.yml` with correct env vars
- **Task 24:** Extract a Cursor session token; populate `.env` with `CURSOR_TOKEN` and a `CURSOR2API_KEY`
- **Task 25:** `cp docker-compose.override.example.yml docker-compose.override.yml`, bring stack up
- **Task 26:** In sub2api admin UI, register `http://cursor2api:3000` as an Anthropic-compatible upstream using `CURSOR2API_KEY`. Test a `/v1/messages` request routed through it.

---

## Milestone E — P1 + P2 view re-skin (outline)

- **Task 27:** User / carpool group management
- **Task 28:** Billing page
- **Task 29:** Settings + Install wizard
- **Task 30:** 404 / 403 / error states

---

## Milestone F — Phase 2 Public Deploy (outline)

- **Task 31:** Acquire domain, point A record
- **Task 32:** Write `Caddyfile` (auto-TLS, reverse proxy to sub2api, basic rate limit)
- **Task 33:** Write `docker-compose.prod.yml` adding Caddy
- **Task 34:** Deploy to prod host, end-to-end smoke test (signup → first request)

---

## Self-Review Notes

Spec coverage check:
- §3 Scope (MVP) — Tasks 1–8 cover stack, 9–14 cover design system foundation, 15–22 cover P0 reskin → ✅
- §5 Design system — Tasks 9–14 implement tokens / preset / atoms → ✅
- §5.5 Hard rules — enforced by Task 15+ template (only import + class changes in views) → ✅
- §6 cursor2api sidecar — Tasks 23–26 → ✅
- §8 Phase 0/1/2 — A=0, D=1, F=2 → ✅
- §9 Fork sync workflow — Task 2 (initial), Task 6 (`update-sub2api.sh` script) → ✅
- §11 Phase 0 success criteria — Task 7 verifies stack-up + login; Task 14 verifies dark mode → ✅

Type/name consistency:
- Token names (`--color-ink`, `--color-paper`, etc.) used consistently in tokens.css (Task 10), preset (Task 11), components (Tasks 12–13)
- Button variants (primary/ghost/danger/link) match spec §5.2 exactly

Granularity:
- Milestones A and B are detailed at 2-5-min step granularity. C/D/E/F are outlined; they will be re-planned with this skill before each milestone starts.

---

## Appendix: When upstream sub2api conflicts during sync

```bash
./scripts/update-sub2api.sh                        # try clean pull
# if conflicts in views you imported design components into:
git status                                         # see conflicts
# resolve each: keep the upstream logic + your design imports
git add <resolved files>
git commit
```
