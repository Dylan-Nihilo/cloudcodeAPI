<!--
  Design comp · Landing page proposal.
  Static mockup. No real data, no API calls. Lives at /__design/landing.
  Goal: lock visual direction before touching the actual HomeView.vue.
-->
<script setup lang="ts">
import { computed } from 'vue'
import { useDarkMode } from './composables/useDarkMode'
import { ArrowUpRight, Moon, Sun } from 'lucide-vue-next'

const { isDark, toggle } = useDarkMode()

interface Upstream {
  model: string
  source: string
  status: 'live' | 'staged' | 'idle'
  latency?: string
}

const upstreams: Upstream[] = [
  { model: 'claude-3.5-sonnet', source: 'anthropic',   status: 'live',   latency: '342ms' },
  { model: 'claude-3.5-sonnet', source: 'antigravity', status: 'live',   latency: '518ms' },
  { model: 'claude-3.5-haiku',  source: 'anthropic',   status: 'live',   latency: '198ms' },
  { model: 'claude-4.5-opus',   source: 'cursor',      status: 'staged', latency: '—'     },
  { model: 'gpt-4.1',           source: 'openai',      status: 'staged', latency: '—'     },
  { model: 'gemini-2.5-pro',    source: 'vertex',      status: 'idle',   latency: '—'     },
]

const statusDot = (s: Upstream['status']) => ({
  live:   'bg-success',
  staged: 'bg-warning',
  idle:   'bg-subtle',
}[s])

const statusLabel = (s: Upstream['status']) => ({
  live:   'live',
  staged: 'staged',
  idle:   'not configured',
}[s])

const now = computed(() => new Date().toISOString().slice(0, 10))
</script>

<template>
  <div class="min-h-screen bg-paper text-ink font-sans antialiased selection:bg-ink selection:text-paper">

    <!-- ═══════════════════════════════════════════════════════ TOP BAR -->
    <header class="border-b border-border">
      <div class="mx-auto max-w-[1200px] px-8 h-14 flex items-center justify-between">
        <div class="flex items-baseline gap-3">
          <span class="font-display italic text-[22px] leading-none">proxy</span>
          <span class="font-sans font-medium text-[14px] leading-none -ml-1">api</span>
          <span class="ml-3 text-[12.5px] uppercase tracking-[0.16em] text-subtle font-mono">v0.1</span>
        </div>
        <nav class="flex items-center gap-6 text-[14px]">
          <a href="#features" class="text-muted hover:text-ink transition-colors">Features</a>
          <a href="#upstreams" class="text-muted hover:text-ink transition-colors">Upstreams</a>
          <a href="#docs" class="text-muted hover:text-ink transition-colors">Docs</a>
          <span class="h-4 w-px bg-border mx-1"></span>
          <button @click="toggle()" :aria-label="isDark ? 'Light mode' : 'Dark mode'"
                  class="text-muted hover:text-ink transition-colors">
            <component :is="isDark ? Sun : Moon" :size="16" stroke-width="1.5" />
          </button>
          <button class="text-muted hover:text-ink transition-colors">EN · ZH</button>
          <a href="#login"
             class="ml-2 inline-flex items-center gap-1.5 px-3 h-8 rounded-sm border border-ink/15 hover:border-ink/40 text-[14px] transition-colors">
            Sign in
            <ArrowUpRight :size="13" stroke-width="1.5" />
          </a>
        </nav>
      </div>
    </header>

    <!-- ═══════════════════════════════════════════════════════ HERO -->
    <section class="border-b border-border">
      <div class="mx-auto max-w-[1200px] px-8 pt-24 pb-28">
        <div class="grid grid-cols-12 gap-8">

          <!-- LEFT: editorial type column -->
          <div class="col-span-12 md:col-span-7">
            <div class="text-[12.5px] uppercase tracking-[0.16em] text-subtle font-mono mb-10">
              <span class="inline-block w-6 border-t border-subtle align-middle mr-2"></span>
              Anthropic-compatible relay · self-hosted
            </div>

            <h1 class="font-sans font-light tracking-[-0.025em] text-[clamp(56px,7vw,92px)] leading-[1.04]">
              Claude,<br>
              served at
              <span class="font-display italic font-normal text-[1.04em] tracking-[-0.01em]">wire speed</span>.
            </h1>

            <p class="mt-10 max-w-[36ch] text-[17px] leading-[1.65] text-muted">
              Aggregate official API keys, IDE subscriptions and third-party gateways
              behind a single <span class="font-mono text-[14px] text-ink bg-ink/5 px-1.5 py-0.5 rounded-sm">/v1/messages</span>
              endpoint. Health-checked pools rotate keys on rate-limit or quota
              exhaustion. Per-key, per-route, per-hour metering.
            </p>

            <div class="mt-12 flex items-center gap-6">
              <a href="#start"
                 class="group inline-flex items-center gap-2 h-11 px-5 bg-ink text-paper text-[14px] font-medium rounded-sm transition-all hover:translate-y-[-1px] hover:shadow-medium">
                Get an API key
                <ArrowUpRight :size="14" stroke-width="2"
                              class="transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
              </a>
              <a href="#docs" class="text-[14px] text-muted hover:text-ink transition-colors underline-offset-4 hover:underline">
                Read the protocol →
              </a>
            </div>
          </div>

          <!-- RIGHT: code listing — flat, NOT a fake terminal -->
          <div class="col-span-12 md:col-span-5 md:pt-2">
            <figure class="border border-border bg-surface">
              <figcaption class="flex items-center justify-between border-b border-border px-4 py-2.5
                                 text-[12.5px] uppercase tracking-[0.14em] text-subtle font-mono">
                <span>request.sh</span>
                <span class="flex items-center gap-1.5">
                  <span class="w-1.5 h-1.5 rounded-full bg-success"></span>
                  200
                </span>
              </figcaption>
              <pre class="font-mono text-[14px] leading-[1.85] text-ink/85 px-4 py-4 overflow-x-auto"><span class="select-none text-subtle pr-4">1</span><span class="text-subtle">$</span> curl <span class="text-muted">-sN</span> https://your.proxy.api/v1/messages <span class="text-muted">\</span>
