// design/tailwind.preset.js
// Token-backed Tailwind theme keys for proxy-api re-skin.
//
// This preset is deliberately ADDITIVE in two layers:
//
// 1) Net-new keys (ink, paper, surface, …) for our own design components.
// 2) OVERRIDES of sub2api's existing palette keys (primary / dark / accent) —
//    remapped to grayscale ramps so that EVERY existing `bg-primary-500`,
//    `text-primary-700`, `bg-dark-900` etc. across the upstream codebase
//    automatically goes black-and-white without touching any view file.
//
// To restore upstream's teal palette, delete the `primary` / `dark` / `accent`
// keys from `colors` below.

// Zinc-leaning neutral ramp; biased toward solid black at the action end.
const neutral = {
  50:  '#FAFAFA',
  100: '#F4F4F5',
  200: '#E4E4E7',
  300: '#D4D4D8',
  400: '#A1A1AA',
  500: '#52525B',
  600: '#3F3F46',
  700: '#27272A',
  800: '#18181B',
  900: '#0A0A0A',
  950: '#000000',
}

// Same ramp but the mid-band biased toward true black so that primary CTAs
// (bg-primary-500/600/700) are almost-black instead of mid-gray.
const action = {
  50:  '#FAFAFA',
  100: '#F4F4F5',
  200: '#E4E4E7',
  300: '#D4D4D8',
  400: '#71717A',
  500: '#27272A',  // primary fill
  600: '#18181B',  // hover
  700: '#0A0A0A',
  800: '#000000',
  900: '#000000',
  950: '#000000',
}

export default {
  theme: {
    extend: {
      colors: {
        // ── proxy-api new tokens (token-backed, theme-aware) ─────────
        // Wrapped in rgb(... / <alpha-value>) so Tailwind opacity
        // modifiers like `bg-ink/[0.04]` and `text-ink/85` work.
        ink:             'rgb(var(--color-ink) / <alpha-value>)',
        paper:           'rgb(var(--color-paper) / <alpha-value>)',
        surface:         'rgb(var(--color-surface) / <alpha-value>)',
        muted:           'rgb(var(--color-muted) / <alpha-value>)',
        subtle:          'rgb(var(--color-subtle) / <alpha-value>)',
        border:          'rgb(var(--color-border) / <alpha-value>)',
        'border-strong': 'rgb(var(--color-border-strong) / <alpha-value>)',
        success:         'rgb(var(--color-success) / <alpha-value>)',
        warning:         'rgb(var(--color-warning) / <alpha-value>)',
        danger:          'rgb(var(--color-danger) / <alpha-value>)',

        // ── overrides for upstream's brand palette ────────────────────
        primary: action,
        accent:  neutral,
        dark:    neutral,
      },
      borderRadius: {
        sm: 'var(--radius-sm)',
        md: 'var(--radius-md)',
        lg: 'var(--radius-lg)',
      },
      boxShadow: {
        soft:   'var(--shadow-soft)',
        medium: 'var(--shadow-medium)',
      },
      transitionTimingFunction: {
        'out-soft': 'var(--ease-out)',
      },
      transitionDuration: {
        fast: 'var(--duration-fast)',
      },
      fontFamily: {
        sans:    ['var(--font-sans)'],
        mono:    ['var(--font-mono)'],
        display: ['var(--font-display)'],
      },
    },
  },
}
