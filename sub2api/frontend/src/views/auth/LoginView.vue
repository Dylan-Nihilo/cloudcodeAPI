<template>
  <AuthLayout>
    <!-- Title -->
    <div class="mb-8">
      <h2 class="text-[28px] font-light tracking-[-0.015em] text-ink">
        {{ t('auth.welcomeBack') }}
      </h2>
      <p class="mt-2 text-[14px] text-muted">
        {{ t('auth.signInToAccount') }}
      </p>
    </div>

    <!-- OAuth providers (above the fold if enabled) -->
    <div v-if="!backendModeEnabled && (linuxdoOAuthEnabled || oidcOAuthEnabled)" class="space-y-3 mb-6">
      <LinuxDoOAuthSection v-if="linuxdoOAuthEnabled" :disabled="isLoading" :show-divider="false" />
      <OidcOAuthSection v-if="oidcOAuthEnabled" :disabled="isLoading" :provider-name="oidcOAuthProviderName" :show-divider="false" />
      <div class="flex items-center gap-3 pt-2">
        <div class="h-px flex-1 bg-border"></div>
        <span class="text-[11px] uppercase tracking-[0.14em] text-subtle font-mono">
          {{ t('auth.oauthOrContinue') }}
        </span>
        <div class="h-px flex-1 bg-border"></div>
      </div>
    </div>

    <!-- Login form -->
    <form @submit.prevent="handleLogin" class="space-y-5">

      <!-- Email -->
      <div>
        <label for="email" class="block text-[12px] font-medium uppercase tracking-[0.14em] text-subtle font-mono mb-2">
          {{ t('auth.emailLabel') }}
        </label>
        <div class="relative">
          <Mail :size="14" stroke-width="1.5" class="absolute left-3 top-1/2 -translate-y-1/2 text-subtle pointer-events-none" />
          <input
            id="email"
            v-model="formData.email"
            type="email"
            required
            autofocus
            autocomplete="email"
            :disabled="isLoading"
            :placeholder="t('auth.emailPlaceholder')"
            class="h-10 w-full pl-9 pr-3 text-[14px] rounded-sm
                   bg-paper text-ink placeholder:text-subtle
                   border border-border
                   focus:outline-none focus:border-ink/40 focus:ring-2 focus:ring-ink/15
                   disabled:opacity-50 disabled:cursor-not-allowed
                   transition-[border-color,box-shadow] duration-fast ease-out-soft"
            :class="{ '!border-danger/60 !ring-danger/15': errors.email }"
          />
        </div>
        <p v-if="errors.email" class="mt-1.5 text-[12px] text-danger">{{ errors.email }}</p>
      </div>

      <!-- Password -->
      <div>
        <div class="flex items-baseline justify-between mb-2">
          <label for="password" class="block text-[12px] font-medium uppercase tracking-[0.14em] text-subtle font-mono">
            {{ t('auth.passwordLabel') }}
          </label>
          <router-link
            v-if="passwordResetEnabled && !backendModeEnabled"
            to="/forgot-password"
            class="text-[12px] text-muted hover:text-ink transition-colors underline-offset-4 hover:underline"
          >
            {{ t('auth.forgotPassword') }}
          </router-link>
        </div>
        <div class="relative">
          <Lock :size="14" stroke-width="1.5" class="absolute left-3 top-1/2 -translate-y-1/2 text-subtle pointer-events-none" />
          <input
            id="password"
            v-model="formData.password"
            :type="showPassword ? 'text' : 'password'"
            required
            autocomplete="current-password"
            :disabled="isLoading"
            :placeholder="t('auth.passwordPlaceholder')"
            class="h-10 w-full pl-9 pr-10 text-[14px] rounded-sm
                   bg-paper text-ink placeholder:text-subtle
                   border border-border
                   focus:outline-none focus:border-ink/40 focus:ring-2 focus:ring-ink/15
                   disabled:opacity-50 disabled:cursor-not-allowed
                   transition-[border-color,box-shadow] duration-fast ease-out-soft"
            :class="{ '!border-danger/60 !ring-danger/15': errors.password }"
          />
          <button
            type="button"
            @click="showPassword = !showPassword"
            class="absolute inset-y-0 right-0 flex items-center pr-3 text-subtle hover:text-ink transition-colors"
            :aria-label="showPassword ? t('auth.passwordPlaceholder') : t('auth.passwordPlaceholder')"
          >
            <component :is="showPassword ? EyeOff : Eye" :size="15" stroke-width="1.5" />
          </button>
        </div>
        <p v-if="errors.password" class="mt-1.5 text-[12px] text-danger">{{ errors.password }}</p>
      </div>

      <!-- Turnstile -->
      <div v-if="turnstileEnabled && turnstileSiteKey">
        <TurnstileWidget
          ref="turnstileRef"
          :site-key="turnstileSiteKey"
          @verify="onTurnstileVerify"
          @expire="onTurnstileExpire"
          @error="onTurnstileError"
        />
        <p v-if="errors.turnstile" class="mt-2 text-center text-[12px] text-danger">{{ errors.turnstile }}</p>
      </div>

      <!-- Error message -->
      <transition name="fade">
        <div
          v-if="errorMessage"
          class="border border-danger/30 bg-danger/[0.04] rounded-sm px-3.5 py-3 flex items-start gap-2.5"
        >
          <AlertCircle :size="15" stroke-width="1.5" class="text-danger shrink-0 mt-0.5" />
          <p class="text-[13px] text-danger leading-snug">{{ errorMessage }}</p>
        </div>
      </transition>

      <!-- Submit -->
      <button
        type="submit"
        :disabled="isLoading || (turnstileEnabled && !turnstileToken)"
        class="group w-full inline-flex items-center justify-center gap-2 h-11 px-5
               bg-ink text-paper text-[14px] font-medium rounded-sm
               disabled:opacity-50 disabled:cursor-not-allowed
               transition-all hover:-translate-y-px hover:shadow-medium
               focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ink/30 focus-visible:ring-offset-2 focus-visible:ring-offset-surface"
      >
        <span
          v-if="isLoading"
          class="inline-block w-3 h-3 border-2 border-paper border-t-transparent rounded-sm animate-spin"
        />
        {{ isLoading ? t('auth.signingIn') : t('auth.signIn') }}
        <ArrowUpRight v-if="!isLoading" :size="14" stroke-width="2"
                      class="transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
      </button>
    </form>

    <!-- Footer slot -->
    <template v-if="!backendModeEnabled" #footer>
      <span class="text-muted">{{ t('auth.dontHaveAccount') }}</span>
      <router-link
        to="/register"
        class="ml-1 text-ink hover:underline underline-offset-4"
      >
        {{ t('auth.signUp') }} →
      </router-link>
    </template>
  </AuthLayout>

  <!-- 2FA Modal -->
  <TotpLoginModal
    v-if="show2FAModal"
    ref="totpModalRef"
    :temp-token="totpTempToken"
    :user-email-masked="totpUserEmailMasked"
    @verify="handle2FAVerify"
    @cancel="handle2FACancel"
  />
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { AuthLayout } from '@/components/layout'
import LinuxDoOAuthSection from '@/components/auth/LinuxDoOAuthSection.vue'
import OidcOAuthSection from '@/components/auth/OidcOAuthSection.vue'
import TotpLoginModal from '@/components/auth/TotpLoginModal.vue'
import TurnstileWidget from '@/components/TurnstileWidget.vue'
import { Mail, Lock, Eye, EyeOff, AlertCircle, ArrowUpRight } from 'lucide-vue-next'
import { useAuthStore, useAppStore } from '@/stores'
import { getPublicSettings, isTotp2FARequired } from '@/api/auth'
import type { TotpLoginResponse } from '@/types'

