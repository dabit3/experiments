import type { CartItem, Promo, Totals } from './cart'
import { detectCardBrand, last4, type PaymentInfo, type ShippingInfo } from './validation'

export interface Order {
  number: string
  placedAt: Date
  items: CartItem[]
  totals: Totals
  promo: Promo | null
  shipping: ShippingInfo
  card: { brand: string; last4: string }
}

export function createOrder(
  items: CartItem[],
  totals: Totals,
  promo: Promo | null,
  shipping: ShippingInfo,
  payment: PaymentInfo,
): Order {
  return {
    number: generateOrderNumber(),
    placedAt: new Date(),
    items,
    totals,
    promo,
    shipping,
    card: { brand: detectCardBrand(payment.cardNumber) ?? 'Card', last4: last4(payment.cardNumber) },
  }
}

/** e.g. "DV-7K3M2Q" — short, uppercase, easy to read back. */
function generateOrderNumber(): string {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
  const bytes = crypto.getRandomValues(new Uint8Array(6))
  const body = Array.from(bytes, (b) => alphabet[b % alphabet.length]).join('')
  return `DV-${body}`
}
