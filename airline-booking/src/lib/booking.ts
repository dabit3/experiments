import type { Extras, Flight, FlightSelection, Leg, Passenger, SearchParams, SeatAssignments } from '../types'
import { AIRPORT_BY_CODE } from '../data/airports'
import { farePrice } from '../data/flights'
import { utcToZoned, zonedToUtc } from './date'
import { hashString } from './random'
import { seatFee } from './seats'

export const EXTRA_PRICES = {
  bag: 35,
  insurance: 29,
  priority: 15,
  wifi: 12,
} as const

export const TAX_RATE = 0.075
export const SEGMENT_FEE = 5.6

export interface LegTimes {
  departUtc: Date
  arriveUtc: Date
  departLocal: string
  arriveLocal: string
  arriveDate: string
  dayOffset: number
}

export function legTimes(flight: Flight, dateISO: string): LegTimes {
  const from = AIRPORT_BY_CODE[flight.from]
  const to = AIRPORT_BY_CODE[flight.to]
  const departUtc = zonedToUtc(dateISO, flight.depart, from.tz)
  const arriveUtc = new Date(departUtc.getTime() + flight.durationMin * 60000)
  const arrive = utcToZoned(arriveUtc, to.tz)
  const dayOffset = Math.round(
    (Date.parse(arrive.date + 'T00:00:00Z') - Date.parse(dateISO + 'T00:00:00Z')) / 86400000,
  )
  return {
    departUtc,
    arriveUtc,
    departLocal: flight.depart,
    arriveLocal: arrive.time,
    arriveDate: arrive.date,
    dayOffset,
  }
}

export interface PriceBreakdown {
  fares: { leg: Leg; label: string; perPax: number; count: number; total: number }[]
  seats: number
  extras: { label: string; total: number }[]
  taxes: number
  total: number
}

export function computePrice(
  search: SearchParams,
  selections: Partial<Record<Leg, FlightSelection>>,
  passengers: Passenger[],
  seats: SeatAssignments,
  extras: Extras,
): PriceBreakdown {
  const paxCount = Math.max(passengers.length, search.adults + search.children)
  const fares: PriceBreakdown['fares'] = []
  for (const leg of ['outbound', 'return'] as Leg[]) {
    const sel = selections[leg]
    if (!sel) continue
    const perPax = farePrice(sel.flight, sel.fare)
    fares.push({
      leg,
      label: `${sel.flight.number} · ${sel.flight.from}→${sel.flight.to}`,
      perPax,
      count: paxCount,
      total: perPax * paxCount,
    })
  }
  let seatTotal = 0
  for (const leg of ['outbound', 'return'] as Leg[]) {
    for (const seat of Object.values(seats[leg])) seatTotal += seatFee(seat)
  }
  const extraLines: PriceBreakdown['extras'] = []
  if (extras.bags > 0)
    extraLines.push({ label: `${extras.bags} checked bag${extras.bags > 1 ? 's' : ''}`, total: extras.bags * EXTRA_PRICES.bag })
  if (extras.insurance)
    extraLines.push({ label: `Travel insurance × ${paxCount}`, total: EXTRA_PRICES.insurance * paxCount })
  if (extras.priority)
    extraLines.push({ label: `Priority boarding × ${paxCount}`, total: EXTRA_PRICES.priority * paxCount })
  if (extras.wifi) extraLines.push({ label: `In-flight Wi-Fi × ${paxCount}`, total: EXTRA_PRICES.wifi * paxCount })

  const fareSum = fares.reduce((s, f) => s + f.total, 0)
  const extrasSum = extraLines.reduce((s, e) => s + e.total, 0)
  const segments = fares.length * paxCount
  const taxes = Math.round((fareSum * TAX_RATE + segments * SEGMENT_FEE) * 100) / 100
  const total = Math.round((fareSum + seatTotal + extrasSum + taxes) * 100) / 100
  return { fares, seats: seatTotal, extras: extraLines, taxes, total }
}

export function money(n: number): string {
  return n.toLocaleString('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: n % 1 === 0 ? 0 : 2 })
}

const REF_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'

export function bookingReference(passengers: Passenger[], flightIds: string[]): string {
  let h = hashString(passengers.map((p) => `${p.firstName}|${p.lastName}|${p.dob}`).join(';') + flightIds.join(','))
  let ref = ''
  for (let i = 0; i < 6; i++) {
    ref += REF_ALPHABET[h % REF_ALPHABET.length]
    h = Math.floor(h / REF_ALPHABET.length) + hashString(ref)
  }
  return ref
}

export function boardingGroup(seat: string | undefined, priority: boolean): string {
  if (priority) return 'A'
  if (!seat) return 'D'
  const row = Number(seat.replace(/\D/g, ''))
  return row <= 10 ? 'B' : 'C'
}

export function gateFor(flightId: string): string {
  const h = hashString(`gate:${flightId}`)
  return `${'ABCDE'[h % 5]}${(h % 28) + 2}`
}

export function passengerFullName(p: Passenger): string {
  return `${p.firstName.trim()} ${p.lastName.trim()}`.trim()
}
