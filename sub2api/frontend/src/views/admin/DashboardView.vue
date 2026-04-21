<template>
  <AppLayout>
    <!-- Loading state -->
    <div v-if="loading" class="flex items-center justify-center py-24">
      <LoadingSpinner />
    </div>

    <template v-else-if="stats">
      <!-- ─── Editorial section header ─────────────────────────── -->
      <div class="mb-6">
        <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono mb-2">
          <span class="inline-block w-6 border-t border-subtle align-middle mr-2"></span>
          {{ t('admin.dashboard.title', 'admin · overview') }}
        </div>
        <h1 class="text-[28px] font-light tracking-[-0.015em] text-ink">
          {{ t('admin.dashboard.welcomeMessage', 'System overview') }}
        </h1>
      </div>

      <!-- ─── Row 1: core counters (4 cells, hairline-divided) ── -->
      <div class="border-y border-border grid grid-cols-2 lg:grid-cols-4 divide-x divide-border">
        <div class="p-5">
          <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">{{ t('admin.dashboard.apiKeys') }}</div>
          <div class="mt-1.5 font-mono tabular-nums text-[24px] leading-none text-ink">{{ stats.total_api_keys }}</div>
          <div class="mt-1.5 text-[11px] text-muted inline-flex items-center gap-1.5">
            <span class="w-1.5 h-1.5 rounded-full bg-success"></span>
            <span class="font-mono tabular-nums text-ink">{{ stats.active_api_keys }}</span>
            <span>{{ t('common.active') }}</span>
          </div>
        </div>

        <div class="p-5">
          <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">{{ t('admin.dashboard.accounts') }}</div>
          <div class="mt-1.5 font-mono tabular-nums text-[24px] leading-none text-ink">{{ stats.total_accounts }}</div>
          <div class="mt-1.5 text-[11px] text-muted inline-flex items-center gap-2">
            <span class="inline-flex items-center gap-1.5">
              <span class="w-1.5 h-1.5 rounded-full bg-success"></span>
              <span class="font-mono tabular-nums text-ink">{{ stats.normal_accounts }}</span>
            </span>
            <span v-if="stats.error_accounts > 0" class="inline-flex items-center gap-1.5">
              <span class="w-1.5 h-1.5 rounded-full bg-danger"></span>
              <span class="font-mono tabular-nums text-danger">{{ stats.error_accounts }}</span>
            </span>
          </div>
        </div>

        <div class="p-5">
          <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">{{ t('admin.dashboard.todayRequests') }}</div>
          <div class="mt-1.5 font-mono tabular-nums text-[24px] leading-none text-ink">{{ stats.today_requests }}</div>
          <div class="mt-1.5 text-[11px] text-muted">
            <span class="text-subtle">{{ t('common.total') }}:</span>
            <span class="font-mono tabular-nums ml-1 text-ink">{{ formatNumber(stats.total_requests) }}</span>
          </div>
        </div>

        <div class="p-5">
          <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">{{ t('admin.dashboard.users') }}</div>
          <div class="mt-1.5 font-display italic font-normal tabular-nums text-[28px] leading-none tracking-[-0.02em] text-ink">
            +{{ stats.today_new_users }}
          </div>
          <div class="mt-1.5 text-[11px] text-muted">
            <span class="text-subtle">{{ t('common.total') }}:</span>
            <span class="font-mono tabular-nums ml-1 text-ink">{{ formatNumber(stats.total_users) }}</span>
          </div>
        </div>
      </div>

      <!-- ─── Row 2: tokens / performance / latency ─────────────── -->
      <div class="border-b border-border grid grid-cols-2 lg:grid-cols-4 divide-x divide-border">
        <div class="p-5">
          <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">{{ t('admin.dashboard.todayTokens') }}</div>
          <div class="mt-1.5 font-mono tabular-nums text-[22px] leading-none text-ink">{{ formatTokens(stats.today_tokens) }}</div>
          <div class="mt-1.5 text-[11px] text-muted font-mono tabular-nums">
            <span class="text-ink">${{ formatCost(stats.today_actual_cost) }}</span>
            <span class="mx-1 text-subtle">/</span>
            <span class="text-muted" :title="t('admin.dashboard.accountCost')">${{ formatCost(stats.today_account_cost) }}</span>
            <span class="mx-1 text-subtle">/</span>
            <span class="text-subtle" :title="t('admin.dashboard.standard')">${{ formatCost(stats.today_cost) }}</span>
          </div>
        </div>

        <div class="p-5">
          <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">{{ t('admin.dashboard.totalTokens') }}</div>
          <div class="mt-1.5 font-mono tabular-nums text-[22px] leading-none text-ink">{{ formatTokens(stats.total_tokens) }}</div>
          <div class="mt-1.5 text-[11px] text-muted font-mono tabular-nums">
            <span class="text-ink">${{ formatCost(stats.total_actual_cost) }}</span>
            <span class="mx-1 text-subtle">/</span>
            <span class="text-muted">${{ formatCost(stats.total_account_cost) }}</span>
            <span class="mx-1 text-subtle">/</span>
            <span class="text-subtle">${{ formatCost(stats.total_cost) }}</span>
          </div>
        </div>

        <div class="p-5">
          <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">{{ t('admin.dashboard.performance') }}</div>
          <div class="mt-1.5 flex items-baseline gap-2.5">
            <span class="font-mono tabular-nums text-[22px] leading-none text-ink">{{ formatTokens(stats.rpm) }}</span>
            <span class="text-[11px] uppercase tracking-[0.14em] text-subtle font-mono">rpm</span>
          </div>
          <div class="mt-1.5 flex items-baseline gap-2.5">
            <span class="font-mono tabular-nums text-[14px] text-muted">{{ formatTokens(stats.tpm) }}</span>
            <span class="text-[11px] uppercase tracking-[0.14em] text-subtle font-mono">tpm</span>
          </div>
        </div>

        <div class="p-5">
          <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">{{ t('admin.dashboard.avgResponse') }}</div>
          <div class="mt-1.5 font-mono tabular-nums text-[22px] leading-none text-ink">{{ formatDuration(stats.average_duration_ms) }}</div>
          <div class="mt-1.5 text-[11px] text-muted">
            <span class="font-mono tabular-nums text-ink">{{ stats.active_users }}</span>
            <span class="ml-1">{{ t('admin.dashboard.activeUsers') }}</span>
          </div>
        </div>
      </div>

      <!-- ─── Filter strip — flat row, no card ─────────────────── -->
      <div class="py-3 border-b border-border flex flex-wrap items-center gap-4">
        <div class="flex items-center gap-2">
          <span class="text-[11px] uppercase tracking-[0.14em] text-subtle font-mono">{{ t('admin.dashboard.timeRange') }}</span>
          <DateRangePicker
            v-model:start-date="startDate"
            v-model:end-date="endDate"
            @change="onDateRangeChange"
          />
        </div>
        <button @click="loadDashboardStats" :disabled="chartsLoading" class="btn btn-ghost btn-sm">
          {{ t('common.refresh') }}
        </button>
        <div class="ml-auto flex items-center gap-2">
          <span class="text-[11px] uppercase tracking-[0.14em] text-subtle font-mono">{{ t('admin.dashboard.granularity') }}</span>
          <div class="w-24">
            <Select
              v-model="granularity"
              :options="granularityOptions"
              @change="loadChartData"
            />
          </div>
        </div>
      </div>

      <!-- ─── Charts grid ───────────────────────────────────────── -->
      <div class="grid grid-cols-1 lg:grid-cols-2 divide-x divide-border border-b border-border">
        <div class="p-6">
          <ModelDistributionChart
            :model-stats="modelStats"
            :enable-ranking-view="true"
            :ranking-items="rankingItems"
            :ranking-total-actual-cost="rankingTotalActualCost"
            :ranking-total-requests="rankingTotalRequests"
            :ranking-total-tokens="rankingTotalTokens"
            :loading="chartsLoading"
            :ranking-loading="rankingLoading"
            :ranking-error="rankingError"
            :start-date="startDate"
            :end-date="endDate"
            @ranking-click="goToUserUsage"
          />
        </div>
        <div class="p-6">
          <TokenUsageTrend :trend-data="trendData" :loading="chartsLoading" />
        </div>
      </div>

      <!-- ─── User trend (full width) ───────────────────────────── -->
      <div class="border-b border-border px-6 py-6">
        <div class="flex items-end justify-between mb-4">
          <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">
            <span class="inline-block w-6 border-t border-subtle align-middle mr-2"></span>
            {{ t('admin.dashboard.recentUsage') }} <span class="ml-1.5 text-ink normal-case tracking-normal">Top 12</span>
          </div>
        </div>
        <div class="h-64">
          <div v-if="userTrendLoading" class="flex h-full items-center justify-center">
            <LoadingSpinner size="md" />
          </div>
          <Line v-else-if="userTrendChartData" :data="userTrendChartData" :options="lineOptions" />
          <div v-else class="flex h-full items-center justify-center text-[12px] text-subtle font-mono">
            {{ t('admin.dashboard.noDataAvailable') }}
          </div>
        </div>
      </div>
    </template>
  </AppLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { useAppStore } from '@/stores/app'

