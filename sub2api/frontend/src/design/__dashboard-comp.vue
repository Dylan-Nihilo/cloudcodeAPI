<!--
  Design comp · Dashboard.
  Static mockup. No real data. Lives at /__design/dashboard.
  Goal: lock the authenticated UI's visual language before touching real views.
-->
<script setup lang="ts">
import { computed, ref } from 'vue'
import { useDarkMode } from './composables/useDarkMode'
import {
  ArrowUpRight, ArrowDownRight, Search, Bell, Moon, Sun,
  LayoutGrid, KeyRound, Server, Users, BarChart3, Settings, BookOpen,
  ChevronRight,
} from 'lucide-vue-next'

const { isDark, toggle } = useDarkMode()

// ─── nav ─────────────────────────────────────────────────────────────
const nav = [
  { label: 'Overview',  icon: LayoutGrid, active: true },
  { label: 'API keys',  icon: KeyRound },
  { label: 'Upstreams', icon: Server, badge: '3 pools' },
  { label: 'Groups',    icon: Users },
  { label: 'Usage',     icon: BarChart3 },
  { label: 'Settings',  icon: Settings },
]

// ─── 24h throughput sparkline (synthetic) ────────────────────────────
const throughput = [
  18, 14, 11, 9, 7, 5, 6, 12, 28, 41, 52, 47,
  44, 49, 55, 62, 71, 68, 59, 51, 42, 34, 28, 22,
]
const maxT = Math.max(...throughput)

// ─── upstream pools ──────────────────────────────────────────────────
interface Pool {
  name: string
  source: string
  keys: { healthy: number; total: number }
  rps: number
  spend: string
  status: 'live' | 'degraded' | 'idle'
  load: number  // 0-1
}
const pools: Pool[] = [
  { name: 'anthropic·primary',   source: 'official key',   keys: { healthy: 3, total: 4 }, rps: 8.4, spend: '$ 2.41', status: 'live',     load: 0.62 },
  { name: 'antigravity·a',       source: 'oauth subscription', keys: { healthy: 2, total: 2 }, rps: 4.1, spend: '$ 1.18', status: 'live',     load: 0.48 },
  { name: 'relay·packycode',     source: 'third-party relay',  keys: { healthy: 1, total: 2 }, rps: 1.7, spend: '$ 0.83', status: 'degraded', load: 0.27 },
  { name: 'cursor·sidecar',      source: 'oauth subscription', keys: { healthy: 0, total: 1 }, rps: 0,   spend: '$ 0.00', status: 'idle',     load: 0    },
]

const statusDot = (s: Pool['status']) => ({
  live:     'bg-success',
  degraded: 'bg-warning',
  idle:     'bg-subtle',
}[s])

// ─── recent activity (last 8) ────────────────────────────────────────
interface Req {
  ts: string
  model: string
  key: string
  pool: string
  status: number
  latency: number
  cost: string
}
const recent: Req[] = [
  { ts: '14:42:09', model: 'claude-3.5-sonnet', key: 'cli-dylan',     pool: 'anthropic·primary',   status: 200, latency: 312, cost: '$ 0.0042' },
  { ts: '14:41:58', model: 'claude-3.5-haiku',  key: 'web-app',       pool: 'anthropic·primary',   status: 200, latency: 184, cost: '$ 0.0009' },
  { ts: '14:41:51', model: 'claude-3.5-sonnet', key: 'cli-dylan',     pool: 'antigravity·a',       status: 200, latency: 488, cost: '$ —'      },
  { ts: '14:41:33', model: 'claude-3.5-sonnet', key: 'lab-shared',    pool: 'anthropic·primary',   status: 429, latency:  41, cost: '$ —'      },
  { ts: '14:41:22', model: 'claude-3.5-sonnet', key: 'lab-shared',    pool: 'antigravity·a',       status: 200, latency: 511, cost: '$ —'      },
  { ts: '14:41:08', model: 'claude-3.5-haiku',  key: 'cron·digest',   pool: 'anthropic·primary',   status: 200, latency: 198, cost: '$ 0.0007' },
  { ts: '14:40:54', model: 'claude-3.5-sonnet', key: 'web-app',       pool: 'anthropic·primary',   status: 200, latency: 287, cost: '$ 0.0035' },
  { ts: '14:40:39', model: 'claude-3.5-sonnet', key: 'cli-dylan',     pool: 'relay·packycode',     status: 200, latency: 624, cost: '$ 0.0033' },
]

const statusColor = (s: number) =>
  s >= 500 ? 'text-danger' : s === 429 ? 'text-warning' : s >= 400 ? 'text-warning' : 'text-success'

const now = computed(() => new Date().toLocaleString('en-US', { hour12: false, timeZoneName: 'short' }))

const search = ref('')
</script>

