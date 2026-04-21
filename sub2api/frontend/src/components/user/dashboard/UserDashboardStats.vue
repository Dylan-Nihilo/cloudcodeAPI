<template>
  <div>
    <!-- ─── Row 1: hero strip — primary daily metrics ──────────── -->
    <div class="border-y border-border grid grid-cols-2 lg:grid-cols-4 divide-x divide-border">

      <!-- Today cost (HERO — oversized italic serif) -->
      <div class="p-6">
        <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">{{ t('dashboard.todayCost') }}</div>
        <div class="mt-2 font-display italic font-normal tabular-nums text-[44px] leading-none tracking-[-0.02em]">
          $&thinsp;{{ formatCost(stats?.today_actual_cost || 0) }}
        </div>
        <div class="mt-2 text-[11px] text-muted">
          <span class="text-subtle">{{ t('common.total') }}:</span>
          <span class="font-mono tabular-nums ml-1">${{ formatCost(stats?.total_actual_cost || 0) }}</span>
        </div>
      </div>

      <!-- Today requests -->
      <div class="p-6">
        <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">{{ t('dashboard.todayRequests') }}</div>
        <div class="mt-2 font-mono tabular-nums text-[28px] leading-none text-ink">
          {{ formatNumber(stats?.today_requests || 0) }}
        </div>
        <div class="mt-2 text-[11px] text-muted">
          <span class="text-subtle">{{ t('common.total') }}:</span>
          <span class="font-mono tabular-nums ml-1">{{ formatNumber(stats?.total_requests || 0) }}</span>
        </div>
      </div>

      <!-- Avg response -->
      <div class="p-6">
        <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">{{ t('dashboard.avgResponse') }}</div>
        <div class="mt-2 font-mono tabular-nums text-[28px] leading-none text-ink">
          {{ formatDuration(stats?.average_duration_ms || 0) }}
        </div>
        <div class="mt-2 text-[11px] text-muted">{{ t('dashboard.averageTime') }}</div>
      </div>

      <!-- Balance (admin-only when isSimple) -->
      <div v-if="!isSimple" class="p-6">
        <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">{{ t('dashboard.balance') }}</div>
        <div class="mt-2 font-mono tabular-nums text-[28px] leading-none text-ink">
          $&thinsp;{{ formatBalance(balance) }}
        </div>
        <div class="mt-2 text-[11px] text-muted">{{ t('common.available') }}</div>
      </div>
      <div v-else class="p-6">
        <!-- Fill slot when simple mode hides balance -->
        <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">{{ t('dashboard.apiKeys') }}</div>
        <div class="mt-2 font-mono tabular-nums text-[28px] leading-none text-ink">
          {{ stats?.total_api_keys || 0 }}
        </div>
        <div class="mt-2 text-[11px]">
          <span class="inline-flex items-center gap-1.5">
            <span class="w-1.5 h-1.5 rounded-full bg-success"></span>
            <span class="text-muted font-mono tabular-nums">{{ stats?.active_api_keys || 0 }} {{ t('common.active') }}</span>
          </span>
        </div>
      </div>
    </div>

    <!-- ─── Row 2: supporting metrics ──────────────────────────── -->
    <div class="border-b border-border grid grid-cols-2 lg:grid-cols-4 divide-x divide-border">

      <!-- Today tokens -->
      <div class="p-6">
        <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">{{ t('dashboard.todayTokens') }}</div>
        <div class="mt-2 font-mono tabular-nums text-[24px] leading-none text-ink">
          {{ formatTokens(stats?.today_tokens || 0) }}
        </div>
        <div class="mt-2 text-[11px] text-muted">
          {{ t('dashboard.input') }}: <span class="font-mono tabular-nums text-ink">{{ formatTokens(stats?.today_input_tokens || 0) }}</span>
          <span class="mx-1.5 text-subtle">·</span>
          {{ t('dashboard.output') }}: <span class="font-mono tabular-nums text-ink">{{ formatTokens(stats?.today_output_tokens || 0) }}</span>
        </div>
      </div>

      <!-- Total tokens -->
      <div class="p-6">
        <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">{{ t('dashboard.totalTokens') }}</div>
        <div class="mt-2 font-mono tabular-nums text-[24px] leading-none text-ink">
          {{ formatTokens(stats?.total_tokens || 0) }}
        </div>
        <div class="mt-2 text-[11px] text-muted">
          {{ t('dashboard.input') }}: <span class="font-mono tabular-nums text-ink">{{ formatTokens(stats?.total_input_tokens || 0) }}</span>
          <span class="mx-1.5 text-subtle">·</span>
          {{ t('dashboard.output') }}: <span class="font-mono tabular-nums text-ink">{{ formatTokens(stats?.total_output_tokens || 0) }}</span>
        </div>
      </div>

      <!-- API keys (when not in simple mode this slot still shows it) -->
      <div v-if="!isSimple" class="p-6">
        <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">{{ t('dashboard.apiKeys') }}</div>
        <div class="mt-2 font-mono tabular-nums text-[24px] leading-none text-ink">
          {{ stats?.total_api_keys || 0 }}
        </div>
        <div class="mt-2 text-[11px]">
          <span class="inline-flex items-center gap-1.5">
            <span class="w-1.5 h-1.5 rounded-full bg-success"></span>
            <span class="text-muted font-mono tabular-nums">{{ stats?.active_api_keys || 0 }} {{ t('common.active') }}</span>
          </span>
        </div>
      </div>
      <div v-else class="p-6">
        <!-- Spacer for layout symmetry in simple mode -->
      </div>

      <!-- Performance: RPM / TPM -->
      <div class="p-6">
        <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">{{ t('dashboard.performance') }}</div>
        <div class="mt-2 flex items-baseline gap-3">
          <span class="font-mono tabular-nums text-[20px] leading-none text-ink">
            {{ formatTokens(stats?.rpm || 0) }}
          </span>
          <span class="text-[11px] text-subtle uppercase tracking-[0.14em] font-mono">rpm</span>
        </div>
        <div class="mt-1.5 flex items-baseline gap-3">
          <span class="font-mono tabular-nums text-[14px] text-muted">
            {{ formatTokens(stats?.tpm || 0) }}
          </span>
          <span class="text-[11px] text-subtle uppercase tracking-[0.14em] font-mono">tpm</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import type { UserDashboardStats as UserStatsType } from '@/api/usage'

defineProps<{
  stats: UserStatsType
  balance: number
  isSimple: boolean
}>()
const { t } = useI18n()

const formatBalance = (b: number) =>
  new Intl.NumberFormat('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(b)

const formatNumber = (n: number) => n.toLocaleString()
const formatCost = (c: number) => c.toFixed(4)
const formatTokens = (n: number) => {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`
  if (n >= 1000) return `${(n / 1000).toFixed(1)}K`
  return n.toString()
}
const formatDuration = (ms: number) => (ms >= 1000 ? `${(ms / 1000).toFixed(2)}s` : `${ms.toFixed(0)}ms`)
</script>
