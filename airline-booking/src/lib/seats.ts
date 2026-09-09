import { createRng, hashString } from './random'

export const ROWS = 30
export const SEAT_LETTERS = ['A', 'B', 'C', 'D', 'E', 'F'] as const
export const EXIT_ROWS = [14, 15]
export const PREFERRED_ROWS = [1, 2, 3]
export const EXIT_ROW_FEE = 24
export const PREFERRED_FEE = 12

export type SeatKind = 'standard' | 'exit' | 'preferred'

export function seatKind(row: number): SeatKind {
  if (EXIT_ROWS.includes(row)) return 'exit'
  if (PREFERRED_ROWS.includes(row)) return 'preferred'
  return 'standard'
}

export function seatFee(seat: string | undefined): number {
  if (!seat) return 0
  const kind = seatKind(seatRow(seat))
  return kind === 'exit' ? EXIT_ROW_FEE : kind === 'preferred' ? PREFERRED_FEE : 0
}

export function seatRow(seat: string): number {
  return Number(seat.replace(/[A-F]$/, ''))
}

export function seatLetter(seat: string): string {
  return seat.slice(-1)
}

export function isWindow(seat: string): boolean {
  const l = seatLetter(seat)
  return l === 'A' || l === 'F'
}

export function isAisle(seat: string): boolean {
  const l = seatLetter(seat)
  return l === 'C' || l === 'D'
}

export function seatPosition(seat: string): string {
  return isWindow(seat) ? 'Window' : isAisle(seat) ? 'Aisle' : 'Middle'
}

/** Deterministic set of already-taken seats for a flight (~38% load). */
export function takenSeats(flightId: string): Set<string> {
  const rng = createRng(hashString(`seats:${flightId}`))
  const taken = new Set<string>()
  for (let row = 1; row <= ROWS; row++) {
    for (const letter of SEAT_LETTERS) {
      const bias = row <= 3 ? 0.55 : row <= 10 ? 0.42 : 0.33
      if (rng.chance(bias)) taken.add(`${row}${letter}`)
    }
  }
  return taken
}
