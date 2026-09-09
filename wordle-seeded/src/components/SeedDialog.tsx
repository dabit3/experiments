import { useState, type FormEvent } from 'react'
import { randomSeed } from '../lib/words'
import { Modal } from './Modal'
import './SeedDialog.css'

interface SeedDialogProps {
  open: boolean
  seed: number
  onClose: () => void
  onPlaySeed: (seed: number) => void
}

export function SeedDialog({ open, seed, onClose, onPlaySeed }: SeedDialogProps) {
  const [value, setValue] = useState(String(seed))

  const submit = (e: FormEvent) => {
    e.preventDefault()
    const n = Number(value)
    if (!Number.isInteger(n) || n < 0) return
    onPlaySeed(n)
    onClose()
  }

  return (
    <Modal open={open} onClose={onClose} title="Choose a seed">
      <p className="seed__lead">
        Every seed maps to exactly one answer. Share a seed and a friend gets the same puzzle.
      </p>
      <form className="seed__form" onSubmit={submit}>
        <label className="seed__field">
          <span className="seed__hash">#</span>
          <input
            className="seed__input"
            type="number"
            inputMode="numeric"
            min={0}
            step={1}
            value={value}
            onChange={(e) => setValue(e.target.value)}
            aria-label="Seed number"
          />
        </label>
        <button type="submit" className="button button--primary">
          Play seed
        </button>
      </form>
      <div className="seed__shortcuts">
        <button type="button" className="button button--secondary" onClick={() => setValue(String(seed + 1))}>
          Next (#{seed + 1})
        </button>
        <button
          type="button"
          className="button button--secondary"
          onClick={() => setValue(String(randomSeed()))}
        >
          Random
        </button>
      </div>
    </Modal>
  )
}
