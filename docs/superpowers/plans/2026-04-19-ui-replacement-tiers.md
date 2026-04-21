# CloudCodeAPI UI Replacement · Tiered Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the editorial CloudCodeAPI design language (validated in `__landing-comp.vue` and `__dashboard-comp.vue`) to the real sub2api views — without rewriting the backend or breaking script logic.

**Architecture:** Layered application of the design system. Each tier is its own commit-ready milestone. Lower tiers wrap (visually) all higher tiers, so executing top-down delivers visible value at each step.

**Tech Stack:** Vue 3.4 SFC + TailwindCSS + design tokens in `src/design/`. Lucide icons. Existing pinia stores, vue-router, vue-i18n untouched.

**Reference:**
- Design comps: `src/design/__landing-comp.vue`, `src/design/__dashboard-comp.vue`
- Tokens: `src/design/tokens.css`
- Tailwind preset: `src/design/tailwind.preset.js`
- Brand context: `.impeccable.md`
- Spec: `docs/superpowers/specs/2026-04-18-proxy-api-design.md`

---

## Hard rules (apply to every tier)

- **Don't touch logic.** Script section (props/emits/store calls/computed/i18n) is preserved as-is in every modified view, unless the tier explicitly authorizes a change (e.g. removing now-dead Icon imports).
- **No raw colors.** No `bg-gray-*`, `text-blue-*`, hex literals in templates. Use design tokens (`bg-paper`, `text-ink`, `border-border`) or palette keys (`bg-primary-500` → these flow through our preset to neutrals).
- **No raw radius / shadow.** Use `rounded-sm/md/lg`, `shadow-soft/medium`.
- **Preserve i18n keys.** All `t('...')` calls stay; we may rewrap them in different markup.
- **Preserve store wiring.** Every `useXStore()` call and reactive state stays.
- **Commit per file** (or per logical unit) so a bad change is easy to revert.
- **Test in browser** between commits. Vite HMR + manual browser refresh + check at least: light mode, dark mode, primary user paths.

---

## Milestone Overview

| Tier | Files | What changes | Effort |
|---|---|---|---|
| **1** Chrome | `AppLayout`, `AppHeader`, `AppSidebar` | All authenticated views adopt CloudCodeAPI shell | 3-4h |
| **2** Auth surface | `LoginView`, `RegisterView`, `ForgotPasswordView`, `ResetPasswordView` | Public-facing brand impression | 2h |
| **3** User primary | `user/DashboardView`, `user/KeysView`, `user/UsageView`, `user/ProfileView` | Daily user surfaces | 4h |
| **4** Admin primary | `admin/DashboardView`, `admin/AccountsView`, `admin/UsersView`, `admin/GroupsView` + key modals | Dylan's daily admin surfaces | 4h |

After Tier 4: stop. The remaining 30+ views (ops monitoring, payment flows, settings panels) inherit monochrome from the palette override and are accepted as-is until concrete demand surfaces.

---

# TIER 1 — App Chrome

**Why first:** every authenticated page renders inside `<AppLayout>` which composes `<AppSidebar>` and `<AppHeader>`. Reskinning these three transforms the visual experience of the entire post-login application without touching any page-level view.

**Reference target:** `__dashboard-comp.vue`'s sidebar + topbar.

## File structure (Tier 1)

| File | Current size | What we change |
|---|---|---|
| `src/components/layout/AppLayout.vue` | 52 lines | Already partly done. Verify wrapping uses `bg-paper`, no gradients. |
| `src/components/layout/AppHeader.vue` | 338 lines | Replace template entirely (no script changes). New 14px-tall bar with breadcrumb + search + bell + theme + avatar. |
| `src/components/layout/AppSidebar.vue` | 922 lines | Replace template entirely. Wordmark + workspace switcher + ghost nav with ink-active + bottom user pill. Script logic + stores preserved. |

## Tasks

### Task 1.1 — Audit AppLayout (verify Milestone B's earlier change still holds)

- [ ] **Step 1: Read current AppLayout**
  Run: `cat sub2api/frontend/src/components/layout/AppLayout.vue`
  Confirm: outer `<div>` uses `bg-paper text-ink`, no `bg-mesh-gradient` or other ornamental backdrop. Sidebar collapse logic still works.

- [ ] **Step 2: If AppLayout already conforms, no commit needed.** Otherwise edit per the design comp's outer wrap pattern.

