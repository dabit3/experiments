import { useEffect, useState, type FormEvent } from 'react'
import type { Cart } from '../hooks/useCart'
import { describeSelection, formatMoney } from '../lib/cart'
import { ProductArt } from './ProductArt'
import { OrderTotals } from './OrderTotals'
import './CartDrawer.css'

interface Props {
  cart: Cart
  open: boolean
  onClose: () => void
  onCheckout: () => void
}

export function CartDrawer({ cart, open, onClose, onCheckout }: Props) {
  const [code, setCode] = useState('')

  useEffect(() => {
    if (!open) return
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && onClose()
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [open, onClose])

  const submitPromo = (e: FormEvent) => {
    e.preventDefault()
    if (code.trim()) cart.applyPromo(code)
  }

  return (
    <div className={`drawer${open ? ' is-open' : ''}`} aria-hidden={!open}>
      <div className="drawer__backdrop" onClick={onClose} />
      <aside className="drawer__panel" role="dialog" aria-label="Shopping cart" data-testid="cart-drawer">
        <header className="drawer__header">
          <h2>
            Your cart <span className="drawer__count">{cart.count}</span>
          </h2>
          <button type="button" className="icon-btn" aria-label="Close cart" onClick={onClose}>
            ×
          </button>
        </header>

        {cart.items.length === 0 ? (
          <div className="drawer__empty">
            <p>Your cart is empty.</p>
            <button type="button" className="btn btn--ghost" onClick={onClose}>
              Keep shopping
            </button>
          </div>
        ) : (
          <>
            <ul className="drawer__items">
              {cart.items.map((item) => (
                <li className="line" key={item.key} data-testid="cart-line">
                  <div className="line__thumb">
                    <ProductArt product={item.product} selection={item.selection} />
                  </div>
                  <div className="line__info">
                    <div className="line__name">{item.product.name}</div>
                    <div className="line__variant">{describeSelection(item)}</div>
                    <div className="stepper" aria-label={`Quantity for ${item.product.name}`}>
                      <button
                        type="button"
                        aria-label={`Decrease quantity of ${item.product.name}`}
                        onClick={() => cart.setQuantity(item.key, item.quantity - 1)}
                      >
                        −
                      </button>
                      <span data-testid="line-qty">{item.quantity}</span>
                      <button
                        type="button"
                        aria-label={`Increase quantity of ${item.product.name}`}
                        onClick={() => cart.setQuantity(item.key, item.quantity + 1)}
                      >
                        +
                      </button>
                    </div>
                  </div>
                  <div className="line__right">
                    <span className="line__price">{formatMoney(item.product.price * item.quantity)}</span>
                    <button type="button" className="line__remove" onClick={() => cart.removeItem(item.key)}>
                      Remove
                    </button>
                  </div>
                </li>
              ))}
            </ul>

            <footer className="drawer__footer">
              <form className="promo" onSubmit={submitPromo}>
                <label htmlFor="promo-code" className="promo__label">
                  Promo code
                </label>
                <div className="promo__row">
                  <input
                    id="promo-code"
                    className="input"
                    placeholder="e.g. DEVIN20"
                    value={code}
                    autoComplete="off"
                    onChange={(e) => setCode(e.target.value.toUpperCase())}
                  />
                  <button type="submit" className="btn btn--secondary">
                    Apply
                  </button>
                </div>
                {cart.promoStatus.kind === 'applied' && (
                  <p className="promo__msg promo__msg--ok" role="status">
                    {cart.promoStatus.promo.code} applied — {Math.round(cart.promoStatus.promo.rate * 100)}% off
                    <button type="button" className="link" onClick={cart.clearPromo}>
                      Remove
                    </button>
                  </p>
                )}
                {cart.promoStatus.kind === 'invalid' && (
                  <p className="promo__msg promo__msg--err" role="alert">
                    “{cart.promoStatus.code}” isn’t a valid code
                  </p>
                )}
              </form>

              <OrderTotals totals={cart.totals} promo={cart.promo} />

              <button type="button" className="btn btn--primary btn--lg" onClick={onCheckout}>
                Checkout
              </button>
            </footer>
          </>
        )}
      </aside>
    </div>
  )
}
