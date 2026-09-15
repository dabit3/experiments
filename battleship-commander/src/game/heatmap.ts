import {
  BOARD_SIZE,
  FLEET,
  inBounds,
  key,
  type Coord,
  type Shot,
  type ShipSpec,
} from './types'

export interface Intel {
  /** Cells shot at that did not hit anything. */
  misses: Set<string>
  /** Hit cells belonging to ships that are already sunk. */
  sunkCells: Set<string>
  /** Hit cells belonging to ships still afloat. */
  openHits: Coord[]
  /** Ships not yet sunk. */
  remaining: ShipSpec[]
}

export function analyseShots(shots: ReadonlyMap<string, Shot>): Intel {
  const misses = new Set<string>()
  const sunkIds = new Set<string>()
  for (const s of shots.values()) {
    if (s.result === 'miss') misses.add(key(s.coord))
    if (s.result === 'sunk' && s.shipId) sunkIds.add(s.shipId)
  }
  const sunkCells = new Set<string>()
  const openHits: Coord[] = []
  for (const s of shots.values()) {
    if (s.result === 'miss') continue
    if (s.shipId && sunkIds.has(s.shipId)) sunkCells.add(key(s.coord))
    else openHits.push(s.coord)
  }
  return {
    misses,
    sunkCells,
    openHits,
    remaining: FLEET.filter((f) => !sunkIds.has(f.id)),
  }
}

export interface Heatmap {
  /** weights[r][c]; 0 for cells already shot. */
  weights: number[][]
  max: number
  total: number
  best: Coord | null
  mode: 'hunt' | 'target'
}

const HIT_BONUS = 24

/**
 * Probability-density estimate of where the remaining enemy ships can be.
 * Every legal placement of every remaining ship adds weight to the cells it
 * covers. Placements running through un-sunk hits are boosted heavily, which
 * is what turns the map into a "target" map after a hit.
 */
export function computeHeatmap(shots: ReadonlyMap<string, Shot>): Heatmap {
  const intel = analyseShots(shots)
  const openHitKeys = new Set(intel.openHits.map(key))
  const weights: number[][] = Array.from({ length: BOARD_SIZE }, () =>
    Array<number>(BOARD_SIZE).fill(0),
  )
  const blocked = (c: Coord): boolean =>
    intel.misses.has(key(c)) || intel.sunkCells.has(key(c))

  for (const ship of intel.remaining) {
    for (const orientation of ['h', 'v'] as const) {
      for (let r = 0; r < BOARD_SIZE; r++) {
        for (let c = 0; c < BOARD_SIZE; c++) {
          const cells: Coord[] = []
          let ok = true
          for (let i = 0; i < ship.size; i++) {
            const cell = orientation === 'h' ? { r, c: c + i } : { r: r + i, c }
            if (!inBounds(cell) || blocked(cell)) {
              ok = false
              break
            }
            cells.push(cell)
          }
          if (!ok) continue
          const covered = cells.filter((cell) => openHitKeys.has(key(cell))).length
          const w = 1 + covered * HIT_BONUS
          for (const cell of cells) {
            if (shots.has(key(cell))) continue
            weights[cell.r][cell.c] += w
          }
        }
      }
    }
  }

  let max = 0
  let total = 0
  let best: Coord | null = null
  for (let r = 0; r < BOARD_SIZE; r++) {
    for (let c = 0; c < BOARD_SIZE; c++) {
      const w = weights[r][c]
      total += w
      if (w > max) {
        max = w
        best = { r, c }
      }
    }
  }
  return {
    weights,
    max,
    total,
    best,
    mode: intel.openHits.length > 0 ? 'target' : 'hunt',
  }
}
