import type { SVGProps } from 'react'

export type IconName =
  | 'play'
  | 'pause'
  | 'skip-start'
  | 'skip-end'
  | 'rewind'
  | 'forward'
  | 'undo'
  | 'redo'
  | 'download'
  | 'plus'
  | 'razor'
  | 'select'
  | 'magnet'
  | 'title'
  | 'trash'
  | 'zoom-in'
  | 'zoom-out'
  | 'fit'
  | 'film'
  | 'split'
  | 'chevron'
  | 'folder'
  | 'search'
  | 'grid'
  | 'list'
  | 'guides'
  | 'step-back'
  | 'step-forward'
  | 'stop'

const paths: Record<IconName, string> = {
  play: 'M8 5v14l11-7z',
  pause: 'M6 5h4v14H6zm8 0h4v14h-4z',
  'skip-start': 'M6 6h2v12H6zm3.5 6 8.5 6V6z',
  'skip-end': 'M16 6h2v12h-2zM6 18l8.5-6L6 6z',
  rewind: 'M11 18V6l-8.5 6zm.5-6 8.5 6V6z',
  forward: 'M4 18l8.5-6L4 6zm9 0 8.5-6L13 6z',
  undo: 'M12.5 8H7.8l2.6-2.6L9 4 4 9l5 5 1.4-1.4L7.8 10h4.7a4 4 0 0 1 0 8H8v2h4.5a6 6 0 0 0 0-12z',
  redo: 'M11.5 8h4.7l-2.6-2.6L15 4l5 5-5 5-1.4-1.4 2.6-2.6h-4.7a4 4 0 0 0 0 8H16v2h-4.5a6 6 0 0 1 0-12z',
  download: 'M12 3v10.2l3.6-3.6L17 11l-5 5-5-5 1.4-1.4L11 13.2V3zM4 17h2v2h12v-2h2v4H4z',
  plus: 'M11 5h2v6h6v2h-6v6h-2v-6H5v-2h6z',
  razor: 'M4 19 15.5 7.5l1.4 1.4L5.4 20.4zM14 4l6 6-2.5 2.5-6-6zM3 3l4 4-1.4 1.4L1.6 4.4z',
  select: 'M5 3l14 8.5-6 1.5-2.5 6z',
  magnet: 'M7 3h4v8a1 1 0 0 0 2 0V3h4v8a5 5 0 0 1-10 0zm0 0v4h4V3zm6 0v4h4V3z',
  title: 'M4 5h16v3h-6.5v11h-3V8H4z',
  trash: 'M9 3h6l1 2h4v2H4V5h4zm-3 5h12l-1 13H7z',
  'zoom-in': 'M10 3a7 7 0 1 1 4.2 12.6l5.6 5.6-1.4 1.4-5.6-5.6A7 7 0 0 1 10 3zm0 2a5 5 0 1 0 0 10 5 5 0 0 0 0-10zm-1 2h2v2h2v2h-2v2H9v-2H7V9h2z',
  'zoom-out': 'M10 3a7 7 0 1 1 4.2 12.6l5.6 5.6-1.4 1.4-5.6-5.6A7 7 0 0 1 10 3zm0 2a5 5 0 1 0 0 10 5 5 0 0 0 0-10zM7 9h6v2H7z',
  fit: 'M3 5h6v2H5v4H3zm12 0h6v6h-2V7h-4zM3 13h2v4h4v2H3zm16 0h2v6h-6v-2h4z',
  film: 'M3 4h18v16H3zm2 2v2h2V6zm0 4v2h2v-2zm0 4v2h2v-2zm0 4h2v-2H5zm12-12v2h2V6zm0 4v2h2v-2zm0 4v2h2v-2zm0 4h2v-2h-2zM9 6v12h6V6z',
  split: 'M11 3h2v18h-2zM4 7h5v2H6v6h3v2H4zm11 0h5v10h-5v-2h3V9h-3z',
  chevron: 'M7 10l5 5 5-5z',
  folder: 'M3 5h7l2 2h9v13H3zm2 2v11h14V9h-8L9 7z',
  search: 'M10 3a7 7 0 1 1 4.2 12.6l5.6 5.6-1.4 1.4-5.6-5.6A7 7 0 0 1 10 3zm0 2a5 5 0 1 0 0 10 5 5 0 0 0 0-10z',
  grid: 'M3 3h7v7H3zm2 2v3h3V5zm9-2h7v7h-7zm2 2v3h3V5zM3 14h7v7H3zm2 2v3h3v-3zm9-2h7v7h-7zm2 2v3h3v-3z',
  list: 'M3 4h4v4H3zm6 1h12v2H9zM3 10h4v4H3zm6 1h12v2H9zM3 16h4v4H3zm6 1h12v2H9z',
  guides: 'M5 2h2v3h10V2h2v3h3v2h-3v10h3v2h-3v3h-2v-3H7v3H5v-3H2v-2h3V7H2V5h3zm2 5v10h10V7z',
  'step-back': 'M5 5h2v14H5zm4 7 10 7V5z',
  'step-forward': 'M17 5h2v14h-2zM5 5v14l10-7z',
  stop: 'M5 5h14v14H5z',
}

interface Props extends SVGProps<SVGSVGElement> {
  name: IconName
  size?: number
}

export function Icon({ name, size = 18, ...rest }: Props) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" aria-hidden="true" {...rest}>
      <path d={paths[name]} />
    </svg>
  )
}
