<script setup lang="ts">
interface Props {
  label: string
  value: string | number
  hint?: string
}
defineProps<Props>()
</script>

<template>
  <div class="bg-surface border border-border rounded-md p-5">
    <div class="text-xs uppercase tracking-wider text-subtle">{{ label }}</div>
    <div class="mt-2 text-3xl font-semibold tabular-nums text-ink">{{ value }}</div>
    <div v-if="hint" class="mt-1 text-xs text-muted">{{ hint }}</div>
  </div>
</template>
