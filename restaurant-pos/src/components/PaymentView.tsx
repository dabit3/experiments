import { useState } from 'react'
import { allSplitsPaid, checkTotals, computeSplits, hasAutoGratuity, lineTotal, type Split } from '../lib/calc'
import { fmt } from '../lib/money'
import type { Action } from '../state/reducer'
import type { Check, SplitMode, Table } from '../types'
import { PayModal } from './PayModal'
import { ReceiptModal } from './ReceiptModal'
import './PaymentView.css'

interface Props {
  table: Table
  check: Check
  dispatch: (action: Action) => void
  onBack: () => void
  onClosed: () => void
}

type ModalState = { kind: 'none' } | { kind: 'pay'; split: Split } | { kind: 'receipt'; split: Split }

const MODES: Array<{ id: SplitMode; label: string }> = [
  { id: 'none', label: 'No split' },
  { id: 'seat', label: 'By seat' },
  { id: 'even', label: 'Evenly' },
  { id: 'item', label: 'By item' },
]

export function PaymentView({ table, check, dispatch, onBack, onClosed }: Props) {
  const [modal, setModal] = useState<ModalState>({ kind: 'none' })
  const totals = checkTotals(check)
  const splits = computeSplits(check)
  const splitsSum = splits.reduce((s, x) => s + x.total, 0)
  const matches = splitsSum === totals.total
  const paidCount = splits.filter((s) => s.payment).length
  const allPaid = allSplitsPaid(splits)
  const locked = check.payments.length > 0
  const lines = check.lines.filter((l) => l.status !== 'voided')

  const setMode = (mode: SplitMode) => {
    if (locked) return
    dispatch({ type: 'setSplitMode', checkId: check.id, mode })
  }

  return (
    <div className="pay-page">
      <header className="order-header">
        <button type="button" className="btn-ghost back" onClick={onBack}>
          ← Back to order
        </button>
        <div className="order-title">
          <span className="eyebrow">A gracious finish</span>
          <h1>Table {table.number} · Split &amp; pay</h1>
          <div className="order-chips">
            <span className="chip">Party of {check.partySize}</span>
            {hasAutoGratuity(check) && <span className="chip chip-amber">18% auto-gratuity</span>}
            <span className={`chip ${allPaid ? 'chip-green' : ''}`}>
              {paidCount}/{splits.length} paid
            </span>
          </div>
        </div>
        <div className="order-header-actions">
          <button
            type="button"
            className="btn-success"
            disabled={!allPaid}
            onClick={() => {
              dispatch({ type: 'closeCheck', checkId: check.id })
              onClosed()
            }}
          >
            Close table
          </button>
        </div>
      </header>

      <div className="pay-toolbar">
        <span className="eyebrow">Arrange the check</span>
        <div className="segmented" role="radiogroup" aria-label="Split mode">
          {MODES.map((m) => (
            <button
              type="button"
              key={m.id}
              role="radio"
              aria-checked={check.splitMode === m.id}
              className={check.splitMode === m.id ? 'active' : ''}
              disabled={locked && check.splitMode !== m.id}
              onClick={() => setMode(m.id)}
            >
              {m.label}
            </button>
          ))}
        </div>

        {check.splitMode === 'even' && (
          <Stepper
            label="Ways"
            value={check.evenSplitCount}
            min={1}
            max={12}
            disabled={locked}
            onChange={(v) => dispatch({ type: 'setEvenCount', checkId: check.id, count: v })}
          />
        )}
        {check.splitMode === 'item' && (
          <Stepper
            label="Checks"
            value={check.itemSplitCount}
            min={1}
            max={6}
            disabled={locked}
            onChange={(v) => dispatch({ type: 'setItemCount', checkId: check.id, count: v })}
          />
        )}

        {locked && <span className="muted lock-note">Split mode is locked once a payment is taken.</span>}
      </div>

      <div className={`pay-body ${check.splitMode === 'item' ? 'with-assign' : ''}`}>
        {check.splitMode === 'item' && (
          <aside className="assign-panel" aria-label="Assign items to checks">
            <h2>Assign items</h2>
            <p className="muted">Tap a letter to move an item to that check.</p>
            <div className="assign-list">
              {lines.map((line) => {
                const idx = check.itemAssignments[line.id] ?? 0
                return (
                  <div key={line.id} className="assign-row">
                    <div className="assign-main">
                      <span className="assign-name">{line.name}</span>
                      <span className="muted">
                        Seat {line.seat} · {fmt(lineTotal(line))}
                      </span>
                    </div>
                    <div className="assign-chips">
                      {Array.from({ length: check.itemSplitCount }, (_, i) => (
                        <button
                          type="button"
                          key={i}
                          className={`assign-chip ${idx === i ? 'active' : ''}`}
                          disabled={locked}
                          onClick={() => dispatch({ type: 'assignItem', checkId: check.id, lineId: line.id, splitIndex: i })}
                        >
                          {String.fromCharCode(65 + i)}
                        </button>
                      ))}
                    </div>
                  </div>
                )
              })}
            </div>
          </aside>
        )}

        <div className="splits-grid">
          {splits.map((split) => (
            <SplitCard
              key={split.id}
              split={split}
              hasGratuity={hasAutoGratuity(check)}
              hasDiscount={totals.discount > 0}
              onPay={() => setModal({ kind: 'pay', split })}
              onReceipt={() => setModal({ kind: 'receipt', split })}
            />
          ))}
        </div>
      </div>

      <footer className={`verify-bar ${matches ? 'ok' : 'bad'}`} aria-live="polite">
        <div className="verify-sum">
          {splits.map((s, i) => (
            <span key={s.id}>
              {i > 0 && <span className="op">+</span>}
              <span className="term">
                <small>{s.label}</small>
                <b className="mono">{fmt(s.total)}</b>
              </span>
            </span>
          ))}
          <span className="op">=</span>
          <span className="term">
            <small>Splits total</small>
            <b className="mono">{fmt(splitsSum)}</b>
          </span>
        </div>
        <div className="verify-table">
          <span className="term">
            <small>Table total incl. tax{hasAutoGratuity(check) ? ' + 18% gratuity' : ''}</small>
            <b className="mono">{fmt(totals.total)}</b>
          </span>
          <span className={`chip ${matches ? 'chip-green' : 'chip-red'} verify-chip`}>
            {matches ? '✓ Splits match table total' : '✕ Mismatch'}
          </span>
        </div>
      </footer>

      {modal.kind === 'pay' && (
        <PayModal
          split={modal.split}
          onClose={() => setModal({ kind: 'none' })}
          onPay={(payment) => {
            dispatch({ type: 'paySplit', checkId: check.id, payment })
            setModal({ kind: 'none' })
          }}
        />
      )}
      {modal.kind === 'receipt' && (
        <ReceiptModal
          table={table}
          check={check}
          split={computeSplits(check).find((s) => s.id === modal.split.id) ?? modal.split}
          onClose={() => setModal({ kind: 'none' })}
        />
      )}
    </div>
  )
}