<template>
  <div class="min-h-screen bg-paper text-ink font-sans antialiased flex">

    <!-- ════════════════════════════════════════════════════ SIDEBAR -->
    <aside class="w-[240px] shrink-0 border-r border-border min-h-screen flex flex-col">
      <!-- wordmark -->
      <div class="px-6 h-14 flex items-center border-b border-border">
        <div class="flex items-baseline gap-2">
          <span class="font-display italic text-[24px] leading-none">proxy</span>
          <span class="font-sans font-medium text-[14px] leading-none -ml-1">api</span>
        </div>
      </div>

      <!-- workspace switcher -->
      <button class="mx-3 mt-3 px-3 py-2.5 flex items-center justify-between
                     border border-border rounded-sm hover:border-ink/40 transition-colors group">
        <div class="flex items-center gap-2.5">
          <div class="w-6 h-6 rounded-sm bg-ink text-paper text-[11px] font-semibold flex items-center justify-center">D</div>
          <div class="text-left">
            <div class="text-[13px] font-medium leading-none">dylan&rsquo;s workspace</div>
            <div class="text-[11px] text-subtle uppercase tracking-[0.16em] font-mono mt-1">free · 1 of 5 seats</div>
          </div>
        </div>
        <ChevronRight :size="14" class="text-subtle group-hover:text-ink transition-colors" />
      </button>

      <!-- nav -->
      <nav class="mt-6 px-3">
        <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono px-3 mb-2">workspace</div>
        <a v-for="item in nav" :key="item.label"
           href="#"
           :class="[
             'group flex items-center justify-between px-3 py-2 rounded-sm text-[14px] transition-colors',
             item.active ? 'bg-ink text-paper' : 'text-muted hover:text-ink hover:bg-ink/[0.04]',
           ]">
          <div class="flex items-center gap-2.5">
            <component :is="item.icon" :size="14" stroke-width="1.5"
                       :class="item.active ? 'opacity-100' : 'opacity-70 group-hover:opacity-100'" />
            <span>{{ item.label }}</span>
          </div>
          <span v-if="item.badge"
                :class="[
                  'text-[11px] font-mono uppercase tracking-[0.12em]',
                  item.active ? 'text-paper/60' : 'text-subtle',
                ]">{{ item.badge }}</span>
        </a>

        <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono px-3 mt-8 mb-2">resources</div>
        <a href="#" class="flex items-center gap-2.5 px-3 py-2 rounded-sm text-[14px] text-muted hover:text-ink hover:bg-ink/[0.04] transition-colors">
          <BookOpen :size="14" stroke-width="1.5" class="opacity-70" />
          Documentation
        </a>
      </nav>

      <!-- footer pill -->
      <div class="mt-auto px-3 pb-3">
        <div class="border-t border-border pt-3 px-3 flex items-center gap-2.5">
          <div class="w-7 h-7 rounded-sm bg-ink text-paper text-[11px] font-semibold flex items-center justify-center shrink-0">DT</div>
          <div class="min-w-0 flex-1">
            <div class="text-[13px] font-medium truncate">Dylan Thomas</div>
            <div class="text-[11px] text-subtle uppercase tracking-[0.16em] font-mono mt-0.5">admin</div>
          </div>
        </div>
      </div>
    </aside>

    <!-- ════════════════════════════════════════════════════ MAIN -->
    <div class="flex-1 min-w-0">

      <!-- top bar -->
      <header class="h-14 border-b border-border flex items-center justify-between px-8">
        <div class="flex items-center gap-2 text-[14px] text-muted">
          <span>workspace</span>
          <ChevronRight :size="12" class="text-subtle" />
          <span class="text-ink font-medium">overview</span>
        </div>
        <div class="flex items-center gap-2">
          <div class="relative">
            <Search :size="13" stroke-width="1.5" class="absolute left-2.5 top-1/2 -translate-y-1/2 text-subtle" />
            <input v-model="search" placeholder="Search keys, models, requests…"
                   class="h-8 w-[280px] pl-8 pr-2 text-[14.5px] bg-paper border border-border rounded-sm
                          focus:outline-none focus:border-ink/40 transition-colors placeholder:text-subtle" />
            <span class="absolute right-2 top-1/2 -translate-y-1/2 text-[11px] text-subtle font-mono uppercase tracking-[0.12em]">⌘ K</span>
          </div>
          <button class="ml-2 p-1.5 text-muted hover:text-ink transition-colors">
            <Bell :size="15" stroke-width="1.5" />
          </button>
          <button @click="toggle()" :aria-label="isDark ? 'Light' : 'Dark'"
                  class="p-1.5 text-muted hover:text-ink transition-colors">
            <component :is="isDark ? Sun : Moon" :size="15" stroke-width="1.5" />
          </button>
        </div>
      </header>

      <!-- ─── HERO: today's spend + 24h throughput ─────────────────── -->
      <section class="px-8 pt-10 pb-12 border-b border-border">
        <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono mb-6">
          <span class="inline-block w-6 border-t border-subtle align-middle mr-2"></span>
          today · {{ now }}
        </div>

        <div class="grid grid-cols-12 gap-12">
          <!-- big spend number, italic serif -->
          <div class="col-span-12 lg:col-span-5">
            <div class="text-[13px] uppercase tracking-[0.16em] text-subtle font-mono mb-3">spend so far</div>
            <div class="font-display italic font-normal tabular-nums text-[112px] leading-[0.92] tracking-[-0.025em]">
              $&thinsp;4<span class="text-subtle">.82</span>
            </div>
            <div class="mt-5 flex items-baseline gap-3 text-[14px]">
              <span class="inline-flex items-center gap-1 text-success">
                <ArrowUpRight :size="13" stroke-width="2" />
                12.4%
              </span>
              <span class="text-muted">vs same hour yesterday · projecting <span class="text-ink font-mono">$&thinsp;7.40</span> by midnight</span>
            </div>
          </div>

          <!-- 24h throughput sparkline (meaningful: hourly bar chart) -->
          <div class="col-span-12 lg:col-span-7">
            <div class="flex items-end justify-between mb-3">
              <div class="text-[13px] uppercase tracking-[0.16em] text-subtle font-mono">throughput · last 24h · req/min</div>
              <div class="text-[13px] text-muted">peak <span class="font-mono text-ink">{{ maxT }}</span> · now <span class="font-mono text-ink">{{ throughput[throughput.length - 1] }}</span></div>
            </div>
            <div class="flex items-end gap-[3px] h-[120px] border-b border-border">
              <div v-for="(v, i) in throughput" :key="i"
                   :style="{ height: `${(v / maxT) * 100}%` }"
                   :class="[
                     'flex-1 rounded-t-[1px] transition-colors',
                     i === throughput.length - 1 ? 'bg-ink' : 'bg-ink/25 hover:bg-ink/55',
                   ]"
                   :title="`${23 - i}h ago · ${v} req/min`"></div>
            </div>
            <div class="mt-2 flex justify-between text-[11px] text-subtle font-mono uppercase tracking-[0.12em]">
              <span>−24h</span>
              <span>−18h</span>
              <span>−12h</span>
              <span>−6h</span>
              <span>now</span>
            </div>
          </div>
        </div>

        <!-- secondary metrics, single row, no cards -->
        <div class="mt-12 grid grid-cols-4 border-t border-border pt-6">
          <div class="pr-8">
            <div class="text-[11px] uppercase tracking-[0.14em] text-subtle font-mono">success rate · 24h</div>
            <div class="mt-1.5 flex items-baseline gap-2">
              <span class="font-mono tabular-nums text-[24px] text-ink">99.84%</span>
              <span class="text-[13px] text-success inline-flex items-center gap-0.5">
                <ArrowUpRight :size="11" stroke-width="2" />0.05
              </span>
            </div>
          </div>
          <div class="px-8 border-l border-border">
            <div class="text-[11px] uppercase tracking-[0.14em] text-subtle font-mono">p50 latency</div>
            <div class="mt-1.5 flex items-baseline gap-2">
              <span class="font-mono tabular-nums text-[24px] text-ink">287<span class="text-subtle text-[17px]">ms</span></span>
              <span class="text-[13px] text-danger inline-flex items-center gap-0.5">
                <ArrowDownRight :size="11" stroke-width="2" />18
              </span>
            </div>
          </div>
          <div class="px-8 border-l border-border">
            <div class="text-[11px] uppercase tracking-[0.14em] text-subtle font-mono">tokens · 24h</div>
            <div class="mt-1.5 flex items-baseline gap-2">
              <span class="font-mono tabular-nums text-[24px] text-ink">12.4<span class="text-subtle text-[17px]">M</span></span>
              <span class="text-[13px] text-success inline-flex items-center gap-0.5">
                <ArrowUpRight :size="11" stroke-width="2" />8.1%
              </span>
            </div>
          </div>
          <div class="px-8 border-l border-border">
            <div class="text-[11px] uppercase tracking-[0.14em] text-subtle font-mono">active keys</div>
            <div class="mt-1.5 flex items-baseline gap-2">
              <span class="font-mono tabular-nums text-[24px] text-ink">7</span>
              <span class="text-[13px] text-muted">of 12</span>
            </div>
          </div>
        </div>
      </section>

      <!-- ─── UPSTREAM POOLS ──────────────────────────────────────── -->
      <section class="px-8 pt-10 pb-12 border-b border-border">
        <div class="flex items-end justify-between mb-6">
          <div>
            <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono mb-2">
              <span class="inline-block w-6 border-t border-subtle align-middle mr-2"></span>
              upstream pools
            </div>
            <h2 class="text-[24px] font-medium tracking-[-0.01em]">4 configured · 3 live · 1 idle</h2>
          </div>
          <a href="#" class="text-[14px] text-muted hover:text-ink underline-offset-4 hover:underline">Manage pools →</a>
        </div>

        <div class="border-t border-border">
          <div class="grid grid-cols-12 text-[11px] uppercase tracking-[0.14em] text-subtle font-mono py-3 border-b border-border">
            <div class="col-span-4">pool</div>
            <div class="col-span-2">keys</div>
            <div class="col-span-2 text-right">req / sec</div>
            <div class="col-span-2 text-right">spend · today</div>
            <div class="col-span-2 text-right">load</div>
          </div>
          <div v-for="p in pools" :key="p.name"
               class="grid grid-cols-12 items-center py-4 border-b border-border last:border-b-0
                      transition-colors hover:bg-ink/[0.02]">
            <div class="col-span-4">
              <div class="font-mono text-[14.5px]">{{ p.name }}</div>
              <div class="text-[11px] text-subtle uppercase tracking-[0.14em] font-mono mt-0.5">{{ p.source }}</div>
            </div>
            <div class="col-span-2 flex items-center gap-2 text-[14px]">
              <span class="w-1.5 h-1.5 rounded-full" :class="statusDot(p.status)"></span>
              <span class="font-mono tabular-nums">{{ p.keys.healthy }}<span class="text-subtle">/{{ p.keys.total }}</span></span>
            </div>
            <div class="col-span-2 text-right font-mono tabular-nums text-[14px]">{{ p.rps.toFixed(1) }}</div>
            <div class="col-span-2 text-right font-mono tabular-nums text-[14px]">{{ p.spend }}</div>
            <div class="col-span-2">
              <div class="ml-auto w-full h-1 bg-ink/[0.06] rounded-sm overflow-hidden">
                <div class="h-full bg-ink transition-all" :style="{ width: `${p.load * 100}%` }"></div>
              </div>
              <div class="text-right text-[11px] text-subtle font-mono uppercase tracking-[0.12em] mt-1">{{ Math.round(p.load * 100) }}%</div>
            </div>
          </div>
        </div>
      </section>

      <!-- ─── RECENT ACTIVITY ─────────────────────────────────────── -->
      <section class="px-8 pt-10 pb-16">
        <div class="flex items-end justify-between mb-6">
          <div>
            <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono mb-2">
              <span class="inline-block w-6 border-t border-subtle align-middle mr-2"></span>
              recent activity
            </div>
            <h2 class="text-[24px] font-medium tracking-[-0.01em]">
              Last 8 requests
              <span class="font-display italic font-normal text-muted text-[18px]">— live</span>
            </h2>
          </div>
          <div class="flex items-center gap-3 text-[13px]">
            <button class="px-2.5 py-1 border border-ink/15 rounded-sm hover:border-ink/40 transition-colors">All routes</button>
            <button class="px-2.5 py-1 text-muted hover:text-ink transition-colors">Errors only</button>
            <a href="#" class="text-muted hover:text-ink underline-offset-4 hover:underline">Open log →</a>
          </div>
        </div>

        <div class="border-t border-border">
          <div class="grid grid-cols-12 text-[11px] uppercase tracking-[0.14em] text-subtle font-mono py-3 border-b border-border">
            <div class="col-span-2">timestamp</div>
            <div class="col-span-3">model</div>
            <div class="col-span-2">key</div>
            <div class="col-span-2">pool</div>
            <div class="col-span-1 text-right">status</div>
            <div class="col-span-1 text-right">latency</div>
            <div class="col-span-1 text-right">cost</div>
          </div>
          <div v-for="r in recent" :key="r.ts"
               class="grid grid-cols-12 items-center py-3 border-b border-border last:border-b-0
                      transition-colors hover:bg-ink/[0.02] cursor-pointer">
            <div class="col-span-2 font-mono tabular-nums text-[14.5px] text-muted">{{ r.ts }}</div>
            <div class="col-span-3 font-mono text-[14.5px]">{{ r.model }}</div>
            <div class="col-span-2 font-mono text-[14.5px] text-muted">{{ r.key }}</div>
            <div class="col-span-2 font-mono text-[14.5px] text-muted">{{ r.pool }}</div>
            <div class="col-span-1 text-right font-mono tabular-nums text-[14.5px]" :class="statusColor(r.status)">{{ r.status }}</div>
            <div class="col-span-1 text-right font-mono tabular-nums text-[14.5px]">{{ r.latency }}<span class="text-subtle">ms</span></div>
            <div class="col-span-1 text-right font-mono tabular-nums text-[14.5px] text-muted">{{ r.cost }}</div>
          </div>
        </div>
      </section>

    </div>
  </div>
</template>