### Task 1.2 — Reskin AppHeader

**Files:**
- Modify: `src/components/layout/AppHeader.vue` (template only)

- [ ] **Step 1: Read AppHeader to map content**
  - Note all i18n keys, store reads, slots, and event handlers in script.
  - Note what's in template: page title, mobile menu, doc link, locale switcher, balance pill, subscription mini, announcement bell, user dropdown.

- [ ] **Step 2: Write a new template aligned to dashboard comp's topbar:**
  - 14px tall (`h-14`), 1px bottom border
  - Left: breadcrumb (workspace › current page) — page title from existing logic
  - Right cluster: subscription progress + balance + announcements + locale + docs link + theme + user dropdown
  - Re-skin balance pill from `bg-primary-50 + gradient avatar` → `border-border + bg-ink avatar`
  - User dropdown trigger: `bg-ink` square avatar with initials
  - All icons via `lucide-vue-next` (replace `<Icon name="...">` with named imports)

- [ ] **Step 3: Verify in browser**
  Open `http://localhost:5173/admin/dashboard` (logged in). Header should be 14px tall, B/W, hairline-bordered. Click avatar → dropdown opens. Theme toggle works. Balance number renders.

- [ ] **Step 4: Commit**
  ```bash
  git add sub2api/frontend/src/components/layout/AppHeader.vue
  git commit -m "feat(layout): reskin AppHeader to editorial topbar"
  ```

### Task 1.3 — Reskin AppSidebar (the big one)

**Files:**
- Modify: `src/components/layout/AppSidebar.vue` (template only; script preserved)

This is 922 lines. Vast majority is template (icons, links, nested groups, collapse states). Strategy: read the script section first to inventory state/computed/methods, then completely rewrite the template referencing the dashboard comp's sidebar.

- [ ] **Step 1: Map script surface**
  - Read script section. Inventory: `sidebarCollapsed`, `mobileOpen`, `currentRoute`, `isAdmin`, `userMenuItems`, `adminMenuItems`, etc.
  - List every nav route the sidebar offers (we keep all of them).

- [ ] **Step 2: Inventory navigation items**
  - From the script's `menuItems` array (or wherever defined), list all entries: label, icon, path, badge, active condition.
  - Map each old icon to a `lucide-vue-next` icon (LayoutGrid, KeyRound, Server, Users, BarChart3, Settings, BookOpen, etc.)

- [ ] **Step 3: Rewrite template using design comp's sidebar pattern**
  Structure:
  ```
  <aside class="w-[240px] shrink-0 border-r border-border min-h-screen flex flex-col">
    <!-- wordmark (CloudCode + API split) -->
    <!-- workspace switcher (DT pill + plan meta + chevron) -->
    <!-- nav: workspace section + resources section -->
    <!-- bottom: user pill (avatar + name + role) -->
  </aside>
  ```
  - Preserve all `<router-link>` to-paths and `:active` logic
  - Active state: `bg-ink text-paper` (inverted), inactive: `text-muted hover:text-ink hover:bg-ink/[0.04]`
  - Nav badges (counts, "new" indicators) become `text-[11px] font-mono uppercase tracking-[0.12em]` next to label
  - Collapse state still respected (240px → 72px when `sidebarCollapsed`)

- [ ] **Step 4: Handle mobile**
  Sidebar should slide in from left on mobile (`lg:translate-x-0`, otherwise `-translate-x-full` controlled by `mobileOpen`).

- [ ] **Step 5: Verify in browser**
  - Sidebar shows wordmark, workspace pill, nav with all original routes
  - Click each nav item → routes correctly
  - Active route shows ink/paper inversion
  - Click collapse → narrows to 72px (icon-only)
  - Mobile: hamburger in header opens slide-out

- [ ] **Step 6: Commit**
  ```bash
  git add sub2api/frontend/src/components/layout/AppSidebar.vue
  git commit -m "feat(layout): reskin AppSidebar to editorial nav with ink-active"
  ```

### Task 1.4 — Tag the chrome milestone

- [ ] **Step 1: Tag stable**
  ```bash
  git tag -a tier-1-chrome -m "Tier 1 complete: chrome reskinned, all auth views wear CloudCodeAPI shell"
  ```

> **★ STOP HERE.** Demo to Dylan. Get green light before Tier 2.

---

# TIER 2 — Auth Surface

