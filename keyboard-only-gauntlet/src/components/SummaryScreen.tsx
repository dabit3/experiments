import { useEffect, useRef } from 'react'
import type { TaskResult } from '../App'
import { TASKS } from '../tasks'
import { formatDuration } from '../lib/keys'

interface Props {
  elapsed: number
  violations: number
  results: TaskResult[]
  onRestart: () => void
}

export function SummaryScreen({ elapsed, violations, results, onRestart }: Props) {
  const headingRef = useRef<HTMLHeadingElement>(null)
  const clean = violations === 0
  const totalKeys = results.reduce((sum, r) => sum + r.keys, 0)

  useEffect(() => {
    headingRef.current?.focus()
  }, [])

  return (
    <section className="card summary" aria-labelledby="summary-title" data-testid="summary">
      <p className="eyebrow">Gauntlet complete</p>
      <h2 id="summary-title" tabIndex={-1} ref={headingRef}>
        {clean ? 'Flawless run.' : 'Finished, but the mouse got involved.'}
      </h2>
      <div className="summary-grid">
        <div className="summary-stat">
          <span className="summary-label">Tasks</span>
          <span className="summary-value">
            {results.length}/{TASKS.length}
          </span>
        </div>
        <div className="summary-stat">
          <span className="summary-label">Time</span>
          <span className="summary-value mono">{formatDuration(elapsed)}</span>
        </div>
        <div className={`summary-stat ${clean ? 'good' : 'bad'}`}>
          <span className="summary-label">Mouse violations</span>
          <span className="summary-value" data-testid="summary-violations">
            {violations}
          </span>
        </div>
        <div className="summary-stat">
          <span className="summary-label">Keystrokes</span>
          <span className="summary-value">{totalKeys}</span>
        </div>
      </div>
      <table className="summary-table">
        <thead>
          <tr>
            <th scope="col">#</th>
            <th scope="col">Widget</th>
            <th scope="col">Time</th>
            <th scope="col">Keys</th>
          </tr>
        </thead>
        <tbody>
          {TASKS.map((task, i) => (
            <tr key={task.id}>
              <td>{i + 1}</td>
              <td>{task.title}</td>
              <td className="mono">{results[i] ? `${(results[i].ms / 1000).toFixed(1)}s` : '—'}</td>
              <td className="mono">{results[i]?.keys ?? '—'}</td>
            </tr>
          ))}
        </tbody>
      </table>
      <div className="intro-actions">
        <button type="button" className="btn btn-lg" onClick={onRestart}>
          Run it again
          <kbd>Enter</kbd>
        </button>
      </div>
    </section>
  )
}
