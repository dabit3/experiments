import './Logo.css'

interface MarkProps {
  size?: number
  tone?: 'brand' | 'ink'
  className?: string
}

export function LogoMark({ size = 28, tone = 'brand', className }: MarkProps) {
  const bg = tone === 'brand' ? 'var(--brand)' : '#111114'
  const fg = '#ffffff'
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
      <rect width="32" height="32" rx="8" fill={bg} />
      <rect x="8" y="8.5" width="16" height="3.2" rx="1.6" fill={fg} />
      <rect x="8" y="14.4" width="11.5" height="3.2" rx="1.6" fill={fg} />
      <rect x="8" y="20.3" width="16" height="3.2" rx="1.6" fill={fg} />
    </svg>
  )
}

interface LogoProps {
  subtitle?: string
}

export function Logo({ subtitle = 'Point of Sale' }: LogoProps) {
  return (
    <div className="logo">
      <LogoMark size={30} />
      <span className="logo-text">
        <span className="logo-word">Ember</span>
        <span className="logo-sub">{subtitle}</span>
      </span>
    </div>
  )
}
