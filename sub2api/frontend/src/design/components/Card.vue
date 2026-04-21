<script setup lang="ts">
interface Props { padded?: boolean }
withDefaults(defineProps<Props>(), { padded: true })
</script>

<template>
  <div
    class="bg-surface border border-border rounded-md shadow-soft"
    :class="padded ? 'p-6' : ''"
  >
    <slot />
  </div>
</template>
