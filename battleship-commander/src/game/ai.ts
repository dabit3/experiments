import { analyseShots } from './heatmap'
import type { Rng } from './rng'
import { BOARD_SIZE, inBounds, key, type Coord, type Shot } from './types'

export type AiMode = 'hunt' | 'target'

export interface AiDecision {
  coord: Coord
  mode: AiMode
  reason: string
}

const DIRS: readonly Coord[] = [
  { r: -1, c: 0 },
  { r: 1, c: 0 },
  { r: 0, c: -1 },
  { r: 0, c: 1 },
]

/**
 * Classic hunt/target Battleship AI.
 *
 * Hunt: fire at a random (seeded) unknown cell on a checkerboard parity that
 * could still hold the smallest ship afloat. Target: once a ship is hit but not
 * sunk, extend along the line of adjacent hits; otherwise probe the four
 * neighbours of the open hit.
 */
export function chooseShot(shots: ReadonlyMap<string, Shot>, rng: Rng): AiDecision {
  const intel = analyseShots(shots)
  const unknown = (c: Coord): boolean => inBounds(c) && !shots.has(key(c))

  if (intel.openHits.length > 0) {
    const hitKeys = new Set(intel.openHits.map(key))
    const lineEnds: Coord[] = []
    for (const h of intel.openHits) {
      for (const d of DIRS) {
        const prev = { r: h.r - d.r, c: h.c - d.c }
        if (!hitKeys.has(key(prev))) continue
        // h continues a run of hits in direction d: walk to the run's end.
        let cur = { r: h.r + d.r, c: h.c + d.c }
        while (hitKeys.has(key(cur))) cur = { r: cur.r + d.r, c: cur.c + d.c }
        if (unknown(cur)) lineEnds.push(cur)
      }
    }
    if (lineEnds.length > 0) {
      return {
        coord: rng.pick(dedupe(lineEnds)),
        mode: 'target',
        reason: 'extending a line of hits',
      }
    }
    const neighbours: Coord[] = []
    for (const h of intel.openHits) {
      for (const d of DIRS) {
        const n = { r: h.r + d.r, c: h.c + d.c }
        if (unknown(n)) neighbours.push(n)
      }
    }
    if (neighbours.length > 0) {
      return {
        coord: rng.pick(dedupe(neighbours)),
        mode: 'target',
        reason: 'probing around a hit',
      }
    }
  }

  const smallest = Math.min(...intel.remaining.map((s) => s.size))
  const fits = (c: Coord): boolean => {
    for (const orientation of ['h', 'v'] as const) {
      for (let offset = 0; offset < smallest; offset++) {
        let ok = true
        for (let i = 0; i < smallest; i++) {
          const cell =
            orientation === 'h'
              ? { r: c.r, c: c.c - offset + i }
              : { r: c.r - offset + i, c: c.c }
          if (!unknown(cell)) {
            ok = false
            break
          }
        }
        if (ok) return true
      }
    }
    return false
  }

  const candidates: Coord[] = []
  const fallback: Coord[] = []
  for (let r = 0; r < BOARD_SIZE; r++) {
    for (let c = 0; c < BOARD_SIZE; c++) {
      const cell = { r, c }
      if (!unknown(cell)) continue
      fallback.push(cell)
      if ((r + c) % smallest === 0 && fits(cell)) candidates.push(cell)
    }
  }
  const pool = candidates.length > 0 ? candidates : fallback.filter(fits)
  return {
    coord: rng.pick(pool.length > 0 ? pool : fallback),
    mode: 'hunt',
    reason: 'searching on parity',
  }
}

function dedupe(coords: Coord[]): Coord[] {
  const seen = new Set<string>()
  return coords.filter((c) => {
    const k = key(c)
    if (seen.has(k)) return false
    seen.add(k)
    return true
  })
}
