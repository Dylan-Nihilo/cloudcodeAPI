<template>
  <AuthLayout>
    <div class="space-y-6">
      <!-- Title -->
      <div class="mb-8">
        <h2 class="text-[28px] font-light tracking-[-0.015em] text-ink">
          {{ t('auth.forgotPasswordTitle') }}
        </h2>
        <p class="mt-2 text-[14px] text-muted">
          {{ t('auth.forgotPasswordHint') }}
        </p>
      </div>

      <!-- Success State -->
      <div v-if="isSubmitted" class="space-y-6">
        <div class="rounded-sm border border-success/30 bg-success/[0.06] p-5">
          <div class="flex flex-col items-center gap-4 text-center">
            <div class="w-1.5 h-1.5 rounded-full bg-success"></div>
            <div>
              <h3 class="text-[16px] font-medium text-ink">
                {{ t('auth.resetEmailSent') }}
              </h3>
              <p class="mt-2 text-[13px] text-muted">
                {{ t('auth.resetEmailSentHint') }}
              </p>
            </div>
          </div>
        </div>

        <div class="text-center">
          <router-link
            to="/login"
            class="inline-flex items-center gap-2 text-[14px] text-ink hover:underline underline-offset-4"
          >
            ← {{ t('auth.backToLogin') }}
          </router-link>
        </div>
      </div>

      <!-- Form State -->
      <form v-else @submit.prevent="handleSubmit" class="space-y-5">
        <!-- Email Input -->
        <div>
          <label for="email" class="input-label">
            {{ t('auth.emailLabel') }}
          </label>
          <div class="relative">
            <div class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3.5">
              <Icon name="mail" size="md" class="text-subtle" />
            </div>
            <input
              id="email"
              v-model="formData.email"
              type="email"
              required
              autofocus
              autocomplete="email"
              :disabled="isLoading"
              class="input pl-11"
              :class="{ 'input-error': errors.email }"
              :placeholder="t('auth.emailPlaceholder')"
            />
          </div>
          <p v-if="errors.email" class="input-error-text">
            {{ errors.email }}
          </p>
        </div>

        <!-- Turnstile Widget -->
        <div v-if="turnstileEnabled && turnstileSiteKey">
          <TurnstileWidget
            ref="turnstileRef"
            :site-key="turnstileSiteKey"
            @verify="onTurnstileVerify"
            @expire="onTurnstileExpire"
            @error="onTurnstileError"
          />
          <p v-if="errors.turnstile" class="input-error-text mt-2 text-center">
            {{ errors.turnstile }}
          </p>
        </div>

        <!-- Error Message -->
        <transition name="fade">
          <div
            v-if="errorMessage"
            class="rounded-sm border border-danger/30 bg-danger/[0.04] p-3.5"
          >
            <div class="flex items-start gap-2.5">
              <div class="flex-shrink-0">
                <Icon name="exclamationCircle" size="md" class="text-danger" />
              </div>
              <p class="text-[13px] text-danger leading-snug">
                {{ errorMessage }}
              </p>
            </div>
          </div>
        </transition>

        <!-- Submit Button -->
        <button
          type="submit"
          :disabled="isLoading || (turnstileEnabled && !turnstileToken)"
          class="btn btn-primary w-full"
        >
          <svg
            v-if="isLoading"
            class="-ml-1 mr-2 h-4 w-4 animate-spin text-white"
            fill="none"
            viewBox="0 0 24 24"
          >
            <circle
              class="opacity-25"
              cx="12"
              cy="12"
              r="10"
              stroke="currentColor"
              stroke-width="4"
            ></circle>
            <path
              class="opacity-75"
              fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            ></path>
          </svg>
          <Icon v-else name="mail" size="md" class="mr-2" />
          {{ isLoading ? t('auth.sendingResetLink') : t('auth.sendResetLink') }}
        </button>
      </form>
    </div>

    <!-- Footer -->
    <template #footer>
      <span class="text-muted">{{ t('auth.rememberedPassword') }}</span>
      <router-link
        to="/login"
        class="ml-1 text-ink hover:underline underline-offset-4"
      >
        {{ t('auth.signIn') }} →
      </router-link>
    </template>
  </AuthLayout>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { AuthLayout } from '@/components/layout'
import Icon from '@/components/icons/Icon.vue'
import TurnstileWidget from '@/components/TurnstileWidget.vue'
import { useAppStore } from '@/stores'
import { getPublicSettings, forgotPassword } from '@/api/auth'

const { t } = useI18n()

// ==================== Stores ====================

const appStore = useAppStore()

// ==================== State ====================

const isLoading = ref<boolean>(false)
const isSubmitted = ref<boolean>(false)
const errorMessage = ref<string>('')

// Public settings
const turnstileEnabled = ref<boolean>(false)
const turnstileSiteKey = ref<string>('')

// Turnstile
const turnstileRef = ref<InstanceType<typeof TurnstileWidget> | null>(null)
const turnstileToken = ref<string>('')

const formData = reactive({
  email: ''
})

const errors = reactive({
  email: '',
  turnstile: ''
})

// ==================== Lifecycle ====================

onMounted(async () => {
  try {
    const settings = await getPublicSettings()
    turnstileEnabled.value = settings.turnstile_enabled
    turnstileSiteKey.value = settings.turnstile_site_key || ''
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
  errors.email = ''
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

  // Turnstile validation
  if (turnstileEnabled.value && !turnstileToken.value) {
    errors.turnstile = t('auth.completeVerification')
    isValid = false
  }

  return isValid
}

// ==================== Form Handlers ====================

async function handleSubmit(): Promise<void> {
  errorMessage.value = ''

  if (!validateForm()) {
    return
  }

  isLoading.value = true

  try {
    await forgotPassword({
      email: formData.email,
      turnstile_token: turnstileEnabled.value ? turnstileToken.value : undefined
    })

    isSubmitted.value = true
    appStore.showSuccess(t('auth.resetEmailSent'))
  } catch (error: unknown) {
    // Reset Turnstile on error
    if (turnstileRef.value) {
      turnstileRef.value.reset()
      turnstileToken.value = ''
    }

    const err = error as { message?: string; response?: { data?: { detail?: string } } }

    if (err.response?.data?.detail) {
      errorMessage.value = err.response.data.detail
    } else if (err.message) {
      errorMessage.value = err.message
    } else {
      errorMessage.value = t('auth.sendResetLinkFailed')
    }

    appStore.showError(errorMessage.value)
  } finally {
    isLoading.value = false
  }
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