const { t } = useI18n()

// ==================== Router & Stores ====================

const router = useRouter()
const authStore = useAuthStore()
const appStore = useAppStore()

// ==================== State ====================

const isLoading = ref<boolean>(false)
const errorMessage = ref<string>('')
const showPassword = ref<boolean>(false)

// Public settings
const turnstileEnabled = ref<boolean>(false)
const turnstileSiteKey = ref<string>('')
const linuxdoOAuthEnabled = ref<boolean>(false)
const backendModeEnabled = ref<boolean>(false)
const oidcOAuthEnabled = ref<boolean>(false)
const oidcOAuthProviderName = ref<string>('OIDC')
const passwordResetEnabled = ref<boolean>(false)

// Turnstile
const turnstileRef = ref<InstanceType<typeof TurnstileWidget> | null>(null)
const turnstileToken = ref<string>('')

// 2FA state
const show2FAModal = ref<boolean>(false)
const totpTempToken = ref<string>('')
const totpUserEmailMasked = ref<string>('')
const totpModalRef = ref<InstanceType<typeof TotpLoginModal> | null>(null)

const formData = reactive({
  email: '',
  password: ''
})

const errors = reactive({
  email: '',
  password: '',
  turnstile: ''
})

// ==================== Lifecycle ====================

onMounted(async () => {
  const expiredFlag = sessionStorage.getItem('auth_expired')
  if (expiredFlag) {
    sessionStorage.removeItem('auth_expired')
    const message = t('auth.reloginRequired')
    errorMessage.value = message
    appStore.showWarning(message)
  }

  try {
    const settings = await getPublicSettings()
    turnstileEnabled.value = settings.turnstile_enabled
    turnstileSiteKey.value = settings.turnstile_site_key || ''
    linuxdoOAuthEnabled.value = settings.linuxdo_oauth_enabled
    backendModeEnabled.value = settings.backend_mode_enabled
    oidcOAuthEnabled.value = settings.oidc_oauth_enabled
    oidcOAuthProviderName.value = settings.oidc_oauth_provider_name || 'OIDC'
    backendModeEnabled.value = settings.backend_mode_enabled
    passwordResetEnabled.value = settings.password_reset_enabled
  } catch (error) {
    console.error('Failed to load public settings:', error)
  }
})

