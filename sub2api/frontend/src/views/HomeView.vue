<template>
  <!-- Custom Home Content: Full Page Mode (admin override, untouched) -->
  <div v-if="homeContent" class="min-h-screen">
    <iframe
      v-if="isHomeContentUrl"
      :src="homeContent.trim()"
      class="h-screen w-full border-0"
      allowfullscreen
    ></iframe>
    <div v-else v-html="homeContent"></div>
  </div>

  <!-- Default Home Page · proxy-api editorial reskin -->
  <div v-else class="min-h-screen bg-paper text-ink font-sans antialiased selection:bg-ink selection:text-paper">

    <!-- ════════════════════════════════════════════════ TOP BAR -->
    <header class="border-b border-border">
      <div class="mx-auto max-w-[1200px] px-6 md:px-8 h-14 flex items-center justify-between">
        <!-- Wordmark / logo -->
        <div class="flex items-center gap-3">
          <img
            v-if="siteLogo"
            :src="siteLogo"
            :alt="brandName"
            class="h-7 w-7 object-contain"
          />
          <div class="flex items-baseline gap-1">
            <span class="font-display italic text-[22px] leading-none">{{ brandHead }}</span>
            <span class="font-sans font-medium text-[15px] leading-none">{{ brandTail }}</span>
          </div>
          <span class="hidden sm:inline ml-2 text-[12px] uppercase tracking-[0.16em] text-subtle font-mono">v0.1</span>
        </div>

        <!-- Right cluster -->
        <div class="flex items-center gap-2 sm:gap-3 text-[14px]">
          <LocaleSwitcher />
          <a
            v-if="docUrl"
            :href="docUrl"
            target="_blank"
            rel="noopener noreferrer"
            :title="t('home.viewDocs')"
            class="hidden sm:inline-flex items-center gap-1.5 text-muted hover:text-ink transition-colors px-2"
          >
            <BookOpen :size="14" stroke-width="1.5" />
            <span>{{ t('home.docs') }}</span>
          </a>
          <button
            @click="toggleTheme"
            :title="isDark ? t('home.switchToLight') : t('home.switchToDark')"
            class="p-1.5 text-muted hover:text-ink transition-colors"
          >
            <component :is="isDark ? Sun : Moon" :size="15" stroke-width="1.5" />
          </button>

          <router-link
            v-if="isAuthenticated"
            :to="dashboardPath"
            class="ml-1 inline-flex items-center gap-2 h-8 pl-1 pr-3 rounded-sm border border-ink/15 hover:border-ink/40 transition-colors"
          >
            <span class="w-6 h-6 rounded-sm bg-ink text-paper text-[11px] font-semibold flex items-center justify-center">{{ userInitial }}</span>
            <span class="text-[13px]">{{ t('home.dashboard') }}</span>
            <ArrowUpRight :size="13" stroke-width="1.5" />
          </router-link>

          <router-link
            v-else
            to="/login"
            class="ml-1 inline-flex items-center gap-1.5 px-3 h-8 rounded-sm border border-ink/15 hover:border-ink/40 transition-colors"
          >
            <span class="text-[13px]">{{ t('home.login') }}</span>
            <ArrowUpRight :size="13" stroke-width="1.5" />
          </router-link>
        </div>
      </div>
    </header>

    <!-- ════════════════════════════════════════════════ HERO -->
    <section class="border-b border-border">
      <div class="mx-auto max-w-[1200px] px-6 md:px-8 pt-20 md:pt-24 pb-24 md:pb-28">
        <div class="grid grid-cols-12 gap-8">

          <!-- LEFT: cycling-verb hero -->
          <div class="col-span-12 md:col-span-7">
            <div class="text-[12px] uppercase tracking-[0.14em] text-subtle font-mono mb-10">
              <span class="inline-block w-6 border-t border-subtle align-middle mr-2"></span>
              Anthropic-compatible relay · self-hosted
            </div>

            <!-- Hero · two lines: animated verb + brand answer -->
            <h1 class="font-sans font-light tracking-[-0.025em] text-[clamp(56px,7vw,92px)] leading-[1.06]">
              <!-- Line 1 — animated verb. min-h ensures the line keeps its
                   slot during the out-in transition, no descender clipping
                   because we don't overflow:hidden anymore. -->
              <span class="block min-h-[1.06em]" :aria-label="verbCurrent">
                <Transition name="cycle" mode="out-in">
                  <span
                    :key="verbIdx"
                    class="inline-block whitespace-nowrap will-change-transform"
                  >{{ verbCurrent }}<span class="text-muted">,</span></span>
                </Transition>
              </span>

              <!-- Line 2 — fixed brand answer (climax). The brand renders as
                   a bg-ink stamp — the accidental selection look Dylan loved. -->
              <span class="block mt-3">
                <span class="text-muted font-light">use </span>
                <span
                  class="brand-stamp font-display italic font-normal tracking-[-0.015em]
                         bg-ink text-paper inline-block leading-[1] align-baseline"
                  style="padding: 0.08em 0.18em 0.18em; transform: translateY(0.06em);"
                >{{ brandName }}</span>
                <span class="text-muted font-light">.</span>
              </span>
            </h1>

            <p class="mt-10 max-w-[44ch] text-[15.5px] leading-[1.7] text-muted">
              {{ siteSubtitle }}
            </p>

            <div class="mt-12 flex items-center gap-6">
              <router-link
                :to="isAuthenticated ? dashboardPath : '/login'"
                class="group inline-flex items-center gap-2 h-11 px-5 bg-ink text-paper text-[14px] font-medium rounded-sm transition-all hover:translate-y-[-1px] hover:shadow-medium"
              >
                {{ isAuthenticated ? t('home.goToDashboard') : t('home.getStarted') }}
                <ArrowUpRight :size="14" stroke-width="2"
                              class="transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
              </router-link>
              <a
                v-if="docUrl"
                :href="docUrl"
                target="_blank"
                rel="noopener noreferrer"
                class="text-[14px] text-muted hover:text-ink transition-colors underline-offset-4 hover:underline"
              >
                {{ t('home.docs') }} →
              </a>
            </div>
          </div>

          <!-- RIGHT: live routing log — entries stream in at top -->
          <div class="col-span-12 md:col-span-5 md:pt-2">
            <figure class="border border-border bg-surface overflow-hidden">
              <figcaption class="flex items-center justify-between border-b border-border px-4 py-2.5
                                 text-[12px] uppercase tracking-[0.14em] text-subtle font-mono">
                <span>routing log</span>
                <span class="flex items-center gap-1.5">
                  <span class="relative flex w-1.5 h-1.5">
                    <span class="absolute inline-flex h-full w-full rounded-full bg-success opacity-60 animate-ping"></span>
                    <span class="relative inline-flex w-1.5 h-1.5 rounded-full bg-success"></span>
                  </span>
                  live · {{ rps.toFixed(1) }} req/s
                </span>
              </figcaption>

              <!-- Log stream. Top of container has gradient fade so newest is sharpest. -->
              <div class="relative" style="height: 384px">
                <div class="absolute inset-x-0 bottom-0 h-12 bg-gradient-to-t from-surface to-transparent pointer-events-none z-10"></div>
                <ul class="px-4 py-3 font-mono text-[13.5px] space-y-3">
                  <TransitionGroup name="log">
                    <li
                      v-for="(e, i) in log"
                      :key="e.id"
                      class="flex items-start gap-3 transition-opacity"
                      :style="{ opacity: 1 - (i * 0.13) }"
                    >
                      <span class="text-subtle tabular-nums shrink-0">{{ e.ts }}</span>
                      <div class="flex-1 min-w-0">
                        <div class="text-ink truncate">{{ e.model }}</div>
                        <div class="text-muted text-[12.5px] mt-0.5 flex items-baseline gap-2">
                          <span class="text-subtle">→</span>
                          <span class="text-ink">{{ e.pool }}</span>
                          <span class="ml-auto flex items-baseline gap-2.5">
                            <span :class="statusColor(e.status)" class="tabular-nums">{{ e.status }}</span>
                            <span class="text-muted tabular-nums">{{ e.latency }}<span class="text-subtle">ms</span></span>
                          </span>
                        </div>
                      </div>
                    </li>
                  </TransitionGroup>
                </ul>
              </div>
            </figure>
            <div class="mt-3 flex items-center justify-between text-[12px] text-subtle font-mono px-1">
              <span>protocol: anthropic-messages-2023-06-01</span>
              <span>{{ today }}</span>
            </div>
          </div>

        </div>
      </div>
    </section>

    <!-- ════════════════════════════════════════════════ FEATURES -->
    <section class="border-b border-border">
      <div class="mx-auto max-w-[1200px] px-6 md:px-8 pt-20 pb-24">
        <div class="text-[12px] uppercase tracking-[0.14em] text-subtle font-mono mb-12">
          <span class="inline-block w-6 border-t border-subtle align-middle mr-2"></span>
          {{ t('home.tags.subscriptionToApi') }} · {{ t('home.tags.stickySession') }} · {{ t('home.tags.realtimeBilling') }}
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-x-12 gap-y-16">
          <article class="flex flex-col gap-3">
            <div class="font-mono text-[13px] text-subtle">01</div>
            <h3 class="text-[20px] font-medium tracking-[-0.01em]">{{ t('home.features.unifiedGateway') }}</h3>
            <p class="text-[15px] leading-[1.7] text-muted">
              {{ t('home.features.unifiedGatewayDesc') }}
            </p>
          </article>

          <article class="flex flex-col gap-3">
            <div class="font-mono text-[13px] text-subtle">02</div>
            <h3 class="text-[20px] font-medium tracking-[-0.01em]">{{ t('home.features.multiAccount') }}</h3>
            <p class="text-[15px] leading-[1.7] text-muted">
              {{ t('home.features.multiAccountDesc') }}
            </p>
          </article>

          <article class="flex flex-col gap-3">
            <div class="font-mono text-[13px] text-subtle">03</div>
            <h3 class="text-[20px] font-medium tracking-[-0.01em]">{{ t('home.features.balanceQuota') }}</h3>
            <p class="text-[15px] leading-[1.7] text-muted">
              {{ t('home.features.balanceQuotaDesc') }}
            </p>
          </article>
        </div>
      </div>
    </section>

    <!-- ════════════════════════════════════════════════ PROVIDERS -->
    <section class="border-b border-border">
      <div class="mx-auto max-w-[1200px] px-6 md:px-8 pt-20 pb-24">
        <div class="flex items-end justify-between mb-10">
          <div>
            <div class="text-[12px] uppercase tracking-[0.14em] text-subtle font-mono mb-3">
              <span class="inline-block w-6 border-t border-subtle align-middle mr-2"></span>
              {{ t('home.providers.title') }}
            </div>
            <h2 class="text-[32px] font-light tracking-[-0.015em]">
              {{ t('home.providers.description') }}
            </h2>
          </div>
        </div>

        <div class="border-t border-border">
          <div class="grid grid-cols-12 text-[12px] uppercase tracking-[0.14em] text-subtle font-mono py-3 border-b border-border">
            <div class="col-span-7 md:col-span-8">model</div>
            <div class="col-span-5 md:col-span-4 text-right md:text-left">status</div>
          </div>
          <div
            v-for="p in providers"
            :key="p.label"
            class="grid grid-cols-12 items-center py-4 border-b border-border last:border-b-0 transition-colors hover:bg-ink/[0.02]"
          >
            <div class="col-span-7 md:col-span-8 flex items-center gap-3">
              <span
                class="font-mono font-medium text-[12px] w-7 h-7 rounded-sm border border-border flex items-center justify-center"
              >{{ p.glyph }}</span>
              <div>
                <div class="font-mono text-[14.5px]">{{ p.label }}</div>
                <div class="text-[12px] text-subtle uppercase tracking-[0.14em] font-mono mt-0.5">{{ p.note }}</div>
              </div>
            </div>
            <div class="col-span-5 md:col-span-4 flex items-center gap-2 justify-end md:justify-start text-[14px]">
              <span class="w-1.5 h-1.5 rounded-full" :class="p.live ? 'bg-success' : 'bg-subtle'"></span>
              <span :class="p.live ? 'text-ink' : 'text-muted'">
                {{ p.live ? t('home.providers.supported') : t('home.providers.soon') }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- ════════════════════════════════════════════════ FOOTER -->
    <footer>
      <div class="mx-auto max-w-[1200px] px-6 md:px-8 py-10 flex flex-col sm:flex-row items-center sm:items-baseline justify-between gap-4 text-[12px] font-mono uppercase tracking-[0.14em] text-subtle">
        <div class="flex items-center gap-4 sm:gap-6">
          <span>{{ siteName.toLowerCase() }}</span>
          <span class="text-border">/</span>
          <span>&copy; {{ currentYear }}</span>
          <span class="text-border hidden sm:inline">/</span>
          <span class="hidden sm:inline normal-case tracking-normal">{{ t('home.footer.allRightsReserved') }}</span>
        </div>
        <div class="flex items-center gap-4 sm:gap-6">
          <a v-if="docUrl" :href="docUrl" target="_blank" rel="noopener noreferrer" class="hover:text-ink transition-colors">{{ t('home.docs') }}</a>
          <a :href="githubUrl" target="_blank" rel="noopener noreferrer" class="hover:text-ink transition-colors">github</a>
          <span class="flex items-center gap-1.5">
            <span class="w-1.5 h-1.5 rounded-full bg-success"></span>
            <span>operational</span>
          </span>
        </div>
      </div>
    </footer>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAuthStore, useAppStore } from '@/stores'
