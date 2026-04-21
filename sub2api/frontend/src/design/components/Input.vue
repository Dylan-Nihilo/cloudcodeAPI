<script setup lang="ts">
interface Props {
  modelValue?: string
  placeholder?: string
  type?: string
  disabled?: boolean
}
withDefaults(defineProps<Props>(), {
  modelValue: '',
  type: 'text',
  disabled: false,
})
defineEmits<{ (e: 'update:modelValue', value: string): void }>()
</script>

<template>
  <input
    :type="type"
    :value="modelValue"
    :placeholder="placeholder"
    :disabled="disabled"
    @input="$emit('update:modelValue', ($event.target as HTMLInputElement).value)"
    class="h-9 w-full px-3 text-sm rounded-md
           bg-surface text-ink placeholder:text-subtle
           border border-border
           focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ink/30 focus-visible:border-ink/40
           disabled:opacity-50 disabled:cursor-not-allowed
           transition-[border-color,box-shadow] duration-fast ease-out-soft"
  />
</template>