// ==================== Turnstile Handlers ====================

function onTurnstileVerify(token: string): void {
  turnstileToken.value = token
  errors.turnstile = ''
}

function onTurnstileExpire(): void {
  turnstileToken.value = ''
  errors.turnstile = t('auth.turnstileExpired')
}

function onTurnstileError(): void {
  turnstileToken.value = ''
  errors.turnstile = t('auth.turnstileFailed')
}

// ==================== Validation ====================

function validateForm(): boolean {
  // Reset errors
  errors.email = ''
  errors.password = ''
  errors.turnstile = ''

  let isValid = true

  // Email validation
  if (!formData.email.trim()) {
    errors.email = t('auth.emailRequired')
    isValid = false
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
    errors.email = t('auth.invalidEmail')
    isValid = false
  }

  // Password validation
  if (!formData.password) {
    errors.password = t('auth.passwordRequired')
    isValid = false
  } else if (formData.password.length < 6) {
    errors.password = t('auth.passwordMinLength')
    isValid = false
  }

  // Turnstile validation
  if (turnstileEnabled.value && !turnstileToken.value) {
    errors.turnstile = t('auth.completeVerification')
    isValid = false
  }

  return isValid
}

// ==================== Form Handlers ====================

async function handleLogin(): Promise<void> {
  // Clear previous error
  errorMessage.value = ''

  // Validate form
  if (!validateForm()) {
    return
  }

  isLoading.value = true

  try {
    // Call auth store login
    const response = await authStore.login({
      email: formData.email,
      password: formData.password,
      turnstile_token: turnstileEnabled.value ? turnstileToken.value : undefined
    })

    // Check if 2FA is required
    if (isTotp2FARequired(response)) {
      const totpResponse = response as TotpLoginResponse
      totpTempToken.value = totpResponse.temp_token || ''
      totpUserEmailMasked.value = totpResponse.user_email_masked || ''
      show2FAModal.value = true
      isLoading.value = false
      return
    }

    // Show success toast
    appStore.showSuccess(t('auth.loginSuccess'))

    // Redirect to dashboard or intended route
    const redirectTo = (router.currentRoute.value.query.redirect as string) || '/dashboard'
    await router.push(redirectTo)
  } catch (error: unknown) {
    // Reset Turnstile on error
    if (turnstileRef.value) {
      turnstileRef.value.reset()
      turnstileToken.value = ''
    }

    // Handle login error
    const err = error as { message?: string; response?: { data?: { detail?: string } } }

    if (err.response?.data?.detail) {
      errorMessage.value = err.response.data.detail
    } else if (err.message) {
      errorMessage.value = err.message
    } else {
      errorMessage.value = t('auth.loginFailed')
    }

    // Also show error toast
    appStore.showError(errorMessage.value)
  } finally {
    isLoading.value = false
  }
}

// ==================== 2FA Handlers ====================

async function handle2FAVerify(code: string): Promise<void> {
  if (totpModalRef.value) {
    totpModalRef.value.setVerifying(true)
  }

  try {
    await authStore.login2FA(totpTempToken.value, code)

    // Close modal and show success
    show2FAModal.value = false
    appStore.showSuccess(t('auth.loginSuccess'))

    // Redirect to dashboard or intended route
    const redirectTo = (router.currentRoute.value.query.redirect as string) || '/dashboard'
    await router.push(redirectTo)
  } catch (error: unknown) {
    const err = error as { message?: string; response?: { data?: { message?: string } } }
    const message = err.response?.data?.message || err.message || t('profile.totp.loginFailed')

    if (totpModalRef.value) {
      totpModalRef.value.setError(message)
      totpModalRef.value.setVerifying(false)
    }
  }
}

function handle2FACancel(): void {
  show2FAModal.value = false
  totpTempToken.value = ''
  totpUserEmailMasked.value = ''
}
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: all 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}
</style>
