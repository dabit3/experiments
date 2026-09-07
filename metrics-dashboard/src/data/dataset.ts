export const REGIONS = ['North America', 'Europe', 'Asia Pacific', 'Latin America'] as const
export const PLANS = ['Starter', 'Pro', 'Enterprise'] as const

export type Region = (typeof REGIONS)[number]
export type Plan = (typeof PLANS)[number]

export interface DailyRecord {
  /** 0-based day offset from the start of the dataset */
  day: number
  /** ISO date, YYYY-MM-DD */
  date: string
  region: Region
  plan: Plan
  signups: number
  revenue: number
  activeUsers: number
  churned: number
}

export const DAYS = 365
export const START_DATE = new Date(Date.UTC(2025, 0, 1))

export function dateForDay(day: number): string {
  const d = new Date(START_DATE)
  d.setUTCDate(d.getUTCDate() + day)
  return d.toISOString().slice(0, 10)
}

/** Small, fast, deterministic PRNG (mulberry32). */
function mulberry32(seed: number) {
  let a = seed >>> 0
  return () => {
    a = (a + 0x6d2b79f5) >>> 0
    let t = a
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

const REGION_WEIGHT: Record<Region, number> = {
  'North America': 1.0,
  Europe: 0.78,
  'Asia Pacific': 0.62,
  'Latin America': 0.34,
}

const PLAN_PROFILE: Record<Plan, { signups: number; price: number; users: number; churn: number }> = {
  Starter: { signups: 42, price: 29, users: 1900, churn: 0.028 },
  Pro: { signups: 17, price: 99, users: 820, churn: 0.016 },
  Enterprise: { signups: 3, price: 1200, users: 140, churn: 0.006 },
}

/** Product launches / campaigns that create visible bumps in the data. */
const EVENTS: Array<{ day: number; length: number; boost: number }> = [
  { day: 74, length: 6, boost: 1.9 }, // spring campaign
  { day: 158, length: 4, boost: 1.5 }, // summer launch
  { day: 246, length: 8, boost: 2.3 }, // v2 release
  { day: 331, length: 5, boost: 1.7 }, // Black Friday
]

function eventBoost(day: number): number {
  for (const e of EVENTS) {
    if (day >= e.day && day < e.day + e.length) {
      const progress = (day - e.day) / e.length
      return 1 + (e.boost - 1) * (1 - progress)
    }
  }
  return 1
}

export function generateDataset(seed = 20250101): DailyRecord[] {
  const rand = mulberry32(seed)
  const records: DailyRecord[] = []

  for (let day = 0; day < DAYS; day++) {
    const date = dateForDay(day)
    const weekday = (new Date(date).getUTCDay() + 6) % 7 // 0 = Monday
    const weekend = weekday >= 5 ? 0.62 : 1
    const growth = 1 + day / DAYS // roughly doubles over the year
    const season = 1 + 0.12 * Math.sin((day / DAYS) * Math.PI * 2 - Math.PI / 2)
    const boost = eventBoost(day)

    for (const region of REGIONS) {
      const rw = REGION_WEIGHT[region]
      for (const plan of PLANS) {
        const p = PLAN_PROFILE[plan]
        const noise = () => 0.82 + rand() * 0.36

        const signups = Math.round(p.signups * rw * growth * season * weekend * boost * noise())
        const activeUsers = Math.round(p.users * rw * growth * season * (0.96 + rand() * 0.08))
        const churned = Math.round(activeUsers * p.churn * (0.7 + rand() * 0.6))
        const revenue = Math.round((activeUsers * p.price) / 30 + signups * p.price * 0.5 * noise())

        records.push({ day, date, region, plan, signups, revenue, activeUsers, churned })
      }
    }
  }

  return records
}

export const DATASET: readonly DailyRecord[] = generateDataset()
