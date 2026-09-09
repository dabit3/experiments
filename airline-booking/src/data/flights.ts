import type { Airline, Airport, FareClass, Flight } from '../types'
import { AIRPORTS, AIRPORT_BY_CODE } from './airports'
import { createRng, hashString } from '../lib/random'

export const AIRLINES: Airline[] = [
  { code: 'AZ', name: 'Azure Air', color: '#2563eb' },
  { code: 'MW', name: 'Meridian West', color: '#dc2626' },
  { code: 'NL', name: 'Northlight', color: '#0d9488' },
  { code: 'PC', name: 'Pacific Coastal', color: '#ea580c' },
  { code: 'SV', name: 'Silverwing', color: '#6d28d9' },
  { code: 'HZ', name: 'Horizon Blue', color: '#0891b2' },
]

const AIRCRAFT = ['Airbus A320neo', 'Airbus A321', 'Boeing 737 MAX 8', 'Boeing 737-900', 'Airbus A220-300']

const HUBS = ['DEN', 'ORD', 'DFW', 'ATL', 'PHX', 'SLC', 'MSP', 'IAH', 'CLT', 'DTW']

export const FARES: Record<FareClass, { label: string; multiplier: number; perks: string[] }> = {
  basic: {
    label: 'Basic',
    multiplier: 1,
    perks: ['1 personal item', 'Seat assigned at check-in', 'No changes'],
  },
  standard: {
    label: 'Standard',
    multiplier: 1.24,
    perks: ['Carry-on bag included', 'Choose your seat', 'Changes for a fee'],
  },
  flex: {
    label: 'Flex',
    multiplier: 1.62,
    perks: ['Carry-on + 1 checked bag', 'Choose any seat', 'Free changes & refunds'],
  },
}

export function farePrice(flight: Flight, fare: FareClass): number {
  return Math.round(flight.price * FARES[fare].multiplier)
}

function distanceKm(x: Airport, y: Airport): number {
  const toRad = (d: number) => (d * Math.PI) / 180
  const dLat = toRad(y.lat - x.lat)
  const dLon = toRad(y.lon - x.lon)
  const h =
    Math.sin(dLat / 2) ** 2 + Math.cos(toRad(x.lat)) * Math.cos(toRad(y.lat)) * Math.sin(dLon / 2) ** 2
  return 6371 * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h))
}

function pad(n: number): string {
  return n.toString().padStart(2, '0')
}

/**
 * Deterministic schedule for a route. Seeded only by origin+destination so the
 * same route always shows the same flights, regardless of the travel date.
 */
export function flightsFor(fromCode: string, toCode: string): Flight[] {
  const from = AIRPORT_BY_CODE[fromCode]
  const to = AIRPORT_BY_CODE[toCode]
  if (!from || !to) return []
  const rng = createRng(hashString(`${fromCode}>${toCode}`))
  const km = distanceKm(from, to)
  // Westbound legs fight the jet stream; eastbound ones ride it.
  const wind = to.lon < from.lon ? 1.08 : 0.94
  const nonstopMin = Math.round(35 + (km / 13.5) * wind)
  const basePrice = 55 + km * 0.052
  const count = rng.int(9, 11)
  const flights: Flight[] = []
  const usedDepartures = new Set<number>()

  for (let i = 0; i < count; i++) {
    const airline = rng.pick(AIRLINES)
    let departMin = 0
    do {
      departMin = rng.int(11, 44) * 30 // 05:30 – 22:00
    } while (usedDepartures.has(departMin))
    usedDepartures.add(departMin)
    departMin += rng.pick([0, 5, 10, 15, 20, 25])

    const roll = rng.next()
    const stops = roll < 0.5 ? 0 : roll < 0.88 ? 1 : 2
    const via: string[] = []
    const hubPool = HUBS.filter((h) => h !== fromCode && h !== toCode && AIRPORT_BY_CODE[h])
    for (let s = 0; s < stops; s++) {
      let hub = rng.pick(hubPool)
      while (via.includes(hub)) hub = rng.pick(hubPool)
      via.push(hub)
    }
    const layover = stops === 0 ? 0 : stops * rng.int(55, 140)
    const detour = stops === 0 ? 0 : stops * rng.int(20, 70)
    const durationMin = nonstopMin + layover + detour + rng.int(-12, 18)

    let price = basePrice * (0.78 + rng.next() * 0.7)
    if (stops === 0) price *= 1.12
    if (stops === 2) price *= 0.82
    if (departMin < 7 * 60 || departMin > 20 * 60) price *= 0.9
    price = Math.round(price)

    flights.push({
      id: `${airline.code}${rng.int(100, 2999)}-${fromCode}${toCode}`,
      airline,
      number: '',
      from: fromCode,
      to: toCode,
      depart: `${pad(Math.floor(departMin / 60))}:${pad(departMin % 60)}`,
      durationMin,
      stops,
      via,
      aircraft: rng.pick(AIRCRAFT),
      price,
    })
  }
  for (const f of flights) f.number = f.id.split('-')[0]
  // Make sure no two flights share a price so "cheapest" is unambiguous.
  const seen = new Set<number>()
  for (const f of flights.sort((x, y) => x.depart.localeCompare(y.depart))) {
    while (seen.has(f.price)) f.price += 1
    seen.add(f.price)
  }
  return flights
}

export function airportLabel(code: string): string {
  const ap = AIRPORT_BY_CODE[code]
  return ap ? `${ap.city} (${ap.code})` : code
}

export const ALL_AIRPORTS = AIRPORTS
