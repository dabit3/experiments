import { describeSelection, formatMoney } from '../../lib/cart'
import type { Order } from '../../lib/order'
import { OrderTotals } from '../OrderTotals'
import { ProductArt } from '../ProductArt'
import './Confirmation.css'

interface Props {
  order: Order
  onContinue: () => void
}

export function Confirmation({ order, onContinue }: Props) {
  const eta = new Date(order.placedAt)
  eta.setDate(eta.getDate() + 4)

  return (
    <main className="confirm" data-testid="confirmation">
      <div className="confirm__hero">
        <div className="confirm__check" aria-hidden>
          <svg viewBox="0 0 52 52">
            <circle cx="26" cy="26" r="25" />
            <path d="M14 27 L22 35 L38 18" />
          </svg>
        </div>
        <h1>Thanks, {order.shipping.fullName.split(' ')[0]}! Your order is confirmed.</h1>
        <p className="confirm__sub">
          Order number <strong data-testid="order-number">{order.number}</strong> · A receipt is on its way to{' '}
          {order.shipping.email}
        </p>
      </div>

      <div className="confirm__grid">
        <section className="confirm__card">
          <h3>Items</h3>
          <ul className="confirm__items">
            {order.items.map((item) => (
              <li key={item.key}>
                <div className="confirm__thumb">
                  <ProductArt product={item.product} selection={item.selection} />
                </div>
                <div>
                  <div className="confirm__item-name">{item.product.name}</div>
                  <div className="muted">
                    {describeSelection(item)} · Qty {item.quantity}
                  </div>
                </div>
                <div className="confirm__item-price">{formatMoney(item.product.price * item.quantity)}</div>
              </li>
            ))}
          </ul>
          <OrderTotals totals={order.totals} promo={order.promo} />
        </section>

        <aside className="confirm__side">
          <section className="confirm__card">
            <h3>Shipping to</h3>
            <address>
              <strong>{order.shipping.fullName}</strong>
              <br />
              {order.shipping.address1}
              {order.shipping.address2 && <>, {order.shipping.address2}</>}
              <br />
              {order.shipping.city}, {order.shipping.state} {order.shipping.zip}
            </address>
            <p className="confirm__eta">
              Estimated delivery{' '}
              <strong>{eta.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' })}</strong>
            </p>
          </section>
          <section className="confirm__card">
            <h3>Payment</h3>
            <p>
              {order.card.brand} •••• {order.card.last4}
            </p>
            <p className="confirm__paid">
              Charged <strong data-testid="confirmation-total">{formatMoney(order.totals.total)}</strong>
            </p>
          </section>
          <button type="button" className="btn btn--primary btn--lg" onClick={onContinue}>
            Continue shopping
          </button>
        </aside>
      </div>
    </main>
  )
}
