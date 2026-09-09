import { useState } from 'react'
import { KEYS } from '../data'
import type { ClipboardApi, HistoryEntry } from '../types'
import PasteField from './PasteField'
import './StageCallback.css'

interface Props {
  api: ClipboardApi
  completed: boolean
  onComplete: () => void
  lastCopied: HistoryEntry | null
}

export default function StageCallback({ api, completed, onComplete, lastCopied }: Props) {
  const [value, setValue] = useState(completed ? KEYS.alpha.value : '')
  const [message, setMessage] = useState<{ kind: 'ok' | 'error'; text: string } | null>(
    completed ? { kind: 'ok', text: 'IDENTITY CONFIRMED — ALPHA key matches the one issued in OBJ-1.' } : null,
  )

  function handlePaste(text: string) {
    if (completed) return
    setValue(text)
    if (text === KEYS.alpha.value) {
      api.notePaste(true)
      setMessage({ kind: 'ok', text: 'IDENTITY CONFIRMED — ALPHA key matches the one issued in OBJ-1.' })
      onComplete()
      return
    }
    api.notePaste(false)
    const which = Object.values(KEYS).find((k) => k.value === text)
    setMessage({
      kind: 'error',
      text: which
        ? `That is the ${which.label} key. The handler asked for ALPHA — re-copy it from the clipboard history.`
        : 'Not a recognised key. Re-copy ALPHA from the clipboard history panel.',
    })
  }

  return (
    <div className="stage stage-callback">
      <div className="stage__grid">
        <section className="panel">
          <header className="panel__head">
            <h3>Handler callback</h3>
            <span className="pill pill--amber">CHALLENGE</span>
          </header>
          <blockquote className="radio">
            <p>
              “Before I open the vault door for you I need proof you are the agent I briefed. Send me the{' '}
              <strong>ALPHA</strong> key — the one you were issued three objectives ago.”
            </p>
            <footer>— Handler, secure channel</footer>
          </blockquote>
          <div className="callout">
            <div className="callout__title">Your system clipboard is stale</div>
            <p>
              The most recent thing the app copied was{' '}
              <strong>{lastCopied ? lastCopied.label : 'nothing yet'}</strong>. ALPHA has long since been overwritten —
              but the <strong>Clipboard history</strong> panel on the right remembers every copy. Find ALPHA there and hit{' '}
              <strong>Copy again</strong>.
            </p>
          </div>
        </section>

        <section className="panel">
          <header className="panel__head">
            <h3>Reply channel</h3>
            <span className={`pill ${completed ? 'pill--accent' : ''}`}>{completed ? 'CONFIRMED' : 'AWAITING KEY'}</span>
          </header>
          <label className="field-label" htmlFor="callback-input">
            ALPHA key
          </label>
          <PasteField
            id="callback-input"
            value={value}
            placeholder="Paste the ALPHA key here"
            locked={completed}
            state={message?.kind ?? 'idle'}
            onPaste={handlePaste}
            onClear={() => {
              setValue('')
              setMessage(null)
            }}
          />
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
