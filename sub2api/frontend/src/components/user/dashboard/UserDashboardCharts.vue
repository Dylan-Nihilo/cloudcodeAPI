<template>
  <div class="space-y-0">
    <!-- ─── Filter strip — sits on top of section without its own card ─── -->
    <div class="px-6 py-3 border-b border-border flex flex-wrap items-center gap-4">
      <div class="flex items-center gap-2">
        <span class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">{{ t('dashboard.timeRange') }}</span>
        <DateRangePicker
          :start-date="startDate"
          :end-date="endDate"
          @update:startDate="$emit('update:startDate', $event)"
          @update:endDate="$emit('update:endDate', $event)"
          @change="$emit('dateRangeChange', $event)"
        />
      </div>
      <button @click="$emit('refresh')" :disabled="loading" class="btn btn-ghost btn-sm">
        {{ t('common.refresh') }}
      </button>
      <div class="ml-auto flex items-center gap-2">
        <span class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">{{ t('dashboard.granularity') }}</span>
        <div class="w-24">
          <Select
            :model-value="granularity"
            :options="[{value:'day', label:t('dashboard.day')}, {value:'hour', label:t('dashboard.hour')}]"
            @update:model-value="$emit('update:granularity', $event)"
            @change="$emit('granularityChange')"
          />
        </div>
      </div>
    </div>

    <!-- ─── Two-column charts grid ─── -->
    <div class="grid grid-cols-1 lg:grid-cols-2 divide-x divide-border border-b border-border">

      <!-- Model distribution -->
      <div class="p-6 relative">
        <div v-if="loading" class="absolute inset-0 z-10 flex items-center justify-center bg-paper/60 backdrop-blur-sm">
          <LoadingSpinner size="md" />
        </div>
        <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono mb-4">
          <span class="inline-block w-6 border-t border-subtle align-middle mr-2"></span>
          {{ t('dashboard.modelDistribution') }}
        </div>
        <div class="flex items-center gap-6">
          <div class="h-44 w-44 shrink-0">
            <Doughnut v-if="modelData" :data="modelData" :options="doughnutOptions" />
            <div v-else class="flex h-full items-center justify-center text-[12px] text-subtle font-mono">
              {{ t('dashboard.noDataAvailable') }}
            </div>
          </div>
          <div class="max-h-44 flex-1 min-w-0 overflow-y-auto">
            <table class="w-full text-[12px] font-mono">
              <thead>
                <tr class="text-[10px] uppercase tracking-[0.14em] text-subtle border-b border-border">
                  <th class="pb-2 text-left font-normal">{{ t('dashboard.model') }}</th>
                  <th class="pb-2 text-right font-normal">{{ t('dashboard.requests') }}</th>
                  <th class="pb-2 text-right font-normal">{{ t('dashboard.tokens') }}</th>
                  <th class="pb-2 text-right font-normal">{{ t('dashboard.actual') }}</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="model in models" :key="model.model" class="border-b border-border last:border-b-0">
                  <td class="max-w-[110px] truncate py-2 text-ink" :title="model.model">{{ model.model }}</td>
                  <td class="py-2 text-right text-muted tabular-nums">{{ formatNumber(model.requests) }}</td>
                  <td class="py-2 text-right text-muted tabular-nums">{{ formatTokens(model.total_tokens) }}</td>
                  <td class="py-2 text-right text-ink tabular-nums">${{ formatCost(model.actual_cost) }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Token usage trend (existing chart, restyled by its own component) -->
      <div class="p-6">
        <TokenUsageTrend :trend-data="trend" :loading="loading" />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import LoadingSpinner from '@/components/common/LoadingSpinner.vue'
import DateRangePicker from '@/components/common/DateRangePicker.vue'
import Select from '@/components/common/Select.vue'
import { Doughnut } from 'vue-chartjs'
import TokenUsageTrend from '@/components/charts/TokenUsageTrend.vue'
import type { TrendDataPoint, ModelStat } from '@/types'
import { formatCostFixed as formatCost, formatNumberLocaleString as formatNumber, formatTokensK as formatTokens } from '@/utils/format'
import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, ArcElement, Title, Tooltip, Legend, Filler } from 'chart.js'
ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, ArcElement, Title, Tooltip, Legend, Filler)

const props = defineProps<{ loading: boolean; startDate: string; endDate: string; granularity: string; trend: TrendDataPoint[]; models: ModelStat[] }>()
defineEmits(['update:startDate', 'update:endDate', 'update:granularity', 'dateRangeChange', 'granularityChange', 'refresh'])
const { t } = useI18n()

// Monochrome ramp — black at the top, fading to subtle gray
// Consistent with the editorial aesthetic, no rainbow palette
const monochromeColors = [
  '#0A0A0A',  // ink
  '#27272A',
  '#3F3F46',
  '#52525B',
  '#71717A',
  '#A1A1AA',
  '#D4D4D8',
  '#E4E4E7',
]

const modelData = computed(() => !props.models?.length ? null : {
  labels: props.models.map((m: ModelStat) => m.model),
  datasets: [{
    data: props.models.map((m: ModelStat) => m.total_tokens),
    backgroundColor: monochromeColors,
    borderColor: '#FAFAFA',
    borderWidth: 2,
  }],
})

const doughnutOptions = {
  responsive: true,
  maintainAspectRatio: false,
  cutout: '68%',
  plugins: {
    legend: { display: false },
    tooltip: {
      backgroundColor: '#0A0A0A',
      titleColor: '#FAFAFA',
      bodyColor: '#A1A1AA',
      titleFont: { family: 'JetBrains Mono, monospace', size: 11 },
      bodyFont: { family: 'JetBrains Mono, monospace', size: 11 },
      padding: 10,
      borderColor: '#27272A',
      borderWidth: 1,
      callbacks: {
        label: (context: any) => `${context.label}: ${formatTokens(context.parsed)} tokens`,
      },
    },
  },
}
</script>
