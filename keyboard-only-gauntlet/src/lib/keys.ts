const KEY_NAMES: Record<string, string> = {
  ArrowUp: '↑',
  ArrowDown: '↓',
  ArrowLeft: '←',
  ArrowRight: '→',
  ' ': 'Space',
  Escape: 'Esc',
  PageUp: 'PgUp',
  PageDown: 'PgDn',
}

const MODIFIERS = new Set(['Shift', 'Control', 'Alt', 'Meta', 'CapsLock'])

export function isModifierKey(key: string): boolean {
  return MODIFIERS.has(key)
}

export function isPrintableKey(e: { key: string; ctrlKey: boolean; altKey: boolean; metaKey: boolean }): boolean {
  return e.key.length === 1 && e.key !== ' ' && !e.ctrlKey && !e.altKey && !e.metaKey
}

export function formatKey(e: KeyboardEvent): string {
  const base = KEY_NAMES[e.key] ?? (e.key.length === 1 ? e.key.toUpperCase() : e.key)
  const parts: string[] = []
  if (e.ctrlKey) parts.push('Ctrl')
  if (e.altKey) parts.push('Alt')
  if (e.shiftKey && e.key.length > 1) parts.push('Shift')
  parts.push(base)
  return parts.join('+')
}

/** First-letter typeahead: search forward from `start` (exclusive), wrapping around. */
export function findTypeahead(labels: string[], start: number, char: string): number {
  const c = char.toLowerCase()
  const n = labels.length
  for (let step = 1; step <= n; step++) {
    const i = (start + step) % n
    if (labels[i].toLowerCase().startsWith(c)) return i
  }
  return -1
}

export function formatDuration(ms: number): string {
  const totalTenths = Math.floor(ms / 100)
  const minutes = Math.floor(totalTenths / 600)
  const seconds = Math.floor((totalTenths % 600) / 10)
  const tenths = totalTenths % 10
  return `${minutes}:${String(seconds).padStart(2, '0')}.${tenths}`
}
