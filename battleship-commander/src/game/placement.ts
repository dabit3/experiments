import type { Rng } from './rng'
import {
  BOARD_SIZE,
  FLEET,
  cellsOf,
  inBounds,
  key,
  type Coord,
  type Orientation,
  type PlacedShip,
  type ShipSpec,
} from './types'

export function occupiedCells(ships: readonly PlacedShip[], ignoreId?: string): Set<string> {
  const set = new Set<string>()
  for (const s of ships) {
    if (s.id === ignoreId) continue
    for (const c of cellsOf(s)) set.add(key(c))
  }
  return set
}

export function canPlace(
  ships: readonly PlacedShip[],
  candidate: PlacedShip,
  ignoreId: string = candidate.id,
): boolean {
  const taken = occupiedCells(ships, ignoreId)
  return cellsOf(candidate).every((c) => inBounds(c) && !taken.has(key(c)))
}

export function randomFleet(rng: Rng): PlacedShip[] {
  const placed: PlacedShip[] = []
  for (const spec of FLEET) {
    const options: PlacedShip[] = []
    for (const orientation of ['h', 'v'] as const) {
      const maxR = orientation === 'v' ? BOARD_SIZE - spec.size : BOARD_SIZE - 1
      const maxC = orientation === 'h' ? BOARD_SIZE - spec.size : BOARD_SIZE - 1
      for (let r = 0; r <= maxR; r++) {
        for (let c = 0; c <= maxC; c++) {
          const cand: PlacedShip = { ...spec, bow: { r, c }, orientation }
          if (canPlace(placed, cand)) options.push(cand)
        }
      }
    }
    placed.push(rng.pick(options))
  }
  return placed
}

/** Bow coordinate so that the ship's `grabIndex`-th segment lands on `target`. */
export function bowFromGrab(
  target: Coord,
  grabIndex: number,
  orientation: Orientation,
): Coord {
  return orientation === 'h'
    ? { r: target.r, c: target.c - grabIndex }
    : { r: target.r - grabIndex, c: target.c }
}

export function shipAt(ships: readonly PlacedShip[], coord: Coord): PlacedShip | undefined {
  const k = key(coord)
  return ships.find((s) => cellsOf(s).some((c) => key(c) === k))
}

export function remainingSpecs(placed: readonly PlacedShip[]): ShipSpec[] {
  const ids = new Set(placed.map((s) => s.id))
  return FLEET.filter((s) => !ids.has(s.id))
}
