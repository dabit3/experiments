import { useState } from 'react'
import type { Split } from '../lib/calc'
import { fmt, percentOf } from '../lib/money'
import { nowIso } from '../lib/time'
import type { Payment, PaymentMethod } from '../types'
import { Modal } from './Modal'
import './PayModal.css'

interface Props {
  split: Split
  onClose: () => void
  onPay: (payment: Payment) => void
}

const TIP_PRESETS = [0, 15, 18, 20, 25]

export function PayModal({ split, onClose, onPay }: Props) {
  const [tipPct, setTipPct] = useState<number | 'custom'>(0)
  const [customTip, setCustomTip] = useState('')
  const [method, setMethod] = useState<PaymentMethod>('card')

  const tip =
    tipPct === 'custom'
      ? Math.max(0, Math.round((Number.parseFloat(customTip) || 0) * 100))
      : percentOf(split.taxable, tipPct / 100)
  const amount = split.total + tip

  return (
    <Modal
      title={`Pay ${split.label}`}
      subtitle={`${fmt(split.total)} due${split.gratuity > 0 ? ' · includes 18% auto-gratuity' : ''}`}
      onClose={onClose}
      footer={
        <>
          <span className="spacer" />
          <button type="button" className="btn-ghost btn-lg" onClick={onClose}>
            Cancel
          </button>
          <button
            type="button"
            className="btn-success btn-lg"
            onClick={() => onPay({ splitId: split.id, method, tip, amount, paidAt: nowIso() })}
          >
            {method === 'card' ? 'Charge' : 'Take'} {fmt(amount)}
          </button>
        </>
      }
    >
      <div className="field-label">
        <span>Additional tip</span>
        <span className="hint">{split.gratuity > 0 ? 'Optional on top of auto-gratuity' : `% of ${fmt(split.taxable)}`}</span>
      </div>
      <div className="tip-grid">
        {TIP_PRESETS.map((p) => (
          <button
            type="button"
            key={p}
            className={`option ${tipPct === p ? 'selected' : ''}`}
            aria-pressed={tipPct === p}
            onClick={() => setTipPct(p)}
          >
            <span>{p === 0 ? 'No tip' : `${p}%`}</span>
            <span className="delta">{p === 0 ? '' : fmt(percentOf(split.taxable, p / 100))}</span>
          </button>
        ))}
        <button
          type="button"
          className={`option ${tipPct === 'custom' ? 'selected' : ''}`}
          aria-pressed={tipPct === 'custom'}
          onClick={() => setTipPct('custom')}
        >
          <span>Custom</span>
        </button>
      </div>
      {tipPct === 'custom' && (
        <div className="custom-tip">
          <span className="prefix">$</span>
          <input
            type="number"
            min={0}
            step={0.01}
            autoFocus
            value={customTip}
            onChange={(e) => setCustomTip(e.target.value)}
            aria-label="Custom tip amount"
          />
        </div>
      )}

      <div className="field-label">
        <span>Payment method</span>
      </div>
      <div className="segmented method-picker" role="radiogroup" aria-label="Payment method">
        <button type="button" className={method === 'card' ? 'active' : ''} onClick={() => setMethod('card')}>
          Card
        </button>
        <button type="button" className={method === 'cash' ? 'active' : ''} onClick={() => setMethod('cash')}>
          Cash
        </button>
      </div>

      <div className="pay-summary">
        <div>
          <span>Subtotal</span>
          <span className="mono">{fmt(split.subtotal)}</span>
        </div>
        {split.discount > 0 && (
          <div>
            <span>Discount</span>
            <span className="mono">−{fmt(split.discount)}</span>
          </div>
        )}
        <div>
          <span>Tax 8.875%</span>
          <span className="mono">{fmt(split.tax)}</span>
        </div>
        {split.gratuity > 0 && (
          <div>
            <span>Auto-gratuity 18%</span>
            <span className="mono">{fmt(split.gratuity)}</span>
          </div>
        )}
        <div>
          <span>Additional tip</span>
          <span className="mono">{fmt(tip)}</span>
        </div>
        <div className="pay-summary-total">
          <span>Total to {method === 'card' ? 'charge' : 'collect'}</span>
          <span className="mono">{fmt(amount)}</span>
        </div>
      </div>
    </Modal>
  )
}
