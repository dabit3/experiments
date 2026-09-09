import { STEPS, ownerLabel } from '../lib/mission'
import type { MissionState } from '../lib/types'

interface ChecklistProps {
  state: MissionState
}

export function Checklist({ state }: ChecklistProps) {
  const launched = state.phase === 'launched'
  return (
    <section className="panel checklist" aria-label="Launch checklist">
      <div className="panel__head">
        <span className="panel__title">Launch checklist</span>
        <span className="caption mono">
          {Math.min(state.stepIndex, STEPS.length)}/{STEPS.length}
        </span>
      </div>
      <ol className="checklist__list">
        {STEPS.map((step, i) => {
          const done = i < state.stepIndex || launched
          const active = !done && i === state.stepIndex && state.phase !== 'aborted'
          const cls = ['step', `step--${step.owner}`]
          if (done) cls.push('step--done')
          if (active) cls.push('step--active')
          return (
            <li key={step.id} className={cls.join(' ')} aria-current={active ? 'step' : undefined}>
              <span className="step__num mono">{done ? '✓' : i + 1}</span>
              <div className="step__body">
                <div className="step__title">{step.title}</div>
                <div className="step__owner caption">{ownerLabel(step.owner)}</div>
                {active && <p className="step__hint">{step.instruction}</p>}
              </div>
            </li>
          )
        })}
      </ol>
    </section>
  )
}
