import { useEffect, useState } from 'react'
import type { ScreenProps } from '../types'
import './screens.css'

const WAIT_SECONDS = 10

export function Countdown({ onDefeat, onTrap }: ScreenProps) {
  const [remaining, setRemaining] = useState(WAIT_SECONDS)

  useEffect(() => {
    if (remaining <= 0) return
    const t = window.setTimeout(() => setRemaining((r) => r - 1), 1000)
    return () => window.clearTimeout(t)
  }, [remaining])

  const ready = remaining <= 0
  const progress = ((WAIT_SECONDS - remaining) / WAIT_SECONDS) * 100

  return (
    <div className="screen">
      <span className="eyebrow">Step 4 · Account review</span>
      <h1 className="title">
        {ready ? 'Review complete' : 'Reviewing your account…'}
      </h1>
      <p className="lead">
        {ready
          ? 'Thanks for waiting. You may now continue with your cancellation.'
          : 'For security reasons we need a moment to review your account before you can cancel. Please do not close this window.'}
      </p>

      <div className="ring-wrap" aria-live="polite">
        <div
          className={`ring ${ready ? 'ring-done' : ''}`}
          style={{ ['--p' as string]: `${progress}%` }}
        >
          <span className="ring-num mono">{ready ? '✓' : remaining}</span>
        </div>
        <div className="ring-copy">
          <strong>{ready ? 'You can cancel now' : `${remaining} second${remaining === 1 ? '' : 's'} remaining`}</strong>
          <span>{ready ? 'The Cancel button is enabled.' : 'Cancel will unlock when the timer ends.'}</span>
        </div>
      </div>

      <div className="actions">
        <button
          type="button"
          className="btn btn-danger"
          disabled={!ready}
          onClick={onDefeat}
        >
          {ready ? 'Cancel subscription' : `Cancel subscription (${remaining})`}
        </button>
        <button
          type="button"
          className="btn btn-primary"
          onClick={() => onTrap('Skipped the wait by keeping the subscription (decoy)')}
        >
          Skip the wait — keep Streamly+
        </button>
      </div>
    </div>
  )
}
