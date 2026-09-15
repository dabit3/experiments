import { useState, type ChangeEvent, type FormEvent } from 'react'
import { US_STATES, validateShipping, type Errors, type ShippingInfo } from '../../lib/validation'
import { Field } from './Field'
import { fieldA11y } from './fieldA11y'

interface Props {
  value: ShippingInfo
  onChange: (value: ShippingInfo) => void
  onSubmit: () => void
  onBack: () => void
  submitLabel: string
}

export function ShippingForm({ value, onChange, onSubmit, onBack, submitLabel }: Props) {
  const [attempted, setAttempted] = useState(false)
  const errors: Errors<ShippingInfo> = attempted ? validateShipping(value) : {}

  const set = (field: keyof ShippingInfo) => (e: ChangeEvent<HTMLInputElement | HTMLSelectElement>) =>
    onChange({ ...value, [field]: e.target.value })

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault()
    setAttempted(true)
    if (Object.keys(validateShipping(value)).length === 0) onSubmit()
  }

  return (
    <form className="form" onSubmit={handleSubmit} noValidate data-testid="shipping-form">
      <h2 className="form__title">Shipping address</h2>
      <p className="form__subtitle">Where should we send your order?</p>

      <Field id="fullName" label="Full name" error={errors.fullName}>
        <input className="input" autoComplete="name" placeholder="Ada Lovelace" value={value.fullName} onChange={set('fullName')} {...fieldA11y('fullName', errors.fullName)} />
      </Field>

      <Field id="email" label="Email" error={errors.email} hint="We’ll send your receipt here">
        <input className="input" type="email" autoComplete="email" placeholder="ada@example.com" value={value.email} onChange={set('email')} {...fieldA11y('email', errors.email)} />
      </Field>

      <Field id="address1" label="Street address" error={errors.address1}>
        <input className="input" autoComplete="address-line1" placeholder="1234 Market St" value={value.address1} onChange={set('address1')} {...fieldA11y('address1', errors.address1)} />
      </Field>

      <Field id="address2" label="Apt, suite, etc." optional>
        <input className="input" autoComplete="address-line2" placeholder="Apt 4B" value={value.address2} onChange={set('address2')} id="address2" />
      </Field>

      <div className="form__row form__row--city">
        <Field id="city" label="City" error={errors.city}>
          <input className="input" autoComplete="address-level2" placeholder="San Francisco" value={value.city} onChange={set('city')} {...fieldA11y('city', errors.city)} />
        </Field>
        <Field id="state" label="State" error={errors.state}>
          <select className="input" autoComplete="address-level1" value={value.state} onChange={set('state')} {...fieldA11y('state', errors.state)}>
            <option value="">—</option>
            {US_STATES.map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </select>
        </Field>
        <Field id="zip" label="ZIP" error={errors.zip}>
          <input className="input" inputMode="numeric" autoComplete="postal-code" placeholder="94103" value={value.zip} onChange={set('zip')} {...fieldA11y('zip', errors.zip)} />
        </Field>
      </div>

      {attempted && Object.keys(errors).length > 0 && (
        <p className="form__summary-error" role="alert">
          Please fix the {Object.keys(errors).length} highlighted field{Object.keys(errors).length > 1 ? 's' : ''} to continue.
        </p>
      )}

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
