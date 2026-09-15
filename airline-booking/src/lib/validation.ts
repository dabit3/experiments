import type { Contact, Passenger, PaymentDetails } from '../types'
import { addMonths, ageAt, parseISODate, today } from './date'

export type CardType = 'visa' | 'mastercard' | 'amex' | 'discover' | 'unknown'

export function detectCardType(digits: string): CardType {
  if (/^4/.test(digits)) return 'visa'
  if (/^(5[1-5]|2[2-7])/.test(digits)) return 'mastercard'
  if (/^3[47]/.test(digits)) return 'amex'
  if (/^(6011|65|64[4-9])/.test(digits)) return 'discover'
  return 'unknown'
}

export const CARD_LABEL: Record<CardType, string> = {
  visa: 'Visa',
  mastercard: 'Mastercard',
  amex: 'American Express',
  discover: 'Discover',
  unknown: 'Card',
}

export function luhnValid(digits: string): boolean {
  if (digits.length < 12) return false
  let sum = 0
  let double = false
  for (let i = digits.length - 1; i >= 0; i--) {
    let n = Number(digits[i])
    if (double) {
      n *= 2
      if (n > 9) n -= 9
    }
    sum += n
    double = !double
  }
  return sum % 10 === 0
}

export function formatCardNumber(raw: string): string {
  const type = detectCardType(raw.replace(/\D/g, ''))
  const max = type === 'amex' ? 15 : 16
  const digits = raw.replace(/\D/g, '').slice(0, max)
  if (type === 'amex') {
    return [digits.slice(0, 4), digits.slice(4, 10), digits.slice(10, 15)].filter(Boolean).join(' ')
  }
  return digits.replace(/(.{4})/g, '$1 ').trim()
}

export function formatExpiry(raw: string): string {
  const digits = raw.replace(/\D/g, '').slice(0, 4)
  if (digits.length <= 2) return digits
  return `${digits.slice(0, 2)}/${digits.slice(2)}`
}

export function expiryValid(exp: string): boolean {
  const m = /^(\d{2})\/(\d{2})$/.exec(exp)
  if (!m) return false
  const month = Number(m[1])
  const year = 2000 + Number(m[2])
  if (month < 1 || month > 12) return false
  const now = today()
  const endOfMonth = new Date(year, month, 0)
  return endOfMonth >= now
}

export type Errors<T> = Partial<Record<keyof T, string>>

export function validatePayment(p: PaymentDetails): Errors<PaymentDetails> {
  const e: Errors<PaymentDetails> = {}
  if (p.name.trim().length < 2) e.name = 'Enter the name exactly as it appears on the card'
  const digits = p.number.replace(/\D/g, '')
  const type = detectCardType(digits)
  const expectedLen = type === 'amex' ? 15 : 16
  if (digits.length === 0) e.number = 'Card number is required'
  else if (digits.length < expectedLen) e.number = `Card number should be ${expectedLen} digits`
  else if (!luhnValid(digits)) e.number = 'Invalid card number — failed checksum'
  if (!p.expiry) e.expiry = 'Required'
  else if (!expiryValid(p.expiry)) e.expiry = 'Use MM/YY, in the future'
  const cvvLen = type === 'amex' ? 4 : 3
  if (!new RegExp(`^\\d{${cvvLen}}$`).test(p.cvv)) e.cvv = `${cvvLen} digits`
  if (!/^\d{5}$/.test(p.zip)) e.zip = '5-digit ZIP'
  return e
}

export function validateContact(c: Contact): Errors<Contact> {
  const e: Errors<Contact> = {}
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(c.email)) e.email = 'Enter a valid email address'
  if (c.phone.replace(/\D/g, '').length < 10) e.phone = 'Enter a phone number with at least 10 digits'
  return e
}

const NAME_RE = /^[A-Za-zÀ-ÿ' -]{2,}$/

export interface PassengerContext {
  departDate: string
  /** Last travel date (return date for round trips, departure for one-way). */
  lastTravelDate: string
}

export function validatePassenger(p: Passenger, ctx: PassengerContext): Errors<Passenger> {
  const e: Errors<Passenger> = {}
  if (!p.title) e.title = 'Required'
  if (!NAME_RE.test(p.firstName.trim())) e.firstName = 'Enter a first name (letters only)'
  if (!NAME_RE.test(p.lastName.trim())) e.lastName = 'Enter a last name (letters only)'

  const dob = parseISODate(p.dob)
  if (!p.dob) e.dob = 'Date of birth is required'
  else if (!dob) e.dob = 'Use the format YYYY-MM-DD'
  else if (dob > today()) e.dob = 'Date of birth must be in the past'
  else {
    const age = ageAt(p.dob, ctx.departDate) ?? 0
    if (p.type === 'adult' && age < 12) e.dob = `Adults must be 12 or older on the departure date (this passenger would be ${age})`
    if (p.type === 'child' && (age < 2 || age > 11))
      e.dob = `Children must be 2–11 on the departure date (this passenger would be ${age})`
  }

  if (!p.nationality) e.nationality = 'Required'
  if (!/^[A-Za-z0-9]{6,9}$/.test(p.passport.trim())) e.passport = 'Passport number should be 6–9 letters or digits'

  const exp = parseISODate(p.passportExpiry)
  if (!p.passportExpiry) e.passportExpiry = 'Passport expiry date is required'
  else if (!exp) e.passportExpiry = 'Use the format YYYY-MM-DD'
  else {
    const last = parseISODate(ctx.lastTravelDate)
    if (last) {
      const required = addMonths(last, 6)
      if (exp < required) {
        const requiredLabel = required.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
        e.passportExpiry = `Passport must be valid for 6 months after your last flight — expiry must be on or after ${requiredLabel}`
      }
    }
  }
  return e
}

export function hasErrors<T>(e: Errors<T>): boolean {
  return Object.keys(e).length > 0
}
