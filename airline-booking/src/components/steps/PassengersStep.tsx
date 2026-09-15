import { useState, type FormEvent } from 'react'
import type { Contact, Passenger, SearchParams } from '../../types'
import { NATIONALITIES } from '../../data/airports'
import { maskISODate } from '../../lib/date'
import { hasErrors, validateContact, validatePassenger, type Errors } from '../../lib/validation'
import { Field } from '../Field'
import { fieldProps } from '../../lib/fieldProps'

interface Props {
  search: SearchParams
  passengers: Passenger[]
  contact: Contact
  onDone: (passengers: Passenger[], contact: Contact) => void
  onBack: () => void
}

const TITLES = ['Mr', 'Ms', 'Mrs', 'Mx', 'Dr']

export function PassengersStep({ search, passengers: initial, contact: initialContact, onDone, onBack }: Props) {
  const [passengers, setPassengers] = useState<Passenger[]>(initial)
  const [contact, setContact] = useState<Contact>(initialContact)
  const [errors, setErrors] = useState<Record<number, Errors<Passenger>>>({})
  const [contactErrors, setContactErrors] = useState<Errors<Contact>>({})
  const [submitted, setSubmitted] = useState(false)

  const ctx = { departDate: search.depart!, lastTravelDate: search.roundTrip && search.ret ? search.ret : search.depart! }

  const validateAll = (list: Passenger[], c: Contact) => {
    const next: Record<number, Errors<Passenger>> = {}
    for (const p of list) {
      const e = validatePassenger(p, ctx)
      if (hasErrors(e)) next[p.id] = e
    }
    return { pax: next, contact: validateContact(c) }
  }

  const update = (id: number, patch: Partial<Passenger>) => {
    setPassengers((list) => {
      const next = list.map((p) => (p.id === id ? { ...p, ...patch } : p))
      if (submitted) {
        const p = next.find((x) => x.id === id)!
        const e = validatePassenger(p, ctx)
        setErrors((prev) => ({ ...prev, [id]: e }))
      }
      return next
    })
  }

  const updateContact = (patch: Partial<Contact>) => {
    setContact((c) => {
      const next = { ...c, ...patch }
      if (submitted) setContactErrors(validateContact(next))
      return next
    })
  }

  const submit = (e: FormEvent) => {
    e.preventDefault()
    setSubmitted(true)
    const result = validateAll(passengers, contact)
    setErrors(result.pax)
    setContactErrors(result.contact)
    const errorCount =
      Object.values(result.pax).reduce((n, e) => n + Object.keys(e).length, 0) + Object.keys(result.contact).length
    if (errorCount === 0) {
      onDone(passengers, contact)
      return
    }
    requestAnimationFrame(() => {
      document.querySelector<HTMLElement>('.has-error input, .has-error select')?.focus()
    })
  }

  const totalErrors =
    Object.values(errors).reduce((n, e) => n + Object.keys(e).length, 0) + Object.keys(contactErrors).length

  return (
    <form className="passengers" onSubmit={submit} noValidate>
      <div className="step-heading">
        <div>
          <p className="eyebrow">Step 3 · Passenger details</p>
          <h2>Who's flying?</h2>
          <p className="muted">
            Names must match each passenger's passport. Passports must be valid for at least 6 months after your last flight.
          </p>
        </div>
      </div>

      {submitted && totalErrors > 0 && (
        <div className="banner banner-error" role="alert">
          Please fix {totalErrors} {totalErrors === 1 ? 'issue' : 'issues'} below to continue.
        </div>
      )}

      {passengers.map((p, idx) => {
        const e = errors[p.id] ?? {}
        const pid = `p${p.id}`
        return (
          <section key={p.id} className="card passenger-card">
            <header className="passenger-card-head">
              <span className="passenger-avatar">{idx + 1}</span>
              <div>
                <h3>Passenger {idx + 1}</h3>
                <span className="muted">{p.type === 'adult' ? 'Adult · 12+' : 'Child · 2–11'}</span>
              </div>
            </header>
            <div className="form-grid">
              <Field id={`${pid}-title`} label="Title" error={e.title} className="col-2">
                <select
                  className="input"
                  value={p.title}
                  onChange={(ev) => update(p.id, { title: ev.target.value })}
                  {...fieldProps(`${pid}-title`, e.title)}
                >
                  <option value="">—</option>
                  {TITLES.map((t) => (
                    <option key={t}>{t}</option>
                  ))}
                </select>
              </Field>
              <Field id={`${pid}-first`} label="First name" error={e.firstName} className="col-5">
                <input
                  className="input"
                  autoComplete="off"
                  value={p.firstName}
                  onChange={(ev) => update(p.id, { firstName: ev.target.value })}
                  {...fieldProps(`${pid}-first`, e.firstName)}
                />
              </Field>
              <Field id={`${pid}-last`} label="Last name" error={e.lastName} className="col-5">
                <input
                  className="input"
                  autoComplete="off"
                  value={p.lastName}
                  onChange={(ev) => update(p.id, { lastName: ev.target.value })}
                  {...fieldProps(`${pid}-last`, e.lastName)}
                />
              </Field>

              <Field id={`${pid}-dob`} label="Date of birth" error={e.dob} hint="YYYY-MM-DD" className="col-4">
                <input
                  className="input mono"
                  inputMode="numeric"
                  placeholder="YYYY-MM-DD"
                  value={p.dob}
                  onChange={(ev) => update(p.id, { dob: maskISODate(ev.target.value) })}
                  {...fieldProps(`${pid}-dob`, e.dob)}
                />
              </Field>
              <Field id={`${pid}-nat`} label="Nationality" error={e.nationality} className="col-8">
                <select
                  className="input"
                  value={p.nationality}
                  onChange={(ev) => update(p.id, { nationality: ev.target.value })}
                  {...fieldProps(`${pid}-nat`, e.nationality)}
                >
                  <option value="">Select a country</option>
                  {NATIONALITIES.map((n) => (
                    <option key={n}>{n}</option>
                  ))}
                </select>
              </Field>

              <Field id={`${pid}-passport`} label="Passport number" error={e.passport} className="col-6">
                <input
                  className="input mono"
                  autoComplete="off"
                  value={p.passport}
                  onChange={(ev) => update(p.id, { passport: ev.target.value.toUpperCase() })}
                  {...fieldProps(`${pid}-passport`, e.passport)}
                />
              </Field>
              <Field id={`${pid}-exp`} label="Passport expiry" error={e.passportExpiry} hint="YYYY-MM-DD" className="col-6">
                <input
                  className="input mono"
                  inputMode="numeric"
                  placeholder="YYYY-MM-DD"
                  value={p.passportExpiry}
                  onChange={(ev) => update(p.id, { passportExpiry: maskISODate(ev.target.value) })}
                  {...fieldProps(`${pid}-exp`, e.passportExpiry)}
                />
              </Field>
            </div>
          </section>
        )
      })}

      <section className="card passenger-card">
        <header className="passenger-card-head">
          <span className="passenger-avatar contact">@</span>
          <div>
            <h3>Contact details</h3>
            <span className="muted">We'll send the boarding passes here</span>
          </div>
        </header>
        <div className="form-grid">
          <Field id="contact-email" label="Email" error={contactErrors.email} className="col-7">
            <input
              className="input"
              type="email"
              autoComplete="off"
              value={contact.email}
              onChange={(ev) => updateContact({ email: ev.target.value })}
              {...fieldProps('contact-email', contactErrors.email)}
            />
          </Field>
          <Field id="contact-phone" label="Phone" error={contactErrors.phone} className="col-5">
            <input
              className="input"
              type="tel"
              autoComplete="off"
              placeholder="+1 415 555 0100"
              value={contact.phone}
              onChange={(ev) => updateContact({ phone: ev.target.value })}
              {...fieldProps('contact-phone', contactErrors.phone)}
            />
          </Field>
        </div>
      </section>

      <div className="step-actions">
        <button type="button" className="btn btn-ghost" onClick={onBack}>
          Back
        </button>
        <button type="submit" className="btn btn-primary btn-lg">
          Continue to seats
        </button>
      </div>
    </form>
  )
}
