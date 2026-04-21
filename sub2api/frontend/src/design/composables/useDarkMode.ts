import { useDark, useToggle } from '@vueuse/core'

/**
 * Wraps @vueuse/core useDark using sub2api's existing 'theme' localStorage key
 * so our toggle stays in sync with the theme initialization in main.ts.
 */
export function useDarkMode() {
  const isDark = useDark({
    selector: 'html',
    attribute: 'class',
    valueDark: 'dark',
    valueLight: '',
    storageKey: 'theme',
  })
  return { isDark, toggle: useToggle(isDark) }
}
