import type { Category } from '../types'

const ICONS: Record<Category, string> = {
  Audio:
    'M4 13a8 8 0 0 1 16 0v6a2 2 0 0 1-2 2h-2v-7h3a7 7 0 0 0-14 0h3v7H6a2 2 0 0 1-2-2v-6Z',
  Wearables:
    'M9 3h6l1 3h1a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2h-1l-1 3H9l-1-3H7a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h1l1-3Zm3 5a4 4 0 1 0 0 8 4 4 0 0 0 0-8Z',
  Home:
    'M9 3h6l3 9H6l3-9Zm2 10h2v6h3v2H8v-2h3v-6Z',
  Outdoor:
    'M12 3 2 20h20L12 3Zm0 5.5 5.6 9.5H14l-2-3.5-2 3.5H6.4L12 8.5Z',
}

interface Props {
  category: Category
  hue: number
  size?: 'card' | 'thumb'
}

export function ProductArt({ category, hue, size = 'card' }: Props) {
  const style = {
    background: `linear-gradient(135deg, hsl(${hue} 70% 92%), hsl(${(hue + 30) % 360} 60% 80%))`,
    color: `hsl(${hue} 45% 38%)`,
  }
  return (
    <div className={`art art-${size}`} style={style} aria-hidden="true">
      <svg viewBox="0 0 24 24" fill="currentColor">
        <path d={ICONS[category]} />
      </svg>
    </div>
  )
}