function Stepper({
  label,
  value,
  min,
  max,
  disabled,
  onChange,
}: {
  label: string
  value: number
  min: number
  max: number
  disabled: boolean
  onChange: (v: number) => void
}) {
  return (
    <div className="stepper">
      <span className="muted">{label}</span>
      <button type="button" disabled={disabled || value <= min} onClick={() => onChange(value - 1)} aria-label={`Fewer ${label}`}>
        −
      </button>
      <strong>{value}</strong>
      <button type="button" disabled={disabled || value >= max} onClick={() => onChange(value + 1)} aria-label={`More ${label}`}>
        +
      </button>
    </div>
  )
}

function SplitCard({
  split,
  hasGratuity,
  hasDiscount,
  onPay,
  onReceipt,
}: {
  split: Split
  hasGratuity: boolean
  hasDiscount: boolean
  onPay: () => void
  onReceipt: () => void
}) {
  const paid = split.payment
  return (
    <article className={`split-card ${paid ? 'paid' : ''}`} aria-label={split.label}>
      <header className="split-head">
        <div>
          <h3>{split.label}</h3>
          {split.share && <span className="muted">{split.share} of the table</span>}
        </div>
        {paid ? (
          <span className="chip chip-green">Paid · {paid.method === 'card' ? 'Card' : 'Cash'}</span>
        ) : (
          <span className="chip chip-amber">Due</span>
        )}
      </header>

      <ul className="split-lines">
        {split.share
          ? split.lines.map((l) => (
              <li key={l.id}>
                <span>
                  {l.name} <small className="muted">S{l.seat}</small>
                </span>
                <span className="mono muted">{fmt(lineTotal(l))}</span>
              </li>
            ))
          : split.lines.map((l) => (
              <li key={l.id}>
                <span>
                  {l.name}
                  {l.modifiers.length > 0 && <small className="muted"> · {l.modifiers.map((m) => m.optionName).join(', ')}</small>}
                </span>
                <span className="mono">{fmt(lineTotal(l))}</span>
              </li>
            ))}
        {split.lines.length === 0 && <li className="muted">No items</li>}
      </ul>

      <div className="split-totals">
        <div>
          <span>Subtotal{split.share ? ` (${split.share})` : ''}</span>
          <span className="mono">{fmt(split.subtotal)}</span>
        </div>
        {hasDiscount && (
          <div className="discount">
            <span>Discount</span>
            <span className="mono">−{fmt(split.discount)}</span>
          </div>
        )}
        <div>
          <span>Tax 8.875%</span>
          <span className="mono">{fmt(split.tax)}</span>
        </div>
        {hasGratuity && (
          <div>
            <span>Auto-gratuity 18%</span>
            <span className="mono">{fmt(split.gratuity)}</span>
          </div>
        )}
        <div className="split-total">
          <span>Total</span>
          <span className="mono">{fmt(split.total)}</span>
        </div>
        {paid && paid.tip > 0 && (
          <div className="tip">
            <span>Additional tip</span>
            <span className="mono">{fmt(paid.tip)}</span>
          </div>
        )}
        {paid && (
          <div className="charged">
            <span>Charged</span>
            <span className="mono">{fmt(paid.amount)}</span>
          </div>
        )}
      </div>

      <div className="split-actions">
        {paid ? (
          <button type="button" className="btn-ghost" onClick={onReceipt}>
            Receipt
          </button>
        ) : (
          <>
            <button type="button" className="btn-ghost" onClick={onReceipt}>
              Preview
            </button>
            <button type="button" className="btn-primary" onClick={onPay} disabled={split.lines.length === 0 && split.total === 0}>
              Pay {fmt(split.total)}
            </button>
          </>
        )}
      </div>
    </article>
  )
}
