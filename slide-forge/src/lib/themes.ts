import type { Theme, ThemeId } from '../types'

const SANS = "'Inter', system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif"
const SERIF = "Georgia, 'Times New Roman', 'DejaVu Serif', serif"
const MONO = "ui-monospace, 'SF Mono', Menlo, Consolas, 'DejaVu Sans Mono', monospace"

export const THEMES: Theme[] = [
  {
    id: 'midnight',
    name: 'Midnight',
    background: 'linear-gradient(135deg, #0f172a 0%, #1e1b4b 100%)',
    text: '#f8fafc',
    muted: '#a5b4fc',
    accent: '#818cf8',
    headingFont: SANS,
    bodyFont: SANS,
    palette: ['#818cf8', '#38bdf8', '#f472b6', '#fbbf24', '#34d399', '#f8fafc'],
  },
  {
    id: 'paper',
    name: 'Paper',
    background: '#fbf7ef',
    text: '#1c1917',
    muted: '#78716c',
    accent: '#c2410c',
    headingFont: SERIF,
    bodyFont: SANS,
    palette: ['#c2410c', '#0f766e', '#b45309', '#1d4ed8', '#7e22ce', '#1c1917'],
  },
  {
    id: 'coral',
    name: 'Coral',
    background: 'linear-gradient(160deg, #ff6b6b 0%, #f06595 55%, #cc5de8 100%)',
    text: '#ffffff',
    muted: '#ffe3e3',
    accent: '#ffe066',
    headingFont: SANS,
    bodyFont: SANS,
    palette: ['#ffe066', '#ffffff', '#212529', '#74c0fc', '#8ce99a', '#ffa94d'],
  },
  {
    id: 'forest',
    name: 'Forest',
    background: 'linear-gradient(180deg, #052e16 0%, #14532d 100%)',
    text: '#ecfdf5',
    muted: '#86efac',
    accent: '#4ade80',
    headingFont: SERIF,
    bodyFont: SANS,
    palette: ['#4ade80', '#fde047', '#fb923c', '#ecfdf5', '#38bdf8', '#f472b6'],
  },
  {
    id: 'slate',
    name: 'Slate',
    background: '#f1f5f9',
    text: '#0f172a',
    muted: '#475569',
    accent: '#2563eb',
    headingFont: SANS,
    bodyFont: SANS,
    palette: ['#2563eb', '#0f172a', '#16a34a', '#dc2626', '#9333ea', '#f59e0b'],
  },
  {
    id: 'terminal',
    name: 'Terminal',
    background: '#0a0f0a',
    text: '#d9f99d',
    muted: '#65a30d',
    accent: '#22c55e',
    headingFont: MONO,
    bodyFont: MONO,
    palette: ['#22c55e', '#d9f99d', '#f97316', '#38bdf8', '#e879f9', '#ffffff'],
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
