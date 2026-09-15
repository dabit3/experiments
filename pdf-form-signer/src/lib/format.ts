import { ENGAGEMENT_OPTIONS, PAYMENT_OPTIONS, US_STATES } from '../types'
import type { EngagementType, FormValues, PaymentTerms } from '../types'

export function formatLongDate(iso: string): string {
  if (!iso) return ''
  const [y, m, d] = iso.split('-').map(Number)
  if (!y || !m || !d) return iso
  const date = new Date(Date.UTC(y, m - 1, d))
  return date.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric', timeZone: 'UTC' })
}

export function formatTime(iso: string): string {
  const d = new Date(iso)
  return d.toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' })
}

export function formatTimestamp(iso: string): string {
  const d = new Date(iso)
  return `${d.toISOString().slice(0, 10)} ${formatTime(iso)}`
}

export function formatMoney(raw: string): string {
  const n = Number(raw.replace(/[,$\s]/g, ''))
  if (!Number.isFinite(n)) return raw
  return n.toLocaleString('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 2 })
}

export function stateName(code: string): string {
  return US_STATES.find((s) => s.code === code)?.name ?? code
}

export function engagementLabel(v: EngagementType): string {
  return ENGAGEMENT_OPTIONS.find((o) => o.value === v)?.label ?? ''
}

export function rateLabel(v: EngagementType): string {
  switch (v) {
    case 'hourly':
      return 'Hourly rate (USD)'
    case 'retainer':
      return 'Monthly retainer (USD)'
    default:
      return 'Total fee (USD)'
  }
}

export function rateSuffix(v: EngagementType): string {
  switch (v) {
    case 'hourly':
      return ' per hour'
    case 'retainer':
      return ' per month'
    default:
      return ''
  }
}

export function paymentLabel(v: PaymentTerms): string {
  return PAYMENT_OPTIONS.find((o) => o.value === v)?.label ?? ''
}

export function slugify(s: string): string {
  return s
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
}

export function pdfFileName(values: FormValues): string {
  const slug = slugify(values.fullName) || 'unsigned'
  return `contractor-agreement-${slug}.pdf`
}

export function initialsFromName(name: string): string {
  return name
    .trim()
    .split(/\s+/)
    .filter(Boolean)
    .map((p) => p[0]?.toUpperCase() ?? '')
    .join('')
    .slice(0, 3)
}