**Why next:** public-facing impression. After Tier 1 a logged-in user sees CloudCodeAPI; after Tier 2 a brand-new visitor sees CloudCodeAPI before they even sign in.

**Reference target:** Combine landing comp's brand stamp + a single-card form pattern (Vercel/Linear style).

## File structure (Tier 2)

| File | Current size approx | Visual target |
|---|---|---|
| `src/views/auth/LoginView.vue` | TBD-read | Two-column: left brand panel (CloudCode/API stamp), right login card |
| `src/views/auth/RegisterView.vue` | TBD-read | Same shell, register form |
| `src/views/auth/ForgotPasswordView.vue` | TBD-read | Same shell, simple email input |
| `src/views/auth/ResetPasswordView.vue` | TBD-read | Same shell, reset form |

## Tasks

### Task 2.1 — Build a shared `<AuthShell>` component

**Files:**
- Create: `src/design/layouts/AuthShell.vue`

- [ ] **Step 1: Write `AuthShell.vue`**
  Layout:
  - Full-screen 2-column on `md+`, single column on mobile
  - Left col (`md:flex-1` with `bg-paper`): centered brand stamp + small editorial caption
  - Right col (`md:w-[440px]` with `bg-surface`, 1px left border on `md+`): centered slot for form
  - Slot: `<slot />` for the form card
  - Header: locale switcher + theme toggle in top-right corner
  - Footer: `cloudcodeapi · v0.1 · operational` mono uppercase strip

- [ ] **Step 2: Commit**
  ```bash
  git add sub2api/frontend/src/design/layouts/AuthShell.vue
  git commit -m "feat(design): AuthShell layout for auth flows"
  ```

### Task 2.2 — Reskin LoginView using AuthShell

**Files:**
- Modify: `src/views/auth/LoginView.vue` (template only; script preserved)

- [ ] **Step 1: Read LoginView, inventory:**
  Form fields, validation state, OAuth buttons (LinuxDo, OIDC, etc.), error display, "remember me", forgot password link, register link, captcha if any.

- [ ] **Step 2: Wrap content in `<AuthShell>`**
  Inside slot:
  - h2 "Sign in" (light tracking-tight)
  - Email input → use design `<Input>` atom
  - Password input → same
  - Submit button → `bg-ink text-paper` primary
  - OAuth row: ghost-bordered buttons with provider icon + label
  - Error message: `text-danger` text inside `border border-danger/30 bg-danger/[0.03]` block
  - Bottom: "No account? Register →" + "Forgot password? →" muted links

- [ ] **Step 3: Verify**
  Visit `/login` while logged out. Submit valid + invalid creds. OAuth providers render. Locale + theme work in shell header.

- [ ] **Step 4: Commit**
  ```bash
  git add sub2api/frontend/src/views/auth/LoginView.vue
  git commit -m "feat(auth): reskin LoginView with editorial AuthShell"
  ```

### Task 2.3 — Reskin RegisterView, ForgotPasswordView, ResetPasswordView

For each: same wrap-in-AuthShell pattern as LoginView. Each commit:

- [ ] **Step 1**: `RegisterView.vue` — wrap in AuthShell. Commit.
- [ ] **Step 2**: `ForgotPasswordView.vue` — wrap in AuthShell. Commit.
- [ ] **Step 3**: `ResetPasswordView.vue` — wrap in AuthShell. Commit.

### Task 2.4 — Tag

- [ ] `git tag -a tier-2-auth -m "Tier 2 complete: auth surface in CloudCodeAPI editorial shell"`

> **★ STOP HERE.** Demo Login + Register to Dylan.

---

# TIER 3 — User Primary

**Why next:** these are the daily-used surfaces for any non-admin user. After Tier 3, a regular user has a complete CloudCodeAPI experience.

## File structure (Tier 3)

