import type { ScreenProps } from '../types'
import './screens.css'

export function Confirmshaming({ onDefeat, onTrap }: ScreenProps) {
  return (
    <div className="screen">
      <span className="eyebrow">Step 3 · Your benefits</span>
      <h1 className="title">You&apos;re about to lose everything you&apos;ve built</h1>
      <p className="lead">
        Your <strong>4,382 saved favourites</strong>, your <strong>212-day watch streak</strong> and
        your personalised recommendations will be permanently deleted. Members who cancel report
        feeling 37% more bored within a week.*
      </p>

      <div className="shame-stats">
        <div className="shame-stat">
          <span className="shame-num">4,382</span>
          <span className="shame-label">favourites lost</span>
        </div>
        <div className="shame-stat">
          <span className="shame-num">212</span>
          <span className="shame-label">day streak reset</span>
        </div>
        <div className="shame-stat">
          <span className="shame-num">∞</span>
          <span className="shame-label">regret</span>
        </div>
      </div>

      <div className="actions actions-stack">
        <button
          type="button"
          className="btn btn-primary btn-wide"
          onClick={() => onTrap('Kept your benefits (decoy)')}
        >
          Yes! Keep my benefits
        </button>
        <button type="button" className="shame-link" onClick={onDefeat}>
          No thanks, I don&apos;t care about my benefits
        </button>
      </div>

      <p className="note">*Made-up statistic. Boredom levels may vary.</p>
    </div>
  )
}
