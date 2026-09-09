import type { CSSProperties } from 'react'

interface RocketProps {
  launched: boolean
  engineHot: boolean
}

/** The pad view. Lift-off is driven by CSS classes on the wrapper. */
export function Rocket({ launched, engineHot }: RocketProps) {
  const cls = ['pad']
  if (launched) cls.push('pad--launched')
  if (engineHot) cls.push('pad--hot')
  return (
    <div className={cls.join(' ')} aria-hidden="true">
      <div className="pad__stars" />
      <div className="pad__stars pad__stars--far" />
      <div className="pad__smoke">
        {Array.from({ length: 10 }, (_, i) => (
          <span key={i} className="pad__puff" style={{ '--i': i } as CSSProperties} />
        ))}
      </div>
      <svg className="pad__rocket" viewBox="0 0 120 300" width="120" height="300">
        <defs>
          <linearGradient id="hull" x1="0" x2="1">
            <stop offset="0" stopColor="#9aa7b8" />
            <stop offset="0.35" stopColor="#f3f7fb" />
            <stop offset="0.7" stopColor="#d7dfe8" />
            <stop offset="1" stopColor="#7d8a9c" />
          </linearGradient>
          <linearGradient id="flame" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stopColor="#fff8e6" />
            <stop offset="0.35" stopColor="#ffd15c" />
            <stop offset="0.75" stopColor="#ff7a3d" />
            <stop offset="1" stopColor="rgba(255,90,60,0)" />
          </linearGradient>
        </defs>
        <g className="pad__flame">
          <path d="M44 232 C48 268 56 292 60 300 C64 292 72 268 76 232 Z" fill="url(#flame)" />
          <path d="M52 232 C54 254 58 270 60 278 C62 270 66 254 68 232 Z" fill="#fff8e6" opacity="0.9" />
        </g>
        <path d="M60 6 C82 34 90 70 90 118 L90 214 L30 214 L30 118 C30 70 38 34 60 6 Z" fill="url(#hull)" />
        <path d="M30 150 L8 200 L8 226 L30 214 Z" fill="#ffb347" />
        <path d="M90 150 L112 200 L112 226 L90 214 Z" fill="#ffb347" />
        <path d="M60 6 C70 20 76 34 79 50 L41 50 C44 34 50 20 60 6 Z" fill="#ff7a3d" />
        <circle cx="60" cy="92" r="11" fill="#0a0e14" stroke="#5ad1ff" strokeWidth="3" />
        <circle cx="60" cy="92" r="5" fill="#5ad1ff" opacity="0.8" />
        <rect x="30" y="160" width="60" height="6" fill="#0a0e14" opacity="0.35" />
        <rect x="30" y="196" width="60" height="6" fill="#0a0e14" opacity="0.35" />
        <path d="M38 214 L82 214 L74 234 L46 234 Z" fill="#3a4556" />
      </svg>
      <div className="pad__tower" />
      <div className="pad__ground" />
    </div>
  )
}
