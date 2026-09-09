import { useId } from 'react'

interface LogoProps {
  size?: number
  className?: string
}

/**
 * Crest-style emblem: gold-edged shield, targeting reticle, destroyer
 * silhouette over the waterline. Mirrors public/favicon.svg.
 */
export function Logo({ size = 44, className }: LogoProps) {
  const uid = useId().replace(/[^a-zA-Z0-9]/g, '')
  const id = (name: string) => `bc-${name}-${uid}`
  return (
    <svg
      viewBox="0 0 64 64"
      width={size}
      height={size}
      className={className}
      aria-hidden="true"
      focusable="false"
    >
      <defs>
        <linearGradient id={id('gold')} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#ffe9a8" />
          <stop offset="0.45" stopColor="#e6b04a" />
          <stop offset="1" stopColor="#8f5d12" />
        </linearGradient>
        <linearGradient id={id('gold2')} x1="0" y1="1" x2="0" y2="0">
          <stop offset="0" stopColor="#ffe9a8" />
          <stop offset="1" stopColor="#c9902c" />
        </linearGradient>
        <linearGradient id={id('steel')} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#f6f8fb" />
          <stop offset="0.55" stopColor="#c3ceda" />
          <stop offset="1" stopColor="#7d8ea3" />
        </linearGradient>
        <radialGradient id={id('deep')} cx="0.5" cy="0.35" r="0.75">
          <stop offset="0" stopColor="#173a68" />
          <stop offset="0.6" stopColor="#0a1a33" />
          <stop offset="1" stopColor="#040912" />
        </radialGradient>
      </defs>
      <path
        d="M32 2.5 58 10.5V31.5C58 44.8 47.1 55.6 32 61.5 16.9 55.6 6 44.8 6 31.5V10.5Z"
        fill={`url(#${id('deep')})`}
        stroke={`url(#${id('gold')})`}
        strokeWidth="2.6"
        strokeLinejoin="round"
      />
      <path
        d="M32 7.6 53.2 14.1V31.5C53.2 42.4 44.5 51.3 32 56.6 19.5 51.3 10.8 42.4 10.8 31.5V14.1Z"
        fill="none"
        stroke="#f2cf7a"
        strokeOpacity="0.28"
        strokeWidth="1"
      />
      <circle
        cx="32"
        cy="32"
        r="14"
        fill="none"
        stroke="#63e0d2"
        strokeOpacity="0.6"
        strokeWidth="1.2"
        strokeDasharray="17 5"
        strokeDashoffset="-2.5"
      />
      <path
        d="M32 16v4.5M32 43.5V48M16 32h4.5M43.5 32H48"
        stroke="#63e0d2"
        strokeOpacity="0.9"
        strokeWidth="1.5"
        strokeLinecap="round"
      />
      <path d="M13 34.2h34.6l4.2-3.2-2.6 7.6H18.6l-3.6-2.4Z" fill={`url(#${id('steel')})`} />
      <path d="M25.5 34.2v-4h11.8v4Z" fill={`url(#${id('steel')})`} />
      <path d="M28 30.2v-3.4h6.2v3.4Z" fill="#dfe7f1" />
      <path d="M34.8 30.2 35.6 27.4h2.6l.6 2.8Z" fill="#b9c6d6" />
      <path d="M39.6 34.2v-2.4h4.4v2.4Z" fill="#dfe7f1" />
      <path d="M44 32.9h3.6" stroke="#eef3f9" strokeWidth="1.3" strokeLinecap="round" />
      <path
        d="M29.6 26.8 31 20.6M32.4 26.8 31 20.6"
        stroke="#eef3f9"
        strokeWidth="1.1"
        strokeLinecap="round"
      />
      <path d="M31 20.6l3.6 1.1-3.6 1.3Z" fill="#f0b73f" />
      <path
        d="M14.5 42c3.2-2.4 6.4 2.4 9.6 0s6.4 2.4 9.6 0 6.4 2.4 9.6 0 4.2-1.6 6.2 0"
        fill="none"
        stroke="#63e0d2"
        strokeOpacity="0.95"
        strokeWidth="1.5"
        strokeLinecap="round"
      />
      <path
        d="M19 46.6c2.6-1.9 5.2 1.9 7.8 0s5.2 1.9 7.8 0 5.2 1.9 7.8 0"
        fill="none"
        stroke="#63e0d2"
        strokeOpacity="0.4"
        strokeWidth="1.2"
        strokeLinecap="round"
      />
      <path
        d="M32 5.2l1.15 2.35 2.6.38-1.88 1.83.44 2.58L32 11.12l-2.31 1.22.44-2.58-1.88-1.83 2.6-.38Z"
        fill={`url(#${id('gold2')})`}
      />
    </svg>
  )
}
