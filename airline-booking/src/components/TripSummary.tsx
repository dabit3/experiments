import type { FlightSelection, Leg, Passenger, SearchParams, SeatAssignments } from '../types'
import { FARES, farePrice } from '../data/flights'
import { formatMedium, to12h } from '../lib/date'
import { money, passengerFullName, type PriceBreakdown } from '../lib/booking'

interface Props {
  search: SearchParams
  selections: Partial<Record<Leg, FlightSelection>>
  passengers: Passenger[]
  seats: SeatAssignments
  price: PriceBreakdown
}

export function TripSummary({ search, selections, passengers, seats, price }: Props) {
  const paxCount = search.adults + search.children
  const legs: Leg[] = search.roundTrip ? ['outbound', 'return'] : ['outbound']
  return (
    <div className="card trip-summary">
      <div className="summary-heading">
        <h3>Your trip</h3>
        <div className="summary-route">
          <div>
            <span className="summary-code">{search.from?.code}</span>
            <span className="summary-city">{search.from?.city}</span>
          </div>
          <span className="summary-arrow">{search.roundTrip ? '⇄' : '→'}</span>
          <div>
            <span className="summary-code">{search.to?.code}</span>
            <span className="summary-city">{search.to?.city}</span>
          </div>
        </div>
        <p className="muted">
          {formatMedium(search.depart)}
          {search.roundTrip && ` – ${formatMedium(search.ret)}`} · {paxCount} passenger{paxCount === 1 ? '' : 's'}
        </p>
      </div>

      <ul className="summary-legs">
        {legs.map((leg) => {
          const sel = selections[leg]
          return (
            <li key={leg} className={sel ? '' : 'pending'}>
              <span className="summary-leg-title">{leg === 'outbound' ? 'Outbound' : 'Return'}</span>
              {sel ? (
                <>
                  <span>
                    {sel.flight.airline.name} {sel.flight.number} · {to12h(sel.flight.depart)}
                  </span>
                  <span className="muted">
                    {FARES[sel.fare].label} · {money(farePrice(sel.flight, sel.fare))} × {paxCount}
                  </span>
                  {passengers.some((p) => seats[leg][p.id]) && (
                    <span className="muted">
                      Seats:{' '}
                      {passengers
                        .map((p) => seats[leg][p.id])
                        .filter(Boolean)
                        .join(', ')}
                    </span>
                  )}
                </>
              ) : (
                <span className="muted">Not chosen yet</span>
              )}
            </li>
          )
        })}
      </ul>

      {passengers.some((p) => p.firstName) && (
        <ul className="summary-pax">
          {passengers.map((p) => (
            <li key={p.id}>
              {passengerFullName(p) || `Passenger ${p.id}`} <span className="muted">· {p.type}</span>
            </li>
          ))}
        </ul>
      )}

      <dl className="summary-totals">
        {price.fares.map((f) => (
          <div key={f.leg}>
            <dt>
              {f.leg === 'outbound' ? 'Outbound' : 'Return'} fares × {f.count}
            </dt>
            <dd>{money(f.total)}</dd>
          </div>
        ))}
        {price.seats > 0 && (
          <div>
            <dt>Seat fees</dt>
            <dd>{money(price.seats)}</dd>
          </div>
        )}
        {price.extras.map((e) => (
          <div key={e.label}>
            <dt>{e.label}</dt>
            <dd>{money(e.total)}</dd>
          </div>
        ))}
        {price.fares.length > 0 && (
          <div>
            <dt>Taxes & fees</dt>
            <dd>{money(price.taxes)}</dd>
          </div>
        )}
        <div className="total">
          <dt>
            Total{' '}
            <small>
              {paxCount} traveller{paxCount === 1 ? '' : 's'} · USD
            </small>
          </dt>
          <dd aria-live="polite">{money(price.total)}</dd>
        </div>
      </dl>
      <p className="summary-note">
        All prices in US dollars.
        <br />
        Taxes and selected extras included in your total.
      </p>
    </div>
  )
}
