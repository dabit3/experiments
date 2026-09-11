import { useState } from 'react'
import type {
  Booking,
  Contact,
  Extras,
  FlightSelection,
  Leg,
  Passenger,
  SearchParams,
  SeatAssignments,
} from '../../types'
import { AIRPORT_BY_CODE } from '../../data/airports'
import { FARES } from '../../data/flights'
import { formatLong, to12h } from '../../lib/date'
import { legTimes, money, passengerFullName } from '../../lib/booking'
import { buildIcs, downloadTextFile, type IcsEvent } from '../../lib/ics'
import { BoardingPass } from '../BoardingPass'

interface Props {
  search: SearchParams
  selections: Partial<Record<Leg, FlightSelection>>
  passengers: Passenger[]
  contact: Contact
  seats: SeatAssignments
  extras: Extras
  booking: Booking
  onRestart: () => void
}

export function ConfirmationStep({
  search,
  selections,
  passengers,
  contact,
  seats,
  extras,
  booking,
  onRestart,
}: Props) {
  const legs: Leg[] = search.roundTrip && selections.return ? ['outbound', 'return'] : ['outbound']
  const [downloaded, setDownloaded] = useState(false)

  const legDate = (leg: Leg) => (leg === 'outbound' ? search.depart! : search.ret!)

  const downloadIcs = () => {
    const events: IcsEvent[] = legs.map((leg) => {
      const { flight } = selections[leg]!
      const date = legDate(leg)
      const times = legTimes(flight, date)
      const from = AIRPORT_BY_CODE[flight.from]
      const to = AIRPORT_BY_CODE[flight.to]
      const seatList = passengers.map((p) => `${passengerFullName(p)}: ${seats[leg][p.id]}`).join(', ')
      return {
        uid: `${booking.reference}-${leg}-${flight.id}@contrail.example`,
        start: times.departUtc,
        end: times.arriveUtc,
        summary: `Flight ${flight.number} ${flight.from} → ${flight.to}`,
        description: [
          `${flight.airline.name} ${flight.number} · ${FARES[selections[leg]!.fare].label} fare`,
          `Departs ${from.city} ${to12h(flight.depart)} · Arrives ${to.city} ${to12h(times.arriveLocal)}${times.dayOffset ? ` (+${times.dayOffset} day)` : ''}`,
          `Booking reference ${booking.reference}`,
          `Seats — ${seatList}`,
          flight.stops ? `${flight.stops} stop via ${flight.via.join(', ')}` : 'Nonstop',
        ].join('\n'),
        location: `${from.name} (${from.code}), ${from.city}`,
      }
    })
    downloadTextFile(`contrail-${booking.reference}.ics`, buildIcs(events), 'text/calendar;charset=utf-8')
    setDownloaded(true)
  }

  return (
    <div className="confirmation">
      <div className="confirm-hero card">
        <span className="confirm-check" aria-hidden>
          <svg viewBox="0 0 24 24" width="30" height="30">
            <path
              className="check-path"
              d="M5 12.5l4.5 4.5L19 7.5"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.8"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        </span>
        <div className="confirm-copy">
          <p className="eyebrow">Step 6 · Booking confirmed</p>
          <h2>You're all set, {passengers[0]?.firstName || 'traveller'}.</h2>
          <p className="muted">Your next chapter starts here. Your itinerary and boarding passes are ready below.</p>
          <p className="confirm-payment">
            {money(booking.total)} · Card ending {booking.last4} · <strong>{contact.email}</strong>
          </p>
          <div className="confirm-ref">
            <span className="confirm-ref-label">Booking reference</span>
            <span className="ref">{booking.reference}</span>
          </div>
        </div>
        <div className="confirm-actions">
          <button type="button" className="btn btn-primary" onClick={downloadIcs}>
            <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden>
              <path
                d="M12 4v11m0 0l-4-4m4 4l4-4M5 19h14"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
            Download .ics
          </button>
          <button type="button" className="btn btn-outline" onClick={() => window.print()}>
            Print passes
          </button>
        </div>
        {downloaded && (
          <p className="confirm-toast" role="status">
            Calendar file saved — {legs.length} flight{legs.length > 1 ? 's' : ''} added with a 3-hour reminder.
          </p>
        )}
      </div>

      <div className="boarding-intro">
        <div>
          <p className="eyebrow">Ready for departure</p>
          <h2>Your boarding passes</h2>
        </div>
        <p className="muted">Please arrive at the airport 3 hours before departure.</p>
      </div>
      {legs.map((leg) => {
        const { flight, fare } = selections[leg]!
        const date = legDate(leg)
        const times = legTimes(flight, date)
        return (
          <section key={leg} className="pass-group">
            <header className="pass-group-head">
              <h3>
                {leg === 'outbound' ? 'Outbound' : 'Return'} · {AIRPORT_BY_CODE[flight.from].city} →{' '}
                {AIRPORT_BY_CODE[flight.to].city}
              </h3>
              <span className="muted">
                {formatLong(date)} · {to12h(flight.depart)} – {to12h(times.arriveLocal)}
                {times.dayOffset > 0 ? ` (+${times.dayOffset})` : ''} ·{' '}
                {flight.stops === 0 ? 'Nonstop' : `${flight.stops} stop`}
              </span>
            </header>
            <div className="pass-grid">
              {passengers.map((p, i) => (
                <BoardingPass
                  key={p.id}
                  passenger={p}
                  index={i}
                  flight={flight}
                  date={date}
                  seat={seats[leg][p.id] ?? '—'}
                  reference={booking.reference}
                  fareLabel={FARES[fare].label}
                  priority={extras.priority}
                />
              ))}
            </div>
          </section>
        )
      })}

      <div className="step-actions center">
        <button type="button" className="btn btn-ghost" onClick={onRestart}>
          Book another trip
        </button>
      </div>
    </div>
  )
}
