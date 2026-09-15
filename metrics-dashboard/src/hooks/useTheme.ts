import { useCallback, useEffect, useState } from 'react'

export type Theme = 'light' | 'dark'

const STORAGE_KEY = 'metrics-dashboard-theme'

function initialTheme(): Theme {
  const stored = localStorage.getItem(STORAGE_KEY)
  if (stored === 'light' || stored === 'dark') return stored
  return 'light'
}

export function useTheme(): [Theme, () => void] {
  const [theme, setTheme] = useState<Theme>(initialTheme)

  useEffect(() => {
    document.documentElement.dataset.theme = theme
    localStorage.setItem(STORAGE_KEY, theme)
  }, [theme])

  const toggle = useCallback(() => setTheme((t) => (t === 'light' ? 'dark' : 'light')), [])
  return [theme, toggle]
}

export interface ChartPalette {
  grid: string
  axis: string
  text: string
  accent: string
  accentSoft: string
  cursor: string
  series: string[]
  muted: string
}

export const PALETTES: Record<Theme, ChartPalette> = {
  light: {
    grid: '#e6e8ef',
    axis: '#8a90a2',
    text: '#1c1f2a',
    accent: '#4f6bff',
    accentSoft: 'rgba(79,107,255,0.14)',
    cursor: '#4f6bff',
    series: ['#4f6bff', '#22c39a', '#f59e0b', '#ef5da8'],
    muted: '#c9cdd9',
  },
  dark: {
    grid: '#262b3a',
    axis: '#7d849a',
    text: '#e8eaf2',
    accent: '#7c93ff',
    accentSoft: 'rgba(124,147,255,0.18)',
    cursor: '#a5b4ff',
    series: ['#7c93ff', '#34d8ac', '#fbbf24', '#f472b6'],
    muted: '#3a4054',
  },
}
