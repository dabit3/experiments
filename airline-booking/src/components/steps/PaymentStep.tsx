import { useMemo, useState, type FormEvent } from 'react'
import type { Extras, FlightSelection, Leg, Passenger, PaymentDetails, SearchParams, SeatAssignments } from '../../types'
import { EXTRA_PRICES, bookingReference, computePrice, money } from '../../lib/booking'
import {
  CARD_LABEL,
  detectCardType,
  formatCardNumber,
  formatExpiry,
  hasErrors,
  luhnValid,
  validatePayment,
  type CardType,
  type Errors,
} from '../../lib/validation'
import { CountStepper } from '../CountStepper'
import { Field } from '../Field'
import { fieldProps } from '../../lib/fieldProps'

interface Props {
  search: SearchParams
  selections: Partial<Record<Leg, FlightSelection>>
  passengers: Passenger[]
  seats: SeatAssignments
  extras: Extras
  onExtrasChange: (extras: Extras) => void
  onPaid: (extras: Extras, payment: PaymentDetails, reference: string) => void
  onBack: () => void
}

const EMPTY_PAYMENT: PaymentDetails = { name: '', number: '', expiry: '', cvv: '', zip: '' }

export function PaymentStep({ search, selections, passengers, seats, extras, onExtrasChange, onPaid, onBack }: Props) {
  const setExtras = (patch: Partial<Extras>) => onExtrasChange({ ...extras, ...patch })
  const [payment, setPayment] = useState<PaymentDetails>(EMPTY_PAYMENT)
  const [errors, setErrors] = useState<Errors<PaymentDetails>>({})
  const [touched, setTouched] = useState<Partial<Record<keyof PaymentDetails, boolean>>>({})
  const [processing, setProcessing] = useState(false)

  const price = useMemo(
    () => computePrice(search, selections, passengers, seats, extras),
    [search, selections, passengers, seats, extras],
  )
  const paxCount = passengers.length
  const digits = payment.number.replace(/\D/g, '')
  const cardType = detectCardType(digits)
  const expectedLen = cardType === 'amex' ? 15 : 16
  const numberComplete = digits.length === expectedLen
  const liveNumberError =
    numberComplete && !luhnValid(digits) ? 'Invalid card number — failed checksum' : undefined

  const update = (patch: Partial<PaymentDetails>) => {
    setPayment((p) => {
      const next = { ...p, ...patch }
      if (Object.keys(touched).length) {
        const all = validatePayment(next)
        setErrors(Object.fromEntries(Object.entries(all).filter(([k]) => touched[k as keyof PaymentDetails])))
      }
      return next
    })
  }

  const blur = (key: keyof PaymentDetails) => {
    setTouched((t) => ({ ...t, [key]: true }))
    const all = validatePayment(payment)
    setErrors((e) => ({ ...e, [key]: all[key] }))
  }

  const submit = (e: FormEvent) => {
    e.preventDefault()
    const all = validatePayment(payment)
    setTouched({ name: true, number: true, expiry: true, cvv: true, zip: true })
    setErrors(all)
    if (hasErrors(all)) {
      requestAnimationFrame(() => document.querySelector<HTMLElement>('.payment-form .has-error input')?.focus())
      return
    }
    setProcessing(true)
    const ref = bookingReference(
      passengers,
      (['outbound', 'return'] as Leg[]).map((l) => selections[l]?.flight.id ?? ''),
    )
    setTimeout(() => onPaid(extras, payment, ref), 1400)
  }

  return (
    <form className="payment" onSubmit={submit} noValidate>
      <div className="step-heading">
        <div>
          <p className="eyebrow">Step 5 · Extras & payment</p>
          <h2>Almost there</h2>
          <p className="muted">Add any extras, then pay securely. This is a demo — no real charge is made.</p>
        </div>
      </div>

      <section className="card extras-card">
        <h3>Extras</h3>
        <div className="extras-grid">
          <div className="extra-row">
            <CountStepper
              id="bags"
              label="Checked bags"
              sublabel={`${money(EXTRA_PRICES.bag)} each · 23 kg`}
              value={extras.bags}
              min={0}
              max={paxCount * 2}
              onChange={(n) => setExtras({ bags: n })}
            />
          </div>
          <ExtraToggle
            id="insurance"
            label="Travel insurance"
            sublabel={`${money(EXTRA_PRICES.insurance)} per passenger · cancel for any reason`}
            checked={extras.insurance}
            onChange={(v) => setExtras({ insurance: v })}
          />
          <ExtraToggle
            id="priority"
            label="Priority boarding"
            sublabel={`${money(EXTRA_PRICES.priority)} per passenger · Group A`}
            checked={extras.priority}
            onChange={(v) => setExtras({ priority: v })}
          />
          <ExtraToggle
            id="wifi"
            label="In-flight Wi-Fi"
            sublabel={`${money(EXTRA_PRICES.wifi)} per passenger · whole trip`}
            checked={extras.wifi}
            onChange={(v) => setExtras({ wifi: v })}
          />
        </div>
      </section>

      <section className="card payment-form">
        <div className="payment-head">
          <h3>Payment</h3>
          <div className="card-brands" aria-hidden>
            {(['visa', 'mastercard', 'amex', 'discover'] as CardType[]).map((t) => (
              <CardIcon key={t} type={t} dim={cardType !== 'unknown' && cardType !== t} />
            ))}
          </div>
        </div>
        <div className="payment-body">
        <CardPreview payment={payment} cardType={cardType} valid={numberComplete && !liveNumberError} />
        <div className="form-grid">
          <Field id="card-name" label="Name on card" error={errors.name} className="col-12">
            <input
              className="input"
              autoComplete="off"
              value={payment.name}
              onChange={(e) => update({ name: e.target.value })}
              onBlur={() => blur('name')}
              {...fieldProps('card-name', errors.name)}
            />
          </Field>
          <Field
            id="card-number"
            label="Card number"
            error={errors.number ?? liveNumberError}
            hint={cardType !== 'unknown' ? `${CARD_LABEL[cardType]} detected` : 'Try 4242 4242 4242 4242'}
            className="col-12"
          >
            <div className={`card-input ${cardType}`}>
              <input
                className="input mono"
                inputMode="numeric"
                autoComplete="off"
                placeholder="1234 5678 9012 3456"
                value={payment.number}
                onChange={(e) => update({ number: formatCardNumber(e.target.value) })}
                onBlur={() => blur('number')}
                {...fieldProps('card-number', errors.number ?? liveNumberError)}
              />
              <span className="card-input-icon">
                <CardIcon type={cardType} />
              </span>
              {numberComplete && !liveNumberError && (
                <span className="card-input-check" aria-label="Valid card number">
                  <svg viewBox="0 0 16 16" width="16" height="16" aria-hidden>
                    <path d="M3 8.5l3 3 7-7" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                </span>
              )}
            </div>
          </Field>
          <Field id="card-expiry" label="Expiry" error={errors.expiry} className="col-4">
            <input
              className="input mono"
              inputMode="numeric"
              autoComplete="off"
              placeholder="MM/YY"
              value={payment.expiry}
              onChange={(e) => update({ expiry: formatExpiry(e.target.value) })}
              onBlur={() => blur('expiry')}
              {...fieldProps('card-expiry', errors.expiry)}
            />
          </Field>
          <Field id="card-cvv" label={cardType === 'amex' ? 'CID' : 'CVV'} error={errors.cvv} className="col-4">
            <input
              className="input mono"
              inputMode="numeric"
              autoComplete="off"
              placeholder={cardType === 'amex' ? '1234' : '123'}
              maxLength={cardType === 'amex' ? 4 : 3}
              value={payment.cvv}
              onChange={(e) => update({ cvv: e.target.value.replace(/\D/g, '') })}
              onBlur={() => blur('cvv')}
              {...fieldProps('card-cvv', errors.cvv)}
            />
          </Field>
          <Field id="card-zip" label="Billing ZIP" error={errors.zip} className="col-4">
            <input
              className="input mono"
              inputMode="numeric"
              autoComplete="off"
              placeholder="94103"
              maxLength={5}
              value={payment.zip}
              onChange={(e) => update({ zip: e.target.value.replace(/\D/g, '') })}
              onBlur={() => blur('zip')}
              {...fieldProps('card-zip', errors.zip)}
            />
          </Field>
        </div>
        </div>
        <p className="secure-note">
          <svg viewBox="0 0 24 24" width="14" height="14" aria-hidden>
            <path d="M6 10V8a6 6 0 1 1 12 0v2m-13 0h14v10H5z" fill="none" stroke="currentColor" strokeWidth="2" strokeLinejoin="round" />
          </svg>
          Encrypted demo checkout · nothing is stored or charged
        </p>
      </section>

      <div className="step-actions">
        <button type="button" className="btn btn-ghost" onClick={onBack} disabled={processing}>
          Back
        </button>
        <button type="submit" className={`btn btn-primary btn-lg ${processing ? 'loading' : ''}`} disabled={processing}>
          {processing ? (
            <>
              <span className="spinner" aria-hidden /> Processing…
            </>
          ) : (
            <>
              <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden>
                <path d="M6 10V8a6 6 0 1 1 12 0v2m-13 0h14v10H5z" fill="none" stroke="currentColor" strokeWidth="2" strokeLinejoin="round" />
              </svg>
              Pay {money(price.total)}
            </>
          )}
        </button>
      </div>
    </form>
  )
}

