import { useMemo, useState } from 'react'
import { hasRequiredModifiers, MENU } from '../data/menu'
import { checkTotals, courseLabel, hasAutoGratuity, lineTotal } from '../lib/calc'
import { fmt, fmtDelta } from '../lib/money'
import { fmtTime, nowIso } from '../lib/time'
import type { Action } from '../state/reducer'
import { CATEGORIES, type Category, type Check, type Course, type MenuItem, type OrderLine, type Table } from '../types'
import { DiscountModal, NoteModal, VoidModal } from './LineModals'
import { ModifierModal, type ModifierResult } from './ModifierModal'
import './OrderView.css'

interface Props {
  table: Table
  check: Check
  dispatch: (action: Action) => void
  onBack: () => void
  onPay: () => void
  onKitchen: () => void
}

type ModalState =
  | { kind: 'none' }
  | { kind: 'modifiers'; item: MenuItem }
  | { kind: 'note'; line: OrderLine }
  | { kind: 'void'; line: OrderLine }
  | { kind: 'discount' }

export function OrderView({ table, check, dispatch, onBack, onPay, onKitchen }: Props) {
  const [activeSeat, setActiveSeat] = useState(1)
  const [category, setCategory] = useState<Category>('Mains')
  const [modal, setModal] = useState<ModalState>({ kind: 'none' })
  const [flash, setFlash] = useState<string | null>(null)

  const totals = checkTotals(check)
  const seats = Array.from({ length: check.partySize }, (_, i) => i + 1)
  const items = useMemo(() => MENU.filter((m) => m.category === category), [category])

  const pendingByCourse = (course: Course) =>
    check.lines.filter((l) => l.status === 'pending' && l.course === course).length

  const addItem = (item: MenuItem, result: ModifierResult) => {
    dispatch({
      type: 'addLine',
      checkId: check.id,
      seat: result.seat,
      menuItemId: item.id,
      name: item.name,
      basePrice: item.price,
      modifiers: result.modifiers,
      note: result.note,
      course: result.course,
    })
    setModal({ kind: 'none' })
    setFlash(`${item.name} added to Seat ${result.seat}`)
    window.setTimeout(() => setFlash(null), 1600)
  }

  const onItemClick = (item: MenuItem) => {
    if (hasRequiredModifiers(item)) {
      setModal({ kind: 'modifiers', item })
    } else {
      addItem(item, { modifiers: [], note: '', course: item.defaultCourse, seat: activeSeat })
    }
  }

  const fire = (course: Course) => {
    dispatch({ type: 'fireCourse', checkId: check.id, course, firedAt: nowIso() })
    setFlash(`${courseLabel(course)} fired to kitchen`)
    window.setTimeout(() => setFlash(null), 1800)
  }

  const cycleCourse = (line: OrderLine) => {
    const next = (line.course === 3 ? 1 : line.course + 1) as Course
    dispatch({ type: 'setCourse', checkId: check.id, lineId: line.id, course: next })
  }

  const activeCount = check.lines.filter((l) => l.status !== 'voided').length

  return (
    <div className="order-page">
      <header className="order-header">
        <button type="button" className="btn-ghost back" onClick={onBack}>
          ← Floor
        </button>
        <div className="order-title">
          <h1>Table {table.number}</h1>
          <div className="order-chips">
            <span className="chip">Party of {check.partySize}</span>
            <span className="chip">Opened {fmtTime(check.openedAt)}</span>
            {hasAutoGratuity(check) && <span className="chip chip-amber">18% auto-gratuity</span>}
            {check.discount && <span className="chip chip-green">{check.discount.label}</span>}
          </div>
        </div>
        <div className="order-header-actions">
          <button type="button" className="btn-ghost" onClick={onKitchen}>
            Kitchen tickets
          </button>
          <button type="button" className="btn-primary" onClick={onPay} disabled={activeCount === 0}>
            Split &amp; pay
          </button>
        </div>
      </header>

      <div className="order-body">
        <section className="check-panel" aria-label="Check">
          <div className="seat-tabs" role="tablist" aria-label="Seats">
            {seats.map((n) => {
              const count = check.lines.filter((l) => l.seat === n && l.status !== 'voided').length
              return (
                <button
                  type="button"
                  key={n}
                  role="tab"
                  aria-selected={activeSeat === n}
                  className={`seat-tab ${activeSeat === n ? 'active' : ''}`}
                  onClick={() => setActiveSeat(n)}
                >
                  <span>Seat {n}</span>
                  <small>{count === 0 ? 'empty' : `${count} item${count === 1 ? '' : 's'}`}</small>
                </button>
              )
            })}
          </div>

          <div className="lines">
            {check.lines.length === 0 && (
              <div className="empty-check">
                <strong>No items yet</strong>
                <span className="muted">Pick a seat, then tap menu items on the right.</span>
              </div>
            )}
            {seats.map((n) => {
              const seatLines = check.lines.filter((l) => l.seat === n)
              if (seatLines.length === 0) return null
              const seatTotal = seatLines.filter((l) => l.status !== 'voided').reduce((s, l) => s + lineTotal(l), 0)
              return (
                <div key={n} className={`seat-group ${activeSeat === n ? 'active' : ''}`}>
                  <button type="button" className="seat-group-header" onClick={() => setActiveSeat(n)}>
                    <span>Seat {n}</span>
                    <span className="mono">{fmt(seatTotal)}</span>
                  </button>
                  {seatLines.map((line) => (
                    <LineRow
                      key={line.id}
                      line={line}
                      onNote={() => setModal({ kind: 'note', line })}
                      onVoid={() => setModal({ kind: 'void', line })}
                      onCycleCourse={() => cycleCourse(line)}
                    />
                  ))}
                </div>
              )
            })}
          </div>

          <div className="totals">
            <div className="totals-row">
              <span>Subtotal</span>
              <span>{fmt(totals.subtotal)}</span>
            </div>
            {check.discount && (
              <div className="totals-row discount">
                <span>Discount · {check.discount.label}</span>
                <span>−{fmt(totals.discount)}</span>
              </div>
            )}
            <div className="totals-row">
              <span>Tax 8.875%</span>
              <span>{fmt(totals.tax)}</span>
            </div>
            <div className="totals-row">
              <span>
                Auto-gratuity 18%
                {!hasAutoGratuity(check) && <span className="muted"> · parties of 6+</span>}
              </span>
              <span>{fmt(totals.gratuity)}</span>
            </div>
            <div className="totals-row total">
              <span>Total</span>
              <span>{fmt(totals.total)}</span>
            </div>
          </div>

          <div className="check-actions">
            {([1, 2, 3] as Course[]).map((c) => {
              const n = pendingByCourse(c)
              return (
                <button
                  type="button"
                  key={c}
                  className={`fire-btn ${n > 0 ? 'ready' : ''}`}
                  disabled={n === 0}
                  onClick={() => fire(c)}
                >
                  <span>Fire course {c}</span>
                  <small>{n === 0 ? 'nothing pending' : `${n} item${n === 1 ? '' : 's'}`}</small>
                </button>
              )
            })}
            <button type="button" className="btn-ghost" onClick={() => setModal({ kind: 'discount' })}>
              {check.discount ? 'Edit discount' : 'Discount'}
            </button>
          </div>
        </section>

        <section className="menu-panel" aria-label="Menu">
          <div className="menu-header">
            <div className="category-tabs" role="tablist" aria-label="Menu categories">
              {CATEGORIES.map((c) => (
                <button
                  type="button"
                  key={c}
                  role="tab"
                  aria-selected={category === c}
                  className={`category-tab ${category === c ? 'active' : ''}`}
                  onClick={() => setCategory(c)}
                >
                  {c}
                </button>
              ))}
            </div>
            <div className="adding-to">
              Adding to <strong>Seat {activeSeat}</strong>
            </div>
          </div>

          <div className="menu-grid">
            {items.map((item) => {
              const required = hasRequiredModifiers(item)
              return (
                <div key={item.id} className="menu-card">
                  <button type="button" className="menu-card-main" onClick={() => onItemClick(item)}>
                    <span className="menu-card-name">{item.name}</span>
                    <span className="menu-card-desc">{item.description}</span>
                    <span className="menu-card-foot">
                      <span className="menu-card-price">{fmt(item.price)}</span>
                      {required && <span className="chip chip-accent">Modifiers</span>}
                    </span>
                  </button>
                  {!required && item.modifierGroups.length > 0 && (
                    <button
                      type="button"
                      className="menu-card-customize"
                      onClick={() => setModal({ kind: 'modifiers', item })}
                    >
                      Customize
                    </button>
                  )}
                </div>
              )
            })}
          </div>
        </section>
      </div>

      {flash && (
        <div className="flash" role="status">
          {flash}
        </div>
      )}

      {modal.kind === 'modifiers' && (
        <ModifierModal
          item={modal.item}
          seat={activeSeat}
          partySize={check.partySize}
          onClose={() => setModal({ kind: 'none' })}
          onAdd={(result) => addItem(modal.item, result)}
        />
      )}
      {modal.kind === 'note' && (
        <NoteModal
          line={modal.line}
          onClose={() => setModal({ kind: 'none' })}
          onSave={(note) => {
            dispatch({ type: 'setNote', checkId: check.id, lineId: modal.line.id, note })
            setModal({ kind: 'none' })
          }}
        />
      )}
      {modal.kind === 'void' && (
        <VoidModal
          line={modal.line}
          onClose={() => setModal({ kind: 'none' })}
          onVoid={(reason) => {
            dispatch({ type: 'voidLine', checkId: check.id, lineId: modal.line.id, reason })
            setModal({ kind: 'none' })
          }}
        />
      )}
      {modal.kind === 'discount' && (
        <DiscountModal
          subtotal={totals.subtotal}
          current={check.discount}
          onClose={() => setModal({ kind: 'none' })}
          onApply={(discount) => {
            dispatch({ type: 'setDiscount', checkId: check.id, discount })
            setModal({ kind: 'none' })
          }}
        />
      )}
    </div>
  )
}

