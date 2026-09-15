export interface ShippingInfo {
  fullName: string
  email: string
  address1: string
  address2: string
  city: string
  state: string
  zip: string
}

export interface PaymentInfo {
  cardName: string
  cardNumber: string
  expiry: string
  cvv: string
}

export type Errors<T> = Partial<Record<keyof T, string>>

export const emptyShipping: ShippingInfo = {
  fullName: '',
  email: '',
  address1: '',
  address2: '',
  city: '',
  state: '',
  zip: '',
}

export const emptyPayment: PaymentInfo = {
  cardName: '',
  cardNumber: '',
  expiry: '',
  cvv: '',
}

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/
const ZIP_RE = /^\d{5}(-\d{4})?$/

export function validateShipping(info: ShippingInfo): Errors<ShippingInfo> {
  const errors: Errors<ShippingInfo> = {}
  if (!info.fullName.trim()) errors.fullName = 'Full name is required'
  if (!info.email.trim()) errors.email = 'Email is required'
  else if (!EMAIL_RE.test(info.email.trim())) errors.email = 'Enter a valid email address'
  if (!info.address1.trim()) errors.address1 = 'Street address is required'
  if (!info.city.trim()) errors.city = 'City is required'
  if (!info.state) errors.state = 'State is required'
  if (!info.zip.trim()) errors.zip = 'ZIP code is required'
  else if (!ZIP_RE.test(info.zip.trim())) errors.zip = 'ZIP must be 5 digits (e.g. 94103)'
  return errors
}

export function validatePayment(info: PaymentInfo): Errors<PaymentInfo> {
  const errors: Errors<PaymentInfo> = {}
  const digits = digitsOnly(info.cardNumber)

  if (!info.cardName.trim()) errors.cardName = 'Name on card is required'

  if (!digits) errors.cardNumber = 'Card number is required'
  else if (digits.length < 13 || digits.length > 19) errors.cardNumber = 'Card number must be 13–19 digits'
  else if (!luhnCheck(digits)) errors.cardNumber = 'Invalid card number — failed checksum'

  if (!info.expiry) errors.expiry = 'Expiry is required'
  else if (!/^\d{2}\/\d{2}$/.test(info.expiry)) errors.expiry = 'Use MM/YY format'
  else if (!isExpiryInFuture(info.expiry)) errors.expiry = 'Card is expired or month is invalid'

  if (!info.cvv) errors.cvv = 'CVV is required'
  else if (!/^\d{3}$/.test(info.cvv)) errors.cvv = 'CVV must be 3 digits'

  return errors
}

export function digitsOnly(value: string): string {
  return value.replace(/\D/g, '')
}

/** Luhn mod-10 checksum, as used by all major card networks. */
export function luhnCheck(digits: string): boolean {
  let sum = 0
  let double = false
  for (let i = digits.length - 1; i >= 0; i--) {
    let d = Number(digits[i])
    if (double) {
      d *= 2
      if (d > 9) d -= 9
    }
    sum += d
    double = !double
  }
  return sum % 10 === 0
}

/** "4242424242424242" -> "4242 4242 4242 4242" */
export function formatCardNumber(value: string): string {
  return digitsOnly(value).slice(0, 19).replace(/(\d{4})(?=\d)/g, '$1 ')
}

/** "1229" -> "12/29"; tolerates the user typing the slash themselves. */
export function formatExpiry(value: string): string {
  const digits = digitsOnly(value).slice(0, 4)
  if (digits.length <= 2) return digits
  return `${digits.slice(0, 2)}/${digits.slice(2)}`
}

export function isExpiryInFuture(expiry: string, now = new Date()): boolean {
  const [mm, yy] = expiry.split('/').map(Number)
  if (mm < 1 || mm > 12) return false
  const year = 2000 + yy
  const thisYear = now.getFullYear()
  const thisMonth = now.getMonth() + 1
  return year > thisYear || (year === thisYear && mm >= thisMonth)
}

export type CardBrand = 'Visa' | 'Mastercard' | 'Amex' | 'Discover' | null

export function detectCardBrand(cardNumber: string): CardBrand {
  const d = digitsOnly(cardNumber)
  if (/^4/.test(d)) return 'Visa'
  if (/^(5[1-5]|2[2-7])/.test(d)) return 'Mastercard'
  if (/^3[47]/.test(d)) return 'Amex'
  if (/^6(011|5)/.test(d)) return 'Discover'
  return null
}

export function last4(cardNumber: string): string {
  return digitsOnly(cardNumber).slice(-4)
}

export const US_STATES = [
  'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA', 'HI', 'ID', 'IL', 'IN', 'IA',
  'KS', 'KY', 'LA', 'ME', 'MD', 'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
  'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VT',
  'VA', 'WA', 'WV', 'WI', 'WY', 'DC',
]
