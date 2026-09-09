interface Props {
  size?: number
}

/** Monochrome knob mark: a ring with an indicator notch and a live dot. */
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
      <rect x="1" y="1" width="30" height="30" rx="9" fill="url(#lg-bg)" stroke="rgba(255,255,255,0.12)" />
      <circle cx="16" cy="16" r="8.25" fill="none" stroke="#f4f5f7" strokeWidth="2.5" />
      <path d="M16 8v5.5" stroke="#f4f5f7" strokeWidth="2.5" strokeLinecap="round" />
      <circle cx="24.5" cy="7.5" r="2" fill="#ff8a1f" />
      <defs>
        <linearGradient id="lg-bg" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#262b32" />
          <stop offset="1" stopColor="#121417" />
        </linearGradient>
      </defs>
    </svg>
  )
}
