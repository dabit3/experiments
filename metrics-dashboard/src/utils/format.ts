import type { MetricKey } from '../data/aggregate'

const compact = new Intl.NumberFormat('en-US', { notation: 'compact', maximumFractionDigits: 1 })
const integer = new Intl.NumberFormat('en-US')
const money = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 })
const percent = new Intl.NumberFormat('en-US', { style: 'percent', minimumFractionDigits: 2, maximumFractionDigits: 2 })

export function formatMetric(key: MetricKey, value: number, opts: { compact?: boolean } = {}): string {
  switch (key) {
    case 'revenue':
      return opts.compact ? `$${compact.format(value)}` : money.format(value)
    case 'churnRate':
      return percent.format(value)
    default:
      return opts.compact ? compact.format(value) : integer.format(value)
  }
}

export function formatDelta(current: number, previous: number): { text: string; direction: 'up' | 'down' | 'flat' } {
  if (!previous) return { text: '—', direction: 'flat' }
  const change = (current - previous) / previous
  const direction = Math.abs(change) < 0.0005 ? 'flat' : change > 0 ? 'up' : 'down'
  const sign = change > 0 ? '+' : ''
  return { text: `${sign}${(change * 100).toFixed(1)}%`, direction }
}

const shortDate = new Intl.DateTimeFormat('en-US', { month: 'short', day: 'numeric', timeZone: 'UTC' })
const longDate = new Intl.DateTimeFormat('en-US', {
  weekday: 'short',
  month: 'short',
  day: 'numeric',
  year: 'numeric',
  timeZone: 'UTC',
})

export function formatShortDate(iso: string): string {
  return shortDate.format(new Date(iso))
}

export function formatLongDate(iso: string): string {
  return longDate.format(new Date(iso))
}
