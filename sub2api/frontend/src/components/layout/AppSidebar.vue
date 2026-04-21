<template>
  <!-- Mobile overlay -->
  <transition name="fade">
    <div
      v-if="mobileOpen"
      class="fixed inset-0 z-30 bg-ink/40 backdrop-blur-sm lg:hidden"
      @click="closeMobile"
    ></div>
  </transition>

  <aside
    class="fixed top-0 inset-y-0 left-0 z-40
           bg-paper border-r border-border
           flex flex-col h-screen
           transition-[width,transform] duration-200 ease-out
           lg:translate-x-0"
    :class="[
      sidebarCollapsed ? 'w-[72px]' : 'w-[240px]',
      mobileOpen ? 'translate-x-0' : '-translate-x-full',
    ]"
  >
    <!-- ─── Wordmark / brand ─────────────────────────────────────── -->
    <div class="h-14 border-b border-border flex items-center px-5 shrink-0">
      <router-link to="/" class="flex items-center gap-2 min-w-0">
        <img
          v-if="siteLogo && settingsLoaded"
          :src="siteLogo"
          :alt="brandName"
          class="h-6 w-6 object-contain shrink-0"
        />
        <div v-if="!sidebarCollapsed" class="flex items-baseline gap-1 truncate">
          <span class="font-display italic text-[20px] leading-none">{{ brandHead }}</span>
          <span class="font-sans font-medium text-[14px] leading-none">{{ brandTail }}</span>
        </div>
      </router-link>
    </div>

    <!-- ─── Workspace pill (collapsed-aware) ─────────────────────── -->
    <div v-if="!sidebarCollapsed" class="px-3 pt-3 shrink-0">
      <div class="px-3 py-2.5 flex items-center justify-between border border-border rounded-sm">
        <div class="flex items-center gap-2.5 min-w-0">
          <div class="w-6 h-6 rounded-sm bg-ink text-paper text-[11px] font-semibold flex items-center justify-center shrink-0">
            C
          </div>
          <div class="min-w-0">
            <div class="text-[13px] font-medium leading-none truncate">{{ brandName }}</div>
            <div class="text-[11px] text-subtle uppercase tracking-[0.14em] font-mono mt-1 truncate">
              {{ isAdmin ? 'admin · v' : 'v' }}{{ siteVersion || '0.1' }}
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ─── Navigation ───────────────────────────────────────────── -->
    <nav class="flex-1 min-h-0 overflow-y-auto px-3 pt-5 pb-4">
      <!-- Admin: admin section + personal section -->
      <template v-if="isAdmin">
        <SectionHeader v-if="!sidebarCollapsed" :label="t('nav.workspace', 'workspace')" />
        <div class="space-y-0.5">
          <template v-for="item in adminNavItems" :key="item.path">
            <!-- Group with children (e.g. orders) -->
            <template v-if="item.children?.length">
              <button
                type="button"
                class="nav-item w-full"
                :class="{ 'nav-item-active': isGroupActive(item) && !isGroupExpanded(item) }"
                :title="sidebarCollapsed ? item.label : undefined"
                @click="sidebarCollapsed ? undefined : toggleGroup(item)"
              >
                <NavIcon :icon="item.icon" />
                <span v-if="!sidebarCollapsed" class="flex-1 truncate text-left">{{ item.label }}</span>
                <ChevronDown
                  v-if="!sidebarCollapsed"
                  :size="13"
                  stroke-width="1.5"
                  class="shrink-0 transition-transform duration-200"
                  :class="isGroupExpanded(item) ? 'rotate-180' : ''"
                />
              </button>
              <div
                v-if="!sidebarCollapsed && isGroupExpanded(item)"
                class="ml-3 mt-0.5 mb-1 pl-3 border-l border-border space-y-0.5"
              >
                <router-link
                  v-for="child in item.children"
                  :key="child.path"
                  :to="child.path"
                  class="nav-item nav-item-sm"
                  :class="{ 'nav-item-active': route.path === child.path }"
                  @click="handleMenuItemClick(child.path)"
                >
                  <NavIcon :icon="child.icon" :size="13" />
                  <span class="truncate">{{ child.label }}</span>
                </router-link>
              </div>
            </template>
            <!-- Normal item -->
            <router-link
              v-else
              :to="item.path"
              class="nav-item"
              :class="{ 'nav-item-active': isActive(item.path) }"
              :title="sidebarCollapsed ? item.label : undefined"
              :id="navItemId(item.path)"
              @click="handleMenuItemClick(item.path)"
            >
              <span
                v-if="item.iconSvg"
                class="shrink-0 w-[15px] h-[15px] sidebar-svg-icon"
                v-html="sanitizeSvg(item.iconSvg)"
              ></span>
              <NavIcon v-else :icon="item.icon" />
              <span v-if="!sidebarCollapsed" class="truncate flex-1">{{ item.label }}</span>
            </router-link>
          </template>
        </div>

        <!-- Personal section (hidden in simple mode) -->
        <template v-if="!authStore.isSimpleMode">
          <SectionHeader v-if="!sidebarCollapsed" :label="t('nav.myAccount')" class="mt-7" />
          <div class="space-y-0.5">
            <router-link
              v-for="item in personalNavItems"
              :key="item.path"
              :to="item.path"
              class="nav-item"
              :class="{ 'nav-item-active': isActive(item.path) }"
              :title="sidebarCollapsed ? item.label : undefined"
              :data-tour="item.path === '/keys' ? 'sidebar-my-keys' : undefined"
              @click="handleMenuItemClick(item.path)"
            >
              <span
                v-if="item.iconSvg"
                class="shrink-0 w-[15px] h-[15px] sidebar-svg-icon"
                v-html="sanitizeSvg(item.iconSvg)"
              ></span>
              <NavIcon v-else :icon="item.icon" />
              <span v-if="!sidebarCollapsed" class="truncate flex-1">{{ item.label }}</span>
            </router-link>
          </div>
        </template>
      </template>

      <!-- Regular user view -->
      <template v-else-if="!appStore.backendModeEnabled">
        <div class="space-y-0.5">
          <router-link
            v-for="item in userNavItems"
            :key="item.path"
            :to="item.path"
            class="nav-item"
            :class="{ 'nav-item-active': isActive(item.path) }"
            :title="sidebarCollapsed ? item.label : undefined"
            :data-tour="item.path === '/keys' ? 'sidebar-my-keys' : undefined"
            @click="handleMenuItemClick(item.path)"
          >
            <span
              v-if="item.iconSvg"
              class="shrink-0 w-[15px] h-[15px] sidebar-svg-icon"
              v-html="sanitizeSvg(item.iconSvg)"
            ></span>
            <NavIcon v-else :icon="item.icon" />
            <span v-if="!sidebarCollapsed" class="truncate flex-1">{{ item.label }}</span>
          </router-link>
        </div>
      </template>
    </nav>

    <!-- ─── Footer: collapse toggle ──────────────────────────────── -->
    <div class="border-t border-border p-3 shrink-0">
      <button
        @click="toggleSidebar"
        class="nav-item w-full"
        :title="sidebarCollapsed ? t('nav.expand') : t('nav.collapse')"
      >
        <component :is="sidebarCollapsed ? PanelLeftOpen : PanelLeftClose" :size="15" stroke-width="1.5" class="shrink-0" />
        <span v-if="!sidebarCollapsed" class="truncate flex-1 text-left">{{ t('nav.collapse') }}</span>
      </button>
    </div>
  </aside>
