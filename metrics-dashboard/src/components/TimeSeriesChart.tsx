import { useMemo, useState } from 'react'
import {
  Area,
  CartesianGrid,
  ComposedChart,
  Line,
  ReferenceArea,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
  type TooltipContentProps,
} from 'recharts'
import { METRIC_LABEL, type DayPoint, type MetricKey } from '../data/aggregate'
import type { ChartPalette } from '../hooks/useTheme'
import { formatLongDate, formatMetric, formatShortDate } from '../utils/format'

interface Props {
  data: DayPoint[]
  metric: MetricKey
  onMetricChange: (m: MetricKey) => void
  zoom: [string, string] | null
  onZoom: (range: [string, string] | null) => void
  palette: ChartPalette
}

const METRICS: MetricKey[] = ['revenue', 'signups', 'activeUsers', 'churnRate']

export function TimeSeriesChart({ data, metric, onMetricChange, zoom, onZoom, palette }: Props) {
  const [dragStart, setDragStart] = useState<string | null>(null)
  const [dragEnd, setDragEnd] = useState<string | null>(null)

  const visible = useMemo(() => {
    if (!zoom) return data
    const [a, b] = zoom
    return data.filter((p) => p.date >= a && p.date <= b)
  }, [data, zoom])

  const label = (v: unknown): string | null => (typeof v === 'string' ? v : null)

  const finishDrag = () => {
    if (dragStart && dragEnd && dragStart !== dragEnd) {
      const [a, b] = dragStart < dragEnd ? [dragStart, dragEnd] : [dragEnd, dragStart]
      onZoom([a, b])
    }
    setDragStart(null)
    setDragEnd(null)
  }

  const first = visible[0]?.date
  const last = visible[visible.length - 1]?.date

  return (
    <section className="panel chart-panel" data-testid="timeseries-panel">
      <header className="panel__head">
        <div>
          <h2 className="panel__title">{METRIC_LABEL[metric]} over time</h2>
          <p className="panel__subtitle" data-testid="chart-range">
            {first && last ? `${formatLongDate(first)} → ${formatLongDate(last)} · ${visible.length} days` : 'No data'}
            {zoom && <span className="badge">Zoomed</span>}
          </p>
        </div>
        <div className="panel__actions">
          <div className="segmented segmented--small" role="tablist" aria-label="Chart metric">
            {METRICS.map((m) => (
              <button
                key={m}
                type="button"
                role="tab"
                aria-selected={m === metric}
                className={`segmented__item${m === metric ? ' segmented__item--active' : ''}`}
                onClick={() => onMetricChange(m)}
              >
                {METRIC_LABEL[m]}
              </button>
            ))}
          </div>
          <button
            type="button"
            className="btn"
            onClick={() => onZoom(null)}
            disabled={!zoom}
            data-testid="reset-zoom"
          >
            Reset zoom
          </button>
        </div>
      </header>

      <p className="hint">Hover for exact values · click and drag to zoom into a date range</p>

      <div className="chart-area chart-area--tall" data-testid="timeseries-chart">
        <ResponsiveContainer width="100%" height="100%">
          <ComposedChart
            key={zoom ? zoom.join('|') : 'full'}
            data={visible}
            margin={{ top: 12, right: 16, bottom: 4, left: 4 }}
            onMouseDown={(s) => {
              const d = label(s.activeLabel)
              if (d) {
                setDragStart(d)
                setDragEnd(d)
              }
            }}
            onMouseMove={(s) => {
              if (dragStart) {
                const d = label(s.activeLabel)
                if (d) setDragEnd(d)
              }
            }}
            onMouseUp={finishDrag}
            onMouseLeave={finishDrag}
            style={{ cursor: dragStart ? 'col-resize' : 'crosshair' }}
          >
            <defs>
              <linearGradient id="main-fill" x1="0" x2="0" y1="0" y2="1">
                <stop offset="0%" stopColor={palette.accent} stopOpacity={0.28} />
                <stop offset="100%" stopColor={palette.accent} stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid stroke={palette.grid} vertical={false} />
            <XAxis
              dataKey="date"
              tickFormatter={formatShortDate}
              tick={{ fill: palette.axis, fontSize: 12 }}
              axisLine={{ stroke: palette.grid }}
              tickLine={false}
              minTickGap={32}
            />
            <YAxis
              tickFormatter={(v: number) => formatMetric(metric, v, { compact: true })}
              tick={{ fill: palette.axis, fontSize: 12 }}
              axisLine={false}
              tickLine={false}
              width={64}
              domain={metric === 'churnRate' ? [0, 'auto'] : ['auto', 'auto']}
            />
            <Tooltip
              content={(props) => <ChartTooltip {...props} metric={metric} palette={palette} />}
              cursor={{ stroke: palette.cursor, strokeWidth: 1, strokeDasharray: '4 4' }}
              isAnimationActive={false}
            />
            <Area
              type="monotone"
              dataKey={metric}
              stroke="none"
              fill="url(#main-fill)"
              isAnimationActive={false}
              activeDot={false}
              tooltipType="none"
            />
            <Line
              type="monotone"
              dataKey={metric}
              stroke={palette.accent}
              strokeWidth={2.5}
              dot={false}
              activeDot={{ r: 5, fill: palette.accent, stroke: '#fff', strokeWidth: 2 }}
              isAnimationActive={false}
            />
            {dragStart && dragEnd && dragStart !== dragEnd && (
              <ReferenceArea
                x1={dragStart}
                x2={dragEnd}
                fill={palette.accent}
                fillOpacity={0.12}
                stroke={palette.accent}
                strokeOpacity={0.5}
              />
            )}
          </ComposedChart>
        </ResponsiveContainer>
      </div>
    </section>
  )
}

type ChartTooltipProps = TooltipContentProps & { metric: MetricKey; palette: ChartPalette }

function ChartTooltip({ active, payload, metric, palette }: ChartTooltipProps) {
  const point = payload?.[0]?.payload as DayPoint | undefined
  if (!active || !point) return null
  return (
    <div className="tooltip" data-testid="chart-tooltip">
      <div className="tooltip__title">{formatLongDate(point.date)}</div>
      {METRICS.map((m) => (
        <div key={m} className={`tooltip__row${m === metric ? ' tooltip__row--active' : ''}`}>
          <span className="tooltip__dot" style={{ background: m === metric ? palette.accent : palette.muted }} />
          <span className="tooltip__label">{METRIC_LABEL[m]}</span>
          <span className="tooltip__value">{formatMetric(m, point[m])}</span>
        </div>
      ))}
    </div>
  )
}