const { t } = useI18n()
import { adminAPI } from '@/api/admin'
import type {
  DashboardStats,
  TrendDataPoint,
  ModelStat,
  UserUsageTrendPoint,
  UserSpendingRankingItem
} from '@/types'
import AppLayout from '@/components/layout/AppLayout.vue'
import LoadingSpinner from '@/components/common/LoadingSpinner.vue'
import DateRangePicker from '@/components/common/DateRangePicker.vue'
import Select from '@/components/common/Select.vue'
import ModelDistributionChart from '@/components/charts/ModelDistributionChart.vue'
import TokenUsageTrend from '@/components/charts/TokenUsageTrend.vue'

import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Tooltip,
  Legend,
  Filler
} from 'chart.js'
import { Line } from 'vue-chartjs'

// Register Chart.js components
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Tooltip,
  Legend,
  Filler
)

const appStore = useAppStore()
const router = useRouter()
const stats = ref<DashboardStats | null>(null)
const loading = ref(false)
const chartsLoading = ref(false)
const userTrendLoading = ref(false)
const rankingLoading = ref(false)
const rankingError = ref(false)

// Chart data
const trendData = ref<TrendDataPoint[]>([])
const modelStats = ref<ModelStat[]>([])
const userTrend = ref<UserUsageTrendPoint[]>([])
const rankingItems = ref<UserSpendingRankingItem[]>([])
const rankingTotalActualCost = ref(0)
const rankingTotalRequests = ref(0)
const rankingTotalTokens = ref(0)
let chartLoadSeq = 0
let usersTrendLoadSeq = 0
let rankingLoadSeq = 0
const rankingLimit = 12

