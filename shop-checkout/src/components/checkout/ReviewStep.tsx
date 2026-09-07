import type { CartItem } from '../../lib/cart'
import { describeSelection, formatMoney } from '../../lib/cart'
import { detectCardBrand, last4, type PaymentInfo, type ShippingInfo } from '../../lib/validation'
import { ProductArt } from '../ProductArt'

interface Props {
  items: CartItem[]
  shipping: ShippingInfo
  payment: PaymentInfo
  onEditShipping: () => void
  onEditPayment: () => void
  onBack: () => void
  onPlaceOrder: () => void
  total: number
}

export function ReviewStep({ items, shipping, payment, onEditShipping, onEditPayment, onBack, onPlaceOrder, total }: Props) {
  return (
    <div className="form" data-testid="review-step">
      <h2 className="form__title">Review &amp; place order</h2>
      <p className="form__subtitle">Double-check everything before we ship it.</p>

      <section className="review-card" data-testid="review-shipping">
        <header className="review-card__header">
          <h3>Shipping to</h3>
          <button type="button" className="link" onClick={onEditShipping}>
            Edit
          </button>
        </header>
        <address className="review-card__body">
          <strong>{shipping.fullName}</strong>
          <br />
          {shipping.address1}
          {shipping.address2 && <>, {shipping.address2}</>}
          <br />
          <span data-testid="review-city-line">
            {shipping.city}, {shipping.state} {shipping.zip}
          </span>
          <br />
          <span className="muted">{shipping.email}</span>
        </address>
      </section>

      <section className="review-card" data-testid="review-payment">
        <header className="review-card__header">
          <h3>Paying with</h3>
          <button type="button" className="link" onClick={onEditPayment}>
            Edit
          </button>
        </header>
        <div className="review-card__body">
          <strong>
            {detectCardBrand(payment.cardNumber) ?? 'Card'} •••• {last4(payment.cardNumber)}
          </strong>
          <br />
          <span className="muted">
            {payment.cardName} · expires {payment.expiry}
          </span>
        </div>
      </section>

      <section className="review-card">
        <header className="review-card__header">
          <h3>Items ({items.reduce((n, i) => n + i.quantity, 0)})</h3>
        </header>
        <ul className="review-items">
          {items.map((item) => (
            <li key={item.key} className="review-item">
              <div className="review-item__thumb">
                <ProductArt product={item.product} selection={item.selection} />
              </div>
              <div className="review-item__info">
                <div className="review-item__name">{item.product.name}</div>
                <div className="muted">
                  {describeSelection(item)} · Qty {item.quantity}
                </div>
              </div>
              <div className="review-item__price">{formatMoney(item.product.price * item.quantity)}</div>
            </li>
          ))}
        </ul>
      </section>

      <div className="form__actions">
        <button type="button" className="btn btn--ghost" onClick={onBack}>
          Back
        </button>
        <button type="button" className="btn btn--primary btn--lg" onClick={onPlaceOrder} data-testid="place-order">
          Place order · {formatMoney(total)}
        </button>
      </div>
    </div>
  )
}
