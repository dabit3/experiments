export const BOARD_SIZE = 10

export type Orientation = 'h' | 'v'

export interface Coord {
  r: number
  c: number
}

export interface ShipSpec {
  id: string
  name: string
  size: number
}

export const FLEET: readonly ShipSpec[] = [
  { id: 'carrier', name: 'Carrier', size: 5 },
  { id: 'battleship', name: 'Battleship', size: 4 },
  { id: 'cruiser', name: 'Cruiser', size: 3 },
  { id: 'submarine', name: 'Submarine', size: 3 },
  { id: 'destroyer', name: 'Destroyer', size: 2 },
]

export interface PlacedShip extends ShipSpec {
  bow: Coord
  orientation: Orientation
}

export type ShotResult = 'miss' | 'hit' | 'sunk'

export interface Shot {
  coord: Coord
  result: ShotResult
  shipId?: string
}

export type Side = 'player' | 'enemy'

export interface LogEntry {
  turn: number
  side: Side
  coord: Coord
  result: ShotResult
  shipName?: string
}

export const key = (c: Coord): string => `${c.r},${c.c}`

export const inBounds = (c: Coord): boolean =>
  c.r >= 0 && c.r < BOARD_SIZE && c.c >= 0 && c.c < BOARD_SIZE

export const cellsOf = (ship: PlacedShip): Coord[] =>
  Array.from({ length: ship.size }, (_, i) =>
    ship.orientation === 'h'
      ? { r: ship.bow.r, c: ship.bow.c + i }
      : { r: ship.bow.r + i, c: ship.bow.c },
  )

export const coordLabel = (c: Coord): string =>
  `${String.fromCharCode(65 + c.r)}${c.c + 1}`