// Helper function to format date in local timezone
const formatLocalDate = (date: Date): string => {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
}

const getLast24HoursRangeDates = (): { start: string; end: string } => {
  const end = new Date()
  const start = new Date(end.getTime() - 24 * 60 * 60 * 1000)
  return {
    start: formatLocalDate(start),
    end: formatLocalDate(end)
  }
}

// Date range
const granularity = ref<'day' | 'hour'>('hour')
const defaultRange = getLast24HoursRangeDates()
const startDate = ref(defaultRange.start)
const endDate = ref(defaultRange.end)

// Granularity options for Select component
const granularityOptions = computed(() => [
  { value: 'day', label: t('admin.dashboard.day') },
  { value: 'hour', label: t('admin.dashboard.hour') }
])

// Dark mode detection
const isDarkMode = computed(() => {
  return document.documentElement.classList.contains('dark')
})

// Chart colors
const chartColors = computed(() => ({
  text: isDarkMode.value ? '#e5e7eb' : '#374151',
  grid: isDarkMode.value ? '#374151' : '#e5e7eb'
}))

// Line chart options (for user trend chart)
const lineOptions = computed(() => ({
  responsive: true,
  maintainAspectRatio: false,
  interaction: {
    intersect: false,
    mode: 'index' as const
  },
  plugins: {
    legend: {
      position: 'top' as const,
      labels: {
        color: chartColors.value.text,
        usePointStyle: true,
        pointStyle: 'circle',
        padding: 15,
        font: {
          size: 11
        }
      }
    },
    tooltip: {
      itemSort: (a: any, b: any) => {
        const aValue = typeof a?.raw === 'number' ? a.raw : Number(a?.parsed?.y ?? 0)
        const bValue = typeof b?.raw === 'number' ? b.raw : Number(b?.parsed?.y ?? 0)
        return bValue - aValue
      },
      callbacks: {
        label: (context: any) => {
          return `${context.dataset.label}: ${formatTokens(context.raw)}`
        }
      }
    }
  },
  scales: {
    x: {
      grid: {
        color: chartColors.value.grid
      },
      ticks: {
        color: chartColors.value.text,
        font: {
          size: 10
        }
      }
    },
    y: {
      grid: {
        color: chartColors.value.grid
      },
      ticks: {
        color: chartColors.value.text,
        font: {
          size: 10
        },
        callback: (value: string | number) => formatTokens(Number(value))
      }
    }
  }
}))

