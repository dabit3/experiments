import { PATTERNS, TOTAL_STEPS } from '../types'
import { formatDuration } from '../lib/format'
import './screens.css'

interface SuccessProps {
  elapsedMs: number
  traps: string[]
  onRestart: () => void
}

export function Success({ elapsedMs, traps, onRestart }: SuccessProps) {
  return (
    <div className="card success">
      <div className="success-badge" aria-hidden="true">
        <svg viewBox="0 0 24 24" width="40" height="40">
          <path
            d="M5 12.5l4.5 4.5L19 7.5"
            stroke="currentColor"
            strokeWidth="3"
            fill="none"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </svg>
      </div>
      <span className="eyebrow eyebrow-success">Done</span>
      <h1 className="title">Subscription cancelled.</h1>
      <p className="lead success-lead">
        Dark patterns defeated: <strong className="mono">{TOTAL_STEPS}/{TOTAL_STEPS}</strong>
      </p>

      <div className="success-stats">
        <div className="success-stat">
          <span className="success-num mono">{formatDuration(elapsedMs)}</span>
          <span className="success-label">time taken</span>
        </div>
        <div className="success-stat">
          <span className="success-num mono">{traps.length}</span>
          <span className="success-label">{traps.length === 1 ? 'trap triggered' : 'traps triggered'}</span>
        </div>
        <div className="success-stat">
          <span className="success-num mono">{TOTAL_STEPS}</span>
          <span className="success-label">screens survived</span>
        </div>
      </div>

      <ol className="defeated-list">
        {PATTERNS.map((p) => (
          <li key={p.id}>
            <span className="defeated-check" aria-hidden="true">
              ✓
            </span>
            <span>
              <strong>{p.name}</strong>
              <small>{p.trick}</small>
            </span>
          </li>
        ))}
      </ol>

      {traps.length > 0 && (
        <details className="trap-log">
          <summary>Trap log ({traps.length})</summary>
          <ul>
            {traps.map((t, i) => (
              <li key={`${i}-${t}`}>{t}</li>
            ))}
          </ul>
        </details>
      )}

      <div className="actions">
        <button type="button" className="btn btn-secondary" onClick={onRestart}>
          Run the gauntlet again
        </button>
      </div>
    </div>
  )
}
