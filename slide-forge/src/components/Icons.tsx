import type { ReactNode, SVGProps } from 'react'

type IconName =
  | 'undo'
  | 'redo'
  | 'text'
  | 'rect'
  | 'ellipse'
  | 'arrow'
  | 'sticker'
  | 'play'
  | 'pdf'
  | 'plus'
  | 'alignLeft'
  | 'alignCenter'
  | 'alignRight'
  | 'bold'
  | 'bullets'
  | 'trash'
  | 'copy'
  | 'front'
  | 'back'
  | 'check'
  | 'notes'
  | 'logo'

const PATHS: Record<IconName, ReactNode> = {
  undo: <path d="M9 14 4 9l5-5M4 9h10a6 6 0 0 1 0 12h-3" />,
  redo: <path d="m15 14 5-5-5-5M20 9H10a6 6 0 0 0 0 12h3" />,
  text: <path d="M5 6V4h14v2M12 4v16M9 20h6" />,
  rect: <rect x="4" y="6" width="16" height="12" rx="1.5" />,
  ellipse: <ellipse cx="12" cy="12" rx="8.5" ry="6.5" />,
  arrow: <path d="M4 12h14M13 7l5 5-5 5" />,
  sticker: <path d="M12 3a9 9 0 1 0 9 9v-1l-9 1zM8.5 10h.01M15.5 10h.01M8.5 14.5c1.5 1.5 5.5 1.5 7 0" />,
  play: <path d="M7 5v14l11-7z" />,
  pdf: <path d="M6 3h8l5 5v13H6zM14 3v5h5M9 16h6M9 12h6" />,
  plus: <path d="M12 5v14M5 12h14" />,
  alignLeft: <path d="M4 6h16M4 10h10M4 14h16M4 18h10" />,
  alignCenter: <path d="M4 6h16M7 10h10M4 14h16M7 18h10" />,
  alignRight: <path d="M4 6h16M10 10h10M4 14h16M10 18h10" />,
  bold: <path d="M7 4h6.5a3.5 3.5 0 0 1 0 7H7zM7 11h7.5a3.75 3.75 0 0 1 0 7.5H7z" />,
  bullets: <path d="M9 6h11M9 12h11M9 18h11M4.5 6h.01M4.5 12h.01M4.5 18h.01" />,
  trash: <path d="M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13M10 11v6M14 11v6" />,
  copy: <path d="M8 8h11v11H8zM5 16V5h11" />,
  front: <path d="M4 4h10v10H4zM10 10h10v10H10z" />,
  back: <path d="M10 10h10v10H10zM4 4h10v10H4z" />,
  check: <path d="m5 12 5 5L20 7" />,
  notes: <path d="M5 4h14v16H5zM8 9h8M8 13h8M8 17h5" />,
  logo: <path d="M4 5h16v11H4zM8 20h8M12 16v4M8 9l3 3-3 3M13 15h3" />,
}

interface Props extends SVGProps<SVGSVGElement> {
  name: IconName
  size?: number
}

export function Icon({ name, size = 18, ...rest }: Props) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill={name === 'play' ? 'currentColor' : 'none'}
      stroke="currentColor"
      strokeWidth={2}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      {...rest}
    >
      {PATHS[name]}
    </svg>
  )
}
