import { useState } from 'react'
import { AUTO_GRATUITY_MIN_PARTY, type Table } from '../types'
import { Modal } from './Modal'
import './SeatPartyModal.css'

interface Props {
  table: Table
  onClose: () => void
  onSeat: (partySize: number) => void
}

export function SeatPartyModal({ table, onClose, onSeat }: Props) {
  const [size, setSize] = useState(Math.min(table.capacity, 2))

  return (
    <Modal
      title={`Seat Table ${table.number}`}
      subtitle={`${table.capacity}-top · choose the party size`}
      onClose={onClose}
      footer={
        <>
          <span className="muted seat-hint">
            {size >= AUTO_GRATUITY_MIN_PARTY
              ? `Parties of ${AUTO_GRATUITY_MIN_PARTY}+ get 18% auto-gratuity`
              : 'No auto-gratuity for this party size'}
          </span>
          <span className="spacer" />
          <button type="button" className="btn-ghost btn-lg" onClick={onClose}>
            Cancel
          </button>
          <button type="button" className="btn-primary btn-lg" onClick={() => onSeat(size)}>
            Seat party of {size}
          </button>
        </>
      }
    >
      <div className="party-grid" role="radiogroup" aria-label="Party size">
        {Array.from({ length: 12 }, (_, i) => i + 1).map((n) => (
          <button
            type="button"
            key={n}
            role="radio"
            aria-checked={size === n}
            className={`party-btn ${size === n ? 'selected' : ''} ${n > table.capacity ? 'over' : ''}`}
            onClick={() => setSize(n)}
          >
            {n}
            {n > table.capacity && <small>over cap</small>}
          </button>
        ))}
      </div>
    </Modal>
  )
}
