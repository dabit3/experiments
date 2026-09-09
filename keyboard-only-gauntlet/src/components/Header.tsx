import type { Phase } from '../App'
import { TASKS } from '../tasks'
import { formatDuration } from '../lib/keys'

interface Props {
  phase: Phase
  elapsed: number
  violations: number
  doneCount: number
}

export function Header({ phase, elapsed, violations, doneCount }: Props) {
  return (
    <header className="topbar">
      <div className="brand">
        <span className="brand-mark" aria-hidden="true">
          ⌨
        </span>
        <div>
          <h1>Keyboard-Only Gauntlet</h1>
          <p className="brand-sub">The mouse is disabled. Six ARIA widgets. Zero clicks.</p>
        </div>
      </div>
      <div className="stats">
        <div className="stat">
          <span className="stat-label">Progress</span>
          <span className="stat-value">
            {doneCount}
            <span className="stat-dim">/{TASKS.length}</span>
          </span>
        </div>
        <div className="stat">
          <span className="stat-label">Time</span>
          <span className={`stat-value mono${phase === 'running' ? ' live' : ''}`}>{formatDuration(elapsed)}</span>
        </div>
        <div className={`stat violations${violations > 0 ? ' bad' : ''}`} data-testid="violations">
          <span className="stat-label">Mouse violations</span>
          <span className="stat-value">{violations}</span>
        </div>
      </div>
    </header>
  )
}
