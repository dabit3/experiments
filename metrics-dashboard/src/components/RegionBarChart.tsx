import { useState } from 'react'
import { Bar, BarChart, CartesianGrid, Cell, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { ALL_PLANS, type RegionBar } from '../data/aggregate'
import type { ChartPalette } from '../hooks/useTheme'
import { formatMetric } from '../utils/format'

interface Props {
  bars: RegionBar[]
  palette: ChartPalette
}

export function RegionBarChart({ bars, palette }: Props) {
  const [hovered, setHovered] = useState<number | null>(null)
  const total = bars.reduce((s, b) => s + b.revenue, 0)

  return (
    <section className="panel" data-testid="bar-panel">
      <header className="panel__head">
        <div>
          <h2 className="panel__title">Revenue by region</h2>
          <p className="panel__subtitle" data-testid="bar-summary">
            {bars.length} region{bars.length === 1 ? '' : 's'} · {formatMetric('revenue', total)} total
          </p>
        </div>
      </header>
      <div className="chart-area" data-testid="bar-chart">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart
            data={bars}
            margin={{ top: 12, right: 16, bottom: 4, left: 4 }}
            barCategoryGap="28%"
            onMouseLeave={() => setHovered(null)}
          >
            <CartesianGrid stroke={palette.grid} vertical={false} />
            <XAxis
              dataKey="region"
              tick={{ fill: palette.axis, fontSize: 12 }}
              axisLine={{ stroke: palette.grid }}
              tickLine={false}
              interval={0}
            />
            <YAxis
              tickFormatter={(v: number) => formatMetric('revenue', v, { compact: true })}
              tick={{ fill: palette.axis, fontSize: 12 }}
              axisLine={false}
              tickLine={false}
              width={64}
            />
            <Tooltip
              cursor={false}
              isAnimationActive={false}
              content={({ active, payload }) => {
                const bar = payload?.[0]?.payload as RegionBar | undefined
                if (!active || !bar) return null
                return (
                  <div className="tooltip" data-testid="bar-tooltip">
                    <div className="tooltip__title">{bar.region}</div>
                    <div className="tooltip__row tooltip__row--active">
                      <span className="tooltip__label">Revenue</span>
                      <span className="tooltip__value">{formatMetric('revenue', bar.revenue)}</span>
                    </div>
                    {ALL_PLANS.map((plan) => (
                      <div key={plan} className="tooltip__row">
                        <span className="tooltip__label">{plan}</span>
                        <span className="tooltip__value">{formatMetric('revenue', bar.byPlan[plan])}</span>
                      </div>
                    ))}
                    <div className="tooltip__row">
                      <span className="tooltip__label">Share</span>
                      <span className="tooltip__value">{total ? ((bar.revenue / total) * 100).toFixed(1) : '0.0'}%</span>
                    </div>
                  </div>
                )
              }}
            />
            <Bar
              dataKey="revenue"
              radius={[8, 8, 2, 2]}
              isAnimationActive={false}
              activeBar={false}
              onMouseEnter={(_, index) => setHovered(index)}
            >
              {bars.map((bar, i) => (
                <Cell
                  key={bar.region}
                  fill={palette.series[i % palette.series.length]}
                  fillOpacity={hovered === null || hovered === i ? 1 : 0.35}
                  stroke={hovered === i ? palette.text : 'none'}
                  strokeWidth={hovered === i ? 1.5 : 0}
                  className="bar-cell"
                  data-testid={`bar-${bar.region}`}
                />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>
    </section>
  )
}
