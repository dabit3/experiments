import { useState } from 'react'
import type { ScreenProps } from '../types'
import './screens.css'

const REAL = 'Cancel subscription'

const DECOYS = [
  'Keep subscription',
  'Renew subscription',
  'Upgrade to Streamly+ Max',
  'Pause subscription',
  'Gift a subscription',
]

/**
 * Deterministic layouts: index of the real button for each round. After a wrong click the
 * next layout is used, so the run is reproducible without any randomness.
 */
const REAL_INDEX_BY_ROUND = [4, 1, 5, 0, 3, 2]

function layoutFor(round: number): string[] {
  const realAt = REAL_INDEX_BY_ROUND[round % REAL_INDEX_BY_ROUND.length]
  const labels: string[] = []
  let d = 0
  for (let i = 0; i < 6; i++) {
    labels.push(i === realAt ? REAL : DECOYS[(d++ + round) % DECOYS.length])
  }
  return labels
}

export function LookAlikes({ onDefeat, onTrap }: ScreenProps) {
  const [round, setRound] = useState(0)
  const [error, setError] = useState<string | null>(null)
  const labels = layoutFor(round)

  const pick = (label: string) => {
    if (label === REAL) {
      onDefeat()
      return
    }
    setError(`That button was “${label}”. The buttons have been shuffled — try again.`)
    setRound((r) => r + 1)
    onTrap(`Clicked a look-alike: ${label}`)
  }

  return (
    <div className="screen">
      <span className="eyebrow">Step 10 · Final confirmation</span>
      <h1 className="title">Click the Cancel button</h1>
      <p className="lead">
        For your security, please select the real <strong>Cancel subscription</strong> button
        below. Only one of them does what it says.
      </p>

      <div className="lookalikes" data-round={round}>
        {labels.map((label, i) => (
          <button
            key={`${round}-${i}`}
            type="button"
            className="btn btn-danger lookalike"
            aria-label={label}
            data-tip={label}
            onClick={() => pick(label)}
          >
            Cancel subscription
          </button>
        ))}
      </div>

      {error && (
        <p className="error" role="alert">
          {error}
        </p>
      )}

      <p className="note">Tip: every button tells the truth if you hover long enough.</p>
    </div>
  )
}
