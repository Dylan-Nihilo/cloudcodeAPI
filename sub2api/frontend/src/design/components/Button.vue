<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  variant?: 'primary' | 'ghost' | 'danger' | 'link'
  size?: 'sm' | 'md' | 'lg'
  disabled?: boolean
  loading?: boolean
  type?: 'button' | 'submit' | 'reset'
}
const props = withDefaults(defineProps<Props>(), {
  variant: 'primary',
  size: 'md',
  disabled: false,
  loading: false,
  type: 'button',
})
defineEmits<{ (e: 'click', event: MouseEvent): void }>()

const variantClasses = computed(() => ({
  primary: 'bg-ink text-paper hover:opacity-90 border border-ink',
  ghost:   'bg-transparent text-ink hover:bg-ink/5 border border-border',
  danger:  'bg-danger text-paper hover:opacity-90 border border-danger',
  link:    'bg-transparent text-ink underline-offset-4 hover:underline border-transparent !p-0 !h-auto',
}[props.variant]))

const sizeClasses = computed(() => ({
  sm: 'h-8 px-3 text-sm rounded-sm',
  md: 'h-9 px-4 text-sm rounded-md',
  lg: 'h-11 px-6 text-base rounded-md',
}[props.size]))
</script>

<template>
  <button
    :type="type"
    :disabled="disabled || loading"
    :class="[
      'inline-flex items-center justify-center gap-2 font-medium',
      'transition-[background-color,opacity,transform] duration-fast ease-out-soft',
      'disabled:opacity-50 disabled:cursor-not-allowed',
      'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ink/30 focus-visible:ring-offset-2 focus-visible:ring-offset-paper',
      variantClasses,
      sizeClasses,
    ]"
    @click="$emit('click', $event)"
  >
    <span
      v-if="loading"
      class="inline-block w-3 h-3 border-2 border-current border-t-transparent rounded-sm animate-spin"
    />
    <slot />
  </button>
</template>
