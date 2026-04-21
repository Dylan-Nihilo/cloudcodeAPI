<template>
  <header class="sticky top-0 z-30 h-14 bg-paper/85 backdrop-blur-sm border-b border-border">
    <div class="flex h-full items-center justify-between px-4 md:px-6">

      <!-- LEFT: mobile menu + breadcrumb -->
      <div class="flex items-center gap-3 min-w-0">
        <button
          @click="toggleMobileSidebar"
          class="lg:hidden p-1.5 -ml-1.5 text-muted hover:text-ink transition-colors"
          aria-label="Toggle menu"
        >
          <Menu :size="18" stroke-width="1.5" />
        </button>

        <nav class="flex items-center gap-2 text-[14px] min-w-0" aria-label="breadcrumb">
          <span class="text-muted hidden sm:inline">workspace</span>
          <ChevronRight :size="13" class="text-subtle hidden sm:inline shrink-0" />
          <span class="text-ink font-medium truncate">{{ pageTitle }}</span>
          <span v-if="pageDescription" class="text-subtle text-[13px] hidden md:inline truncate">· {{ pageDescription }}</span>
        </nav>
      </div>

      <!-- RIGHT: actions -->
      <div class="flex items-center gap-1 shrink-0">

        <!-- Subscription Progress (existing component, unchanged) -->
        <SubscriptionProgressMini v-if="user" />

        <!-- Balance pill — ghost-bordered, no teal -->
        <div
          v-if="user"
          class="hidden sm:flex items-center gap-1.5 h-8 px-2.5 mr-1
                 border border-border rounded-sm font-mono tabular-nums text-[13px]"
        >
          <span class="text-subtle">$</span>
          <span class="text-ink">{{ user.balance?.toFixed(2) || '0.00' }}</span>
        </div>

        <!-- Announcement Bell (existing component) -->
        <AnnouncementBell v-if="user" />

        <!-- Docs Link -->
        <a
          v-if="docUrl"
          :href="docUrl"
          target="_blank"
          rel="noopener noreferrer"
          :title="t('nav.docs')"
          class="hidden sm:inline-flex items-center justify-center p-1.5 text-muted hover:text-ink transition-colors"
        >
          <BookOpen :size="15" stroke-width="1.5" />
        </a>

        <!-- Language Switcher (existing component) -->
        <LocaleSwitcher />

        <!-- Theme toggle -->
        <button
          @click="toggle()"
          :title="isDark ? 'Light mode' : 'Dark mode'"
          class="p-1.5 text-muted hover:text-ink transition-colors"
        >
          <component :is="isDark ? Sun : Moon" :size="15" stroke-width="1.5" />
        </button>

        <!-- User Dropdown -->
        <div v-if="user" class="relative ml-1" ref="dropdownRef">
          <button
            @click="toggleDropdown"
            class="flex items-center gap-2 h-8 pl-1 pr-2 rounded-sm hover:bg-ink/[0.04] transition-colors"
            aria-label="User menu"
          >
            <span class="w-6 h-6 rounded-sm bg-ink text-paper text-[11px] font-semibold flex items-center justify-center">
              {{ userInitials }}
            </span>
            <span class="hidden md:inline text-[13px] text-ink">{{ displayName }}</span>
            <ChevronDown :size="13" class="hidden md:inline text-subtle" />
          </button>

          <!-- Dropdown -->
          <transition name="dropdown">
            <div
              v-if="dropdownOpen"
              class="absolute right-0 top-[calc(100%+6px)] w-64 bg-surface border border-border rounded-md shadow-medium overflow-hidden"
            >
              <!-- Identity -->
              <div class="px-4 py-3 border-b border-border">
                <div class="text-[13.5px] font-medium text-ink truncate">{{ displayName }}</div>
                <div class="text-[12px] text-muted truncate mt-0.5">{{ user.email }}</div>
                <div class="mt-2 flex items-center gap-2 text-[10px] uppercase tracking-[0.16em] font-mono text-subtle">
                  <span>{{ user.role }}</span>
                  <span class="sm:hidden ml-auto text-ink">${{ user.balance?.toFixed(2) || '0.00' }}</span>
                </div>
              </div>

              <!-- Nav items -->
              <div class="py-1.5">
                <router-link
                  to="/profile"
                  @click="closeDropdown"
                  class="dropdown-row"
                >
                  <User :size="14" stroke-width="1.5" />
                  <span>{{ t('nav.profile') }}</span>
                </router-link>
                <router-link
                  to="/keys"
                  @click="closeDropdown"
                  class="dropdown-row"
                >
                  <KeyRound :size="14" stroke-width="1.5" />
                  <span>{{ t('nav.apiKeys') }}</span>
                </router-link>
                <a
                  v-if="authStore.isAdmin"
                  href="https://github.com/Wei-Shaw/sub2api"
                  target="_blank"
                  rel="noopener noreferrer"
                  @click="closeDropdown"
                  class="dropdown-row"
                >
                  <Github :size="14" stroke-width="1.5" />
                  <span>{{ t('nav.github') }}</span>
                </a>
              </div>

              <!-- Contact support -->
              <div
                v-if="contactInfo"
                class="px-4 py-2.5 border-t border-border flex items-center gap-2 text-[12px] text-subtle"
              >
                <MessageCircle :size="13" stroke-width="1.5" class="shrink-0" />
                <span>{{ t('common.contactSupport') }}:</span>
                <span class="text-muted truncate">{{ contactInfo }}</span>
              </div>

              <!-- Onboarding replay -->
              <div v-if="showOnboardingButton" class="border-t border-border py-1.5">
                <button @click="handleReplayGuide" class="dropdown-row w-full">
                  <HelpCircle :size="14" stroke-width="1.5" />
                  <span>{{ $t('onboarding.restartTour') }}</span>
                </button>
              </div>

              <!-- Logout -->
              <div class="border-t border-border py-1.5">
                <button @click="handleLogout" class="dropdown-row w-full text-danger hover:bg-danger/[0.06]">
                  <LogOut :size="14" stroke-width="1.5" />
                  <span>{{ t('nav.logout') }}</span>
                </button>
              </div>
            </div>
          </transition>
        </div>
      </div>
    </div>
  </header>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useAppStore, useAuthStore, useOnboardingStore } from '@/stores'
