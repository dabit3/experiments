import { useEffect, useRef } from 'react'
import { ROLE_SHORT, formatMet } from '../lib/mission'
import type { LogEntry } from '../lib/types'

interface StatusLogProps {
  entries: LogEntry[]
  title?: string
}

export function StatusLog({ entries, title = 'Status log' }: StatusLogProps) {
  const listRef = useRef<HTMLOListElement>(null)

  useEffect(() => {
    const el = listRef.current
    if (el) el.scrollTop = el.scrollHeight
  }, [entries.length])

  return (
    <section className="panel log" aria-label={title}>
      <div className="panel__head">
        <span className="panel__title">{title}</span>
        <span className="caption">{entries.length} entries</span>
      </div>
      {entries.length === 0 ? (
        <p className="log__empty">Waiting for the Main window…</p>
      ) : (
        <ol className="log__list" ref={listRef} aria-live="polite">
          {entries.map((entry) => (
            <li key={entry.id} className={`log__row log__row--${entry.level}`}>
              <span className="log__met">{formatMet(entry.met)}</span>
              <span className={`log__src log__src--${entry.source}`}>{ROLE_SHORT[entry.source]}</span>
              <span className="log__text">{entry.text}</span>
            </li>
          ))}
        </ol>
      )}
    </section>
  )
}