import LocaleSwitcher from '@/components/common/LocaleSwitcher.vue'
import { ArrowUpRight, BookOpen, Moon, Sun } from 'lucide-vue-next'

const { t } = useI18n()

const authStore = useAuthStore()
const appStore = useAppStore()

// ─── Brand identity ──────────────────────────────────────────────────
// The product brand is CloudCodeAPI, decoupled from sub2api's stored
// siteName (which is for the upstream installation defaults).
const brandName = 'CloudCodeAPI'
const brandHead = 'CloudCode'   // italic accent half (display serif)
const brandTail = 'API'          // descriptor half (sans medium)

// Site settings - directly from appStore (already initialized from injected config)
// Used for things that need admin-customizable values (page title, subtitle, etc.).
const siteName = computed(() => appStore.cachedPublicSettings?.site_name || appStore.siteName || brandName)
const siteLogo = computed(() => appStore.cachedPublicSettings?.site_logo || appStore.siteLogo || '')
const siteSubtitle = computed(() => appStore.cachedPublicSettings?.site_subtitle || 'AI API Gateway Platform')
const docUrl = computed(() => appStore.cachedPublicSettings?.doc_url || appStore.docUrl || '')
const homeContent = computed(() => appStore.cachedPublicSettings?.home_content || '')


// Check if homeContent is a URL (for iframe display)
const isHomeContentUrl = computed(() => {
  const content = homeContent.value.trim()
  return content.startsWith('http://') || content.startsWith('https://')
})

