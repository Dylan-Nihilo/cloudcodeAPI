<script setup lang="ts">
import { computed } from 'vue'

interface Props { tone?: 'default' | 'success' | 'warning' | 'danger' }
const props = withDefaults(defineProps<Props>(), { tone: 'default' })

const toneClasses = computed(() => ({
  default: 'bg-paper text-muted border-border',
  success: 'bg-paper text-success border-success/30',
  warning: 'bg-paper text-warning border-warning/30',
  danger:  'bg-paper text-danger  border-danger/30',
}[props.tone]))
</script>

<template>
  <span
    :class="[
      'inline-flex items-center gap-1.5 px-2 py-0.5 rounded-sm text-xs font-medium border',
      toneClasses,
    ]"
  >
    <slot />
  </span>
</template>
