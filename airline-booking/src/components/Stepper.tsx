import { STEPS } from '../lib/steps'

interface Props {
  current: number
  onSelect: (n: number) => void
  locked: boolean
}

export function Stepper({ current, onSelect, locked }: Props) {
  return (
    <ol className="stepper" aria-label="Booking progress">
      {STEPS.map((s, i) => {
        const state = i < current ? 'done' : i === current ? 'active' : 'todo'
        const clickable = !locked && i < current
        return (
          <li key={s.id} className={`step ${state}`}>
            <button
              type="button"
              className="step-btn"
              disabled={!clickable}
              onClick={() => onSelect(i)}
              aria-current={i === current ? 'step' : undefined}
            >
              <span className="step-index">
                {state === 'done' ? (
                  <svg viewBox="0 0 16 16" width="12" height="12" aria-hidden>
                    <path d="M3 8.5l3 3 7-7" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                ) : (
                  i + 1
                )}
              </span>
              <span className="step-label">{s.label}</span>
            </button>
            {i < STEPS.length - 1 && <span className="step-line" aria-hidden />}
          </li>
        )
      })}
    </ol>
  )
}
