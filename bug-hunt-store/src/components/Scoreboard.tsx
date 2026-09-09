import { BUGS } from '../lib/matcher'
import { TOTAL_BUGS } from '../types'

interface Props {
  found: string[]
  onClose: () => void
  onReset: () => void
}

export function Scoreboard({ found, onClose, onReset }: Props) {
  return (
    <div className="modal-scrim" onClick={onClose}>
      <div className="modal modal-narrow" role="dialog" aria-modal="true" aria-labelledby="scoreboard-title" onClick={(e) => e.stopPropagation()}>
        <header className="modal-header">
          <h2 id="scoreboard-title">
            Bugs found: {found.length}/{TOTAL_BUGS}
          </h2>
          <button type="button" className="icon-btn" onClick={onClose} aria-label="Close scoreboard">
            ×
          </button>
        </header>
        <ol className="found-list">
          {BUGS.map((bug, i) => {
            const isFound = found.includes(bug.id)
            return (
              <li key={bug.id} className={isFound ? 'found' : 'hidden-bug'}>
                <span className="found-index">{i + 1}</span>
                <span className="found-title">{isFound ? bug.title : 'Not found yet'}</span>
                <span className="chip chip-soft">{isFound ? bug.area : '?'}</span>
              </li>
            )
          })}
        </ol>
        <footer className="modal-footer">
          <button type="button" className="btn btn-ghost" onClick={onReset}>
            Reset hunt
          </button>
          <button type="button" className="btn btn-primary" onClick={onClose}>
            Back to hunting
          </button>
        </footer>
      </div>
    </div>
  )
}
