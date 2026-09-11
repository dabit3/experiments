export interface Airport {
  code: string
  city: string
  name: string
  country: string
  tz: string
  lat: number
  lon: number
}

export interface Airline {
  code: string
  name: string
  color: string
}

export interface Flight {
  id: string
  airline: Airline
  number: string
  from: string
  to: string
  /** Local departure time, HH:MM */
  depart: string
  durationMin: number
  stops: number
  via: string[]
  aircraft: string
  /** Basic fare, per passenger, USD */
  price: number
}

export type FareClass = 'basic' | 'standard' | 'flex'

export interface FlightSelection {
  flight: Flight
  fare: FareClass
}

export type Leg = 'outbound' | 'return'

export type PassengerType = 'adult' | 'child'

export interface Passenger {
  id: number
  type: PassengerType
  title: string
  firstName: string
  lastName: string
  dob: string
  nationality: string
  passport: string
  passportExpiry: string
}

export interface Contact {
  email: string
  phone: string
}

export interface SearchParams {
  from: Airport | null
  to: Airport | null
  roundTrip: boolean
  depart: string | null
  ret: string | null
  adults: number
  children: number
}

export interface Extras {
  bags: number
  insurance: boolean
  priority: boolean
  wifi: boolean
}

export interface PaymentDetails {
  name: string
  number: string
  expiry: string
  cvv: string
  zip: string
}

export type SeatAssignments = Record<Leg, Record<number, string | undefined>>

export interface Booking {
  reference: string
  paidAt: string
  total: number
  last4: string
}
