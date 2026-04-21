<template>
  <div class="border border-border rounded-sm">
    <div class="px-5 py-4 border-b border-border">
      <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">
        <span class="inline-block w-6 border-t border-subtle align-middle mr-2"></span>
        {{ t('dashboard.quickActions') }}
      </div>
    </div>

    <div class="divide-y divide-border">
      <button
        v-for="action in actions"
        :key="action.path"
        @click="router.push(action.path)"
        class="group w-full flex items-center justify-between px-5 py-4 text-left transition-colors hover:bg-ink/[0.02]"
      >
        <div class="flex items-start gap-3 min-w-0">
          <component :is="action.icon" :size="16" stroke-width="1.5"
                     class="shrink-0 text-muted mt-0.5 group-hover:text-ink transition-colors" />
          <div class="min-w-0 flex-1">
            <p class="text-[14px] font-medium text-ink truncate">{{ action.title }}</p>
            <p class="text-[12.5px] text-muted mt-0.5 truncate">{{ action.subtitle }}</p>
          </div>
        </div>
        <ArrowUpRight :size="14" stroke-width="1.5"
                      class="shrink-0 ml-3 text-subtle transition-transform duration-fast ease-out-soft
                             group-hover:text-ink group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { KeyRound, BarChart3, Gift, ArrowUpRight } from 'lucide-vue-next'

const router = useRouter()
const { t } = useI18n()

const actions = computed(() => [
  { path: '/keys',   icon: KeyRound,  title: t('dashboard.createApiKey'), subtitle: t('dashboard.generateNewKey') },
  { path: '/usage',  icon: BarChart3, title: t('dashboard.viewUsage'),    subtitle: t('dashboard.checkDetailedLogs') },
  { path: '/redeem', icon: Gift,      title: t('dashboard.redeemCode'),   subtitle: t('dashboard.addBalanceWithCode') },
])
</script>
