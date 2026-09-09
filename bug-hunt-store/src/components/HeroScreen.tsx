import { BUGS } from '../lib/matcher'
import { TOTAL_BUGS } from '../types'

interface Props {
  onReset: () => void
}

const CONFETTI = Array.from({ length: 36 }, (_, i) => ({
  left: `${(i * 37) % 100}%`,
  delay: `${(i % 9) * 0.25}s`,
  duration: `${3 + (i % 5) * 0.5}s`,
  hue: (i * 47) % 360,
  rotate: `${(i * 83) % 360}deg`,
}))

export function HeroScreen({ onReset }: Props) {
  return (
    <div className="hero" role="dialog" aria-modal="true" aria-labelledby="hero-title">
      <div className="confetti" aria-hidden="true">
        {CONFETTI.map((c, i) => (
          <span
            key={i}
            style={{
              left: c.left,
              animationDelay: c.delay,
              animationDuration: c.duration,
              background: `hsl(${c.hue} 80% 60%)`,
              transform: `rotate(${c.rotate})`,
            }}
          />
        ))}
      </div>
      <div className="hero-card">
        <div className="hero-trophy" aria-hidden="true">
          <svg viewBox="0 0 24 24" fill="currentColor">
            <path d="M7 2h10v2h3v4a4 4 0 0 1-4 4h-.3A5 5 0 0 1 13 15.9V18h3v2H8v-2h3v-2.1A5 5 0 0 1 8.3 12H8a4 4 0 0 1-4-4V4h3V2Zm0 4H6v2a2 2 0 0 0 2 2V6h-1Zm10 0v4a2 2 0 0 0 2-2V6h-2Z" />
          </svg>
        </div>
        <p className="hero-kicker">
          {TOTAL_BUGS}/{TOTAL_BUGS} bugs found
        </p>
        <h1 id="hero-title">You're a QA hero.</h1>
        <p className="hero-sub">
          Wrong maths, broken sorting, an invisible overlay and an off-by-one — nothing got past you.
        </p>
        <ol className="hero-list">
          {BUGS.map((bug) => (
            <li key={bug.id}>
              <span className="chip chip-soft">{bug.area}</span>
              {bug.title}
            </li>
          ))}
        </ol>
        <button type="button" className="btn btn-primary" onClick={onReset}>
          Reset and hunt again
        </button>
      </div>
    </div>
  )
}
