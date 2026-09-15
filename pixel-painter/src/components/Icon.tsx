const paths = {
  undo: 'M9 5L4 10l5 5M4 10h9a6 6 0 0 1 6 6v3',
  redo: 'M15 5l5 5-5 5m5-5h-9a6 6 0 0 0-6 6v3',
  download: 'M12 3v12m-5-5 5 5 5-5M4 16v4h16v-4',
  image: 'M3 4h18v16H3zM3 16l6-6 5 5 3-3 4 4M16 8h.01',
  plus: 'M12 5v14M5 12h14',
  minus: 'M5 12h14',
  fit: 'M8 3H3v5m13-5h5v5M3 16v5h5m13-5v5h-5M8 8h8v8H8z',
  chevron: 'm8 10 4 4 4-4',
  close: 'm6 6 12 12M6 18 18 6',
  help: 'M9 8a3 3 0 1 1 5 2c-2 1-2 2-2 3m0 4h.01M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0',
  trash: 'M4 6h16M9 6V3h6v3M6 6l1 15h10l1-15M10 10v7m4-7v7',
  grid: 'M3 3h18v18H3zM3 9h18M3 15h18M9 3v18m6-18v18',
  check: 'm5 12 4 4L19 6',
  sliders: 'M4 6h16M4 18h16M8 3v6m8 6v6',
  file: 'M5 3h9l5 5v13H5zM14 3v6h5',
  arrow: 'm5 12 14 0m-5-5 5 5-5 5',
} as const

export function Icon({
  name,
  size = 18,
}: {
  name: keyof typeof paths
  size?: number
}) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.6"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d={paths[name]} />
    </svg>
  )
}
