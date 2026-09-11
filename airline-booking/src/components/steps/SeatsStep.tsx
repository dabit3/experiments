import { useMemo, useState } from 'react'
import type { FlightSelection, Leg, Passenger, SearchParams, SeatAssignments } from '../../types'
import { passengerFullName, money } from '../../lib/booking'
import {
  EXIT_ROW_FEE,
  PREFERRED_FEE,
  ROWS,
  SEAT_LETTERS,
  seatFee,
  seatKind,
  seatPosition,
  takenSeats,
} from '../../lib/seats'
import { formatMedium, to12h } from '../../lib/date'

interface Props {
  search: SearchParams
  selections: Partial<Record<Leg, FlightSelection>>
  passengers: Passenger[]
  initial: SeatAssignments
  onDone: (seats: SeatAssignments) => void
  onBack: () => void
}

export function SeatsStep({ search, selections, passengers, initial, onDone, onBack }: Props) {
  const legs: Leg[] = search.roundTrip && selections.return ? ['outbound', 'return'] : ['outbound']
  const [leg, setLeg] = useState<Leg>('outbound')
  const [seats, setSeats] = useState<SeatAssignments>(initial)
  const [activePax, setActivePax] = useState<number>(passengers[0]?.id ?? 1)
  const [notice, setNotice] = useState<string | null>(null)

  const flight = selections[leg]!.flight
  const taken = useMemo(() => takenSeats(flight.id), [flight.id])
  const legSeats = seats[leg]

  const ownerOf = (seat: string): Passenger | undefined =>
    passengers.find((p) => legSeats[p.id] === seat)

  const clickSeat = (seat: string) => {
    if (taken.has(seat)) return
    const owner = ownerOf(seat)
    const pax = passengers.find((p) => p.id === activePax)!
    if (owner) {
      // clicking an assigned seat releases it
      setSeats((s) => ({ ...s, [leg]: { ...s[leg], [owner.id]: undefined } }))
      setActivePax(owner.id)
      setNotice(null)
      return
    }
    if (pax.type === 'child' && seatKind(Number(seat.replace(/\D/g, ''))) === 'exit') {
      setNotice(`Exit-row seats can't be assigned to children. Pick another seat for ${passengerFullName(pax) || `Passenger ${pax.id}`}.`)
      return
    }
    setNotice(null)
    const nextLeg = { ...legSeats, [pax.id]: seat }
    setSeats((s) => ({ ...s, [leg]: nextLeg }))
    const nextUnassigned = passengers.find((p) => p.id !== pax.id && !nextLeg[p.id])
    if (nextUnassigned) setActivePax(nextUnassigned.id)
  }

  const legComplete = (l: Leg) => passengers.every((p) => Boolean(seats[l][p.id]))
  const allComplete = legs.every(legComplete)

  const copyOutboundToReturn = () => {
    const ret = selections.return!.flight
    const retTaken = takenSeats(ret.id)
    const copy: Record<number, string | undefined> = {}
    let blocked = false
    for (const p of passengers) {
      const s = seats.outbound[p.id]
      if (s && !retTaken.has(s)) copy[p.id] = s
      else blocked = true
    }
    setSeats((s) => ({ ...s, return: copy }))
    setLeg('return')
    setNotice(blocked ? 'Some outbound seats are already taken on the return flight — pick replacements below.' : null)
    const firstMissing = passengers.find((p) => !copy[p.id])
    setActivePax(firstMissing?.id ?? passengers[0].id)
  }

  const legFees = (l: Leg) => Object.values(seats[l]).reduce((n, s) => n + seatFee(s), 0)

  return (
    <div className="seats">
      <div className="step-heading">
        <div>
          <p className="eyebrow">Step 4 · Seat selection</p>
          <h2>Pick your seats</h2>
          <p className="muted">Click a passenger, then click a seat. Click an assigned seat to release it.</p>
        </div>
      </div>

      {legs.length > 1 && (
        <div className="leg-tabs" role="tablist">
          {legs.map((l) => {
            const f = selections[l]!.flight
            return (
              <button
                key={l}
                type="button"
                role="tab"
                aria-selected={leg === l}
                className={`leg-tab ${leg === l ? 'active' : ''} ${legComplete(l) ? 'complete' : ''}`}
                onClick={() => {
                  setLeg(l)
                  setNotice(null)
                  setActivePax(passengers.find((p) => !seats[l][p.id])?.id ?? passengers[0].id)
                }}
              >
                <span className="leg-tab-title">
                  {l === 'outbound' ? 'Outbound' : 'Return'} · {f.from} → {f.to}
                </span>
                <span className="leg-tab-sub">
                  {formatMedium(l === 'outbound' ? search.depart : search.ret)} · {to12h(f.depart)} · {f.number}
                </span>
                <span className="leg-tab-status">{legComplete(l) ? 'Seats chosen' : `${passengers.filter((p) => seats[l][p.id]).length}/${passengers.length} chosen`}</span>
              </button>
            )
          })}
        </div>
      )}

      <div className="seat-layout">
        <aside className="seat-side card">
          <h3>Passengers</h3>
          <ul className="pax-list">
            {passengers.map((p, i) => {
              const seat = legSeats[p.id]
              return (
                <li key={p.id}>
                  <button
                    type="button"
                    className={`pax-btn ${activePax === p.id ? 'active' : ''}`}
                    onClick={() => setActivePax(p.id)}
                    aria-pressed={activePax === p.id}
                  >
                    <span className={`pax-dot pax-${i + 1}`}>{i + 1}</span>
                    <span className="pax-text">
                      <span className="pax-name">{passengerFullName(p) || `Passenger ${i + 1}`}</span>
                      <span className="pax-seat">
                        {seat ? `Seat ${seat} · ${seatPosition(seat)}${seatFee(seat) ? ` · +${money(seatFee(seat))}` : ''}` : 'No seat yet'}
                      </span>
                    </span>
                  </button>
                </li>
              )
            })}
          </ul>

          <h3>Legend</h3>
          <ul className="legend">
            <li>
              <span className="seat-swatch standard" /> Standard · free
            </li>
            <li>
              <span className="seat-swatch preferred" /> Preferred (rows 1–3) · +{money(PREFERRED_FEE)}
            </li>
            <li>
              <span className="seat-swatch exit" /> Exit row · extra legroom · +{money(EXIT_ROW_FEE)}
            </li>
            <li>
              <span className="seat-swatch taken" /> Taken
            </li>
            <li>
              <span className="seat-swatch selected" /> Your seats
            </li>
          </ul>

          {leg === 'return' && (
            <button type="button" className="btn btn-outline btn-block" onClick={copyOutboundToReturn}>
              Use the same seats as outbound
            </button>
          )}
          <div className="seat-fees">
            <span>Seat fees ({leg === 'outbound' ? 'outbound' : 'return'})</span>
            <strong>{money(legFees(leg))}</strong>
          </div>
        </aside>

        <div className="seat-map-wrap card">
          <div className="seat-map-header">
            <span className="airline-logo small" style={{ background: flight.airline.color }}>
              {flight.airline.code}
            </span>
            <span>
              {flight.airline.name} {flight.number} · {flight.aircraft} · 3-3 · {ROWS} rows
            </span>
          </div>
          {notice && (
            <div className="banner banner-warn" role="alert">
              {notice}
            </div>
          )}
          <div className="cabin">
            <div className="cabin-nose" aria-hidden />
            <div className="cabin-wing left" aria-hidden />
            <div className="cabin-wing right" aria-hidden />
            <div className="cabin-front-label" aria-hidden>
              Front of aircraft
            </div>
            <div className="seat-grid" role="grid" aria-label="Seat map">
              <div className="seat-row seat-row-letters" aria-hidden>
                <span className="row-num" />
                {SEAT_LETTERS.slice(0, 3).map((l) => (
                  <span key={l} className="seat-letter">
                    {l}
                  </span>
                ))}
                <span className="aisle" />
                {SEAT_LETTERS.slice(3).map((l) => (
                  <span key={l} className="seat-letter">
                    {l}
                  </span>
                ))}
                <span className="row-num" />
              </div>
              {Array.from({ length: ROWS }, (_, i) => i + 1).map((row) => {
                const kind = seatKind(row)
                return (
                  <div key={row} className={`seat-row kind-${kind}`} role="row">
                    <span className="row-num">{kind === 'exit' ? <span className="exit-tag">EXIT</span> : row}</span>
                    {SEAT_LETTERS.flatMap((letter, idx) => {
                      const seat = `${row}${letter}`
                      const isTaken = taken.has(seat)
                      const owner = ownerOf(seat)
                      const ownerIdx = owner ? passengers.indexOf(owner) + 1 : 0
                      const cell = (
                          <button
                            key={seat}
                            type="button"
                            role="gridcell"
                            className={`seat ${kind} ${isTaken ? 'taken' : ''} ${owner ? `selected pax-${ownerIdx}` : ''}`}
                            disabled={isTaken}
                            onClick={() => clickSeat(seat)}
                            aria-label={`Seat ${seat}, ${seatPosition(seat)}${isTaken ? ', taken' : owner ? `, ${passengerFullName(owner)}` : ''}${
                              kind === 'exit' ? `, exit row +$${EXIT_ROW_FEE}` : kind === 'preferred' ? `, preferred +$${PREFERRED_FEE}` : ''
                            }`}
                            title={`${seat} · ${seatPosition(seat)}${isTaken ? ' · Taken' : kind === 'exit' ? ` · Exit row +$${EXIT_ROW_FEE}` : kind === 'preferred' ? ` · Preferred +$${PREFERRED_FEE}` : ''}`}
                          >
                            {owner ? ownerIdx : isTaken ? '' : letter}
                          </button>
                      )
                      return idx === 3
                        ? [
                            <span key={`aisle-${row}`} className="aisle">
                              {row}
                            </span>,
                            cell,
                          ]
                        : [cell]
                    })}
                    <span className="row-num">{kind === 'exit' ? <span className="exit-tag">EXIT</span> : row}</span>
                  </div>
                )
              })}
            </div>
            <div className="cabin-tail" aria-hidden />
          </div>
        </div>
      </div>

      <div className="step-actions">
        <button type="button" className="btn btn-ghost" onClick={onBack}>
          Back
        </button>
        <div className="step-actions-right">
          {!allComplete && (
            <span className="muted">
              {legs.length > 1 ? 'Choose a seat for every passenger on both flights' : 'Choose a seat for every passenger'}
            </span>
          )}
          {legs.length > 1 && leg === 'outbound' && legComplete('outbound') && !legComplete('return') ? (
            <button
              type="button"
              className="btn btn-primary btn-lg"
              onClick={() => {
                setLeg('return')
                setNotice(null)
                setActivePax(passengers.find((p) => !seats.return[p.id])?.id ?? passengers[0].id)
              }}
            >
              Next: return seats
            </button>
          ) : (
            <button type="button" className="btn btn-primary btn-lg" disabled={!allComplete} onClick={() => onDone(seats)}>
              Continue to payment
            </button>
          )}
        </div>
      </div>
    </div>
  )
}
