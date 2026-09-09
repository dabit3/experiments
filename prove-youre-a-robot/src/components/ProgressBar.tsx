import { STAGES } from '../stages/types'
import './ProgressBar.css'

interface Props {
  /** Index of the current stage; STAGES.length once everything is done. */
  current: number
  /** Whether the current stage has already been passed. */
  currentPassed: boolean
}

export function ProgressBar({ current, currentPassed }: Props) {
  return (
    <ol className="progress" aria-label="Gauntlet progress">
      {STAGES.map((s, i) => {
        const done = i < current || (i === current && currentPassed)
        const active = i === current && !currentPassed
        return (
          <li key={s.id} className={`progress__step${done ? ' is-done' : ''}${active ? ' is-active' : ''}`}>
            <span className="progress__dot">{done ? '✓' : i + 1}</span>
            <span className="progress__label">{s.label}</span>
            <span className="progress__bar" />
          </li>
        )
      })}
    </ol>
  )
}
