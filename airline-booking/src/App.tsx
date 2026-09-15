import { useCallback, useEffect, useMemo, useState } from 'react'
import type {
  Booking,
  Contact,
  Extras,
  FlightSelection,
  Leg,
  Passenger,
  PaymentDetails,
  SearchParams,
  SeatAssignments,
} from './types'
import { Stepper } from './components/Stepper'
import { STEPS } from './lib/steps'
import { TripSummary } from './components/TripSummary'
import { SearchStep } from './components/steps/SearchStep'
import { ResultsStep } from './components/steps/ResultsStep'
import { PassengersStep } from './components/steps/PassengersStep'
import { SeatsStep } from './components/steps/SeatsStep'
import { PaymentStep } from './components/steps/PaymentStep'
import { ConfirmationStep } from './components/steps/ConfirmationStep'
import { computePrice } from './lib/booking'
import { loadState, saveState, clearState, type PersistedState } from './lib/storage'

const EMPTY_SEARCH: SearchParams = {
  from: null,
  to: null,
  roundTrip: true,
  depart: null,
  ret: null,
  adults: 1,
  children: 0,
}

const EMPTY_EXTRAS: Extras = { bags: 0, insurance: false, priority: false, wifi: false }
const EMPTY_SEATS: SeatAssignments = { outbound: {}, return: {} }

function makePassengers(search: SearchParams, existing: Passenger[]): Passenger[] {
  const list: Passenger[] = []
  let id = 1
  for (let i = 0; i < search.adults; i++) list.push(blankPassenger(id++, 'adult'))
  for (let i = 0; i < search.children; i++) list.push(blankPassenger(id++, 'child'))
  return list.map((p) => {
    const prev = existing.find((e) => e.id === p.id && e.type === p.type)
    return prev ?? p
  })
}

function blankPassenger(id: number, type: Passenger['type']): Passenger {
  return {
    id,
    type,
    title: '',
    firstName: '',
    lastName: '',
    dob: '',
    nationality: '',
    passport: '',
    passportExpiry: '',
  }
}

