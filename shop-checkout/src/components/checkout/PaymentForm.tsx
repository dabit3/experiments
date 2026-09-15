import { useState, type ChangeEvent, type FormEvent } from 'react'
import {
  detectCardBrand,
  digitsOnly,
  formatCardNumber,
  formatExpiry,
  validatePayment,
  type PaymentInfo,
} from '../../lib/validation'
import { Field } from './Field'
import { fieldA11y } from './fieldA11y'

interface Props {
  value: PaymentInfo
  onChange: (value: PaymentInfo) => void
  onSubmit: () => void
  onBack: () => void
  submitLabel: string
}

export function PaymentForm({ value, onChange, onSubmit, onBack, submitLabel }: Props) {
  const [attempted, setAttempted] = useState(false)
  const [touched, setTouched] = useState<Set<keyof PaymentInfo>>(new Set())

  const allErrors = validatePayment(value)
  const brand = detectCardBrand(value.cardNumber)
  const cardComplete = digitsOnly(value.cardNumber).length >= 16

  const visible = (field: keyof PaymentInfo) =>
    attempted || touched.has(field) || (field === 'cardNumber' && cardComplete) ? allErrors[field] : undefined

  const touch = (field: keyof PaymentInfo) => () => setTouched((t) => new Set(t).add(field))
  const set = (field: keyof PaymentInfo, transform: (raw: string) => string = (s) => s) =>
    (e: ChangeEvent<HTMLInputElement>) => onChange({ ...value, [field]: transform(e.target.value) })

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault()
    setAttempted(true)
    if (Object.keys(allErrors).length === 0) onSubmit()
  }

  return (
    <form className="form" onSubmit={handleSubmit} noValidate data-testid="payment-form">
      <h2 className="form__title">Payment</h2>
      <p className="form__subtitle">All transactions are secure and encrypted.</p>

      <Field id="cardName" label="Name on card" error={visible('cardName')}>
        <input className="input" autoComplete="cc-name" placeholder="Ada Lovelace" value={value.cardName} onChange={set('cardName')} onBlur={touch('cardName')} {...fieldA11y('cardName', visible('cardName'))} />
      </Field>

      <Field id="cardNumber" label="Card number" error={visible('cardNumber')} hint={brand ? `${brand} detected` : undefined}>
        <div className="input-wrap">
          <input
            className="input input--card"
            inputMode="numeric"
            autoComplete="cc-number"
            placeholder="1234 5678 9012 3456"
            value={value.cardNumber}
            onChange={set('cardNumber', formatCardNumber)}
            onBlur={touch('cardNumber')}
            {...fieldA11y('cardNumber', visible('cardNumber'))}
          />
          <span className={`card-brand${brand ? ' is-visible' : ''}`} aria-hidden>
            {brand}
          </span>
        </div>
      </Field>

      <div className="form__row form__row--half">
        <Field id="expiry" label="Expiry (MM/YY)" error={visible('expiry')}>
          <input className="input" inputMode="numeric" autoComplete="cc-exp" placeholder="MM/YY" value={value.expiry} onChange={set('expiry', formatExpiry)} onBlur={touch('expiry')} {...fieldA11y('expiry', visible('expiry'))} />
        </Field>
        <Field id="cvv" label="CVV" error={visible('cvv')}>
          <input className="input" inputMode="numeric" autoComplete="cc-csc" placeholder="123" maxLength={3} value={value.cvv} onChange={set('cvv', (s) => digitsOnly(s).slice(0, 3))} onBlur={touch('cvv')} {...fieldA11y('cvv', visible('cvv'))} />
        </Field>
      </div>

      <div className="form__actions">
        <button type="button" className="btn btn--ghost" onClick={onBack}>
          Back
        </button>
        <button type="submit" className="btn btn--primary">
          {submitLabel}
        </button>
      </div>
    </form>
  )
}