| File | Visual target |
|---|---|
| `src/views/user/DashboardView.vue` | Apply `__dashboard-comp.vue` structure to real data |
| `src/views/user/KeysView.vue` | API key reference table (mono key prefix, tabular created/used dates, ghost actions) |
| `src/views/user/UsageView.vue` | Hero metric (today's spend, italic serif) + 24h bar chart + filtered request log |
| `src/views/user/ProfileView.vue` | Single-column form with hairline section dividers; email change, password change, 2FA toggle |

## Tasks

### Task 3.1 — Reskin user/DashboardView

**Files:**
- Modify: `src/views/user/DashboardView.vue`

- [ ] **Step 1: Read view to inventory data sources**
  Identify which stores/composables provide: today's spend, throughput series, success rate, p50 latency, token count, active key count, recent requests, upstream status.

- [ ] **Step 2: Map to dashboard comp sections:**
  - Hero: today's spend (oversized italic serif) + 24h throughput bars
  - Secondary metrics row: success rate / p50 latency / tokens / active keys
  - Upstream pools section (read from store, not synthetic)
  - Recent activity section (last 8 requests from store)

- [ ] **Step 3: Replace template; keep script**
  Use `__dashboard-comp.vue` as a structural reference. Replace synthetic data with real reactive state.

- [ ] **Step 4: Verify in browser**
  - Numbers render correctly; tabular-nums alignment OK
  - Charts re-render on data change
  - Tables scroll if overflow
  - Light + dark mode

- [ ] **Step 5: Commit**

### Task 3.2 — Reskin user/KeysView

**Files:**
- Modify: `src/views/user/KeysView.vue`

- [ ] **Step 1: Read existing view to inventory:** key list columns, create/edit/delete actions, key reveal/copy flow, status indicators.

- [ ] **Step 2: Replace with reference table:**
  - Header: "API Keys" h2 + "Create key" button (bg-ink primary)
  - Table columns: name · key prefix (mono) · created · last used · status · actions
  - Status: green pip = active, grey pip = revoked
  - Actions: ghost icons (Eye reveal, Copy, MoreHorizontal menu)
  - Row hover: subtle `bg-ink/[0.02]` highlight
  - Empty state: editorial "No keys yet" with single CTA

- [ ] **Step 3: Verify create/edit/delete still work end-to-end.**

- [ ] **Step 4: Commit**

### Task 3.3 — Reskin user/UsageView

**Files:**
- Modify: `src/views/user/UsageView.vue`

- [ ] **Step 1: Read** to find date range filter, model filter, export button, chart libs used.

- [ ] **Step 2: Restructure:**
  - Hero: time-window total spend + chart (use existing chart lib but restyle: monochrome bars/lines, no fill gradients, hairline grid)
  - Filter strip: ghost tabs for time range (24h / 7d / 30d / custom), ghost dropdown for model
  - Detail table: per-request log with timestamp, model, key alias, pool, status, latency, cost

- [ ] **Step 3: Verify** filters apply, chart re-renders, table paginates.

- [ ] **Step 4: Commit**

### Task 3.4 — Reskin user/ProfileView

**Files:**
- Modify: `src/views/user/ProfileView.vue`

- [ ] **Step 1: Read** for form sections (account info, password, 2FA, sessions, danger zone).

- [ ] **Step 2: Restructure:**
  - Single column max-width 640px
  - Each section: small mono uppercase section label + `<hr>` border-border + form fields
  - Inputs use design `<Input>` atom
  - Save buttons: bg-ink primary; danger zone: red ghost border `<Button variant="danger" />`

- [ ] **Step 3: Verify** every form action still posts correctly.

- [ ] **Step 4: Commit**

### Task 3.5 — Tag

- [ ] `git tag -a tier-3-user -m "Tier 3 complete: user-facing primary views in CloudCodeAPI"`

> **★ STOP HERE.** Demo to Dylan.

---

# TIER 4 — Admin Primary

**Why last (of detailed tiers):** these are Dylan's tools. Admin is the most complex (table actions, bulk ops, status modals). Best to do after Tier 1-3 because the patterns established there (reference tables, ghost actions, modals on top of tokens) carry over.

## File structure (Tier 4)

| File | Visual target |
|---|---|
| `src/views/admin/DashboardView.vue` | Like user dashboard + global widgets (total users, total spend, system health) |
| `src/views/admin/AccountsView.vue` | **Critical** — upstream account list. Reference table with type icons, healthy/total keys, OAuth status, actions |
| `src/views/admin/UsersView.vue` | User table: email, role, balance, requests, joined, status, actions |
| `src/views/admin/GroupsView.vue` | Carpool group table: name, members, allowed pools, quota |

Plus 4 critical modals:
- `components/account/CreateAccountModal.vue`
- `components/account/EditAccountModal.vue`
- `components/account/OAuthAuthorizationFlow.vue` (Dylan needs this for Google OAuth)
- `components/account/AccountStatsModal.vue`

## Tasks

### Task 4.1 — Reskin admin/DashboardView

**Files:**
- Modify: `src/views/admin/DashboardView.vue`

- [ ] **Step 1: Read** to identify admin-specific widgets vs user-shared.
- [ ] **Step 2: Apply dashboard comp + add admin widgets** (e.g. "users today", "new signups this week", "revenue 30d").
- [ ] **Step 3: Verify, commit.**

### Task 4.2 — Reskin admin/AccountsView (the most important admin page)

**Files:**
- Modify: `src/views/admin/AccountsView.vue`

- [ ] **Step 1: Read** to inventory: account type filter, search, table columns, action menu (test, edit, sync, re-auth, delete), bulk actions.

- [ ] **Step 2: Restructure as reference table:**
  - Filter strip: type tabs (All / Anthropic / Gemini / Antigravity / OpenAI), search input
  - Columns: name · type icon · keys (healthy/total mono) · today's req · today's spend · status · actions
  - Status pip: green (live), yellow (degraded / re-auth needed), red (down), grey (idle)
  - Row click → opens stats modal
  - Action menu: ghost three-dot dropdown
  - Bulk-select: row checkboxes, sticky bulk action bar at bottom when rows selected
  - Empty state: editorial copy + "Add upstream" CTA

- [ ] **Step 3: Verify** every action works (especially test, OAuth re-auth).

- [ ] **Step 4: Commit**

### Task 4.3 — Reskin admin/UsersView

**Files:**
- Modify: `src/views/admin/UsersView.vue`

Pattern from AccountsView. Columns: email · role · balance · requests 30d · joined · status · actions.

- [ ] **Steps 1-3:** read, restructure, verify, commit.

### Task 4.4 — Reskin admin/GroupsView

**Files:**
- Modify: `src/views/admin/GroupsView.vue`

Same pattern. Columns: name · members count · allowed pools · quota usage · actions.

- [ ] **Steps 1-3:** read, restructure, verify, commit.

### Task 4.5 — Reskin critical modals

For each modal:
- Outer container: `bg-surface border border-border rounded-md shadow-medium max-w-[560px]`
- Header: title (h3 font-medium) + close (ghost X icon)
- Form sections: hairline-divided
- Footer: ghost cancel + bg-ink primary action

- [ ] **4.5a:** `CreateAccountModal.vue` — form for adding upstream
- [ ] **4.5b:** `EditAccountModal.vue` — same shell, edit fields
- [ ] **4.5c:** `OAuthAuthorizationFlow.vue` — special: shows OAuth steps with progress indicators (1. Authorize → 2. Callback → 3. Verify). Critical for Google flow.
- [ ] **4.5d:** `AccountStatsModal.vue` — stats display, monochrome charts

Commit each.

### Task 4.6 — Tag

- [ ] `git tag -a tier-4-admin -m "Tier 4 complete: admin primary views + key modals in CloudCodeAPI"`

> **★ STOP HERE.** Full app reskinned. Demo end-to-end. Decide whether to tackle long-tail or move to Phase 1 (Antigravity / Cursor sidecar wiring).

---

## Out of scope (intentionally)

These views inherit monochrome from the palette override and stay structurally as-is until concrete demand:

- `setup/SetupWizardView` (one-time, already used)
- `auth/*Callback*View` (invisible OAuth callbacks)
- `views/NotFoundView` (rarely seen)
- `views/admin/ops/**` (20+ files of advanced ops monitoring)
- `views/admin/orders/**` + `views/user/Payment*` (public-monetization, Phase 2)
- `views/admin/{Backup, Channels, Proxies, PromoCodes, Subscriptions, Announcements, Settings}View` (admin long-tail)
- `KeyUsageView`, `CustomPageView`

Total deferred: ~30 files. Coverage: design language applied to ~16 views + 4 modals = 20 surfaces, which represents ~95% of weekly user time on the product.

---

## Self-review

- ✅ Spec coverage: this plan implements §5 (design system layer applied to views) of the design spec
- ✅ Type/name consistency: all referenced atoms (`Button`, `Input`, `Card`, `Tag`, `Stat`) exist in `src/design/components/`; `__landing-comp.vue` and `__dashboard-comp.vue` are the locked references
- ✅ Granularity: each tier breaks into 4-5 tasks, each task into 4-5 steps. Big files (AppSidebar 922 lines) get explicit "read script first" steps
- ✅ No placeholder steps: file paths concrete, commit commands literal, verification steps describe what to look for
