import { useMemo, useState } from 'react'
import { DataTable } from './components/DataTable'
import { DateRangeControls } from './components/DateRangeControls'
import { KpiCard } from './components/KpiCard'
import { PlanSegmented } from './components/PlanSegmented'
import { RegionBarChart } from './components/RegionBarChart'
import { RegionMultiSelect } from './components/RegionMultiSelect'
import { TimeSeriesChart } from './components/TimeSeriesChart'
import { ALL_REGIONS, dailySeries, kpis, regionBars, tableRows, type Filters, type MetricKey } from './data/aggregate'
import { DAYS } from './data/dataset'
import { PALETTES, useTheme } from './hooks/useTheme'

const KPI_COLORS: Record<MetricKey, number> = { revenue: 0, signups: 1, activeUsers: 2, churnRate: 3 }

export default function App() {
  const [theme, toggleTheme] = useTheme()
  const palette = PALETTES[theme]

  const [filters, setFilters] = useState<Filters>({
    range: [DAYS - 90, DAYS - 1],
    regions: ALL_REGIONS,
    plan: 'All',
  })
  const [metric, setMetric] = useState<MetricKey>('revenue')
  const [zoom, setZoom] = useState<[string, string] | null>(null)

  const update = (patch: Partial<Filters>) => {
    setFilters((f) => ({ ...f, ...patch }))
    if (patch.range) setZoom(null)
  }

  const series = useMemo(() => dailySeries(filters), [filters])
  const cards = useMemo(() => kpis(filters, series), [filters, series])
  const bars = useMemo(() => regionBars(filters), [filters])
  const rows = useMemo(() => tableRows(filters), [filters])

  return (
    <div className="app">
      <header className="topbar">
        <div className="brand">
          <span className="brand__mark" aria-hidden="true">
            ◔
          </span>
          <div>
            <h1 className="brand__name">Pulse Analytics</h1>
            <p className="brand__tagline">Seeded SaaS metrics · 365 days · 4 regions · 3 plans</p>
          </div>
        </div>
        <button
          type="button"
          className="btn btn--icon"
          onClick={toggleTheme}
          aria-label={`Switch to ${theme === 'light' ? 'dark' : 'light'} mode`}
          data-testid="theme-toggle"
        >
          {theme === 'light' ? '☾ Dark' : '☀ Light'}
        </button>
      </header>

      <section className="panel filters" data-testid="filters">
        <DateRangeControls range={filters.range} onChange={(range) => update({ range })} />
        <div className="filters__row">
          <RegionMultiSelect selected={filters.regions} onChange={(regions) => update({ regions })} colors={palette.series} />
          <PlanSegmented value={filters.plan} onChange={(plan) => update({ plan })} />
        </div>
      </section>

      <section className="kpi-grid" data-testid="kpi-grid">
        {cards.map((kpi) => (
          <KpiCard
            key={kpi.key}
            kpi={kpi}
            color={palette.series[KPI_COLORS[kpi.key]]}
            selected={metric === kpi.key}
            onSelect={() => setMetric(kpi.key)}
          />
        ))}
      </section>

      <div className="charts">
        <TimeSeriesChart
          data={series}
          metric={metric}
          onMetricChange={setMetric}
          zoom={zoom}
          onZoom={setZoom}
          palette={palette}
        />
        <RegionBarChart bars={bars} palette={palette} />
      </div>

      <DataTable rows={rows} />

      <footer className="footer">Deterministic dataset generated in-browser · no network requests</footer>
    </div>
  )
}
