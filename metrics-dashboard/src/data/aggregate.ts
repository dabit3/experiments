import { DATASET, PLANS, REGIONS, dateForDay, type DailyRecord, type Plan, type Region } from './dataset'

export type PlanFilter = Plan | 'All'
export type MetricKey = 'revenue' | 'signups' | 'activeUsers' | 'churnRate'

export interface Filters {
  /** Inclusive [start, end] day offsets */
  range: [number, number]
  regions: Region[]
  plan: PlanFilter
}

export interface DayPoint {
  day: number
  date: string
  revenue: number
  signups: number
  activeUsers: number
  churned: number
  churnRate: number
}

export interface RegionBar {
  region: Region
  revenue: number
  signups: number
  byPlan: Record<Plan, number>
}

export interface TableRow {
  id: string
  date: string
  region: Region
  plan: string
  signups: number
  revenue: number
  activeUsers: number
  churnRate: number
}

export interface Kpi {
  key: MetricKey
  label: string
  value: number
  previous: number
  spark: number[]
}

export const METRIC_LABEL: Record<MetricKey, string> = {
  revenue: 'Revenue',
  signups: 'Signups',
  activeUsers: 'Active users',
  churnRate: 'Churn rate',
}

function matches(r: DailyRecord, f: Pick<Filters, 'regions' | 'plan'>): boolean {
  return f.regions.includes(r.region) && (f.plan === 'All' || r.plan === f.plan)
}

function emptyDay(day: number): DayPoint {
  return { day, date: dateForDay(day), revenue: 0, signups: 0, activeUsers: 0, churned: 0, churnRate: 0 }
}

/** Sum every matching record into one point per day for the given range. */
export function dailySeries(f: Filters, range: [number, number] = f.range): DayPoint[] {
  const [start, end] = range
  const days: DayPoint[] = []
  for (let d = start; d <= end; d++) days.push(emptyDay(d))

  for (const r of DATASET) {
    if (r.day < start || r.day > end || !matches(r, f)) continue
    const p = days[r.day - start]
    p.revenue += r.revenue
    p.signups += r.signups
    p.activeUsers += r.activeUsers
    p.churned += r.churned
  }
  for (const p of days) p.churnRate = p.activeUsers ? p.churned / p.activeUsers : 0
  return days
}

export function regionBars(f: Filters): RegionBar[] {
  const [start, end] = f.range
  const bars = new Map<Region, RegionBar>()
  for (const region of REGIONS) {
    if (!f.regions.includes(region)) continue
    bars.set(region, { region, revenue: 0, signups: 0, byPlan: { Starter: 0, Pro: 0, Enterprise: 0 } })
  }
  for (const r of DATASET) {
    if (r.day < start || r.day > end || !matches(r, f)) continue
    const b = bars.get(r.region)!
    b.revenue += r.revenue
    b.signups += r.signups
    b.byPlan[r.plan] += r.revenue
  }
  return [...bars.values()]
}

/** One row per (day, region), plans summed unless a single plan is selected. */
export function tableRows(f: Filters): TableRow[] {
  const [start, end] = f.range
  const rows = new Map<string, TableRow & { churned: number }>()
  for (const r of DATASET) {
    if (r.day < start || r.day > end || !matches(r, f)) continue
    const id = `${r.date}|${r.region}`
    let row = rows.get(id)
    if (!row) {
      row = {
        id,
        date: r.date,
        region: r.region,
        plan: f.plan === 'All' ? 'All plans' : f.plan,
        signups: 0,
        revenue: 0,
        activeUsers: 0,
        churnRate: 0,
        churned: 0,
      }
      rows.set(id, row)
    }
    row.signups += r.signups
    row.revenue += r.revenue
    row.activeUsers += r.activeUsers
    row.churned += r.churned
  }
  return [...rows.values()].map(({ churned, ...row }) => ({
    ...row,
    churnRate: row.activeUsers ? churned / row.activeUsers : 0,
  }))
}

function summarize(points: DayPoint[]): Record<MetricKey, number> {
  let revenue = 0
  let signups = 0
  let activeUsers = 0
  let churned = 0
  for (const p of points) {
    revenue += p.revenue
    signups += p.signups
    activeUsers += p.activeUsers
    churned += p.churned
  }
  return {
    revenue,
    signups,
    activeUsers: points.length ? Math.round(activeUsers / points.length) : 0,
    churnRate: activeUsers ? churned / activeUsers : 0,
  }
}

export function kpis(f: Filters, current: DayPoint[]): Kpi[] {
  const [start, end] = f.range
  const length = end - start + 1
  const prevStart = Math.max(0, start - length)
  const previous = start > 0 ? summarize(dailySeries(f, [prevStart, start - 1])) : summarize([])
  const now = summarize(current)

  return (Object.keys(METRIC_LABEL) as MetricKey[]).map((key) => ({
    key,
    label: METRIC_LABEL[key],
    value: now[key],
    previous: previous[key],
    spark: sparkline(current, key),
  }))
}

/** Downsample a series to at most 40 points for the tiny KPI sparklines. */
function sparkline(points: DayPoint[], key: MetricKey, buckets = 40): number[] {
  if (points.length <= buckets) return points.map((p) => p[key])
  const size = points.length / buckets
  const out: number[] = []
  for (let i = 0; i < buckets; i++) {
    const slice = points.slice(Math.floor(i * size), Math.floor((i + 1) * size))
    out.push(slice.reduce((s, p) => s + p[key], 0) / slice.length)
  }
  return out
}

export const ALL_REGIONS: Region[] = [...REGIONS]
export const ALL_PLANS: Plan[] = [...PLANS]
