<template>
  <div class="min-h-screen flex flex-col md:flex-row bg-paper text-ink font-sans antialiased
              selection:bg-ink selection:text-paper">

    <!-- ─── LEFT: brand panel (md+) ──────────────────────────────── -->
    <aside class="hidden md:flex md:flex-1 relative border-r border-border">
      <!-- Top-left: small caption -->
      <div class="absolute top-8 left-8 text-[12px] uppercase tracking-[0.14em] text-subtle font-mono">
        <span class="inline-block w-6 border-t border-subtle align-middle mr-2"></span>
        Anthropic-compatible relay · self-hosted
      </div>

      <!-- Centered brand stamp + tagline -->
      <div class="m-auto px-12 py-16 max-w-[520px]">
        <h1 class="font-sans font-light tracking-[-0.025em] text-[clamp(48px,5.4vw,72px)] leading-[1.06]">
          <span class="block">use</span>
          <span class="block mt-3">
            <span
              class="font-display italic font-normal tracking-[-0.015em]
                     bg-ink text-paper inline-block leading-[1] align-baseline"
              style="padding: 0.08em 0.18em 0.18em; transform: translateY(0.06em);"
            >{{ brandName }}</span>
            <span class="text-muted">.</span>
          </span>
        </h1>
        <p class="mt-10 max-w-[36ch] text-[15.5px] leading-[1.7] text-muted">
          One Anthropic-native endpoint. Failover, metering and quota
          across every upstream you own.
        </p>
      </div>

      <!-- Bottom-left: status footer -->
      <div class="absolute bottom-8 left-8 right-8 flex items-baseline justify-between
                  text-[12px] font-mono uppercase tracking-[0.14em] text-subtle">
        <div class="flex items-center gap-4">
          <span>{{ brandName.toLowerCase() }}</span>
          <span class="text-border">/</span>
          <span>v{{ siteVersion || '0.1' }}</span>
        </div>
        <span class="flex items-center gap-1.5">
          <span class="w-1.5 h-1.5 rounded-full bg-success"></span>
          operational
        </span>
      </div>
    </aside>

    <!-- ─── RIGHT: form panel ────────────────────────────────────── -->
    <main class="flex-1 md:w-[440px] md:flex-none flex flex-col bg-surface">
      <!-- Top-right corner controls -->
      <div class="flex items-center justify-end gap-1 px-6 md:px-8 h-14">
        <slot name="top-right" />
      </div>

      <!-- Form slot (centered) -->
      <div class="flex-1 flex items-center justify-center px-6 md:px-12 py-8">
        <div class="w-full max-w-[360px]">
          <!-- Mobile-only brand mark (md- doesn't show left panel) -->
          <div class="md:hidden mb-10 text-center">
            <div class="inline-flex items-baseline gap-1">
              <span class="font-display italic text-[26px] leading-none">{{ brandHead }}</span>
              <span class="font-sans font-medium text-[16px] leading-none">{{ brandTail }}</span>
            </div>
          </div>

          <slot />

          <!-- Footer slot (e.g. "Don't have an account? Sign up") -->
          <div v-if="$slots.footer" class="mt-8 text-center text-[14px] text-muted">
            <slot name="footer" />
          </div>
        </div>
      </div>

      <!-- Bottom strip -->
      <div class="px-6 md:px-8 py-4 border-t border-border
                  flex items-center justify-between text-[11px] font-mono uppercase tracking-[0.14em] text-subtle">
        <span>&copy; {{ currentYear }} {{ brandName.toLowerCase() }}</span>
        <span class="md:hidden flex items-center gap-1.5">
          <span class="w-1.5 h-1.5 rounded-full bg-success"></span>
          operational
        </span>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useAppStore } from '@/stores'

const appStore = useAppStore()

// Brand identity — decoupled from sub2api's siteName setting.
const brandName = 'CloudCodeAPI'
const brandHead = 'CloudCode'
const brandTail = 'API'

const siteVersion = computed(() => appStore.siteVersion)
const currentYear = computed(() => new Date().getFullYear())

onMounted(() => {
  appStore.fetchPublicSettings()
})
</script>