export default function App() {
  const initial = useMemo(() => loadState(), [])
  const [step, setStep] = useState(initial?.step ?? 0)
  const [search, setSearch] = useState<SearchParams>(initial?.search ?? EMPTY_SEARCH)
  const [selections, setSelections] = useState<Partial<Record<Leg, FlightSelection>>>(initial?.selections ?? {})
  const [passengers, setPassengers] = useState<Passenger[]>(initial?.passengers ?? [])
  const [contact, setContact] = useState<Contact>(initial?.contact ?? { email: '', phone: '' })
  const [seats, setSeats] = useState<SeatAssignments>(initial?.seats ?? EMPTY_SEATS)
  const [extras, setExtras] = useState<Extras>(initial?.extras ?? EMPTY_EXTRAS)
  const [booking, setBooking] = useState<Booking | null>(initial?.booking ?? null)

  useEffect(() => {
    const state: PersistedState = { step, search, selections, passengers, contact, seats, extras, booking }
    saveState(state)
  }, [step, search, selections, passengers, contact, seats, extras, booking])

  useEffect(() => {
    window.scrollTo({ top: 0 })
  }, [step])

  const price = useMemo(
    () => computePrice(search, selections, passengers, seats, extras),
    [search, selections, passengers, seats, extras],
  )

  const restart = useCallback(() => {
    clearState()
    setStep(0)
    setSearch(EMPTY_SEARCH)
    setSelections({})
    setPassengers([])
    setContact({ email: '', phone: '' })
    setSeats(EMPTY_SEATS)
    setExtras(EMPTY_EXTRAS)
    setBooking(null)
  }, [])

  const goTo = (n: number) => {
    if (booking) return
    if (n <= step) setStep(n)
  }

  const onSearch = (params: SearchParams) => {
    const routeChanged =
      params.from?.code !== search.from?.code ||
      params.to?.code !== search.to?.code ||
      params.roundTrip !== search.roundTrip
    setSearch(params)
    if (routeChanged) {
      setSelections({})
      setSeats(EMPTY_SEATS)
    }
    setPassengers((prev) => makePassengers(params, prev))
    setStep(1)
  }

  const onFlightsChanged = (sel: Partial<Record<Leg, FlightSelection>>) => {
    const changed =
      sel.outbound?.flight.id !== selections.outbound?.flight.id ||
      sel.return?.flight.id !== selections.return?.flight.id
    setSelections(sel)
    if (changed) setSeats(EMPTY_SEATS)
  }

  const onFlightsChosen = (sel: Partial<Record<Leg, FlightSelection>>) => {
    onFlightsChanged(sel)
    setStep(2)
  }

  const onPassengersDone = (list: Passenger[], c: Contact) => {
    setPassengers(list)
    setContact(c)
    setStep(3)
  }

  const onSeatsDone = (s: SeatAssignments) => {
    setSeats(s)
    setStep(4)
  }

  const onPaid = (e: Extras, p: PaymentDetails, ref: string) => {
    setExtras(e)
    const finalPrice = computePrice(search, selections, passengers, seats, e)
    setBooking({
      reference: ref,
      paidAt: new Date().toISOString(),
      total: finalPrice.total,
      last4: p.number.replace(/\D/g, '').slice(-4),
    })
    setStep(5)
  }

  const showSummary = step >= 1 && step <= 4

  return (
    <div className="app">
      <a className="skip-link" href="#main-content">
        Skip to booking
      </a>
      <header className="site-header">
        <div className="topbar">
          <button className="brand" onClick={restart} title="Start over">
            <span className="brand-mark" aria-hidden>
              <svg viewBox="0 0 48 48" width="44" height="44">
                <path d="M6 34 39 9 25 35l-5-11z" fill="currentColor" />
                <path d="m7 40 17-9" fill="none" stroke="currentColor" strokeWidth="1.5" />
              </svg>
            </span>
            <span className="brand-name">
              Contrail<span>Air</span>
            </span>
          </button>
          <span className="brand-promise">A little further. A little closer.</span>
          <div className="topbar-right">
            <span className="locale">
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="1.5"
                aria-hidden
              >
                <circle cx="12" cy="12" r="9" />
                <ellipse cx="12" cy="12" rx="4" ry="9" />
                <path d="M3 12h18" />
              </svg>
              English <span>·</span> USD
            </span>
            <button className="btn btn-ghost btn-sm" onClick={restart}>
              Start over
            </button>
          </div>
        </div>
        <div className="journey-bar">
          <div className="journey-bar-inner">
            <span className="journey-label">Your booking</span>
            <Stepper current={step} onSelect={goTo} locked={Boolean(booking)} />
            <span className="step-count">
              {String(step + 1).padStart(2, '0')} <span>/ {String(STEPS.length).padStart(2, '0')}</span>
            </span>
          </div>
        </div>
      </header>

      <main id="main-content" className={`content ${showSummary ? 'with-summary' : ''} step-${STEPS[step].id}`}>
        <section className="main-col step-panel" key={step}>
          {step === 0 && <SearchStep initial={search} onSearch={onSearch} />}
          {step === 1 && (
            <ResultsStep
              search={search}
              initial={selections}
              onChange={onFlightsChanged}
              onDone={onFlightsChosen}
              onBack={() => setStep(0)}
            />
          )}
          {step === 2 && (
            <PassengersStep
              search={search}
              passengers={passengers}
              contact={contact}
              onDone={onPassengersDone}
              onBack={() => setStep(1)}
            />
          )}
          {step === 3 && (
            <SeatsStep
              search={search}
              selections={selections}
              passengers={passengers}
              initial={seats}
              onDone={onSeatsDone}
              onBack={() => setStep(2)}
            />
          )}
          {step === 4 && (
            <PaymentStep
              search={search}
              selections={selections}
              passengers={passengers}
              seats={seats}
              extras={extras}
              onExtrasChange={setExtras}
              onPaid={onPaid}
              onBack={() => setStep(3)}
            />
          )}
          {step === 5 && booking && (
            <ConfirmationStep
              search={search}
              selections={selections}
              passengers={passengers}
              contact={contact}
              seats={seats}
              extras={extras}
              booking={booking}
              onRestart={restart}
            />
          )}
        </section>
        {showSummary && (
          <aside className="summary-col">
            <TripSummary search={search} selections={selections} passengers={passengers} seats={seats} price={price} />
          </aside>
        )}
      </main>
      <footer className="site-footer">
        <span className="footer-brand">
          Contrail Air <span>A better journey begins here.</span>
        </span>
        <span>Demo booking experience · No real tickets or charges</span>
      </footer>
    </div>
  )
}
