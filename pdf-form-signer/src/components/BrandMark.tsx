interface BrandMarkProps {
  size?: number
  className?: string
}

export function BrandMark({ size = 32, className }: BrandMarkProps) {
  return (
    <svg className={className} width={size} height={size} viewBox="0 0 32 32" aria-hidden="true" focusable="false">
      <rect width="32" height="32" rx="7" fill="currentColor" />
      <g transform="translate(16 16.5) scale(1.22) rotate(-45) translate(-16 -16.5)">
        <path d="M16 28.6 L10.2 14.2 A5.8 5.8 0 0 1 21.8 14.2 Z" fill="#fff" />
        <path d="M16 25.6 V17.8" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
        <circle cx="16" cy="15.2" r="1.7" fill="currentColor" />
      </g>
    </svg>
  )
}
