import { useState } from 'react'
import type { Cart } from '../../hooks/useCart'
import { describeSelection, formatMoney } from '../../lib/cart'
import { createOrder, type Order } from '../../lib/order'
import { emptyPayment, emptyShipping, type PaymentInfo, type ShippingInfo } from '../../lib/validation'
import { OrderTotals } from '../OrderTotals'
import { ProductArt } from '../ProductArt'
import { PaymentForm } from './PaymentForm'
import { ReviewStep } from './ReviewStep'
import { ShippingForm } from './ShippingForm'
import './Checkout.css'

type Step = 'shipping' | 'payment' | 'review'

const STEPS: { id: Step; label: string }[] = [
  { id: 'shipping', label: 'Shipping' },
  { id: 'payment', label: 'Payment' },
  { id: 'review', label: 'Review' },
]

interface Props {
  cart: Cart
  onBackToShop: () => void
  onOrderPlaced: (order: Order) => void
}

export function Checkout({ cart, onBackToShop, onOrderPlaced }: Props) {
  const [step, setStep] = useState<Step>('shipping')
  const [shipping, setShipping] = useState<ShippingInfo>(emptyShipping)
  const [payment, setPayment] = useState<PaymentInfo>(emptyPayment)
  // Set when the user jumps back from Review via "Edit" so the form returns there on save.
  const [returnToReview, setReturnToReview] = useState(false)

  const stepIndex = STEPS.findIndex((s) => s.id === step)

  const editFromReview = (target: Step) => {
    setReturnToReview(true)
    setStep(target)
  }

  const advance = (next: Step) => {
    if (returnToReview) {
      setReturnToReview(false)
      setStep('review')
    } else {
      setStep(next)
    }
  }

  const placeOrder = () => {
    onOrderPlaced(createOrder(cart.items, cart.totals, cart.promo, shipping, payment))
  }

  return (
    <main className="checkout">
      <ol className="stepper-nav" aria-label="Checkout progress">
        {STEPS.map((s, i) => {
          const state = i < stepIndex ? 'done' : i === stepIndex ? 'active' : 'upcoming'
          return (
            <li key={s.id} className={`stepper-nav__step is-${state}`} aria-current={state === 'active' ? 'step' : undefined}>
              <span className="stepper-nav__dot">{state === 'done' ? '✓' : i + 1}</span>
              <span className="stepper-nav__label">{s.label}</span>
            </li>
          )
        })}
      </ol>

      <div className="checkout__grid">
        <section className="checkout__main" key={step}>
          {step === 'shipping' && (
            <ShippingForm
              value={shipping}
              onChange={setShipping}
              onBack={onBackToShop}
              onSubmit={() => advance('payment')}
              submitLabel={returnToReview ? 'Save & return to review' : 'Continue to payment'}
            />
          )}
          {step === 'payment' && (
            <PaymentForm
              value={payment}
              onChange={setPayment}
              onBack={() => setStep('shipping')}
              onSubmit={() => advance('review')}
              submitLabel={returnToReview ? 'Save & return to review' : 'Continue to review'}
            />
          )}
          {step === 'review' && (
            <ReviewStep
              items={cart.items}
              shipping={shipping}
              payment={payment}
              total={cart.totals.total}
              onEditShipping={() => editFromReview('shipping')}
              onEditPayment={() => editFromReview('payment')}
              onBack={() => setStep('payment')}
              onPlaceOrder={placeOrder}
            />
          )}
        </section>

        <aside className="summary">
          <h3 className="summary__title">Order summary</h3>
          <ul className="summary__items">
            {cart.items.map((item) => (
              <li key={item.key}>
                <div className="summary__thumb">
                  <ProductArt product={item.product} selection={item.selection} />
                  <span className="summary__qty">{item.quantity}</span>
                </div>
                <div className="summary__info">
                  <div className="summary__name">{item.product.name}</div>
                  <div className="muted">{describeSelection(item)}</div>
                </div>
                <div className="summary__price">{formatMoney(item.product.price * item.quantity)}</div>
              </li>
            ))}
          </ul>
          <OrderTotals totals={cart.totals} promo={cart.promo} />
        </aside>
      </div>
    </main>
  )
}
