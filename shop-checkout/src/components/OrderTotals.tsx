import { formatMoney, type Promo, type Totals } from '../lib/cart'
import './OrderTotals.css'

interface Props {
  totals: Totals
  promo: Promo | null
}

export function OrderTotals({ totals, promo }: Props) {
  return (
    <dl className="totals">
      <div className="totals__row">
        <dt>Subtotal</dt>
        <dd data-testid="subtotal">{formatMoney(totals.subtotal)}</dd>
      </div>
      {promo && (
        <div className="totals__row totals__row--discount">
          <dt>Discount ({promo.code})</dt>
          <dd data-testid="discount">−{formatMoney(totals.discount)}</dd>
        </div>
      )}
      <div className="totals__row">
        <dt>Shipping</dt>
        <dd>Free</dd>
      </div>
      <div className="totals__row totals__row--total">
        <dt>Total</dt>
        <dd data-testid="total">{formatMoney(totals.total)}</dd>
      </div>
    </dl>
  )
}
