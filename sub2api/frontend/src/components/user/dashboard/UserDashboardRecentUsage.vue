<template>
  <div>
    <div class="flex items-end justify-between mb-6 px-6 pt-6">
      <div>
        <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono mb-2">
          <span class="inline-block w-6 border-t border-subtle align-middle mr-2"></span>
          {{ t('dashboard.recentUsage') }}
        </div>
        <h2 class="text-[20px] font-medium tracking-[-0.01em]">{{ t('dashboard.last7Days') }}</h2>
      </div>
      <router-link
        to="/usage"
        class="text-[13px] text-muted hover:text-ink underline-offset-4 hover:underline"
      >
        {{ t('dashboard.viewAllUsage') }} →
      </router-link>
    </div>

    <div v-if="loading" class="flex items-center justify-center py-12 px-6">
      <LoadingSpinner size="lg" />
    </div>
    <div v-else-if="data.length === 0" class="py-8 px-6">
      <EmptyState :title="t('dashboard.noUsageRecords')" :description="t('dashboard.startUsingApi')" />
    </div>
    <div v-else class="border-t border-border">
      <!-- Table header -->
      <div class="grid grid-cols-12 px-6 py-3 border-b border-border text-[10px] uppercase tracking-[0.14em] text-subtle font-mono">
        <div class="col-span-5">{{ t('dashboard.model') }}</div>
        <div class="col-span-3">{{ t('common.timestamp', 'when') }}</div>
        <div class="col-span-2 text-right">tokens</div>
        <div class="col-span-2 text-right">cost</div>
      </div>
      <!-- Rows -->
      <div
        v-for="log in data"
        :key="log.id"
        class="grid grid-cols-12 items-center px-6 py-3 border-b border-border last:border-b-0
               transition-colors hover:bg-ink/[0.02]"
      >
        <div class="col-span-5 font-mono text-[13.5px] text-ink truncate" :title="log.model">{{ log.model }}</div>
        <div class="col-span-3 font-mono tabular-nums text-[12.5px] text-muted">{{ formatDateTime(log.created_at) }}</div>
        <div class="col-span-2 text-right font-mono tabular-nums text-[13px] text-muted">
          {{ (log.input_tokens + log.output_tokens).toLocaleString() }}
        </div>
        <div class="col-span-2 text-right font-mono tabular-nums text-[13px]">
          <span class="text-ink">${{ formatCost(log.actual_cost) }}</span>
          <span class="text-subtle ml-1">/ ${{ formatCost(log.total_cost) }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import LoadingSpinner from '@/components/common/LoadingSpinner.vue'
import EmptyState from '@/components/common/EmptyState.vue'
import { formatDateTime } from '@/utils/format'
import type { UsageLog } from '@/types'

defineProps<{
  data: UsageLog[]
  loading: boolean
}>()
const { t } = useI18n()
const formatCost = (c: number) => c.toFixed(4)
</script>
