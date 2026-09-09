export interface Point {
  x: number
  y: number
}

export const clamp = (n: number, min: number, max: number): number => Math.min(max, Math.max(min, n))

export const dist = (a: Point, b: Point): number => Math.hypot(a.x - b.x, a.y - b.y)

/** Normalise an angle in degrees to the half-open range (-180, 180]. */
export function normalizeAngle(deg: number): number {
  let a = ((deg % 360) + 360) % 360
  if (a > 180) a -= 360
  return a
}

/** Catmull-Rom spline through `pts`, sampled `perSegment` times per segment. */
export function catmullRom(pts: readonly Point[], perSegment: number): Point[] {
  if (pts.length < 2) return [...pts]
  const out: Point[] = []
  for (let i = 0; i < pts.length - 1; i++) {
    const p0 = pts[Math.max(0, i - 1)]
    const p1 = pts[i]
    const p2 = pts[i + 1]
    const p3 = pts[Math.min(pts.length - 1, i + 2)]
    for (let k = 0; k < perSegment; k++) {
      const t = k / perSegment
      const t2 = t * t
      const t3 = t2 * t
      out.push({
        x:
          0.5 *
          (2 * p1.x +
            (-p0.x + p2.x) * t +
            (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 +
            (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3),
        y:
          0.5 *
          (2 * p1.y +
            (-p0.y + p2.y) * t +
            (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 +
            (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3),
      })
    }
  }
  out.push(pts[pts.length - 1])
  return out
}

export interface Nearest {
  distance: number
  /** Position along the polyline, 0..1 */
  t: number
}

/** Nearest point on a polyline to `p`: distance and normalised arc position. */
export function nearestOnPolyline(line: readonly Point[], p: Point): Nearest {
  let best: Nearest = { distance: Infinity, t: 0 }
  const segs = line.length - 1
  for (let i = 0; i < segs; i++) {
    const a = line[i]
    const b = line[i + 1]
    const abx = b.x - a.x
    const aby = b.y - a.y
    const len2 = abx * abx + aby * aby
    const u = len2 === 0 ? 0 : clamp(((p.x - a.x) * abx + (p.y - a.y) * aby) / len2, 0, 1)
    const d = Math.hypot(p.x - (a.x + abx * u), p.y - (a.y + aby * u))
    if (d < best.distance) best = { distance: d, t: (i + u) / segs }
  }
  return best
}

export const polylineToPath = (line: readonly Point[]): string =>
  line.map((p, i) => `${i === 0 ? 'M' : 'L'} ${p.x.toFixed(1)} ${p.y.toFixed(1)}`).join(' ')