// Theme
const isDark = ref(document.documentElement.classList.contains('dark'))

// GitHub URL
const githubUrl = 'https://github.com/Wei-Shaw/sub2api'

// Auth state
const isAuthenticated = computed(() => authStore.isAuthenticated)
const isAdmin = computed(() => authStore.isAdmin)
const dashboardPath = computed(() => isAdmin.value ? '/admin/dashboard' : '/dashboard')
const userInitial = computed(() => {
  const user = authStore.user
  if (!user || !user.email) return ''
  return user.email.charAt(0).toUpperCase()
})

// Current year + ISO date for footer / hero meta
const currentYear = computed(() => new Date().getFullYear())
const today = computed(() => new Date().toISOString().slice(0, 10))

// Providers (model glyph + label + status)
interface Provider { glyph: string; label: string; note: string; live: boolean }
const providers = computed<Provider[]>(() => [
  { glyph: 'C', label: t('home.providers.claude'),     note: 'anthropic · antigravity', live: true  },
  { glyph: 'G', label: 'GPT',                          note: 'openai',                  live: true  },
  { glyph: 'G', label: t('home.providers.gemini'),     note: 'google · vertex',         live: true  },
  { glyph: 'A', label: t('home.providers.antigravity'), note: 'subscription',           live: true  },
  { glyph: '+', label: t('home.providers.more'),       note: 'roadmap',                 live: false },
])