// User trend chart data
const userTrendChartData = computed(() => {
  if (!userTrend.value?.length) return null

  const getDisplayName = (point: UserUsageTrendPoint): string => {
    const username = point.username?.trim()
    if (username) {
      return username
    }

    const email = point.email?.trim()
    if (email) {
      return email
    }

    return t('admin.redeem.userPrefix', { id: point.user_id })
  }

  // Group by user_id to avoid merging different users with the same display name
  const userGroups = new Map<number, { name: string; data: Map<string, number> }>()
  const allDates = new Set<string>()

  userTrend.value.forEach((point) => {
    allDates.add(point.date)
    const key = point.user_id
    if (!userGroups.has(key)) {
      userGroups.set(key, { name: getDisplayName(point), data: new Map() })
    }
    userGroups.get(key)!.data.set(point.date, point.tokens)
  })

  const sortedDates = Array.from(allDates).sort()
  const colors = [
    '#3b82f6',
    '#27272A',
    '#f59e0b',
    '#ef4444',
    '#8b5cf6',
    '#ec4899',
    '#0A0A0A',
    '#f97316',
    '#6366f1',
    '#84cc16',
    '#52525B',
    '#a855f7'
  ]

  const datasets = Array.from(userGroups.values()).map((group, idx) => ({
    label: group.name,
    data: sortedDates.map((date) => group.data.get(date) || 0),
    borderColor: colors[idx % colors.length],
    backgroundColor: `${colors[idx % colors.length]}20`,
    fill: false,
    tension: 0.3
  }))

  return {
    labels: sortedDates,
    datasets
  }
})

// Format helpers
const formatTokens = (value: number | undefined): string => {
  if (value === undefined || value === null) return '0'
  if (value >= 1_000_000_000) {
    return `${(value / 1_000_000_000).toFixed(2)}B`
  } else if (value >= 1_000_000) {
    return `${(value / 1_000_000).toFixed(2)}M`
  } else if (value >= 1_000) {
    return `${(value / 1_000).toFixed(2)}K`
  }
  return value.toLocaleString()
}

const formatNumber = (value: number): string => {
  return value.toLocaleString()
}

const formatCost = (value: number): string => {
  if (value >= 1000) {
    return (value / 1000).toFixed(2) + 'K'
  } else if (value >= 1) {
    return value.toFixed(2)
  } else if (value >= 0.01) {
    return value.toFixed(3)
  }
  return value.toFixed(4)
}

const formatDuration = (ms: number): string => {
  if (ms >= 1000) {
    return `${(ms / 1000).toFixed(2)}s`
  }
  return `${Math.round(ms)}ms`
}

