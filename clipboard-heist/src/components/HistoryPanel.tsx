import { useState } from 'react'
import { readText } from '../lib/clipboard'
import type { HistoryEntry } from '../types'
import CopyButton from './CopyButton'
import './HistoryPanel.css'

interface Props {
  entries: HistoryEntry[]
  currentId: number | null
  onRecopy: (entry: HistoryEntry) => Promise<boolean>
}

type Peek = { kind: 'idle' } | { kind: 'text'; text: string } | { kind: 'blocked'; reason: string }

export default function HistoryPanel({ entries, currentId, onRecopy }: Props) {
  const [peek, setPeek] = useState<Peek>({ kind: 'idle' })

  async function handlePeek() {
    const result = await readText()
    setPeek(result.ok ? { kind: 'text', text: result.text } : { kind: 'blocked', reason: result.reason })
  }

  const ordered = entries.slice().reverse()

  return (
    <aside className="history" aria-label="Clipboard history">
      <header className="history__head">
        <div>
          <div className="history__eyebrow">Mission kit</div>
          <h2>Clipboard history</h2>
        </div>
        <span className="pill">{entries.length} {entries.length === 1 ? 'copy' : 'copies'}</span>
      </header>
      <p className="history__blurb">
        Everything copied through the app's copy buttons lands here. The system clipboard only holds the latest one —
        this panel holds them all, and <strong>Copy again</strong> puts any of them back.
      </p>

      {ordered.length === 0 ? (
        <div className="history__empty">
          <div className="history__empty-icon" aria-hidden="true">
            <svg viewBox="0 0 24 24" width="28" height="28">
              <rect x="8" y="3" width="8" height="4" rx="1.2" fill="none" stroke="currentColor" strokeWidth="1.6" />
              <path d="M8 5H6.5A1.5 1.5 0 0 0 5 6.5v13A1.5 1.5 0 0 0 6.5 21h11a1.5 1.5 0 0 0 1.5-1.5v-13A1.5 1.5 0 0 0 17.5 5H16" fill="none" stroke="currentColor" strokeWidth="1.6" />
            </svg>
          </div>
          Nothing copied yet. Vault keys and exfiltrated data will appear here.
        </div>
      ) : (
        <ol className="history__list">
          {ordered.map((entry) => {
            const isCurrent = entry.id === currentId
            return (
              <li key={entry.id} className={`history-item ${isCurrent ? 'history-item--current' : ''}`}>
                <div className="history-item__top">
                  <span className="history-item__obj">OBJ-{entry.objective}</span>
                  <span className="history-item__label">{entry.label}</span>
                  <span className="history-item__time">{entry.at}</span>
                </div>
                <code className="history-item__text" title={entry.text}>
                  {entry.text.length > 60 ? `${entry.text.slice(0, 60)}…` : entry.text}
                </code>
                <div className="history-item__actions">
                  {isCurrent ? (
                    <span className="history-item__current">IN SYSTEM CLIPBOARD</span>
                  ) : (
                    <CopyButton label="Copy again" size="sm" variant="ghost" onCopy={() => onRecopy(entry)} />
                  )}
                  {entry.html && <span className="history-item__tag">rich</span>}
                </div>
              </li>
            )
          })}
        </ol>
      )}

      <div className="peek">
        <div className="peek__row">
          <span className="peek__title">System clipboard</span>
          <button type="button" className="peek__btn" onClick={handlePeek}>
            Peek
          </button>
        </div>
        {peek.kind === 'text' && (
          <code className="peek__text">{peek.text.length ? (peek.text.length > 80 ? `${peek.text.slice(0, 80)}…` : peek.text) : '(empty)'}</code>
        )}
        {peek.kind === 'blocked' && (
          <div className="perm-helper" role="alert">
            <div className="perm-helper__title">Clipboard reading is blocked</div>
            <p>{peek.reason}</p>
            <ul>
              <li>
                Pasting still works: focus a field and press <kbd>Ctrl</kbd>+<kbd>V</kbd> — paste events never need
                permission.
              </li>
              <li>
                Chrome: click the padlock in the address bar → <em>Site settings</em> → <em>Clipboard</em> → Allow, then
                reload.
              </li>
              <li>Firefox and Safari do not let pages read the clipboard at all — use Ctrl+V.</li>
            </ul>
            <button type="button" className="peek__btn" onClick={handlePeek}>
              Retry
            </button>
          </div>
        )}
      </div>
    </aside>
  )
}
