import type { Phase, TaskResult } from '../App'
import { TASKS } from '../tasks'

interface Props {
  phase: Phase
  current: number
  results: TaskResult[]
}

export function Checklist({ phase, current, results }: Props) {
  return (
    <aside className="checklist" aria-label="Progress">
      <h2 className="checklist-title">Gauntlet</h2>
      <ol className="checklist-items">
        {TASKS.map((task, i) => {
          const done = phase === 'done' || (phase === 'running' && i < current)
          const active = phase === 'running' && i === current
          const status = done ? 'done' : active ? 'active' : 'todo'
          return (
            <li key={task.id} className={`check-item ${status}`} aria-current={active ? 'step' : undefined}>
              <span className="check-bullet" aria-hidden="true">
                {done ? (
                  <svg viewBox="0 0 16 16">
                    <path d="M3 8.5l3 3 7-7" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                ) : (
                  i + 1
                )}
              </span>
              <span className="check-text">
                <span className="check-title">{task.title}</span>
                <span className="check-pattern">{task.pattern}</span>
              </span>
              <span className="check-meta">
                {done && results[i] && `${(results[i].ms / 1000).toFixed(1)}s`}
                {active && 'now'}
              </span>
            </li>
          )
        })}
      </ol>
      <div className="checklist-foot">
        <p>Every widget is hand-built ARIA: roving tabindex, aria-activedescendant, focus traps.</p>
      </div>
    </aside>
  )
}
