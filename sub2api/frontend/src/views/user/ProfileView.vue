<template>
  <AppLayout>
    <div class="mx-auto max-w-4xl">
      <!-- Editorial section header -->
      <div class="mb-6">
        <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono mb-2">
          <span class="inline-block w-6 border-t border-subtle align-middle mr-2"></span>
          {{ t('nav.profile') }}
        </div>
        <h1 class="text-[28px] font-light tracking-[-0.015em] text-ink">
          {{ user?.username || user?.email?.split('@')[0] || '—' }}
        </h1>
        <p v-if="user?.email" class="mt-1 text-[13px] text-muted font-mono">{{ user.email }}</p>
      </div>

      <!-- Hero metric strip — hairline-divided, no cards -->
      <div class="border-y border-border grid grid-cols-1 sm:grid-cols-3 sm:divide-x divide-border mb-8">
        <div class="px-5 py-4">
          <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">{{ t('profile.accountBalance') }}</div>
          <div class="mt-1.5 font-display italic font-normal tabular-nums text-[28px] leading-none tracking-[-0.02em] text-ink">
            {{ formatCurrency(user?.balance || 0) }}
          </div>
        </div>
        <div class="px-5 py-4 border-t sm:border-t-0 border-border">
          <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">{{ t('profile.concurrencyLimit') }}</div>
          <div class="mt-1.5 font-mono tabular-nums text-[22px] leading-none text-ink">
            {{ user?.concurrency || 0 }}
          </div>
        </div>
        <div class="px-5 py-4 border-t sm:border-t-0 border-border">
          <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">{{ t('profile.memberSince') }}</div>
          <div class="mt-1.5 font-mono tabular-nums text-[16px] text-ink">
            {{ formatDate(user?.created_at || '', { year: 'numeric', month: 'long' }) }}
          </div>
        </div>
      </div>

      <!-- Contact support strip -->
      <div v-if="contactInfo" class="border border-border rounded-sm p-4 mb-8 flex items-center gap-3">
        <Icon name="chat" size="md" class="text-muted shrink-0" />
        <div class="min-w-0">
          <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono">{{ t('common.contactSupport') }}</div>
          <p class="text-[14px] text-ink mt-0.5 truncate">{{ contactInfo }}</p>
        </div>
      </div>

      <!-- Settings sections — stacked with hairline dividers + editorial labels -->
      <div class="space-y-10">
        <section>
          <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono mb-4 pb-2 border-b border-border">
            <span class="inline-block w-6 border-t border-subtle align-middle mr-2"></span>
            {{ t('profile.account', 'account') }}
          </div>
          <ProfileInfoCard :user="user" />
        </section>

        <section>
          <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono mb-4 pb-2 border-b border-border">
            <span class="inline-block w-6 border-t border-subtle align-middle mr-2"></span>
            {{ t('profile.identity', 'identity') }}
          </div>
          <ProfileEditForm :initial-username="user?.username || ''" />
        </section>

        <section v-if="user && balanceLowNotifyEnabled">
          <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono mb-4 pb-2 border-b border-border">
            <span class="inline-block w-6 border-t border-subtle align-middle mr-2"></span>
            {{ t('profile.notifications', 'notifications') }}
          </div>
          <ProfileBalanceNotifyCard
            :enabled="user.balance_notify_enabled ?? true"
            :threshold="user.balance_notify_threshold"
            :extra-emails="user.balance_notify_extra_emails ?? []"
            :system-default-threshold="systemDefaultThreshold"
            :user-email="user.email"
          />
        </section>

        <section>
          <div class="text-[11px] uppercase tracking-[0.16em] text-subtle font-mono mb-4 pb-2 border-b border-border">
            <span class="inline-block w-6 border-t border-subtle align-middle mr-2"></span>
            {{ t('profile.security', 'security') }}
          </div>
          <div class="space-y-6">
            <ProfilePasswordForm />
            <ProfileTotpCard />
          </div>
        </section>
      </div>
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAuthStore } from '@/stores/auth'
import { formatDate } from '@/utils/format'
import { authAPI } from '@/api'
import AppLayout from '@/components/layout/AppLayout.vue'
import ProfileInfoCard from '@/components/user/profile/ProfileInfoCard.vue'
import ProfileEditForm from '@/components/user/profile/ProfileEditForm.vue'
import ProfileBalanceNotifyCard from '@/components/user/profile/ProfileBalanceNotifyCard.vue'
import ProfilePasswordForm from '@/components/user/profile/ProfilePasswordForm.vue'
import ProfileTotpCard from '@/components/user/profile/ProfileTotpCard.vue'
import { Icon } from '@/components/icons'

const { t } = useI18n()
const authStore = useAuthStore()
const user = computed(() => authStore.user)
const contactInfo = ref('')
const balanceLowNotifyEnabled = ref(false)
const systemDefaultThreshold = ref(0)

onMounted(async () => { try { const s = await authAPI.getPublicSettings(); contactInfo.value = s.contact_info || ''; balanceLowNotifyEnabled.value = s.balance_low_notify_enabled ?? false; systemDefaultThreshold.value = s.balance_low_notify_threshold ?? 0 } catch (error) { console.error('Failed to load settings:', error) } })
const formatCurrency = (v: number) => `$${v.toFixed(2)}`
</script>