</template>

<script setup lang="ts">
import { computed, h, onMounted, ref, watch, type FunctionalComponent } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useAdminSettingsStore, useAppStore, useAuthStore, useOnboardingStore } from '@/stores'
import { sanitizeSvg } from '@/utils/sanitize'
import {
  LayoutGrid, KeyRound, BarChart3, Gift, User, Users, Folder,
  Network, CreditCard, Globe, Server, Bell, Ticket, Settings,
  ShoppingCart, Receipt, Activity, ChevronDown,
  PanelLeftClose, PanelLeftOpen, type LucideIcon,
} from 'lucide-vue-next'

interface NavItem {
  path: string
  label: string
  icon: LucideIcon | FunctionalComponent | null
  iconSvg?: string
  hideInSimpleMode?: boolean
  children?: NavItem[]
}

const { t } = useI18n()
const route = useRoute()
const appStore = useAppStore()
const authStore = useAuthStore()
const onboardingStore = useOnboardingStore()
const adminSettingsStore = useAdminSettingsStore()

const sidebarCollapsed = computed(() => appStore.sidebarCollapsed)
const mobileOpen = computed(() => appStore.mobileOpen)
const isAdmin = computed(() => authStore.isAdmin)
const expandedGroups = ref<Set<string>>(new Set())

const siteLogo = computed(() => appStore.siteLogo)
const siteVersion = computed(() => appStore.siteVersion)
const settingsLoaded = computed(() => appStore.publicSettingsLoaded)

// ─── Brand identity ──────────────────────────────────────────────────
// Same constants as HomeView. Brand display is decoupled from siteName.
const brandName = 'CloudCodeAPI'
const brandHead = 'CloudCode'
const brandTail = 'API'

// ─── Tiny render-component for a nav-item icon ───────────────────────
// Takes either a LucideIcon component or a FunctionalComponent (legacy).
const NavIcon: FunctionalComponent<{ icon: any; size?: number }> = (props) => {
  if (!props.icon) return null
  return h(props.icon, { size: props.size ?? 15, strokeWidth: 1.5, class: 'shrink-0' })
}
NavIcon.props = ['icon', 'size']

