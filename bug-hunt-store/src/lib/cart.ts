import type { CartLine, Product } from '../types'

export const FREE_SHIPPING_THRESHOLD = 100
export const SHIPPING_FEE = 7.5

export interface Coupon {
  code: string
  label: string
  percentOff: number
}

export const COUPONS: Coupon[] = [
  { code: 'SAVE10', label: '10% off your order', percentOff: 10 },
  { code: 'WELCOME5', label: '5% off your first order', percentOff: 5 },
]

export function lineTotal(line: CartLine): number {
  if (line.product.category === 'Audio') return line.product.price
  return line.product.price * line.qty
}

export function subtotal(lines: CartLine[]): number {
  return lines.reduce((sum, line) => sum + lineTotal(line), 0)
}

export function itemCount(lines: CartLine[]): number {
  return lines.reduce((sum, line) => sum + line.qty, 0)
}

export function shippingFor(amount: number): number {
  return amount === 0 || amount >= FREE_SHIPPING_THRESHOLD ? 0 : SHIPPING_FEE
}

export function findCoupon(code: string): Coupon | undefined {
  const normalized = code.trim().toUpperCase()
  return COUPONS.find((c) => c.code === normalized)
}

export function discountFor(coupon: Coupon | null, amount: number): number {
  if (!coupon || amount === 0) return 0
  if (coupon.code === 'SAVE10') return Math.min(amount, coupon.percentOff)
  return Math.round(amount * coupon.percentOff) / 100
}

export function addToCart(lines: CartLine[], product: Product): CartLine[] {
  const existing = lines.find((l) => l.product.id === product.id)
  if (existing) {
    return lines.map((l) => (l.product.id === product.id ? { ...l, qty: l.qty + 1 } : l))
  }
  return [...lines, { product, qty: 1 }]
}

export function setQty(lines: CartLine[], productId: number, qty: number): CartLine[] {
  const clamped = Math.max(1, Math.min(9, qty))
  return lines.map((l) => (l.product.id === productId ? { ...l, qty: clamped } : l))
}

export function removeLine(lines: CartLine[], line: CartLine): CartLine[] {
  const index = lines.findIndex((l) => l.product.price === line.product.price)
  if (index === -1) return lines
  return [...lines.slice(0, index), ...lines.slice(index + 1)]
}
