const usd = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' })

/** Format cents as a USD string, e.g. 1234 -> "$12.34". */
export function fmt(cents: number): string {
  return usd.format(cents / 100)
}

/** Format a signed delta, e.g. 300 -> "+$3.00". Empty for zero. */
export function fmtDelta(cents: number): string {
  if (cents === 0) return ''
  return (cents > 0 ? '+' : '−') + fmt(Math.abs(cents))
}

/** Round half up to a whole cent. */
export function roundCents(value: number): number {
  return Math.round(value + Number.EPSILON)
}

/**
 * Split `total` cents across buckets proportionally to `weights` using the
 * largest-remainder method so the pieces always sum exactly to `total`.
 */
export function allocate(total: number, weights: number[]): number[] {
  const n = weights.length
  if (n === 0) return []
  const sum = weights.reduce((a, b) => a + b, 0)
  if (sum <= 0) {
    // Fall back to an even split.
    return allocate(total, weights.map(() => 1))
  }
  const raw = weights.map((w) => (total * w) / sum)
  const floors = raw.map((r) => Math.floor(r))
  let remainder = total - floors.reduce((a, b) => a + b, 0)
  const order = raw
    .map((r, i) => ({ i, frac: r - Math.floor(r) }))
    .sort((a, b) => b.frac - a.frac || a.i - b.i)
  for (const { i } of order) {
    if (remainder <= 0) break
    floors[i] += 1
    remainder -= 1
  }
  return floors
}

export function percentOf(cents: number, rate: number): number {
  return roundCents(cents * rate)
}
