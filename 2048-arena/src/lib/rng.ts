/**
 * mulberry32: a tiny, fast, seedable PRNG. The state is a plain 32-bit integer
 * so it can be stored in undo snapshots and restored exactly, which keeps a
 * whole run reproducible from `?seed=N` plus the key sequence.
 */
export interface RandomResult {
  value: number
  state: number
}

export function nextRandom(state: number): RandomResult {
  const t = (state + 0x6d2b79f5) | 0
  let r = Math.imul(t ^ (t >>> 15), t | 1)
  r ^= r + Math.imul(r ^ (r >>> 7), r | 61)
  return { value: ((r ^ (r >>> 14)) >>> 0) / 4294967296, state: t }
}

export function seedFromString(raw: string | null): number | null {
  if (raw === null || raw.trim() === '') return null
  const n = Number(raw)
  if (!Number.isFinite(n)) return null
  return Math.trunc(n) >>> 0
}

export function randomSeed(): number {
  return Math.floor(Math.random() * 1_000_000)
}
