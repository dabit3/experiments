import { useState, type FormEvent } from 'react'
import type { CartLine } from '../types'
import { discountFor, findCoupon, lineTotal, shippingFor, subtotal, type Coupon } from '../lib/cart'
import { money } from '../lib/format'

interface Props {
  lines: CartLine[]
  onClose: () => void
  onPlaceOrder: () => void
}

export function CheckoutModal({ lines, onClose, onPlaceOrder }: Props) {
  const [code, setCode] = useState('')
  const [coupon, setCoupon] = useState<Coupon | null>(null)
  const [couponError, setCouponError] = useState('')
  const [placedTotal, setPlacedTotal] = useState<number | null>(null)

  const sub = subtotal(lines)
  const discount = discountFor(coupon, sub)
  const shipping = shippingFor(sub)
  const total = Math.max(0, sub - discount + shipping)

  const applyCoupon = () => {
    const found = findCoupon(code)
    if (!found) {
      setCoupon(null)
      setCouponError(`"${code.trim()}" is not a valid code.`)
      return
    }
    setCoupon(found)
    setCouponError('')
  }

  const submit = (e: FormEvent) => {
    e.preventDefault()
    setPlacedTotal(total)
    onPlaceOrder()
  }

  return (
    <div className="modal-scrim" onClick={onClose}>
      <div className="modal" role="dialog" aria-modal="true" aria-labelledby="checkout-title" onClick={(e) => e.stopPropagation()}>
        <header className="modal-header">
          <h2 id="checkout-title">{placedTotal !== null ? 'Order confirmed' : 'Checkout'}</h2>
          <button type="button" className="icon-btn" onClick={onClose} aria-label="Close checkout">
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <path d="M5 5l14 14M19 5 5 19" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
            </svg>
          </button>
        </header>

        {placedTotal !== null ? (
          <div className="order-done">
            <div className="order-check" aria-hidden="true">
              <svg viewBox="0 0 24 24">
                <path d="m5 12.5 4.5 4.5L19 7.5" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </div>
            <p className="order-done-title">Thank you.</p>
            <p className="muted">
              Your order of <strong>{money(placedTotal)}</strong> is confirmed and will ship within two business days.
            </p>
            <button type="button" className="btn btn-primary" onClick={onClose}>
              Continue shopping
            </button>
          </div>
        ) : (
          <form className="checkout" onSubmit={submit}>
            <section className="checkout-summary">
              <h3>Order summary</h3>
              <ul>
                {lines.map((line) => (
                  <li key={line.product.id}>
                    <span>
                      {line.product.name} <span className="muted">× {line.qty}</span>
                    </span>
                    <span>{money(lineTotal(line))}</span>
                  </li>
                ))}
              </ul>
              <div className="coupon">
                <input
                  type="text"
                  placeholder="Promotion code"
                  value={code}
                  onChange={(e) => setCode(e.target.value)}
                  aria-label="Promotion code"
                />
                <button type="button" className="btn btn-ghost" onClick={applyCoupon} disabled={!code.trim()}>
                  Apply
                </button>
              </div>
              {couponError && <p className="error">{couponError}</p>}
              {coupon && (
                <p className="success">
                  {coupon.code} applied — {coupon.label}.
                </p>
              )}
              <div className="totals">
                <div className="totals-row">
                  <span>Subtotal</span>
                  <span>{money(sub)}</span>
                </div>
                {coupon && (
                  <div className="totals-row discount">
                    <span>Discount ({coupon.code})</span>
                    <span>−{money(discount)}</span>
                  </div>
                )}
                <div className="totals-row">
                  <span>Shipping</span>
                  <span>{shipping === 0 ? 'Complimentary' : money(shipping)}</span>
                </div>
                <div className="totals-row totals-grand">
                  <span>Total</span>
                  <span>{money(total)}</span>
                </div>
              </div>
            </section>

            <section className="checkout-form">
              <h3>Delivery &amp; payment</h3>
              <label>
                Full name
                <input type="text" required defaultValue="Ada Lovelace" autoComplete="name" />
              </label>
              <label>
                Email
                <input type="email" required defaultValue="ada@example.com" autoComplete="email" />
              </label>
              <label>
                Address
                <input type="text" required defaultValue="12 Analytical Engine Way" autoComplete="street-address" />
              </label>
              <label>
                Card number
                <input type="text" required inputMode="numeric" defaultValue="4242 4242 4242 4242" autoComplete="cc-number" />
              </label>
              <button type="submit" className="btn btn-primary btn-block btn-lg" disabled={lines.length === 0}>
                Place order · {money(total)}
              </button>
              <p className="muted small">This is a demonstration store. Nothing is charged.</p>
            </section>
          </form>
        )}
      </div>
    </div>
  )
}
