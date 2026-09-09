import type { Split } from '../lib/calc'
import { lineTotal } from '../lib/calc'
import { fmt, fmtDelta } from '../lib/money'
import { fmtDate, fmtTime } from '../lib/time'
import type { Check, Table } from '../types'
import { Modal } from './Modal'
import './ReceiptModal.css'

interface Props {
  table: Table
  check: Check
  split: Split
  onClose: () => void
}

export function ReceiptModal({ table, check, split, onClose }: Props) {
  const paid = split.payment
  const receiptNo = `${check.id.replace(/\D/g, '').padStart(4, '0')}-${(split.id.match(/\d+$/)?.[0] ?? '0').padStart(2, '0')}`
  const stamp = paid?.paidAt ?? check.openedAt

  return (
    <Modal
      title={`Receipt · ${split.label}`}
      subtitle={paid ? 'Paid. Use Print to send to the guest printer.' : 'Preview — not yet paid.'}
      onClose={onClose}
      className="receipt-modal"
      footer={
        <>
          <span className="spacer" />
          <button type="button" className="btn-ghost btn-lg" onClick={onClose}>
            Close
          </button>
          <button type="button" className="btn-primary btn-lg" onClick={() => window.print()}>
            Print receipt
          </button>
        </>
      }
    >
      <div className="receipt-paper" role="document" aria-label={`Receipt for ${split.label}`}>
        <div className="rc-brand">
          <div className="rc-logo">E</div>
          <h2>Ember</h2>
          <p>
            221 Mercer Street · New York, NY 10012
            <br />
            (212) 555-0142 · ember.example
          </p>
        </div>

        <div className="rc-meta">
          <span>Check #{receiptNo}</span>
          <span>{fmtDate(stamp)}</span>
          <span>Table {table.number}</span>
          <span>{fmtTime(stamp)}</span>
          <span>Party of {check.partySize}</span>
          <span>Server: Jordan M.</span>
          <span className="rc-meta-wide">
            {split.label}
            {split.share ? ` · ${split.share} share` : ''}
          </span>
        </div>

        <div className="rc-rule" />

        <table className="rc-items">
          <tbody>
            {split.share
              ? split.lines.map((l) => (
                  <tr key={l.id}>
                    <td>
                      {l.name}
                      <span className="rc-sub">Seat {l.seat}</span>
                    </td>
                    <td className="rc-amt">{fmt(lineTotal(l))}</td>
                  </tr>
                ))
              : split.lines.map((l) => (
                  <tr key={l.id}>
                    <td>
                      {l.name}
                      {l.modifiers.map((m) => (
                        <span key={`${m.groupId}:${m.optionId}`} className="rc-sub">
                          + {m.optionName}
                          {m.delta !== 0 ? ` (${fmtDelta(m.delta)})` : ''}
                        </span>
                      ))}
                      {l.note && <span className="rc-sub rc-note">“{l.note}”</span>}
                    </td>
                    <td className="rc-amt">{fmt(lineTotal(l))}</td>
                  </tr>
                ))}
          </tbody>
        </table>

        <div className="rc-rule" />

        <div className="rc-totals">
          <div>
            <span>Subtotal{split.share ? ` (${split.share} of ${fmt(check.lines.filter((l) => l.status !== 'voided').reduce((s, l) => s + lineTotal(l), 0))})` : ''}</span>
            <span>{fmt(split.subtotal)}</span>
          </div>
          {split.discount > 0 && (
            <div>
              <span>Discount{check.discount ? ` · ${check.discount.label}` : ''}</span>
              <span>−{fmt(split.discount)}</span>
            </div>
          )}
          <div>
            <span>Sales tax 8.875%</span>
            <span>{fmt(split.tax)}</span>
          </div>
          {split.gratuity > 0 && (
            <div>
              <span>Gratuity 18% (party of 6+)</span>
              <span>{fmt(split.gratuity)}</span>
            </div>
          )}
          <div className="rc-total">
            <span>Total</span>
            <span>{fmt(split.total)}</span>
          </div>
          {paid && (
            <>
              <div>
                <span>Additional tip</span>
                <span>{fmt(paid.tip)}</span>
              </div>
              <div className="rc-total">
                <span>{paid.method === 'card' ? 'Card charged' : 'Cash received'}</span>
                <span>{fmt(paid.amount)}</span>
              </div>
            </>
          )}
        </div>

        {!paid && (
          <div className="rc-tipline">
            <div>
              <span>Tip</span>
              <span className="rc-blank" />
            </div>
            <div>
              <span>Total</span>
              <span className="rc-blank" />
            </div>
            <div>
              <span>Signature</span>
              <span className="rc-blank" />
            </div>
          </div>
        )}

        <div className="rc-rule" />
        <p className="rc-footer">
          {split.gratuity > 0 ? 'An 18% gratuity is added for parties of six or more.' : 'Gratuity is not included.'}
          <br />
          Thank you for dining with us.
        </p>
        <div className="rc-barcode" aria-hidden="true">
          {Array.from({ length: 36 }, (_, i) => (
            <i key={i} style={{ width: (i * 7) % 3 === 0 ? 3 : 1 }} />
          ))}
        </div>
      </div>
    </Modal>
  )
}
