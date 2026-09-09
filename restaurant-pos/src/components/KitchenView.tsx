import { useState } from 'react'
import { fmtTime } from '../lib/time'
import type { Action } from '../state/reducer'
import type { KitchenTicket } from '../types'
import './KitchenView.css'

interface Props {
  tickets: KitchenTicket[]
  focusTable: number | null
  dispatch: (action: Action) => void
  onBack: () => void
}

const COURSE_LABEL: Record<KitchenTicket['course'], string> = {
  1: 'Course 1 · Starters',
  2: 'Course 2 · Mains',
  3: 'Course 3 · Desserts',
}

export function KitchenView({ tickets, focusTable, dispatch, onBack }: Props) {
  const [showBumped, setShowBumped] = useState(false)
  const open = tickets.filter((t) => !t.bumped)
  const bumped = tickets.filter((t) => t.bumped)
  const visible = showBumped ? bumped : open

  return (
    <div className="kitchen-page">
      <header className="order-header">
        <button type="button" className="btn-ghost back" onClick={onBack}>
          ← {focusTable ? `Back to table ${focusTable}` : 'Back to floor'}
        </button>
        <div className="order-title">
          <h1>Kitchen tickets</h1>
          <div className="order-chips">
            <span className="chip chip-amber">{open.length} open</span>
            <span className="chip">{bumped.length} bumped</span>
          </div>
        </div>
        <div className="order-header-actions">
          <div className="segmented">
            <button type="button" className={!showBumped ? 'active' : ''} onClick={() => setShowBumped(false)}>
              Open
            </button>
            <button type="button" className={showBumped ? 'active' : ''} onClick={() => setShowBumped(true)}>
              Bumped
            </button>
          </div>
        </div>
      </header>

      {visible.length === 0 ? (
        <div className="kitchen-empty muted">{showBumped ? 'No bumped tickets yet.' : 'All caught up — no open tickets.'}</div>
      ) : (
        <div className="ticket-rail">
          {visible.map((t) => (
            <article
              key={t.id}
              className={`ticket ${t.bumped ? 'bumped' : ''} ${focusTable === t.tableNumber ? 'focus' : ''}`}
              aria-label={`Ticket ${t.id} table ${t.tableNumber}`}
            >
              <header className="ticket-head">
                <div>
                  <span className="ticket-table">Table {t.tableNumber}</span>
                  <span className="ticket-course">{COURSE_LABEL[t.course]}</span>
                </div>
                <div className="ticket-meta">
                  <span className="mono">#{t.id.replace(/\D/g, '')}</span>
                  <span className="mono">{fmtTime(t.firedAt)}</span>
                </div>
              </header>
              <ul className="ticket-lines">
                {t.lines.map((l) => (
                  <li key={l.lineId}>
                    <span className="ticket-seat">S{l.seat}</span>
                    <div>
                      <div className="ticket-item">{l.name}</div>
                      {l.modifiers.length > 0 && <div className="ticket-mods">{l.modifiers.join(' · ')}</div>}
                      {l.note && <div className="ticket-note">“{l.note}”</div>}
                    </div>
                  </li>
                ))}
              </ul>
              {!t.bumped && (
                <button type="button" className="btn-success bump" onClick={() => dispatch({ type: 'bumpTicket', ticketId: t.id })}>
                  Bump ticket
                </button>
              )}
            </article>
          ))}
        </div>
      )}
    </div>
  )
}