// ─── Hero verb sequence — plays once, lands on the last word ───────
// Three -ing verbs describe what the visitor might be doing. The animation
// runs once on mount, each verb fades to the next, and stops permanently
// on the last one. The brand line below ("use CloudCodeAPI.") is the
// fixed answer — it's never part of the cycle.
const verbs = ['coding', 'debugging', 'imagining']
const verbIdx = ref(0)
const verbCurrent = computed(() => verbs[verbIdx.value])

let verbTimer: number | undefined
function advanceVerb() {
  if (verbIdx.value >= verbs.length - 1) return  // hold on the last word
  verbTimer = window.setTimeout(() => {
    verbIdx.value++
    advanceVerb()
  }, 1400)
}

// ─── Right panel: live routing log ──────────────────────────────────
// Synthesizes a stream of plausible inbound requests routed through the
// proxy. New entries push in at the top; older drift down and fade off.
// Sells the value prop visually: "your proxy is humming, routing to
// healthy upstreams, every model, every second".
interface LogEntry {
  id: number
  ts: string
  model: string
  pool: string
  status: number
  latency: number
}

const MODELS  = ['claude-3.5-sonnet', 'claude-3.5-sonnet', 'claude-3.5-haiku', 'claude-4.5-opus']
const POOLS   = ['anthropic#1', 'anthropic#3', 'anthropic#4', 'antigravity#a', 'antigravity#b', 'relay#packy']
const MAX_LOG = 6

