import type { PartType } from './parts.ts'

interface IconProps {
  size?: number
  className?: string
}

/** Brand mark: ink tile with a single-weight geometric bell glyph. */
export function LogoMark({ size = 32, className }: IconProps) {
  return (
    <svg viewBox="0 0 32 32" width={size} height={size} className={className} aria-hidden="true">
      <rect width="32" height="32" rx="8" fill="currentColor" />
      <path
        d="M10 19v-4.5a6 6 0 0 1 12 0V19M8.5 20.5h15"
        fill="none"
        stroke="#fff"
        strokeWidth="2.4"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <circle cx="16" cy="24.5" r="1.9" fill="#fff" />
    </svg>
  )
}

export function PlayIcon({ size = 16 }: IconProps) {
  return (
    <svg viewBox="0 0 16 16" width={size} height={size} aria-hidden="true">
      <path d="M4.5 3.2v9.6c0 .6.6.9 1.1.6l7.4-4.8c.4-.3.4-.9 0-1.2L5.6 2.6c-.5-.3-1.1 0-1.1.6z" fill="currentColor" />
    </svg>
  )
}

export function ResetIcon({ size = 16 }: IconProps) {
  return (
    <svg viewBox="0 0 16 16" width={size} height={size} aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <path d="M2.8 8a5.2 5.2 0 1 0 1.5-3.7" />
      <path d="M2.5 2.6v3.2h3.2" />
    </svg>
  )
}

export function ClearIcon({ size = 16 }: IconProps) {
  return (
    <svg viewBox="0 0 16 16" width={size} height={size} aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 4.5h10M6.5 4.5V3h3v1.5M4.2 4.5l.6 8.3a.8.8 0 0 0 .8.7h4.8a.8.8 0 0 0 .8-.7l.6-8.3" />
    </svg>
  )
}

export function CheckIcon({ size = 14 }: IconProps) {
  return (
    <svg viewBox="0 0 16 16" width={size} height={size} aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3.2 8.4l3 3 6.6-7" />
    </svg>
  )
}

export function ArrowRightIcon({ size = 16 }: IconProps) {
  return (
    <svg viewBox="0 0 16 16" width={size} height={size} aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 8h9.5M8.8 4.3 12.5 8l-3.7 3.7" />
    </svg>
  )
}

export function RotateIcon({ size = 13 }: IconProps) {
  return (
    <svg viewBox="0 0 16 16" width={size} height={size} aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
      <path d="M13.2 8A5.2 5.2 0 1 1 11 3.8" />
      <path d="M13.5 1.8v3.4h-3.4" />
    </svg>
  )
}

/** Crisp vector thumbnails for the parts tray (56×40 viewBox). */
export function PartIcon({ type }: { type: PartType }) {
  switch (type) {
    case 'ramp':
      return (
        <svg viewBox="0 0 56 40" width="56" height="40" aria-hidden="true">
          <rect x="6" y="18" width="44" height="7" rx="2.5" fill="#2563eb" transform="rotate(-20 28 21.5)" />
          <rect x="14" y="20.5" width="4" height="2" rx="1" fill="#93c5fd" transform="rotate(-20 28 21.5)" />
          <rect x="26" y="20.5" width="4" height="2" rx="1" fill="#93c5fd" transform="rotate(-20 28 21.5)" />
          <rect x="38" y="20.5" width="4" height="2" rx="1" fill="#93c5fd" transform="rotate(-20 28 21.5)" />
        </svg>
      )
    case 'domino':
      return (
        <svg viewBox="0 0 56 40" width="56" height="40" aria-hidden="true">
          <rect x="24" y="5" width="8" height="30" rx="2" fill="#fff" stroke="#94a3b8" strokeWidth="1.2" />
          <rect x="25.5" y="19.5" width="5" height="1.2" fill="#94a3b8" />
          <circle cx="27" cy="10" r="1.1" fill="#0f172a" />
          <circle cx="29" cy="14.5" r="1.1" fill="#0f172a" />
          <circle cx="27" cy="25.5" r="1.1" fill="#0f172a" />
          <circle cx="29" cy="30" r="1.1" fill="#0f172a" />
        </svg>
      )
    case 'trampoline':
      return (
        <svg viewBox="0 0 56 40" width="56" height="40" aria-hidden="true">
          <rect x="8" y="17" width="40" height="10" rx="4" fill="#4c1d95" />
          <rect x="11" y="18.5" width="34" height="4.5" rx="2" fill="#a78bfa" />
          <path d="M14 20l3 4M22 20l3 4M30 20l3 4M38 20l3 4" stroke="#ddd6fe" strokeWidth="1.4" strokeLinecap="round" />
        </svg>
      )
    case 'fan':
      return (
        <svg viewBox="0 0 56 40" width="56" height="40" aria-hidden="true">
          <rect x="15" y="7" width="26" height="26" rx="7" fill="#0c4a6e" stroke="#0ea5e9" strokeWidth="1.6" />
          <g className="fan-blades" style={{ transformOrigin: '28px 20px' }}>
            <ellipse cx="28" cy="13.5" rx="3.2" ry="6" fill="#7dd3fc" />
            <ellipse cx="28" cy="13.5" rx="3.2" ry="6" fill="#7dd3fc" transform="rotate(120 28 20)" />
            <ellipse cx="28" cy="13.5" rx="3.2" ry="6" fill="#7dd3fc" transform="rotate(240 28 20)" />
          </g>
          <circle cx="28" cy="20" r="2.4" fill="#e0f2fe" />
          <path d="M45 14h5M45 20h7M45 26h5" stroke="#38bdf8" strokeWidth="1.6" strokeLinecap="round" opacity="0.8" />
        </svg>
      )
    case 'seesaw':
      return (
        <svg viewBox="0 0 56 40" width="56" height="40" aria-hidden="true">
          <path d="M20 34h16l-5-12h-6z" fill="#64748b" />
          <rect x="5" y="18" width="46" height="5.5" rx="2" fill="#059669" transform="rotate(-9 28 20.75)" />
          <circle cx="28" cy="21" r="2" fill="#fff" />
        </svg>
      )
  }
}