interface ToggleProps {
  id: string
  label: string
  sublabel: string
  checked: boolean
  onChange: (v: boolean) => void
}

function ExtraToggle({ id, label, sublabel, checked, onChange }: ToggleProps) {
  return (
    <label className={`extra-row toggle-row ${checked ? 'on' : ''}`} htmlFor={id}>
      <span className="count-stepper-text">
        <span className="count-stepper-label">{label}</span>
        <span className="count-stepper-sub">{sublabel}</span>
      </span>
      <input id={id} type="checkbox" role="switch" checked={checked} onChange={(e) => onChange(e.target.checked)} />
      <span className="switch" aria-hidden />
    </label>
  )
}

function CardPreview({ payment, cardType, valid }: { payment: PaymentDetails; cardType: CardType; valid: boolean }) {
  const digits = payment.number.replace(/\D/g, '')
  const groups = cardType === 'amex' ? [4, 6, 5] : [4, 4, 4, 4]
  let cursor = 0
  const shown = groups.map((len) => {
    const part = digits.slice(cursor, cursor + len)
    cursor += len
    return part.padEnd(len, '•')
  })
  return (
    <div className={`card-preview ${cardType} ${valid ? 'valid' : ''}`} aria-hidden>
      <div className="cp-top">
        <span className="cp-chip" />
        <span className="cp-brand">{cardType === 'unknown' ? 'Contrail Pay' : CARD_LABEL[cardType]}</span>
      </div>
      <div className="cp-number">
        {shown.map((g, i) => (
          <span key={i}>{g}</span>
        ))}
      </div>
      <div className="cp-bottom">
        <span className="cp-field">
          <small>Card holder</small>
          <strong>{payment.name.trim() ? payment.name.toUpperCase() : 'YOUR NAME'}</strong>
        </span>
        <span className="cp-field">
          <small>Expires</small>
          <strong>{payment.expiry || 'MM/YY'}</strong>
        </span>
      </div>
      <span className="cp-shine" />
    </div>
  )
}

