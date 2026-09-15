import type { Theme, ThemeId } from '../types'

export const UI_SANS = "'Inter Variable', Inter, system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif"
const DISPLAY = "'Manrope Variable', Manrope, 'Inter Variable', system-ui, sans-serif"
const GROTESK = "'Space Grotesk Variable', 'Space Grotesk', 'Inter Variable', system-ui, sans-serif"
const SERIF = "'Fraunces Variable', Fraunces, Georgia, 'Times New Roman', serif"
const MONO = "'JetBrains Mono Variable', 'JetBrains Mono', ui-monospace, 'SF Mono', Menlo, Consolas, monospace"

/**
 * Each theme sets the slide's colour system and fonts; the matching `theme-<id>` class on the
 * slide surface adds a decorative background layer (glows, grain, grids) in App.css.
 */
export const THEMES: Theme[] = [
  {
    id: 'midnight',
    name: 'Midnight',
    tagline: 'Aurora on navy',
    background: '#0b1020',
    text: '#f4f6ff',
    muted: '#9aa6d6',
    accent: '#8b8cff',
    headingFont: DISPLAY,
    bodyFont: UI_SANS,
    palette: ['#8b8cff', '#49c6ff', '#ff6fae', '#ffc857', '#3fe0a8', '#f4f6ff'],
  },
  {
    id: 'paper',
    name: 'Paper',
    tagline: 'Editorial serif',
    background: '#f7f1e6',
    text: '#1f1a17',
    muted: '#7a6f66',
    accent: '#c2410c',
    headingFont: SERIF,
    bodyFont: UI_SANS,
    palette: ['#c2410c', '#0f766e', '#a16207', '#1d4ed8', '#7e22ce', '#1f1a17'],
  },
  {
    id: 'coral',
    name: 'Coral',
    tagline: 'Sunset gradient',
    background: '#ff6b6b',
    text: '#ffffff',
    muted: '#ffe1e1',
    accent: '#ffe066',
    headingFont: GROTESK,
    bodyFont: UI_SANS,
    palette: ['#ffe066', '#ffffff', '#1f1233', '#7cd4ff', '#a3f7bf', '#ffb26b'],
  },
  {
    id: 'forest',
    name: 'Forest',
    tagline: 'Evergreen & brass',
    background: '#06251a',
    text: '#eefbf3',
    muted: '#8fd4ac',
    accent: '#e2b857',
    headingFont: SERIF,
    bodyFont: UI_SANS,
    palette: ['#e2b857', '#4ade80', '#fb923c', '#eefbf3', '#5fd3f3', '#f6a5c0'],
  },
  {
    id: 'slate',
    name: 'Slate',
    tagline: 'Bright & clean',
    background: '#f4f6fa',
    text: '#0f172a',
    muted: '#5b6b85',
    accent: '#2563eb',
    headingFont: DISPLAY,
    bodyFont: UI_SANS,
    palette: ['#2563eb', '#0f172a', '#059669', '#dc2626', '#7c3aed', '#f59e0b'],
  },
  {
    id: 'terminal',
    name: 'Terminal',
    tagline: 'Phosphor green',
    background: '#060a07',
    text: '#d7ffb0',
    muted: '#6fae4c',
    accent: '#38e07b',
    headingFont: MONO,
    bodyFont: MONO,
    palette: ['#38e07b', '#d7ffb0', '#ff9f43', '#4cc9f0', '#f072ff', '#ffffff'],
  },
]

export function getTheme(id: ThemeId): Theme {
  return THEMES.find((t) => t.id === id) ?? THEMES[0]
}

export function contrastText(hex: string): string {
  const m = /^#?([0-9a-f]{6})$/i.exec(hex.trim())
  if (!m) return '#ffffff'
  const n = parseInt(m[1], 16)
  const r = (n >> 16) & 255
  const g = (n >> 8) & 255
  const b = n & 255
  const lum = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
  return lum > 0.6 ? '#111827' : '#ffffff'
}
