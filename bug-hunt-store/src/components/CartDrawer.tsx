import type { CartLine } from '../types'
import { FREE_SHIPPING_THRESHOLD, itemCount, lineTotal, shippingFor, subtotal } from '../lib/cart'
import { money, plural } from '../lib/format'
import { ProductArt } from './ProductArt'

interface Props {
  open: boolean
  lines: CartLine[]
  onClose: () => void
  onSetQty: (productId: number, qty: number) => void
  onRemove: (line: CartLine) => void
  onCheckout: () => void
}

export function CartDrawer({ open, lines, onClose, onSetQty, onRemove, onCheckout }: Props) {
  const sub = subtotal(lines)
  const shipping = shippingFor(sub)
  return (
    <>
      <div className={`scrim ${open ? 'scrim-open' : ''}`} onClick={onClose} aria-hidden="true" />
      <aside className={`drawer ${open ? 'drawer-open' : ''}`} aria-label="Shopping cart" aria-hidden={!open}>
        <header className="drawer-header">
          <h2>Your cart</h2>
          <span className="muted">{plural(itemCount(lines), 'item')}</span>
          <button type="button" className="icon-btn" onClick={onClose} aria-label="Close cart">
            ×
          </button>
        </header>

        {lines.length === 0 ? (
          <div className="drawer-empty">
            <p>Your cart is empty.</p>
            <button type="button" className="btn btn-ghost" onClick={onClose}>
              Keep shopping
            </button>
          </div>
        ) : (
          <>
            <ul className="cart-lines">
              {lines.map((line) => (
                <li key={line.product.id} className="cart-line" data-product-id={line.product.id}>
                  <ProductArt category={line.product.category} hue={line.product.hue} size="thumb" />
                  <div className="cart-line-info">
                    <strong>{line.product.name}</strong>
                    <span className="muted">
                      {money(line.product.price)} × {line.qty}
                    </span>
                    <div className="qty">
                      <button
                        type="button"
                        className="qty-btn"
                        onClick={() => onSetQty(line.product.id, line.qty - 1)}
                        disabled={line.qty <= 1}
                        aria-label={`Decrease quantity of ${line.product.name}`}
                      >
                        −
                      </button>
                      <span className="qty-value" aria-live="polite">
                        {line.qty}
                      </span>
                      <button
                        type="button"
                        className="qty-btn"
                        onClick={() => onSetQty(line.product.id, line.qty + 1)}
                        aria-label={`Increase quantity of ${line.product.name}`}
                      >
                        +
                      </button>
                    </div>
                  </div>
                  <div className="cart-line-end">
                    <strong className="line-total">{money(lineTotal(line))}</strong>
                    <button type="button" className="link-btn" onClick={() => onRemove(line)}>
                      Remove
                    </button>
                  </div>
                </li>
              ))}
            </ul>
            <footer className="drawer-footer">
              <div className="totals">
                <div className="totals-row">
                  <span>Subtotal</span>
                  <span>{money(sub)}</span>
                </div>
                <div className="totals-row">
                  <span>Shipping</span>
                  <span>{shipping === 0 ? 'Free' : money(shipping)}</span>
                </div>
                {shipping > 0 && (
                  <p className="muted small">Free shipping on orders over {money(FREE_SHIPPING_THRESHOLD)}.</p>
                )}
                <div className="totals-row totals-grand">
                  <span>Total</span>
                  <span>{money(sub + shipping)}</span>
                </div>
              </div>
              <button type="button" className="btn btn-primary btn-block" onClick={onCheckout}>
                Checkout
              </button>
            </footer>
          </>
        )}
      </aside>
    </>
  )
}
