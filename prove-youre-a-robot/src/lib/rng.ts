export type Rng = () => number

/** mulberry32: small, fast, deterministic PRNG. */
export function mulberry32(seed: number): Rng {
  let a = seed >>> 0
  return () => {
    a = (a + 0x6d2b79f5) >>> 0
    let t = a
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

export const rangeInt = (rng: Rng, min: number, max: number): number =>
  min + Math.floor(rng() * (max - min + 1))

export const range = (rng: Rng, min: number, max: number): number => min + rng() * (max - min)

export const pick = <T,>(rng: Rng, items: readonly T[]): T => items[Math.floor(rng() * items.length)]

export function shuffle<T>(rng: Rng, items: readonly T[]): T[] {
  const out = [...items]
  for (let i = out.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1))
    ;[out[i], out[j]] = [out[j], out[i]]
  }
  return out
}

/** Derive an independent sub-seed for one stage of a run. */
export const stageSeed = (seed: number, stage: number): number =>
  (Math.imul(seed + 1, 1000003) + Math.imul(stage + 1, 7919)) >>> 0

export function parseSeed(search: string): number {
  const raw = new URLSearchParams(search).get('seed')
  const n = raw === null ? NaN : Number.parseInt(raw, 10)
  return Number.isFinite(n) && n >= 0 ? n : 1
}