<span class="select-none text-subtle pr-4">2</span>     <span class="text-muted">-H</span> <span class="text-ink">"x-api-key: $KEY"</span> <span class="text-muted">\</span>
<span class="select-none text-subtle pr-4">3</span>     <span class="text-muted">-H</span> <span class="text-ink">"anthropic-version: 2023-06-01"</span> <span class="text-muted">\</span>
<span class="select-none text-subtle pr-4">4</span>     <span class="text-muted">-d</span> <span class="text-ink">'{"model":"claude-3.5-sonnet",</span>
<span class="select-none text-subtle pr-4">5</span>          <span class="text-ink">"max_tokens":1024,</span>
<span class="select-none text-subtle pr-4">6</span>          <span class="text-ink">"messages":[{"role":"user",</span>
<span class="select-none text-subtle pr-4">7</span>                       <span class="text-ink">"content":"hi"}]}'</span>
<span class="select-none text-subtle pr-4">8</span>
<span class="select-none text-subtle pr-4">9</span><span class="text-success">→</span> routed to <span class="text-ink">anthropic#3</span>  <span class="text-subtle">·  342ms  ·  $0.0021</span></pre>
            </figure>
            <div class="mt-3 flex items-center justify-between text-[12.5px] text-subtle font-mono px-1">
              <span>protocol: anthropic-messages-2023-06-01</span>
              <span>{{ now }}</span>
            </div>
          </div>

        </div>
      </div>
    </section>

    <!-- ═══════════════════════════════════════════════════════ FEATURES -->
    <section id="features" class="border-b border-border">
      <div class="mx-auto max-w-[1200px] px-8 pt-20 pb-24">
        <div class="text-[12.5px] uppercase tracking-[0.16em] text-subtle font-mono mb-12">
          <span class="inline-block w-6 border-t border-subtle align-middle mr-2"></span>
          What it does
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-x-12 gap-y-16">
          <article class="flex flex-col gap-3">
            <div class="font-mono text-[12.5px] text-subtle">01</div>
            <h3 class="text-[20px] font-medium tracking-[-0.01em]">Single endpoint, many providers</h3>
            <p class="text-[15.5px] leading-[1.7] text-muted">
              Every upstream — official keys, third-party relays, OAuth-scraped
              IDE subscriptions — hides behind one Anthropic-native endpoint.
              Your client never knows which key answered.
            </p>
          </article>

          <article class="flex flex-col gap-3">
            <div class="font-mono text-[12.5px] text-subtle">02</div>
            <h3 class="text-[20px] font-medium tracking-[-0.01em]">Hot failover, by pool</h3>
            <p class="text-[15.5px] leading-[1.7] text-muted">
              Pools are health-checked continuously. A 429 or 529 cools that key
              for a configurable interval; the next call lands on a sibling.
              Carpool groups isolate Anthropic and Antigravity Claude contexts.
            </p>
          </article>

          <article class="flex flex-col gap-3">
            <div class="font-mono text-[12.5px] text-subtle">03</div>
            <h3 class="text-[20px] font-medium tracking-[-0.01em]">Meter, don&rsquo;t guess</h3>
            <p class="text-[15.5px] leading-[1.7] text-muted">
              Per-key, per-route, per-hour token spend. Enforce quotas <em class="font-display italic font-normal text-[17px] text-ink">before</em>
              they overspend you. Aggregations refresh every 60s.
            </p>
          </article>
        </div>
      </div>
    </section>

    <!-- ═══════════════════════════════════════════════════════ UPSTREAMS -->
    <section id="upstreams" class="border-b border-border">
      <div class="mx-auto max-w-[1200px] px-8 pt-20 pb-24">
        <div class="flex items-end justify-between mb-10">
          <div>
            <div class="text-[12.5px] uppercase tracking-[0.16em] text-subtle font-mono mb-3">
              <span class="inline-block w-6 border-t border-subtle align-middle mr-2"></span>
              Reference
            </div>
            <h2 class="text-[32px] font-light tracking-[-0.015em]">
              Available <span class="font-display italic font-normal">upstreams</span>
            </h2>
          </div>
          <a href="#docs" class="text-[14px] text-muted hover:text-ink transition-colors underline-offset-4 hover:underline">
            See full matrix →
          </a>
        </div>

        <div class="border-t border-border">
          <div class="grid grid-cols-12 text-[12.5px] uppercase tracking-[0.14em] text-subtle font-mono py-3 border-b border-border">
            <div class="col-span-5">Model</div>
            <div class="col-span-3">Source</div>
            <div class="col-span-2">Status</div>
            <div class="col-span-2 text-right">p50 latency</div>
          </div>
          <div v-for="u in upstreams" :key="u.model + u.source"
               class="grid grid-cols-12 items-center py-4 border-b border-border last:border-b-0
                      transition-colors hover:bg-ink/[0.02]">
            <div class="col-span-5 font-mono text-[14.5px]">{{ u.model }}</div>
            <div class="col-span-3 text-[14.5px] text-muted">{{ u.source }}</div>
            <div class="col-span-2 flex items-center gap-2 text-[14px]">
              <span class="w-1.5 h-1.5 rounded-full" :class="statusDot(u.status)"></span>
              <span :class="u.status === 'live' ? 'text-ink' : 'text-muted'">{{ statusLabel(u.status) }}</span>
            </div>
            <div class="col-span-2 text-right font-mono tabular-nums text-[14px] text-muted">{{ u.latency }}</div>
          </div>
        </div>
      </div>
    </section>

    <!-- ═══════════════════════════════════════════════════════ NUMBERS -->
    <section class="border-b border-border">
      <div class="mx-auto max-w-[1200px] px-8 pt-20 pb-24">
        <div class="grid grid-cols-2 md:grid-cols-4 gap-x-8 gap-y-12">
          <div>
            <div class="font-display italic font-normal tabular-nums text-[72px] leading-none tracking-[-0.02em]">
              12<span class="text-subtle">.4</span>M
            </div>
            <div class="mt-3 text-[12.5px] uppercase tracking-[0.14em] text-subtle font-mono">tokens / day</div>
          </div>
          <div>
            <div class="font-display italic font-normal tabular-nums text-[72px] leading-none tracking-[-0.02em]">
              99<span class="text-subtle">.97</span>%
            </div>
            <div class="mt-3 text-[12.5px] uppercase tracking-[0.14em] text-subtle font-mono">success rate · 30d</div>
          </div>
          <div>
            <div class="font-display italic font-normal tabular-nums text-[72px] leading-none tracking-[-0.02em]">
              287<span class="text-subtle">ms</span>
            </div>
            <div class="mt-3 text-[12.5px] uppercase tracking-[0.14em] text-subtle font-mono">p50 latency</div>
          </div>
          <div>
            <div class="font-display italic font-normal tabular-nums text-[72px] leading-none tracking-[-0.02em]">
              7
            </div>
            <div class="mt-3 text-[12.5px] uppercase tracking-[0.14em] text-subtle font-mono">active upstream pools</div>
          </div>
        </div>
      </div>
    </section>

    <!-- ═══════════════════════════════════════════════════════ FOOTER -->
    <footer>
      <div class="mx-auto max-w-[1200px] px-8 py-10 flex items-center justify-between text-[12.5px] font-mono uppercase tracking-[0.16em] text-subtle">
        <div class="flex items-center gap-6">
          <span>proxy-api</span>
          <span class="text-border">/</span>
          <span>0.1.0-rc.1</span>
          <span class="text-border">/</span>
          <span>built {{ now }}</span>
        </div>
        <div class="flex items-center gap-6">
          <a href="#" class="hover:text-ink transition-colors">github</a>
          <a href="#" class="hover:text-ink transition-colors">docs</a>
          <a href="#" class="hover:text-ink transition-colors">status</a>
          <span class="flex items-center gap-1.5">
            <span class="w-1.5 h-1.5 rounded-full bg-success"></span>
            <span>operational</span>
          </span>
        </div>
      </div>
    </footer>

  </div>
</template>
