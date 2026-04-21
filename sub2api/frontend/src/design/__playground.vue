<script setup lang="ts">
import { ref } from 'vue'
import Button from './components/Button.vue'
import Card from './components/Card.vue'
import Input from './components/Input.vue'
import Tag from './components/Tag.vue'
import Stat from './components/Stat.vue'
import { useDarkMode } from './composables/useDarkMode'

const text = ref('')
const { isDark, toggle } = useDarkMode()
</script>

<template>
  <div class="min-h-screen bg-paper text-ink p-12 font-sans">
    <header class="flex items-center justify-between mb-12 pb-6 border-b border-border">
      <div>
        <h1 class="text-2xl font-semibold tracking-tight">Design Playground</h1>
        <p class="text-sm text-muted mt-1">proxy-api · black & white minimalist atoms</p>
      </div>
      <Button variant="ghost" @click="toggle()">
        {{ isDark ? '☀ Light' : '☾ Dark' }}
      </Button>
    </header>

    <section class="mb-12">
      <h2 class="text-xs uppercase tracking-wider text-subtle mb-4">Buttons</h2>
      <div class="flex flex-wrap items-center gap-3 mb-3">
        <Button variant="primary">Primary</Button>
        <Button variant="ghost">Ghost</Button>
        <Button variant="danger">Danger</Button>
        <Button variant="link">Link</Button>
      </div>
      <div class="flex flex-wrap items-center gap-3 mb-3">
        <Button size="sm">Small</Button>
        <Button size="md">Medium</Button>
        <Button size="lg">Large</Button>
      </div>
      <div class="flex flex-wrap items-center gap-3">
        <Button disabled>Disabled</Button>
        <Button loading>Loading</Button>
      </div>
    </section>

    <section class="mb-12">
      <h2 class="text-xs uppercase tracking-wider text-subtle mb-4">Stats</h2>
      <div class="grid grid-cols-3 gap-4">
        <Stat label="Requests today" :value="1234" hint="+12% vs yesterday" />
        <Stat label="Tokens consumed" value="9.2M" />
        <Stat label="Active keys" value="7" />
      </div>
    </section>

    <section class="mb-12">
      <h2 class="text-xs uppercase tracking-wider text-subtle mb-4">Card &amp; Tags</h2>
      <Card class="max-w-md">
        <h3 class="font-semibold text-ink">Upstream: Anthropic Official</h3>
        <p class="text-sm text-muted mt-1">Pool of 4 API keys, 3 healthy</p>
        <div class="mt-4 flex gap-2 flex-wrap">
          <Tag>default</Tag>
          <Tag tone="success">healthy</Tag>
          <Tag tone="warning">degraded</Tag>
          <Tag tone="danger">down</Tag>
        </div>
      </Card>
    </section>

    <section class="max-w-md">
      <h2 class="text-xs uppercase tracking-wider text-subtle mb-4">Input</h2>
      <Input v-model="text" placeholder="Type something…" />
      <p class="text-xs text-muted mt-2">Echo: <span class="font-mono">{{ text || '—' }}</span></p>
    </section>
  </div>
</template>