function LineRow({
  line,
  onNote,
  onVoid,
  onCycleCourse,
}: {
  line: OrderLine
  onNote: () => void
  onVoid: () => void
  onCycleCourse: () => void
}) {
  const voided = line.status === 'voided'
  return (
    <div className={`line status-${line.status}`}>
      <div className="line-main">
        <div className="line-name">
          <span>{line.name}</span>
          <span className="line-price mono">{fmt(lineTotal(line))}</span>
        </div>
        {line.modifiers.length > 0 && (
          <div className="line-mods">
            {line.modifiers.map((m) => (
              <span key={`${m.groupId}-${m.optionId}`}>
                {m.optionName}
                {m.delta !== 0 && <em> {fmtDelta(m.delta)}</em>}
              </span>
            ))}
          </div>
        )}
        {line.note && <div className="line-note">“{line.note}”</div>}
        {voided && <div className="line-void">Voided · {line.voidReason}</div>}
      </div>
      <div className="line-side">
        <div className="line-chips">
          <button
            type="button"
            className={`chip course-chip ${line.status === 'pending' ? 'editable' : ''}`}
            onClick={onCycleCourse}
            disabled={line.status !== 'pending'}
            title={line.status === 'pending' ? 'Change course' : undefined}
          >
            C{line.course}
          </button>
          <span
            className={`chip ${line.status === 'fired' ? 'chip-green' : line.status === 'voided' ? 'chip-red' : 'chip-amber'}`}
          >
            {line.status === 'fired' ? 'Fired' : line.status === 'voided' ? 'Void' : 'Pending'}
          </span>
        </div>
        {!voided && (
          <div className="line-actions">
            <button type="button" className="btn-sm" onClick={onNote}>
              {line.note ? 'Edit note' : 'Note'}
            </button>
            <button type="button" className="btn-sm btn-danger" onClick={onVoid}>
              Void
            </button>
          </div>
        )}
      </div>
    </div>
  )
}
