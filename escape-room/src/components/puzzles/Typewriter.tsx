import { useEffect, useRef, useState } from 'react'
import type { Stage } from '../../game'

interface Props {
  stage: Stage
  onSubmit: (word: string) => boolean
}

export function Typewriter({ stage, onSubmit }: Props) {
  const [value, setValue] = useState('')
  const [shake, setShake] = useState(false)
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    inputRef.current?.focus()
  }, [])

  const submit = () => {
    if (value.length !== 3) return
    const ok = onSubmit(value)
    if (!ok) {
      setShake(true)
      window.setTimeout(() => setShake(false), 500)
    }
  }

  if (stage < 2) {
    return (
      <div className="puzzle">
        <p className="puzzle-lead">An old Remington, oiled and ready. The room is too dark to see the keys clearly, and you have nothing to write yet.</p>
      </div>
    )
  }
  if (stage > 2) {
    return (
      <div className="puzzle">
        <div className="tw-page">
          <p>OWL</p>
          <p className="tw-hidden">The card on the corkboard is written in lemon ink. Warm it under your hand.</p>
        </div>
      </div>
    )
  }
  return (
    <div className="puzzle">
      <p className="puzzle-lead">Type the three-letter word the lamp is spelling, then strike Return.</p>
      <form
        className={`tw-form ${shake ? 'shake' : ''}`}
        onSubmit={(e) => {
          e.preventDefault()
          submit()
        }}
      >
        <input
          ref={inputRef}
          className="tw-input"
          value={value}
          maxLength={3}
          autoCapitalize="characters"
          spellCheck={false}
          onChange={(e) => setValue(e.target.value.replace(/[^a-zA-Z]/g, '').toUpperCase())}
          aria-label="Three letters"
          placeholder="_ _ _"
        />
        <button type="submit" className="btn btn-primary" disabled={value.length !== 3}>
          Strike
        </button>
      </form>
    </div>
  )
}
