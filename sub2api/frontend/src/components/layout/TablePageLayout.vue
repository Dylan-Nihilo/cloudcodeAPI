<template>
  <div class="table-page-layout" :class="{ 'mobile-mode': isMobile }">
    <!-- Page header / actions row -->
    <div v-if="$slots.actions" class="layout-section-fixed">
      <slot name="actions" />
    </div>

    <!-- Filter strip — sits above the table on a hairline divider -->
    <div v-if="$slots.filters" class="layout-section-fixed">
      <slot name="filters" />
    </div>

    <!-- Editorial reference table — flat, hairline-bordered, no card shell -->
    <div class="layout-section-scrollable">
      <div class="table-scroll-container">
        <slot name="table" />
      </div>
    </div>

    <!-- Pagination -->
    <div v-if="$slots.pagination" class="layout-section-fixed">
      <slot name="pagination" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'

const isMobile = ref(false)

const checkMobile = () => {
  isMobile.value = window.innerWidth < 1024
}

onMounted(() => {
  checkMobile()
  window.addEventListener('resize', checkMobile)
})

onUnmounted(() => {
  window.removeEventListener('resize', checkMobile)
})
</script>

<style scoped>
/* Desktop: flexbox column with fixed header / scrolling table / fixed pagination */
.table-page-layout {
  @apply flex flex-col gap-4;
  height: calc(100vh - 64px - 4rem);
}

.layout-section-fixed {
  @apply flex-shrink-0;
}

.layout-section-scrollable {
  @apply flex-1 min-h-0 flex flex-col;
}

/* Reference table container — NO card / shadow / rounded-2xl.
   Flat surface, top + bottom hairline borders, content scrolls inside. */
.table-scroll-container {
  @apply flex flex-col overflow-hidden h-full;
  @apply bg-paper border-y border-border;
}

.table-scroll-container :deep(.table-wrapper) {
  @apply flex-1 overflow-x-auto overflow-y-auto;
  scrollbar-gutter: stable;
}

.table-scroll-container :deep(table) {
  @apply w-full;
  min-width: max-content;
  display: table;
}

/* Header — small uppercase mono labels (editorial reference table style) */
.table-scroll-container :deep(thead) {
  @apply bg-paper sticky top-0 z-10;
}

.table-scroll-container :deep(th) {
  @apply px-4 py-3 text-left;
  @apply text-[11px] uppercase tracking-[0.14em] text-subtle font-mono font-normal;
  @apply border-b border-border;
}

/* Rows — single hairline divider, hover ghost, mono-friendly cells */
.table-scroll-container :deep(td) {
  @apply px-4 py-3 text-[13.5px] text-ink border-b border-border;
}

.table-scroll-container :deep(tbody tr) {
  @apply transition-colors;
}

.table-scroll-container :deep(tbody tr:hover) {
  background-color: rgb(var(--color-ink) / 0.02);
}

.table-scroll-container :deep(tbody tr:last-child td) {
  @apply border-b-0;
}

/* Mobile: drop the sticky scroll container, let the page itself scroll */
.table-page-layout.mobile-mode .table-scroll-container {
  @apply h-auto overflow-visible border-y-0;
}

.table-page-layout.mobile-mode .layout-section-scrollable {
  @apply flex-none min-h-fit;
}

.table-page-layout.mobile-mode .table-scroll-container :deep(.table-wrapper) {
  @apply overflow-visible;
}

.table-page-layout.mobile-mode .table-scroll-container :deep(table) {
  @apply flex-none;
  display: table;
  min-width: 100%;
}
</style>
