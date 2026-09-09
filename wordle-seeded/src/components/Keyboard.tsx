import type { KeyState } from '../lib/evaluate'
import './Keyboard.css'

const ROWS = [
  ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
  ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
  ['Enter', 'z', 'x', 'c', 'v', 'b', 'n', 'm', 'Backspace'],
]

interface KeyboardProps {
  states: Map<string, KeyState>
  onKey: (key: string) => void
  disabled: boolean
}

export function Keyboard({ states, onKey, disabled }: KeyboardProps) {
  return (
    <div className="keyboard" aria-label="On-screen keyboard">
      {ROWS.map((row, i) => (
        <div className="keyboard__row" key={i}>
          {row.map((key) => {
            const wide = key.length > 1
            const state = wide ? 'unused' : states.get(key) ?? 'unused'
            return (
              <button
                type="button"
                key={key}
                className={`key ${wide ? 'key--wide' : ''} key--${state}`}
                data-key={key}
                data-state={state}
                aria-label={key === 'Backspace' ? 'Backspace' : key === 'Enter' ? 'Enter' : key.toUpperCase()}
                disabled={disabled}
                onClick={(e) => {
                  e.currentTarget.blur()
                  onKey(key)
                }}
              >
                {key === 'Backspace' ? <BackspaceIcon /> : key}
              </button>
            )
          })}
        </div>
      ))}
    </div>
  )
}

function BackspaceIcon() {
  return (
    <svg viewBox="0 0 24 24" width="26" height="26" aria-hidden="true">
      <path
        fill="currentColor"
        d="M22 3H7c-.69 0-1.23.35-1.59.88L0 12l5.41 8.11c.36.53.9.89 1.59.89h15c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H7.07L2.4 12l4.66-7H22v14zm-11.59-2L14 13.41 17.59 17 19 15.59 15.41 12 19 8.41 17.59 7 14 10.59 10.41 7 9 8.41 12.59 12 9 15.59z"
      />
    </svg>
  )
}
