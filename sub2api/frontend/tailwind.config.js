import proxyApiPreset from './src/design/tailwind.preset.js'

/**
 * proxy-api / CloudCodeAPI Tailwind config.
 *
 * The preset (./src/design/tailwind.preset.js) owns:
 *   - all color palette keys (ink/paper/surface/muted/border/...
 *     plus the `primary`/`accent`/`dark` overrides that catch upstream
 *     class usages and remap them to grayscale)
 *   - fontFamily (sans/mono/display point to CSS variables in tokens.css)
 *   - radius / shadow / motion tokens
 *
 * This file keeps only what's not in the preset: content globs, darkMode
 * mode, generic non-color theme additions (animations, backdrop blur,
 * extra radii), and plugins.
 *
 * The teal-specific definitions (primary/accent/dark color ramps,
 * shadow-glow, mesh-gradient, gradient-primary, glow keyframes) are
 * INTENTIONALLY removed — they were the source of stubborn green
 * highlights that bypassed the palette override.
 */
export default {
  presets: [proxyApiPreset],
  content: ['./index.html', './src/**/*.{vue,js,ts,jsx,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      boxShadow: {
        // glass-style shadows kept (no color) — used widely in upstream
        glass:      '0 8px 32px rgba(0, 0, 0, 0.08)',
        'glass-sm': '0 4px 16px rgba(0, 0, 0, 0.06)',
        card:       '0 1px 3px rgba(0, 0, 0, 0.04), 0 1px 2px rgba(0, 0, 0, 0.06)',
        'card-hover': '0 10px 40px rgba(0, 0, 0, 0.08)',
        'inner-glow': 'inset 0 1px 0 rgba(255, 255, 255, 0.1)',
      },
      backgroundImage: {
        // Generic radial helper. The colorful mesh-gradient + gradient-primary
        // were removed — anything that needed them gets a flat surface now.
        'gradient-radial': 'radial-gradient(var(--tw-gradient-stops))',
        'gradient-glass':
          'linear-gradient(135deg, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0.05) 100%)',
      },
      animation: {
        'fade-in': 'fadeIn 0.3s ease-out',
        'slide-up': 'slideUp 0.3s ease-out',
        'slide-down': 'slideDown 0.3s ease-out',
        'slide-in-right': 'slideInRight 0.3s ease-out',
        'scale-in': 'scaleIn 0.2s ease-out',
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        shimmer: 'shimmer 2s linear infinite',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { opacity: '0', transform: 'translateY(10px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        slideDown: {
          '0%': { opacity: '0', transform: 'translateY(-10px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        slideInRight: {
          '0%': { opacity: '0', transform: 'translateX(20px)' },
          '100%': { opacity: '1', transform: 'translateX(0)' },
        },
        scaleIn: {
          '0%': { opacity: '0', transform: 'scale(0.95)' },
          '100%': { opacity: '1', transform: 'scale(1)' },
        },
        shimmer: {
          '0%': { backgroundPosition: '-200% 0' },
          '100%': { backgroundPosition: '200% 0' },
        },
      },
      backdropBlur: {
        xs: '2px',
      },
      borderRadius: {
        '4xl': '2rem',
      },
    },
  },
  plugins: [],
}
