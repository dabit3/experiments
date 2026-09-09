import type {
  Booking,
  Contact,
  Extras,
  FlightSelection,
  Leg,
  Passenger,
  SearchParams,
  SeatAssignments,
} from '../types'

export interface PersistedState {
  step: number
  search: SearchParams
  selections: Partial<Record<Leg, FlightSelection>>
  passengers: Passenger[]
  contact: Contact
  seats: SeatAssignments
  extras: Extras
  booking: Booking | null
}

const KEY = 'contrail-air:booking:v1'

export function loadState(): PersistedState | null {
  try {
    const raw = localStorage.getItem(KEY)
    if (!raw) return null
    const parsed = JSON.parse(raw) as Partial<PersistedState>
    if (typeof parsed.step !== 'number' || !parsed.search) return null
    return {
      step: parsed.step,
      search: parsed.search,
      selections: parsed.selections ?? {},
      passengers: parsed.passengers ?? [],
      contact: parsed.contact ?? { email: '', phone: '' },
      seats: parsed.seats ?? { outbound: {}, return: {} },
      extras: parsed.extras ?? { bags: 0, insurance: false, priority: false, wifi: false },
      booking: parsed.booking ?? null,
    }
  } catch {
    return null
  }
}

export function saveState(state: PersistedState): void {
  try {
    localStorage.setItem(KEY, JSON.stringify(state))
  } catch {
    // storage unavailable (private mode / quota) — booking still works in-memory
  }
}

export function clearState(): void {
  try {
    localStorage.removeItem(KEY)
  } catch {
    // ignore
  }
}
