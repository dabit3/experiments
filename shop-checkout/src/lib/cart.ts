import { PROMO_CODES, type Product } from '../data/products'

export type Selection = Record<string, string>

export interface CartItem {
  key: string
  product: Product
  selection: Selection
  quantity: number
}

export interface Promo {
  code: string
  rate: number
}

export interface Totals {
  subtotal: number
  discount: number
  total: number
}

export function itemKey(product: Product, selection: Selection): string {
  const parts = product.variants.map((v) => `${v.name}=${selection[v.name]}`)
  return [product.id, ...parts].join('|')
}

export function defaultSelection(product: Product): Selection {
  return Object.fromEntries(product.variants.map((v) => [v.name, v.options[0]]))
}

export function describeSelection(item: CartItem): string {
  return item.product.variants.map((v) => item.selection[v.name]).join(' · ')
}

export function computeTotals(items: CartItem[], promo: Promo | null): Totals {
  const subtotal = items.reduce((sum, i) => sum + i.product.price * i.quantity, 0)
  const discount = promo ? round2(subtotal * promo.rate) : 0
  return { subtotal, discount, total: round2(subtotal - discount) }
}

export function lookupPromo(code: string): Promo | null {
  const normalized = code.trim().toUpperCase()
  const rate = PROMO_CODES[normalized]
  return rate ? { code: normalized, rate } : null
}

export function formatMoney(amount: number): string {
  return amount.toLocaleString('en-US', { style: 'currency', currency: 'USD' })
}

function round2(n: number): number {
  return Math.round(n * 100) / 100
}
