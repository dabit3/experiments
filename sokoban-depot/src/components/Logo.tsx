/*
 * Brand mark: a stamped crate emblem plus a chunky two-layer wordmark.
 * The wordmark is rendered twice — a dark outlined copy for the stroke and
 * drop shadow, and a gradient copy clipped to the glyphs on top.
 */

export function Emblem({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 64 64" className={className} aria-hidden="true">
      <defs>
        <linearGradient id="em-badge" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#ffd166" />
          <stop offset="1" stopColor="#ff9f1c" />
        </linearGradient>
        <linearGradient id="em-wood" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#e2a458" />
          <stop offset="1" stopColor="#b8742d" />
        </linearGradient>
        <linearGradient id="em-wood-side" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#9a5f22" />
          <stop offset="1" stopColor="#6e4014" />
        </linearGradient>
      </defs>

      {/* badge */}
      <rect x="3" y="3" width="58" height="58" rx="16" fill="#151823" />
      <rect x="3" y="3" width="58" height="58" rx="16" fill="none" stroke="url(#em-badge)" strokeWidth="3.5" />
      <path d="M12 8 H52 A8 8 0 0 1 60 16 V20 Q32 14 4 20 V16 A8 8 0 0 1 12 8 Z" fill="#ffffff" opacity="0.05" />

      {/* floor shadow */}
      <ellipse cx="33" cy="53" rx="20" ry="3.5" fill="#000" opacity="0.55" />

      {/* crate: top face, side face, front face */}
      <path d="M14 22 L21 14 L53 14 L46 22 Z" fill="#f2c47e" stroke="#3a2410" strokeWidth="2.5" strokeLinejoin="round" />
      <path d="M46 22 L53 14 L53 42 L46 50 Z" fill="url(#em-wood-side)" stroke="#3a2410" strokeWidth="2.5" strokeLinejoin="round" />
      <rect x="14" y="22" width="32" height="28" rx="1.5" fill="url(#em-wood)" stroke="#3a2410" strokeWidth="2.5" />
      {/* planks */}
      <path d="M14 31 H46 M14 41 H46" stroke="#7a4b1a" strokeWidth="1.6" />
      {/* cross brace */}
      <path d="M17.5 25.5 L42.5 46.5 M42.5 25.5 L17.5 46.5" stroke="#3a2410" strokeWidth="2.8" strokeLinecap="round" />
      {/* corner brackets */}
      <path d="M14 27 V22 H19 M41 22 H46 V27 M14 45 V50 H19 M41 50 H46 V45" fill="none" stroke="#e8edf5" strokeWidth="2.2" />
      {/* label */}
      <rect x="26" y="32" width="8" height="8" rx="1.5" fill="#ffb020" stroke="#3a2410" strokeWidth="1.3" />
    </svg>
  )
}

export function Wordmark({ compact = false }: { compact?: boolean }) {
  return (
    <span className={`wordmark${compact ? ' wordmark-compact' : ''}`}>
      <span className="wm-line wm-main" data-text="Sokoban">
        <span className="wm-shadow" aria-hidden="true">
          Sokoban
        </span>
        <span className="wm-fill">Sokoban</span>
      </span>
      <span className="wm-tag">
        <span className="wm-tag-text">Depot</span>
      </span>
    </span>
  )
}

export function Logo({ className }: { className?: string }) {
  return (
    <span className={`logo${className ? ` ${className}` : ''}`}>
      <Emblem className="logo-emblem" />
      <Wordmark compact />
    </span>
  )
}