const log = ref<LogEntry[]>([])
const rps = ref(7.4)
let logId = 1000
let logTimer: number | undefined

function pad(n: number) { return n.toString().padStart(2, '0') }
function nowTs() {
  const d = new Date()
  return `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`
}
function pick<T>(arr: T[]): T { return arr[Math.floor(Math.random() * arr.length)] }

function pushLogEntry() {
  const model = pick(MODELS)
  const pool  = pick(POOLS)
  // 92% success, 6% rate-limit, 2% 500
  const r = Math.random()
  const status  = r < 0.92 ? 200 : r < 0.98 ? 429 : 500
  const latency = model.includes('haiku')
    ? 140 + Math.floor(Math.random() * 80)
    : model.includes('opus')
      ? 480 + Math.floor(Math.random() * 280)
      : 240 + Math.floor(Math.random() * 320)

  log.value.unshift({ id: logId++, ts: nowTs(), model, pool, status, latency })
  if (log.value.length > MAX_LOG) log.value.length = MAX_LOG

  // jitter rps a bit
  rps.value = Math.max(2, Math.min(12, rps.value + (Math.random() - 0.5) * 0.8))
}

function scheduleNextLog() {
  logTimer = window.setTimeout(() => {
    pushLogEntry()
    scheduleNextLog()
  }, 900 + Math.random() * 1800)  // 0.9s – 2.7s
}

function seedLog() {
  // Pre-populate so the panel doesn't start empty
  for (let i = 0; i < MAX_LOG; i++) pushLogEntry()
}

const statusColor = (s: number) =>
  s >= 500 ? 'text-danger' : s === 429 ? 'text-warning' : 'text-success'

// Toggle theme
function toggleTheme() {
  isDark.value = !isDark.value
  document.documentElement.classList.toggle('dark', isDark.value)
  localStorage.setItem('theme', isDark.value ? 'dark' : 'light')
}

// Initialize theme
function initTheme() {
  const savedTheme = localStorage.getItem('theme')
  if (
    savedTheme === 'dark' ||
    (!savedTheme && window.matchMedia('(prefers-color-scheme: dark)').matches)
  ) {
    isDark.value = true
    document.documentElement.classList.add('dark')
  }
}

onMounted(() => {
  initTheme()
  authStore.checkAuth()
  if (!appStore.publicSettingsLoaded) {
    appStore.fetchPublicSettings()
  }
  // First verb is shown immediately; advance starts after a brief settle
  verbTimer = window.setTimeout(advanceVerb, 800)
  // Seed log + start streaming new entries
  seedLog()
  scheduleNextLog()
})

onBeforeUnmount(() => {
  if (verbTimer) clearTimeout(verbTimer)
  if (logTimer) clearTimeout(logTimer)
})
</script>

<style scoped>
/* ─── Cycling word: fade + small lift ──────────────────────────────
   Intentionally NOT using overflow:hidden + clipped mask, because that
   eats descenders (g/y/p tails). Pure opacity + small Y translate keeps
   glyphs intact. mode="out-in" removes layout overlap. */
.cycle-enter-active,
.cycle-leave-active {
  transition: transform 380ms cubic-bezier(0.16, 1, 0.3, 1),
              opacity   280ms ease-out;
}
.cycle-enter-from {
  opacity: 0;
  transform: translateY(0.35em);
}
.cycle-leave-to {
  opacity: 0;
  transform: translateY(-0.35em);
}

/* ─── Routing log: new entry slides down + fades in at top ─────────── */
.log-move,
.log-enter-active,
.log-leave-active {
  transition: transform 480ms cubic-bezier(0.16, 1, 0.3, 1),
              opacity   320ms ease-out;
}
.log-enter-from {
  opacity: 0;
  transform: translateY(-12px);
}
.log-leave-active {
  position: absolute;
  width: calc(100% - 2rem);  /* match px-4 padding */
}
.log-leave-to {
  opacity: 0;
  transform: translateY(8px);
}

/* ─── Brand stamp: subtle hover lift to telegraph it's still text ─── */
.brand-stamp {
  transition: transform 240ms cubic-bezier(0.16, 1, 0.3, 1);
}
.brand-stamp:hover {
  transform: translateY(calc(0.04em - 1px));
}

@media (prefers-reduced-motion: reduce) {
  .cycle-enter-active, .cycle-leave-active,
  .log-move, .log-enter-active, .log-leave-active,
  .brand-stamp {
    transition: none;
  }
}
</style>
