import type { MediaItem } from '../types'

export const MEDIA: MediaItem[] = [
  { id: 'A', name: 'Sunrise Gradient', duration: 6, pattern: 'sunrise', primary: '#f97316', secondary: '#fde68a' },
  { id: 'B', name: 'Ocean Waves', duration: 5, pattern: 'ocean', primary: '#0ea5e9', secondary: '#a5f3fc' },
  { id: 'C', name: 'Neon Grid', duration: 8, pattern: 'grid', primary: '#d946ef', secondary: '#22d3ee' },
  { id: 'D', name: 'Forest Bokeh', duration: 7, pattern: 'bokeh', primary: '#22c55e', secondary: '#bbf7d0' },
  { id: 'E', name: 'Golden Bars', duration: 4, pattern: 'bars', primary: '#eab308', secondary: '#78350f' },
  { id: 'F', name: 'Violet Noise', duration: 6, pattern: 'noise', primary: '#8b5cf6', secondary: '#f5d0fe' },
]

export const mediaById = (id: string): MediaItem => {
  const m = MEDIA.find((x) => x.id === id)
  if (!m) throw new Error(`Unknown media ${id}`)
  return m
}