const goToUserUsage = (item: UserSpendingRankingItem) => {
  void router.push({
    path: '/admin/usage',
    query: {
      user_id: String(item.user_id),
      start_date: startDate.value,
      end_date: endDate.value
    }
  })
}

// Date range change handler
const onDateRangeChange = (range: {
  startDate: string
  endDate: string
  preset: string | null
}) => {
  // Auto-select granularity based on date range
  const start = new Date(range.startDate)
  const end = new Date(range.endDate)
  const daysDiff = Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24))

  // If range is 1 day, use hourly granularity
  if (daysDiff <= 1) {
    granularity.value = 'hour'
  } else {
    granularity.value = 'day'
  }

  loadChartData()
}

// Load data
const loadDashboardSnapshot = async (includeStats: boolean) => {
  const currentSeq = ++chartLoadSeq
  if (includeStats && !stats.value) {
    loading.value = true
  }
  chartsLoading.value = true
  try {
    const response = await adminAPI.dashboard.getSnapshotV2({
      start_date: startDate.value,
      end_date: endDate.value,
      granularity: granularity.value,
      include_stats: includeStats,
      include_trend: true,
      include_model_stats: true,
      include_group_stats: false,
      include_users_trend: false
    })
    if (currentSeq !== chartLoadSeq) return
    if (includeStats && response.stats) {
      stats.value = response.stats
    }
    trendData.value = response.trend || []
    modelStats.value = response.models || []
  } catch (error) {
    if (currentSeq !== chartLoadSeq) return
    appStore.showError(t('admin.dashboard.failedToLoad'))
    console.error('Error loading dashboard snapshot:', error)
  } finally {
    if (currentSeq === chartLoadSeq) {
      loading.value = false
      chartsLoading.value = false
    }
  }
}

const loadUsersTrend = async () => {
  const currentSeq = ++usersTrendLoadSeq
  userTrendLoading.value = true
  try {
    const response = await adminAPI.dashboard.getUserUsageTrend({
      start_date: startDate.value,
      end_date: endDate.value,
      granularity: granularity.value,
      limit: 12
    })
    if (currentSeq !== usersTrendLoadSeq) return
    userTrend.value = response.trend || []
  } catch (error) {
    if (currentSeq !== usersTrendLoadSeq) return
    console.error('Error loading users trend:', error)
    userTrend.value = []
  } finally {
    if (currentSeq === usersTrendLoadSeq) {
      userTrendLoading.value = false
    }
  }
}

const loadUserSpendingRanking = async () => {
  const currentSeq = ++rankingLoadSeq
  rankingLoading.value = true
  rankingError.value = false
  try {
    const response = await adminAPI.dashboard.getUserSpendingRanking({
      start_date: startDate.value,
      end_date: endDate.value,
      limit: rankingLimit
    })
    if (currentSeq !== rankingLoadSeq) return
    rankingItems.value = response.ranking || []
    rankingTotalActualCost.value = response.total_actual_cost || 0
    rankingTotalRequests.value = response.total_requests || 0
    rankingTotalTokens.value = response.total_tokens || 0
  } catch (error) {
    if (currentSeq !== rankingLoadSeq) return
    console.error('Error loading user spending ranking:', error)
    rankingItems.value = []
    rankingTotalActualCost.value = 0
    rankingTotalRequests.value = 0
    rankingTotalTokens.value = 0
    rankingError.value = true
  } finally {
    if (currentSeq === rankingLoadSeq) {
      rankingLoading.value = false
    }
  }
}

const loadDashboardStats = async () => {
  await Promise.all([
    loadDashboardSnapshot(true),
    loadUsersTrend(),
    loadUserSpendingRanking()
  ])
}

const loadChartData = async () => {
  await Promise.all([
    loadDashboardSnapshot(false),
    loadUsersTrend(),
    loadUserSpendingRanking()
  ])
}

onMounted(() => {
  loadDashboardStats()
})
</script>

<style scoped>
</style>
