import { useState } from 'react'
import { ACCESS_CODE, TRANSMISSION_LINES } from '../data'
import type { ClipboardApi } from '../types'
import PasteField from './PasteField'
import './StageIntercept.css'

interface Props {
  api: ClipboardApi
  completed: boolean
  onComplete: () => void
}

export default function StageIntercept({ api, completed, onComplete }: Props) {
  const [value, setValue] = useState(completed ? ACCESS_CODE : '')
  const [message, setMessage] = useState<{ kind: 'ok' | 'error'; text: string } | null>(
    completed ? { kind: 'ok', text: 'ACCESS GRANTED — keypad accepted the code.' } : null,
  )

  function handlePaste(text: string) {
    if (completed) return
    setValue(text.slice(0, 12))
    if (text === ACCESS_CODE) {
      api.notePaste(true)
      setMessage({ kind: 'ok', text: 'ACCESS GRANTED — keypad accepted the code.' })
      onComplete()
      return
    }
    api.notePaste(false)
    if (text.length !== 12) {
      setMessage({
        kind: 'error',
        text: `ACCESS DENIED — keypad wants exactly 12 characters, got ${text.length}. Select only the code.`,
      })
    } else {
      setMessage({ kind: 'error', text: 'ACCESS DENIED — that code is not current. Check the transmission.' })
    }
  }

  return (
    <div className="stage stage-intercept">
      <div className="stage__grid">
        <section className="panel">
          <header className="panel__head">
            <h3>Intercepted transmission</h3>
            <span className="pill pill--amber">{completed ? 'BURNED' : 'LIVE'}</span>
          </header>
          <pre className={`transmission ${completed ? 'transmission--burned' : ''}`} aria-label="Intercepted transmission">
            {TRANSMISSION_LINES.map((line, i) => {
              const idx = line.indexOf(ACCESS_CODE)
              if (idx === -1 || completed) {
                return (
                  <span key={i} className="transmission__line">
                    {completed && idx !== -1 ? line.replace(ACCESS_CODE, '████████████') : line}
                    {'\n'}
                  </span>
                )
              }
              return (
                <span key={i} className="transmission__line">
                  {line.slice(0, idx)}
                  <span className="transmission__code">{ACCESS_CODE}</span>
                  {line.slice(idx + ACCESS_CODE.length)}
                  {'\n'}
                </span>
              )
            })}
          </pre>
          <p className="hint">
            Select the current 12-character access code with the mouse, press <kbd>Ctrl</kbd>+<kbd>C</kbd>, then
            paste it into the keypad. The revoked code will not work.
          </p>
        </section>

        <section className="panel">
          <header className="panel__head">
            <h3>Sublevel 3 keypad</h3>
            <span className={`pill ${completed ? 'pill--accent' : ''}`}>{completed ? 'UNLOCKED' : 'ARMED'}</span>
          </header>
          <div className="keypad">
            <div className="keypad__slots" aria-hidden="true">
              {Array.from({ length: 12 }, (_, i) => (
                <span key={i} className={`keypad__slot ${value[i] ? 'keypad__slot--filled' : ''}`}>
                  {value[i] ?? ''}
                </span>
              ))}
            </div>
            <PasteField
              id="keypad-input"
              value={value}
              placeholder="Paste the access code here"
              maxLength={12}
              locked={completed}
              state={message?.kind ?? 'idle'}
              onPaste={handlePaste}
              onClear={() => {
                setValue('')
                setMessage(null)
              }}
            />
          </div>
          {message && (
            <div className={`status status--${message.kind}`} role="status">
              {message.text}
            </div>
          )}
        </section>
      </div>
    </div>
  )
}
