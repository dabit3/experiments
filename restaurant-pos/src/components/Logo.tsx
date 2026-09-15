import './Logo.css'

interface MarkProps {
  size?: number
  tone?: 'brand' | 'ink'
  className?: string
}

export function LogoMark({ size = 28, tone = 'brand', className }: MarkProps) {
  const ink = tone === 'brand' ? 'var(--brand)' : '#233b30'
  return (
    <svg
      className={className}
      width={size}
      height={size}
      viewBox="0 0 32 32"
      role="img"
      aria-label="Ember"
      focusable="false"
    >
      <rect x="1" y="1" width="30" height="30" rx="1" fill="none" stroke={ink} strokeWidth=".75" />
      <path d="M9 8h14v5h-1l-1-4h-7v6h5v-2h1v6h-1v-3h-5v7h7l1-4h1v5H9v-1h2V9H9Z" fill={ink} />
    </svg>
  )
}

interface LogoProps {
  subtitle?: string
}

export function Logo({ subtitle = 'Service, considered' }: LogoProps) {
  return (
    <div className="logo">
      <span className="logo-text">
        <span className="logo-word">Ember</span>
        <span className="logo-sub">{subtitle}</span>
      </span>
    </div>
  )
}
