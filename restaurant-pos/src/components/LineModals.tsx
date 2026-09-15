import { useState } from 'react'
import { fmt } from '../lib/money'
import type { Discount, OrderLine } from '../types'
import { Modal } from './Modal'
import './LineModals.css'

const QUICK_NOTES = [
  'Sauce on the side',
  'No onions',
  'Extra crispy',
  'Light on the salt',
  'Birthday — add candle',
  'Allergy: see server',
]

export function NoteModal({ line, onClose, onSave }: { line: OrderLine; onClose: () => void; onSave: (note: string) => void }) {
  const [note, setNote] = useState(line.note)
  return (
    <Modal
      title="Item note"
      subtitle={`${line.name} · Seat ${line.seat}`}
      onClose={onClose}
      footer={
        <>
          {line.note && (
            <button type="button" className="btn-ghost btn-lg" onClick={() => onSave('')}>
              Remove note
            </button>
          )}
          <span className="spacer" />
          <button type="button" className="btn-ghost btn-lg" onClick={onClose}>
            Cancel
          </button>
          <button type="button" className="btn-primary btn-lg" onClick={() => onSave(note.trim())}>
            Save note
          </button>
        </>
      }
    >
      <div className="quick-notes">
        {QUICK_NOTES.map((q) => (
          <button type="button" key={q} className="btn-sm btn-ghost" onClick={() => setNote(q)}>
            {q}
          </button>
        ))}
      </div>
      <textarea
        autoFocus
        value={note}
        onChange={(e) => setNote(e.target.value)}
        placeholder="Type a note for the kitchen…"
        aria-label="Note"
      />
    </Modal>
  )
}

const VOID_REASONS = [
  'Guest changed mind',
  'Entered by mistake',
  'Kitchen error',
  'Long wait — comped',
  'Quality issue',
  'Manager comp',
]

export function VoidModal({
  line,
  onClose,
  onVoid,
}: {
  line: OrderLine
  onClose: () => void
  onVoid: (reason: string) => void
}) {
  const [reason, setReason] = useState<string>('')
  const [detail, setDetail] = useState('')
  const fullReason = detail.trim() ? `${reason} — ${detail.trim()}` : reason
  return (
    <Modal
      title="Void item"
      subtitle={`${line.name} · Seat ${line.seat}${line.status === 'fired' ? ' · already fired to kitchen' : ''}`}
      onClose={onClose}
      footer={
        <>
          <span className="spacer" />
          <button type="button" className="btn-ghost btn-lg" onClick={onClose}>
            Keep item
          </button>
          <button type="button" className="btn-danger btn-lg" disabled={!reason} onClick={() => onVoid(fullReason)}>
            Void item
          </button>
        </>
      }
    >
      <div className="field-label">
        <span>Reason</span>
        <span className={`hint ${reason ? '' : 'required'}`}>Required</span>
      </div>
      <div className="option-grid">
        {VOID_REASONS.map((r) => (
          <button
            type="button"
            key={r}
            className={`option ${reason === r ? 'selected' : ''}`}
            aria-pressed={reason === r}
            onClick={() => setReason(r)}
          >
            {r}
          </button>
        ))}
      </div>
      <div className="field-label">
        <span>Details</span>
        <span className="hint">Optional</span>
      </div>
      <input
        type="text"
        value={detail}
        onChange={(e) => setDetail(e.target.value)}
        placeholder="Anything the manager should know"
        aria-label="Void details"
      />
    </Modal>
  )
}

export function DiscountModal({
  subtotal,
  current,
  onClose,
  onApply,
}: {
  subtotal: number
  current: Discount | null
  onClose: () => void
  onApply: (discount: Discount | null) => void
}) {
  const [kind, setKind] = useState<Discount['kind']>(current?.kind ?? 'percent')
  const [value, setValue] = useState<string>(current ? String(current.kind === 'amount' ? current.value / 100 : current.value) : '')
  const [label, setLabel] = useState(current?.label ?? '')

  const numeric = Number.parseFloat(value)
  const valid = Number.isFinite(numeric) && numeric > 0 && (kind !== 'percent' || numeric <= 100)
  const preview = valid
    ? kind === 'percent'
      ? Math.round((subtotal * numeric) / 100)
      : Math.min(Math.round(numeric * 100), subtotal)
    : 0

  const presets = [10, 15, 20, 25]

  return (
    <Modal
      title="Check discount"
      subtitle={`Applied to the ${fmt(subtotal)} subtotal before tax and gratuity`}
      onClose={onClose}
      footer={
        <>
          {current && (
            <button type="button" className="btn-danger btn-lg" onClick={() => onApply(null)}>
              Remove discount
            </button>
          )}
          <span className="spacer" />
          <button type="button" className="btn-ghost btn-lg" onClick={onClose}>
            Cancel
          </button>
          <button
            type="button"
            className="btn-primary btn-lg"
            disabled={!valid}
            onClick={() =>
              onApply({
                kind,
                value: kind === 'percent' ? numeric : Math.round(numeric * 100),
                label: label.trim() || (kind === 'percent' ? `${numeric}% off` : `${fmt(Math.round(numeric * 100))} off`),
              })
            }
          >
            Apply −{fmt(preview)}
          </button>
        </>
      }
    >
      <div className="segmented discount-kind" role="radiogroup" aria-label="Discount type">
        <button type="button" className={kind === 'percent' ? 'active' : ''} onClick={() => setKind('percent')}>
          Percent
        </button>
        <button type="button" className={kind === 'amount' ? 'active' : ''} onClick={() => setKind('amount')}>
          Dollar amount
        </button>
      </div>

      {kind === 'percent' && (
        <div className="option-grid discount-presets">
          {presets.map((p) => (
            <button
              type="button"
              key={p}
              className={`option ${value === String(p) ? 'selected' : ''}`}
              onClick={() => setValue(String(p))}
            >
              <span>{p}% off</span>
              <span className="delta">−{fmt(Math.round((subtotal * p) / 100))}</span>
            </button>
          ))}
        </div>
      )}

      <div className="field-label">
        <span>{kind === 'percent' ? 'Percent' : 'Amount'}</span>
      </div>
      <div className="discount-input">
        <span className="prefix">{kind === 'percent' ? '%' : '$'}</span>
        <input
          type="number"
          min={0}
          step={kind === 'percent' ? 1 : 0.01}
          value={value}
          onChange={(e) => setValue(e.target.value)}
          aria-label="Discount value"
        />
      </div>

      <div className="field-label">
        <span>Reason / label</span>
        <span className="hint">Optional</span>
      </div>
      <input
        type="text"
        value={label}
        onChange={(e) => setLabel(e.target.value)}
        placeholder="e.g. Loyalty, Manager comp, Birthday"
        aria-label="Discount label"
      />
    </Modal>
  )
}
