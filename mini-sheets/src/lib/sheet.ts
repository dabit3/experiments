import { cellKey, COLS, inBounds, rangePositions, ROWS, type Pos, type Range } from './cells'
import { evaluateFormula, parseLiteral, shiftFormula, type CellValue } from './formula'

export interface Cell {
  raw: string
  bold?: boolean
}

/** Sparse map of cell key ("A1") to cell contents. */
export type Cells = Record<string, Cell>

export type Values = Record<string, CellValue>

const EMPTY: Cell = { raw: '' }

export const getCell = (cells: Cells, key: string): Cell => cells[key] ?? EMPTY

function withCell(cells: Cells, key: string, cell: Cell): Cells {
  const next = { ...cells }
  if (cell.raw === '' && !cell.bold) delete next[key]
  else next[key] = cell
  return next
}

/** Evaluates every cell, resolving references lazily with cycle detection. */
export function computeValues(cells: Cells): Values {
  const values: Values = {}
  const visiting = new Set<string>()

  const resolve = (key: string): CellValue => {
    if (key in values) return values[key]
    if (visiting.has(key)) return { error: '#CIRC!' }
    const raw = getCell(cells, key).raw
    let value: CellValue
    if (raw.startsWith('=')) {
      visiting.add(key)
      value = evaluateFormula(raw.slice(1), resolve)
      visiting.delete(key)
    } else {
      value = parseLiteral(raw)
    }
    values[key] = value
    return value
  }

  for (const key of Object.keys(cells)) resolve(key)
  return values
}

export function setCellRaw(cells: Cells, key: string, raw: string): Cells {
  return withCell(cells, key, { ...getCell(cells, key), raw })
}

export function clearRange(cells: Cells, range: Range): Cells {
  let next = cells
  for (const pos of rangePositions(range)) {
    const key = cellKey(pos)
    if (cells[key]) next = withCell(next, key, { ...cells[key], raw: '' })
  }
  return next
}

/** Bolds the range, unless every non-empty cell is already bold, in which case it un-bolds. */
export function toggleBold(cells: Cells, range: Range): Cells {
  const keys = [...rangePositions(range)].map(cellKey)
  const allBold = keys.every((key) => getCell(cells, key).bold)
  let next = cells
  for (const key of keys) next = withCell(next, key, { ...getCell(cells, key), bold: !allBold })
  return next
}

function copyCell(cells: Cells, from: Pos, to: Pos): Cells {
  const source = getCell(cells, cellKey(from))
  return withCell(cells, cellKey(to), {
    raw: shiftFormula(source.raw, to.row - from.row, to.col - from.col),
    bold: source.bold,
  })
}

/**
 * Fills the top row of the range down through the rest of it, adjusting relative references.
 * A single-row range is filled from the row directly above it (Excel behaviour).
 */
export function fillDown(cells: Cells, range: Range): Cells {
  const sourceRow = range.r1 === range.r2 ? range.r1 - 1 : range.r1
  if (sourceRow < 0) return cells
  let next = cells
  for (let row = sourceRow + 1; row <= range.r2; row++) {
    for (let col = range.c1; col <= range.c2; col++) {
      next = copyCell(next, { row: sourceRow, col }, { row, col })
    }
  }
  return next
}

export interface Clipboard {
  range: Range
  cells: Cells
}

export function copyRange(cells: Cells, range: Range): Clipboard {
  const copied: Cells = {}
  for (const pos of rangePositions(range)) {
    const key = cellKey(pos)
    if (cells[key]) copied[key] = cells[key]
  }
  return { range, cells: copied }
}

/** Pastes the clipboard with its top-left corner at `target`, shifting relative references. */
export function paste(cells: Cells, clip: Clipboard, target: Pos): { cells: Cells; range: Range } {
  const dRow = target.row - clip.range.r1
  const dCol = target.col - clip.range.c1
  let next = cells
  for (const pos of rangePositions(clip.range)) {
    const to = { row: pos.row + dRow, col: pos.col + dCol }
    if (!inBounds(to)) continue
    const source = getCell(clip.cells, cellKey(pos))
    next = withCell(next, cellKey(to), {
      raw: shiftFormula(source.raw, dRow, dCol),
      bold: source.bold,
    })
  }
  const range: Range = {
    r1: target.row,
    c1: target.col,
    r2: Math.min(ROWS - 1, clip.range.r2 + dRow),
    c2: Math.min(COLS - 1, clip.range.c2 + dCol),
  }
  return { cells: next, range }
}

export function rangeToTsv(values: Values, range: Range): string {
  const lines: string[] = []
  for (let row = range.r1; row <= range.r2; row++) {
    const parts: string[] = []
    for (let col = range.c1; col <= range.c2; col++) {
      const v = values[cellKey({ row, col })]
      parts.push(v === null || v === undefined ? '' : typeof v === 'object' ? v.error : String(v))
    }
    lines.push(parts.join('\t'))
  }
  return lines.join('\n')
}