import { useAdminSettingsStore } from '@/stores/adminSettings'
import LocaleSwitcher from '@/components/common/LocaleSwitcher.vue'
import SubscriptionProgressMini from '@/components/common/SubscriptionProgressMini.vue'
import AnnouncementBell from '@/components/common/AnnouncementBell.vue'
import { useDarkMode } from '@/design/composables/useDarkMode'
import {
  Menu, ChevronRight, ChevronDown, BookOpen, Moon, Sun,
  User, KeyRound, Github, MessageCircle, HelpCircle, LogOut,
} from 'lucide-vue-next'

const router = useRouter()
const route = useRoute()
const { t } = useI18n()
const appStore = useAppStore()
const authStore = useAuthStore()
const adminSettingsStore = useAdminSettingsStore()
const onboardingStore = useOnboardingStore()
const { isDark, toggle } = useDarkMode()

const user = computed(() => authStore.user)
const dropdownOpen = ref(false)
const dropdownRef = ref<HTMLElement | null>(null)
const contactInfo = computed(() => appStore.contactInfo)
const docUrl = computed(() => appStore.docUrl)

// 只在标准模式的管理员下显示新手引导按钮
const showOnboardingButton = computed(() => {
  return !authStore.isSimpleMode && user.value?.role === 'admin'
})

const userInitials = computed(() => {
  if (!user.value) return ''
  if (user.value.username) {
    return user.value.username.substring(0, 2).toUpperCase()
  }
  if (user.value.email) {
    const localPart = user.value.email.split('@')[0]
    return localPart.substring(0, 2).toUpperCase()
  }
  return ''
})

const displayName = computed(() => {
  if (!user.value) return ''
  return user.value.username || user.value.email?.split('@')[0] || ''
})

const pageTitle = computed(() => {
  if (route.name === 'CustomPage') {
    const id = route.params.id as string
    const publicItems = appStore.cachedPublicSettings?.custom_menu_items ?? []
    const menuItem = publicItems.find((item) => item.id === id)
      ?? (authStore.isAdmin ? adminSettingsStore.customMenuItems.find((item) => item.id === id) : undefined)
    if (menuItem?.label) return menuItem.label
  }
  const titleKey = route.meta.titleKey as string
  if (titleKey) {
    return t(titleKey)
  }
  return (route.meta.title as string) || ''
})

const pageDescription = computed(() => {
  const descKey = route.meta.descriptionKey as string
  if (descKey) {
    return t(descKey)
  }
  return (route.meta.description as string) || ''
})

function toggleMobileSidebar() {
  appStore.toggleMobileSidebar()
}

function toggleDropdown() {
  dropdownOpen.value = !dropdownOpen.value
}

function closeDropdown() {
  dropdownOpen.value = false
}

async function handleLogout() {
  closeDropdown()
  try {
    await authStore.logout()
  } catch (error) {
    console.error('Logout error:', error)
  }
  await router.push('/login')
}

function handleReplayGuide() {
  closeDropdown()
  onboardingStore.replay()
}

function handleClickOutside(event: MouseEvent) {
  if (dropdownRef.value && !dropdownRef.value.contains(event.target as Node)) {
    closeDropdown()
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>

<style scoped>
.dropdown-row {
  @apply flex items-center gap-2.5 px-4 py-2 text-[13.5px] text-ink hover:bg-ink/5 transition-colors;
}

.dropdown-enter-active,
.dropdown-leave-active {
  transition: opacity 180ms ease, transform 180ms cubic-bezier(0.16, 1, 0.3, 1);
}
.dropdown-enter-from,
.dropdown-leave-to {
  opacity: 0;
  transform: translateY(-4px);
}
</style>
