/** Small, fast, deterministic PRNG (mulberry32). Same seed => same sequence. */
export interface Rng {
  next(): number
  int(maxExclusive: number): number
  pick<T>(items: readonly T[]): T
}

export function createRng(seed: number): Rng {
  let a = (seed >>> 0) || 0x9e3779b9
  const next = (): number => {
    a = (a + 0x6d2b79f5) | 0
    let t = Math.imul(a ^ (a >>> 15), 1 | a)
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
  return {
    next,
    int: (max) => Math.floor(next() * max),
    pick: (items) => items[Math.floor(next() * items.length)],
  }
}

export function seedFromUrl(): number {
  const raw = new URLSearchParams(window.location.search).get('seed')
  const parsed = raw === null ? NaN : Number.parseInt(raw, 10)
  if (Number.isFinite(parsed) && parsed >= 0) return parsed
  return Math.floor(Math.random() * 100000)
}

export function writeSeedToUrl(seed: number): void {
  const url = new URL(window.location.href)
  if (url.searchParams.get('seed') === String(seed)) return
  url.searchParams.set('seed', String(seed))
  window.history.replaceState(null, '', url)
}
