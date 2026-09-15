import {
  AUTO_GRATUITY_MIN_PARTY,
  AUTO_GRATUITY_RATE,
  TAX_RATE,
  type Check,
  type OrderLine,
  type Payment,
} from '../types'
import { allocate, percentOf } from './money'

export function lineTotal(line: OrderLine): number {
  return line.basePrice + line.modifiers.reduce((sum, m) => sum + m.delta, 0)
}

export function activeLines(check: Check): OrderLine[] {
  return check.lines.filter((l) => l.status !== 'voided')
}

export function hasAutoGratuity(check: Check): boolean {
  return check.partySize >= AUTO_GRATUITY_MIN_PARTY
}

export interface Totals {
  subtotal: number
  discount: number
  taxable: number
  tax: number
  gratuity: number
  /** Amount due before any additional tips. */
  total: number
  tips: number
  /** total + tips */
  grandTotal: number
}

export function discountAmount(check: Check, subtotal: number): number {
  const d = check.discount
  if (!d) return 0
  const amt = d.kind === 'percent' ? percentOf(subtotal, d.value / 100) : d.value
  return Math.min(Math.max(amt, 0), subtotal)
}

export function checkTotals(check: Check): Totals {
  const subtotal = activeLines(check).reduce((s, l) => s + lineTotal(l), 0)
  const discount = discountAmount(check, subtotal)
  const taxable = subtotal - discount
  const tax = percentOf(taxable, TAX_RATE)
  const gratuity = hasAutoGratuity(check) ? percentOf(taxable, AUTO_GRATUITY_RATE) : 0
  const total = taxable + tax + gratuity
  const tips = check.payments.reduce((s, p) => s + p.tip, 0)
  return { subtotal, discount, taxable, tax, gratuity, total, tips, grandTotal: total + tips }
}

export interface Split {
  id: string
  label: string
  /** Lines shown on this split's receipt. For even splits this is every line. */
  lines: OrderLine[]
  /** For even splits, the fraction of the table (e.g. "1/3"). */
  share: string | null
  subtotal: number
  discount: number
  taxable: number
  tax: number
  gratuity: number
  total: number
  payment: Payment | null
}

function seatsWithLines(lines: OrderLine[]): number[] {
  return [...new Set(lines.map((l) => l.seat))].sort((a, b) => a - b)
}

/**
 * Compute the splits for a check in its current split mode. Discount, tax and
 * gratuity are allocated with largest-remainder rounding so the split totals
 * always sum exactly to the table total.
 */
export function computeSplits(check: Check): Split[] {
  const totals = checkTotals(check)
  const lines = activeLines(check)
  const paymentFor = (id: string) => check.payments.find((p) => p.splitId === id) ?? null

  type Bucket = { id: string; label: string; lines: OrderLine[]; share: string | null; weight: number }
  let buckets: Bucket[]

  switch (check.splitMode) {
    case 'seat': {
      buckets = seatsWithLines(lines).map((seat) => {
        const seatLines = lines.filter((l) => l.seat === seat)
        return {
          id: `seat-${seat}`,
          label: `Seat ${seat}`,
          lines: seatLines,
          share: null,
          weight: seatLines.reduce((s, l) => s + lineTotal(l), 0),
        }
      })
      break
    }
    case 'even': {
      const n = Math.max(1, check.evenSplitCount)
      buckets = Array.from({ length: n }, (_, i) => ({
        id: `even-${i + 1}`,
        label: `Guest ${i + 1}`,
        lines,
        share: `1/${n}`,
        weight: 1,
      }))
      break
    }
    case 'item': {
      const n = Math.max(1, check.itemSplitCount)
      buckets = Array.from({ length: n }, (_, i) => {
        const mine = lines.filter((l) => (check.itemAssignments[l.id] ?? 0) === i)
        return {
          id: `item-${i + 1}`,
          label: `Check ${String.fromCharCode(65 + i)}`,
          lines: mine,
          share: null,
          weight: mine.reduce((s, l) => s + lineTotal(l), 0),
        }
      })
      break
    }
    default:
      buckets = [{ id: 'whole', label: 'Whole table', lines, share: null, weight: 1 }]
  }

  const weights = buckets.map((b) => b.weight)
  const subtotals =
    check.splitMode === 'even' || check.splitMode === 'none'
      ? allocate(totals.subtotal, weights)
      : buckets.map((b) => b.lines.reduce((s, l) => s + lineTotal(l), 0))
  const discounts = allocate(totals.discount, subtotals)
  const taxables = subtotals.map((s, i) => s - discounts[i])
  const taxes = allocate(totals.tax, taxables)
  const gratuities = allocate(totals.gratuity, taxables)

  return buckets.map((b, i) => ({
    id: b.id,
    label: b.label,
    lines: b.lines,
    share: b.share,
    subtotal: subtotals[i],
    discount: discounts[i],
    taxable: taxables[i],
    tax: taxes[i],
    gratuity: gratuities[i],
    total: taxables[i] + taxes[i] + gratuities[i],
    payment: paymentFor(b.id),
  }))
}

export function allSplitsPaid(splits: Split[]): boolean {
  return splits.length > 0 && splits.every((s) => s.payment !== null)
}

export function courseLabel(course: number): string {
  return course === 1 ? 'Course 1 · Starters' : course === 2 ? 'Course 2 · Mains' : 'Course 3 · Desserts'
}
