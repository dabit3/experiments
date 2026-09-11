interface LogoProps {
  size?: number
  className?: string
}

export function Logo({ size = 44, className }: LogoProps) {
  return (
    <svg
      viewBox="0 0 64 64"
      width={size}
      height={size}
      className={className}
      aria-hidden="true"
    >
      <path d="m32 3 26 15v28L32 61 6 46V18Z" fill="#ffcc58" />
      <path d="m32 9 20 12v21L32 54 12 42V21Z" fill="#102d44" />
      <path d="M29 17h6v12h11l-4 6H22l-4-6h11Z" fill="#ffcc58" />
      <path d="m17 39 7-3 8 4 8-4 7 3-15 9Z" fill="#62eee3" />
    </svg>
  )
}
