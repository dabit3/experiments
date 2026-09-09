import { BUGS } from '../lib/matcher'
import { TOTAL_BUGS } from '../types'
import { Wordmark } from './Wordmark'

interface Props {
  onReset: () => void
}

export function HeroScreen({ onReset }: Props) {
  return (
    <div className="hero" role="dialog" aria-modal="true" aria-labelledby="hero-title">
      <header className="hero-top">
        <Wordmark size="hero" />
        <span className="hero-kicker">
          {TOTAL_BUGS}/{TOTAL_BUGS} bugs found
        </span>
      </header>

      <div className="hero-body">
        <h1 id="hero-title">
          <span className="hero-line">You're a</span>
          <span className="hero-line hero-line-big">QA hero.</span>
        </h1>
        <p className="hero-sub">
          Wrong maths, broken sorting, an invisible overlay and an off-by-one — nothing got past you.
        </p>
      </div>

      <ol className="hero-list">
        {BUGS.map((bug, i) => (
          <li key={bug.id}>
            <span className="hero-index">{String(i + 1).padStart(2, '0')}</span>
            <span className="hero-bug">{bug.title}</span>
            <span className="hero-area">{bug.area}</span>
          </li>
        ))}
      </ol>

      <footer className="hero-footer">
        <button type="button" className="btn btn-invert btn-lg" onClick={onReset}>
          Reset and hunt again
        </button>
      </footer>
    </div>
  )
}
