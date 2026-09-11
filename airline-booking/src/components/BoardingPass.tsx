import { useEffect, useState, type CSSProperties } from 'react'
import QRCode from 'qrcode'
import type { Flight, Passenger } from '../types'
import { AIRPORT_BY_CODE } from '../data/airports'
import { formatCompact, to12h } from '../lib/date'
import { boardingGroup, gateFor, legTimes, passengerFullName } from '../lib/booking'
import { seatPosition } from '../lib/seats'

interface Props {
  passenger: Passenger
  index: number
  flight: Flight
  date: string
  seat: string
  reference: string
  fareLabel: string
  priority: boolean
}

function minusMinutes(hhmm: string, minutes: number): string {
  const [h, m] = hhmm.split(':').map(Number)
  const total = (h * 60 + m - minutes + 1440) % 1440
  return `${Math.floor(total / 60).toString().padStart(2, '0')}:${(total % 60).toString().padStart(2, '0')}`
}

export function BoardingPass({ passenger, index, flight, date, seat, reference, fareLabel, priority }: Props) {
  const [qr, setQr] = useState<string>('')
  const from = AIRPORT_BY_CODE[flight.from]
  const to = AIRPORT_BY_CODE[flight.to]
  const times = legTimes(flight, date)
  const group = boardingGroup(seat, priority)
  const gate = gateFor(flight.id)
  const sequence = (index + 1).toString().padStart(3, '0')

  // Roughly IATA BCBP-shaped payload so a scanner shows something plausible.
  const payload = `M1${passenger.lastName.toUpperCase()}/${passenger.firstName.toUpperCase()} ${reference} ${flight.from}${flight.to}${flight.airline.code} ${flight.number.replace(/\D/g, '').padStart(4, '0')} ${date} ${seat.padStart(4, '0')} ${sequence} ${group}`

  useEffect(() => {
    let cancelled = false
    QRCode.toDataURL(payload, { margin: 1, width: 220, errorCorrectionLevel: 'M', color: { dark: '#0b1220', light: '#ffffff' } })
      .then((url) => {
        if (!cancelled) setQr(url)
      })
      .catch(() => {
        if (!cancelled) setQr('')
      })
    return () => {
      cancelled = true
    }
  }, [payload])

  const style = { '--airline': flight.airline.color } as CSSProperties

  return (
    <article className="boarding-pass" style={style} aria-label={`Boarding pass for ${passengerFullName(passenger)}`}>
      <div className="bp-main">
        <header className="bp-head">
          <span className="bp-airline">
            <span className="airline-logo small" style={{ background: flight.airline.color }}>
              {flight.airline.code}
            </span>
            {flight.airline.name}
          </span>
          <span className="bp-title">
            Boarding pass{priority && <span className="bp-priority">Priority</span>}
          </span>
        </header>
        <div className="bp-route">
          <div>
            <span className="bp-code">{flight.from}</span>
            <span className="bp-city">{from.city}</span>
            <span className="bp-time">{to12h(flight.depart)}</span>
          </div>
          <div className="bp-plane" aria-hidden>
            <svg viewBox="0 0 24 24" width="26" height="26">
              <path
                d="M21 16v-2l-8-5V3.5a1.5 1.5 0 0 0-3 0V9l-8 5v2l8-2.5V19l-2 1.5V22l3.5-1 3.5 1v-1.5L13 19v-5.5z"
                fill="currentColor"
              />
            </svg>
            <span className="bp-dash" />
          </div>
          <div className="right">
            <span className="bp-code">{flight.to}</span>
            <span className="bp-city">{to.city}</span>
            <span className="bp-time">
              {to12h(times.arriveLocal)}
              {times.dayOffset > 0 && <sup>+{times.dayOffset}</sup>}
            </span>
          </div>
        </div>
        <dl className="bp-grid">
          <div className="wide">
            <dt>Passenger</dt>
            <dd>{passengerFullName(passenger).toUpperCase()}</dd>
          </div>
          <div>
            <dt>Flight</dt>
            <dd>
              {flight.number}
            </dd>
          </div>
          <div>
            <dt>Date</dt>
            <dd>{formatCompact(date)}</dd>
          </div>
          <div>
            <dt>Boarding</dt>
            <dd>{to12h(minusMinutes(flight.depart, 40))}</dd>
          </div>
          <div>
            <dt>Gate</dt>
            <dd>{gate}</dd>
          </div>
          <div>
            <dt>Seat</dt>
            <dd className="bp-seat">
              {seat} <small>{seatPosition(seat)}</small>
            </dd>
          </div>
          <div>
            <dt>Group</dt>
            <dd>{group}</dd>
          </div>
          <div>
            <dt>Fare</dt>
            <dd>{fareLabel}</dd>
          </div>
          <div>
            <dt>Booking ref</dt>
            <dd>{reference}</dd>
          </div>
        </dl>
      </div>
      <div className="bp-stub">
        <div className="bp-stub-top">
          <span className="bp-stub-name">{passengerFullName(passenger).toUpperCase()}</span>
          <span>
            {flight.from} → {flight.to}
          </span>
          <span>
            {flight.number} · {formatCompact(date)}
          </span>
        </div>
        {qr ? <img className="bp-qr" src={qr} alt={`QR code for boarding pass ${reference}`} width={140} height={140} /> : <div className="bp-qr placeholder" />}
        <div className="bp-stub-bottom">
          <span>
            Seat <strong>{seat}</strong>
          </span>
          <span>
            Seq <strong>{sequence}</strong>
          </span>
        </div>
      </div>
    </article>
  )
}
