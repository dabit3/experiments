export const ROWS = 20
export const COLS = 10

export interface Pos {
  row: number
  col: number
}

export interface Range {
  r1: number
  c1: number
  r2: number
  c2: number
}

export const colName = (col: number): string => String.fromCharCode(65 + col)

export const cellKey = (pos: Pos): string => `${colName(pos.col)}${pos.row + 1}`

export const inBounds = (pos: Pos): boolean =>
  pos.row >= 0 && pos.row < ROWS && pos.col >= 0 && pos.col < COLS

export const clampPos = (pos: Pos): Pos => ({
  row: Math.min(ROWS - 1, Math.max(0, pos.row)),
  col: Math.min(COLS - 1, Math.max(0, pos.col)),
})

export const samePos = (a: Pos, b: Pos): boolean => a.row === b.row && a.col === b.col

const REF_RE = /^(\$?)([A-Z]+)(\$?)(\d+)$/i

export interface ParsedRef extends Pos {
  absCol: boolean
  absRow: boolean
}

export function parseRef(text: string): ParsedRef | null {
  const m = REF_RE.exec(text)
  if (!m) return null
  const letters = m[2].toUpperCase()
  if (letters.length !== 1) return null
  const col = letters.charCodeAt(0) - 65
  const row = Number(m[4]) - 1
  if (!inBounds({ row, col })) return null
  return { row, col, absCol: m[1] === '$', absRow: m[3] === '$' }
}

export function normalizeRange(a: Pos, b: Pos): Range {
  return {
    r1: Math.min(a.row, b.row),
    c1: Math.min(a.col, b.col),
    r2: Math.max(a.row, b.row),
    c2: Math.max(a.col, b.col),
  }
}

export const inRange = (pos: Pos, range: Range): boolean =>
  pos.row >= range.r1 && pos.row <= range.r2 && pos.col >= range.c1 && pos.col <= range.c2

export const rangeSize = (range: Range): number =>
  (range.r2 - range.r1 + 1) * (range.c2 - range.c1 + 1)

export function* rangePositions(range: Range): Generator<Pos> {
  for (let row = range.r1; row <= range.r2; row++) {
    for (let col = range.c1; col <= range.c2; col++) {
      yield { row, col }
    }
  }
}

export function rangeLabel(range: Range): string {
  const a = cellKey({ row: range.r1, col: range.c1 })
  const b = cellKey({ row: range.r2, col: range.c2 })
  return a === b ? a : `${a}:${b}`
}