export function CardIcon({ type, dim = false }: { type: CardType; dim?: boolean }) {
  const cls = `card-icon ${type} ${dim ? 'dim' : ''}`
  switch (type) {
    case 'visa':
      return (
        <svg className={cls} viewBox="0 0 48 32" width="40" height="26" aria-label="Visa">
          <rect width="48" height="32" rx="5" fill="#1a1f71" />
          <text x="24" y="21" textAnchor="middle" fontFamily="Arial Black, Arial, sans-serif" fontWeight="900" fontStyle="italic" fontSize="14" fill="#fff">
            VISA
          </text>
        </svg>
      )
    case 'mastercard':
      return (
        <svg className={cls} viewBox="0 0 48 32" width="40" height="26" aria-label="Mastercard">
          <rect width="48" height="32" rx="5" fill="#222" />
          <circle cx="19" cy="16" r="9" fill="#eb001b" />
          <circle cx="29" cy="16" r="9" fill="#f79e1b" fillOpacity=".92" />
        </svg>
      )
    case 'amex':
      return (
        <svg className={cls} viewBox="0 0 48 32" width="40" height="26" aria-label="American Express">
          <rect width="48" height="32" rx="5" fill="#2e77bb" />
          <text x="24" y="20" textAnchor="middle" fontFamily="Arial, sans-serif" fontWeight="700" fontSize="10" fill="#fff">
            AMEX
          </text>
        </svg>
      )
    case 'discover':
      return (
        <svg className={cls} viewBox="0 0 48 32" width="40" height="26" aria-label="Discover">
          <rect width="48" height="32" rx="5" fill="#f5f5f5" />
          <circle cx="36" cy="16" r="7" fill="#f76f20" />
          <text x="16" y="20" textAnchor="middle" fontFamily="Arial, sans-serif" fontWeight="700" fontSize="8" fill="#222">
            DISC
          </text>
        </svg>
      )
    default:
      return (
        <svg className={cls} viewBox="0 0 48 32" width="40" height="26" aria-label="Card">
          <rect width="48" height="32" rx="5" fill="#334155" />
          <rect x="4" y="9" width="40" height="5" fill="#0f172a" />
          <rect x="8" y="20" width="14" height="4" rx="1" fill="#94a3b8" />
        </svg>
      )
  }
}