// ─── Section header (small mono uppercase label) ─────────────────────
const SectionHeader: FunctionalComponent<{ label: string }> = (props) =>
  h(
    'div',
    {
      class: 'text-[11px] uppercase tracking-[0.16em] text-subtle font-mono px-3 mb-2 mt-2',
    },
    props.label,
  )
SectionHeader.props = ['label']

// ─── Custom menu items (admin-defined sidebar links) ─────────────────
const customMenuItemsForUser = computed(() => {
  const items = appStore.cachedPublicSettings?.custom_menu_items ?? []
  return items
    .filter((item) => item.visibility === 'user')
    .sort((a, b) => a.sort_order - b.sort_order)
})

const customMenuItemsForAdmin = computed(() =>
  adminSettingsStore.customMenuItems
    .filter((item) => item.visibility === 'admin')
    .sort((a, b) => a.sort_order - b.sort_order),
)

// ─── User nav items ──────────────────────────────────────────────────
const userNavItems = computed((): NavItem[] => {
  const items: NavItem[] = [
    { path: '/dashboard', label: t('nav.dashboard'), icon: LayoutGrid },
    { path: '/keys', label: t('nav.apiKeys'), icon: KeyRound },
    { path: '/usage', label: t('nav.usage'), icon: BarChart3, hideInSimpleMode: true },
    { path: '/subscriptions', label: t('nav.mySubscriptions'), icon: CreditCard, hideInSimpleMode: true },
    ...(appStore.cachedPublicSettings?.payment_enabled
      ? [{ path: '/purchase', label: t('nav.buySubscription'), icon: ShoppingCart, hideInSimpleMode: true }]
      : []),
    ...(appStore.cachedPublicSettings?.payment_enabled
      ? [{ path: '/orders', label: t('nav.myOrders'), icon: Receipt, hideInSimpleMode: true }]
      : []),
    { path: '/redeem', label: t('nav.redeem'), icon: Gift, hideInSimpleMode: true },
    { path: '/profile', label: t('nav.profile'), icon: User },
    ...customMenuItemsForUser.value.map(
      (item): NavItem => ({ path: `/custom/${item.id}`, label: item.label, icon: null, iconSvg: item.icon_svg }),
    ),
  ]
  return authStore.isSimpleMode ? items.filter((item) => !item.hideInSimpleMode) : items
})

// Personal nav items (for admin's "My Account" section, without Dashboard)
const personalNavItems = computed((): NavItem[] => {
  const items: NavItem[] = [
    { path: '/keys', label: t('nav.apiKeys'), icon: KeyRound },
    { path: '/usage', label: t('nav.usage'), icon: BarChart3, hideInSimpleMode: true },
    { path: '/subscriptions', label: t('nav.mySubscriptions'), icon: CreditCard, hideInSimpleMode: true },
    ...(appStore.cachedPublicSettings?.payment_enabled
      ? [{ path: '/purchase', label: t('nav.buySubscription'), icon: ShoppingCart, hideInSimpleMode: true }]
      : []),
    ...(appStore.cachedPublicSettings?.payment_enabled
      ? [{ path: '/orders', label: t('nav.myOrders'), icon: Receipt, hideInSimpleMode: true }]
      : []),
    { path: '/redeem', label: t('nav.redeem'), icon: Gift, hideInSimpleMode: true },
    { path: '/profile', label: t('nav.profile'), icon: User },
    ...customMenuItemsForUser.value.map(
      (item): NavItem => ({ path: `/custom/${item.id}`, label: item.label, icon: null, iconSvg: item.icon_svg }),
    ),
  ]
  return authStore.isSimpleMode ? items.filter((item) => !item.hideInSimpleMode) : items
})

