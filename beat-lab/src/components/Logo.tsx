interface Props {
  size?: number
}

export function Logo({ size = 32 }: Props) {
  return (
    <svg
      className="logo-mark"
      width={size}
      height={size}
      viewBox="0 0 32 32"
      aria-hidden="true"
      focusable="false"
    >
      <path d="M4 7h8v18H4zM16 7h4a9 9 0 0 1 0 18h-4z" fill="currentColor" />
      <path d="M23 12v8" stroke="var(--bg)" strokeWidth="2" />
    </svg>
  )
}
