import { useState } from 'react'
import type { ScreenProps } from '../types'
import './screens.css'

/** Deterministic sequence of positions (percent of arena width/height). */
const POSITIONS: Array<{ x: number; y: number }> = [
  { x: 0, y: 0 },
  { x: 68, y: 62 },
  { x: 8, y: 66 },
]

const DODGES = POSITIONS.length - 1

export function DodgingButton({ onDefeat, onTrap }: ScreenProps) {
  const [dodges, setDodges] = useState(0)

  const dodge = () => {
    if (dodges < DODGES) setDodges((d) => d + 1)
  }

  const pos = POSITIONS[dodges]
  const settled = dodges >= DODGES

  return (
    <div className="screen">
      <span className="eyebrow">Step 2 · Confirm intent</span>
      <h1 className="title">Are you sure you want to continue?</h1>
      <p className="lead">
        Cancelling stops your next renewal on <strong>14 October</strong>. You&apos;ll keep access
        until then. Press <strong>Continue</strong> to proceed to the next step.
      </p>

      <div className="arena" aria-live="polite">
        <button
          type="button"
          className={`btn btn-primary dodger ${settled ? 'settled' : ''}`}
          style={{ left: `${pos.x}%`, top: `${pos.y}%` }}
          onMouseEnter={dodge}
          onClick={() => {
            if (settled) onDefeat()
            else dodge()
          }}
        >
          Continue
          <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true">
            <path
              d="M5 12h14m-6-6 6 6-6 6"
              stroke="currentColor"
              strokeWidth="2.4"
              fill="none"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        </button>

        <button
          type="button"
          className="btn btn-secondary arena-decoy"
          onClick={() => onTrap('Kept the subscription (decoy)')}
        >
          Never mind, keep Streamly+
        </button>
      </div>

      <p className="note">Having trouble clicking? Our buttons are just excited to see you.</p>
    </div>
  )
}