// ─── Admin nav items ─────────────────────────────────────────────────
const adminNavItems = computed((): NavItem[] => {
  const baseItems: NavItem[] = [
    { path: '/admin/dashboard', label: t('nav.dashboard'), icon: LayoutGrid },
    ...(adminSettingsStore.opsMonitoringEnabled
      ? [{ path: '/admin/ops', label: t('nav.ops'), icon: Activity }]
      : []),
    { path: '/admin/users', label: t('nav.users'), icon: Users, hideInSimpleMode: true },
    { path: '/admin/groups', label: t('nav.groups'), icon: Folder, hideInSimpleMode: true },
    { path: '/admin/channels', label: t('nav.channels', '渠道管理'), icon: Network, hideInSimpleMode: true },
    { path: '/admin/subscriptions', label: t('nav.subscriptions'), icon: CreditCard, hideInSimpleMode: true },
    { path: '/admin/accounts', label: t('nav.accounts'), icon: Globe },
    { path: '/admin/announcements', label: t('nav.announcements'), icon: Bell },
    { path: '/admin/proxies', label: t('nav.proxies'), icon: Server },
    { path: '/admin/redeem', label: t('nav.redeemCodes'), icon: Ticket, hideInSimpleMode: true },
    { path: '/admin/promo-codes', label: t('nav.promoCodes'), icon: Gift, hideInSimpleMode: true },
    ...(adminSettingsStore.paymentEnabled
      ? [
          {
            path: '/admin/orders',
            label: t('nav.orderManagement'),
            icon: ShoppingCart,
            hideInSimpleMode: true,
            children: [
              { path: '/admin/orders/dashboard', label: t('nav.paymentDashboard'), icon: BarChart3 },
              { path: '/admin/orders', label: t('nav.orderManagement'), icon: ShoppingCart },
              { path: '/admin/orders/plans', label: t('nav.paymentPlans'), icon: CreditCard },
            ],
          },
        ]
      : []),
    { path: '/admin/usage', label: t('nav.usage'), icon: BarChart3 },
  ]

  if (authStore.isSimpleMode) {
    const filtered = baseItems.filter((item) => !item.hideInSimpleMode)
    filtered.push({ path: '/keys', label: t('nav.apiKeys'), icon: KeyRound })
    filtered.push({ path: '/admin/settings', label: t('nav.settings'), icon: Settings })
    for (const cm of customMenuItemsForAdmin.value) {
      filtered.push({ path: `/custom/${cm.id}`, label: cm.label, icon: null, iconSvg: cm.icon_svg })
    }
    return filtered
  }

  baseItems.push({ path: '/admin/settings', label: t('nav.settings'), icon: Settings })
  for (const cm of customMenuItemsForAdmin.value) {
    baseItems.push({ path: `/custom/${cm.id}`, label: cm.label, icon: null, iconSvg: cm.icon_svg })
  }
  return baseItems
})

// ─── Helpers ─────────────────────────────────────────────────────────
function toggleSidebar() {
  appStore.toggleSidebar()
}
function closeMobile() {
  appStore.setMobileOpen(false)
}
function handleMenuItemClick(itemPath: string) {
  if (mobileOpen.value) {
    setTimeout(() => appStore.setMobileOpen(false), 150)
  }
  const pathToSelector: Record<string, string> = {
    '/admin/groups': '#sidebar-group-manage',
    '/admin/accounts': '#sidebar-channel-manage',
    '/keys': '[data-tour="sidebar-my-keys"]',
  }
  const selector = pathToSelector[itemPath]
  if (selector && onboardingStore.isCurrentStep(selector)) {
    onboardingStore.nextStep(500)
  }
}
function navItemId(path: string): string | undefined {
  return path === '/admin/accounts'
    ? 'sidebar-channel-manage'
    : path === '/admin/groups'
      ? 'sidebar-group-manage'
      : path === '/admin/redeem'
        ? 'sidebar-wallet'
        : undefined
}
function isActive(path: string): boolean {
  return route.path === path || route.path.startsWith(path + '/')
}
function isGroupActive(item: NavItem): boolean {
  if (!item.children) return false
  return item.children.some((child) => route.path === child.path)
}
function isGroupExpanded(item: NavItem): boolean {
  return expandedGroups.value.has(item.path) || isGroupActive(item)
}
function toggleGroup(item: NavItem) {
  if (expandedGroups.value.has(item.path)) {
    expandedGroups.value.delete(item.path)
  } else {
    expandedGroups.value.add(item.path)
  }
}

// Fetch admin settings (for feature-gated nav items like Ops).
watch(
  isAdmin,
  (v) => {
    if (v) adminSettingsStore.fetch()
  },
  { immediate: true },
)

onMounted(() => {
  if (isAdmin.value) adminSettingsStore.fetch()
})
</script>

<style scoped>
/* Each nav-item is a single design unit so we can keep ink-active
   inversion + hover tone consistent across template branches. */
.nav-item {
  @apply flex items-center gap-2.5 px-3 py-2 rounded-sm text-[14px] text-muted
         transition-colors duration-fast ease-out-soft
         hover:text-ink hover:bg-ink/5;
}
.nav-item-sm {
  @apply text-[13px] py-1.5;
}
.nav-item-active {
  @apply bg-ink text-paper hover:bg-ink hover:text-paper;
}

/* Custom admin-uploaded SVG icons render with currentColor so they
   inherit the active/hover tint instead of being baked-in colored. */
.sidebar-svg-icon {
  color: currentColor;
}
.sidebar-svg-icon :deep(svg) {
  display: block;
  width: 100%;
  height: 100%;
}

/* Mobile overlay fade */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 200ms ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
