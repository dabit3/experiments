import type { Kpi } from '../data/aggregate'
import { formatDelta, formatMetric } from '../utils/format'

interface Props {
  kpi: Kpi
  color: string
  selected: boolean
  onSelect: () => void
}

export function KpiCard({ kpi, color, selected, onSelect }: Props) {
  const delta = formatDelta(kpi.value, kpi.previous)
  // Lower churn is good, so flip the sentiment for that card.
  const good = kpi.key === 'churnRate' ? delta.direction === 'down' : delta.direction === 'up'
  const sentiment = delta.direction === 'flat' ? 'flat' : good ? 'good' : 'bad'

  return (
    <button
      type="button"
      className={`kpi-card${selected ? ' kpi-card--selected' : ''}`}
      onClick={onSelect}
      data-testid={`kpi-${kpi.key}`}
      aria-pressed={selected}
    >
      <div className="kpi-card__head">
        <span className="kpi-card__label">{kpi.label}</span>
        <span className={`kpi-card__delta kpi-card__delta--${sentiment}`} title="vs. previous period">
          {delta.direction === 'up' && '▲ '}
          {delta.direction === 'down' && '▼ '}
          {delta.text}
        </span>
      </div>
      <div className="kpi-card__value" data-testid={`kpi-${kpi.key}-value`}>
        {formatMetric(kpi.key, kpi.value, { compact: kpi.key !== 'churnRate' })}
      </div>
      <Sparkline values={kpi.spark} color={color} />
    </button>
  )
}

function Sparkline({ values, color }: { values: number[]; color: string }) {
  const w = 160
  const h = 36
  if (values.length < 2) return <svg className="sparkline" viewBox={`0 0 ${w} ${h}`} />

  const min = Math.min(...values)
  const max = Math.max(...values)
  const span = max - min || 1
  const pts = values.map((v, i) => {
    const x = (i / (values.length - 1)) * w
    const y = h - 3 - ((v - min) / span) * (h - 6)
    return `${x.toFixed(1)},${y.toFixed(1)}`
  })
  const line = pts.join(' ')
  const area = `0,${h} ${line} ${w},${h}`
  const gradientId = `spark-${color.replace(/[^a-z0-9]/gi, '')}`

  return (
    <svg className="sparkline" viewBox={`0 0 ${w} ${h}`} preserveAspectRatio="none" aria-hidden="true">
      <defs>
        <linearGradient id={gradientId} x1="0" x2="0" y1="0" y2="1">
          <stop offset="0%" stopColor={color} stopOpacity={0.35} />
          <stop offset="100%" stopColor={color} stopOpacity={0} />
        </linearGradient>
      </defs>
      <polygon points={area} fill={`url(#${gradientId})`} />
      <polyline points={line} fill="none" stroke={color} strokeWidth={2} strokeLinejoin="round" strokeLinecap="round" />
    </svg>
  )
}
