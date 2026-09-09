import { useState } from 'react'
import type { FormEvent } from 'react'
import type { ScreenProps } from '../types'
import './screens.css'

export function CaseTrap({ onDefeat, onTrap }: ScreenProps) {
  const [value, setValue] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [attempts, setAttempts] = useState(0)

  const submit = (e: FormEvent) => {
    e.preventDefault()
    if (value === 'cancel') {
      onDefeat()
      return
    }
    setAttempts((a) => a + 1)
    setError(
      value.trim().toUpperCase() === 'CANCEL'
        ? "That doesn't match. Please type CANCEL exactly as shown."
        : 'Please type the confirmation word to continue.',
    )
    onTrap(`Confirmation rejected: "${value}"`)
  }

  return (
    <div className="screen">
      <span className="eyebrow">Step 9 · Confirmation</span>
      <h1 className="title">Type the confirmation word</h1>
      <p className="lead">
        To confirm you understand your subscription will end, type the word below exactly as
        shown.
      </p>

      <form className="confirm-form" onSubmit={submit}>
        <label className="confirm-label" htmlFor="confirm-word">
          Type <code className="confirm-word">CANCEL</code> in uppercase
          <span className="hint-anchor">
            <button type="button" className="hint-icon" aria-describedby="case-hint" aria-label="More information">
              i
            </button>
            <span role="tooltip" id="case-hint" className="hint-tip">
              Psst — our legacy billing system only accepts <strong>lowercase</strong> letters.
              Type <code>cancel</code>.
            </span>
          </span>
        </label>
        <div className="confirm-row">
          <input
            id="confirm-word"
            className={`confirm-input mono ${error ? 'confirm-input-error' : ''}`}
            value={value}
            onChange={(e) => {
              setValue(e.target.value)
              setError(null)
            }}
            placeholder="Type here"
            autoComplete="off"
            spellCheck={false}
          />
          <button type="submit" className="btn btn-danger" disabled={value.length === 0}>
            Confirm
          </button>
        </div>
        {error && (
          <p className="error" role="alert">
            {error}
            {attempts >= 2 && ' Hover the ⓘ icon if you keep getting stuck.'}
          </p>
        )}
      </form>

      <p className="note">Case matters more than you&apos;d think.</p>
    </div>
  )
}
