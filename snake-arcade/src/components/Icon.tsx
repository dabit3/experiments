const paths = {
  play: 'm9 5 11 7-11 7V5Z',
  pause: 'M9 5v14M15 5v14',
  sound: 'm11 5-6 4H2v6h3l6 4V5Zm4 3a6 6 0 0 1 0 8m3-11a10 10 0 0 1 0 14',
  mute: 'm11 5-6 4H2v6h3l6 4V5Zm5 4 6 6m0-6-6 6',
  expand: 'M8 3H3v5m13-5h5v5M3 16v5h5m13-5v5h-5',
  shrink: 'M3 8h5V3m13 5h-5V3M8 21v-5H3m13 5v-5h5',
  trophy: 'M7 3h10v6a5 5 0 0 1-10 0V3Zm0 2H3v3a4 4 0 0 0 4 4m10-7h4v3a4 4 0 0 1-4 4m-5 2v5m-4 2h8',
  arrow: 'M4 12h16m-6-6 6 6-6 6',
  bolt: 'm13 2-9 12h7l-1 8 10-13h-8l1-7Z',
  apple: 'M12 7c-3-4-10-1-8 6s5 9 8 6c3 3 6 1 8-6s-5-10-8-6Zm0-1c0-3 2-4 5-4',
} as const

export function Icon({ name }: { name: keyof typeof paths }) {
  return (
    <svg
      width="20"
      height="20"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.7"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d={paths[name]} />
    </svg>
  )
}
