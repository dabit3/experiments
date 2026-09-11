import { mulberry32 } from './rng'

export type Level = 'beginner' | 'intermediate' | 'expert'

export interface LevelSpec {
  label: string
  rows: number
  cols: number
  mines: number
}

export const LEVELS: Record<Level, LevelSpec> = {
  beginner: { label: 'Beginner', rows: 9, cols: 9, mines: 10 },
  intermediate: { label: 'Intermediate', rows: 16, cols: 16, mines: 40 },
  expert: { label: 'Expert', rows: 16, cols: 30, mines: 99 },
}

export const LEVEL_ORDER: Level[] = ['beginner', 'intermediate', 'expert']

export function isLevel(value: string | null): value is Level {
  return value !== null && value in LEVELS
}

export type Mark = 'none' | 'flag' | 'question'

export interface Cell {
  mine: boolean
  adjacent: number
  revealed: boolean
  mark: Mark
}

export interface Board {
  rows: number
  cols: number
  mines: number
  /** False until the first reveal places the mines. */
  armed: boolean
  cells: Cell[]
}

export function emptyBoard(spec: LevelSpec): Board {
  const cells: Cell[] = []
  for (let i = 0; i < spec.rows * spec.cols; i++) {
    cells.push({ mine: false, adjacent: 0, revealed: false, mark: 'none' })
  }
  return { rows: spec.rows, cols: spec.cols, mines: spec.mines, armed: false, cells }
}

export function neighbors(board: Board, index: number): number[] {
  const r = Math.floor(index / board.cols)
  const c = index % board.cols
  const out: number[] = []
  for (let dr = -1; dr <= 1; dr++) {
    for (let dc = -1; dc <= 1; dc++) {
      if (dr === 0 && dc === 0) continue
      const nr = r + dr
      const nc = c + dc
      if (nr < 0 || nc < 0 || nr >= board.rows || nc >= board.cols) continue
      out.push(nr * board.cols + nc)
    }
  }
  return out
}

/**
 * Place mines deterministically from `seed`, keeping `safeIndex` and all of its
 * neighbours mine-free so the first click always opens an empty region.
 */
export function placeMines(board: Board, seed: number, safeIndex: number): Board {
  const exclude = new Set<number>([safeIndex, ...neighbors(board, safeIndex)])
  const candidates: number[] = []
  for (let i = 0; i < board.cells.length; i++) {
    if (!exclude.has(i)) candidates.push(i)
  }
  const rand = mulberry32(seed)
  // Partial Fisher-Yates: the first `mines` slots become the mine positions.
  const count = Math.min(board.mines, candidates.length)
  for (let i = 0; i < count; i++) {
    const j = i + Math.floor(rand() * (candidates.length - i))
    const tmp = candidates[i]
    candidates[i] = candidates[j]
    candidates[j] = tmp
  }
  const mineSet = new Set(candidates.slice(0, count))
  const cells = board.cells.map((cell, i) => ({ ...cell, mine: mineSet.has(i), adjacent: 0 }))
  const armed: Board = { ...board, armed: true, cells }
  for (let i = 0; i < cells.length; i++) {
    if (cells[i].mine) continue
    cells[i].adjacent = neighbors(armed, i).filter((n) => cells[n].mine).length
  }
  return armed
}

export interface RevealResult {
  board: Board
  /** Index of the mine that was hit, if any. */
  exploded: number | null
  changed: boolean
}

/** Reveal a single cell, flood-filling through zero-adjacent cells. Flags are never revealed. */
export function reveal(board: Board, index: number): RevealResult {
  const target = board.cells[index]
  if (target.revealed || target.mark === 'flag') return { board, exploded: null, changed: false }
  if (target.mine) {
    const cells = board.cells.slice()
    cells[index] = { ...target, revealed: true, mark: 'none' }
    return { board: { ...board, cells }, exploded: index, changed: true }
  }
  const cells = board.cells.slice()
  const stack = [index]
  while (stack.length > 0) {
    const i = stack.pop()!
    const cell = cells[i]
    if (cell.revealed || cell.mark === 'flag' || cell.mine) continue
    cells[i] = { ...cell, revealed: true, mark: 'none' }
    if (cell.adjacent === 0) {
      for (const n of neighbors(board, i)) {
        if (!cells[n].revealed) stack.push(n)
      }
    }
  }
  return { board: { ...board, cells }, exploded: null, changed: true }
}

/**
 * Chord: if `index` is a revealed number whose flagged neighbours equal that
 * number, reveal every remaining hidden, unflagged neighbour. Returns null when
 * the chord is not satisfied (nothing happens).
 */
export function chord(board: Board, index: number): RevealResult | null {
  const cell = board.cells[index]
  if (!cell.revealed || cell.adjacent === 0) return null
  const ns = neighbors(board, index)
  const flags = ns.filter((n) => board.cells[n].mark === 'flag').length
  if (flags !== cell.adjacent) return null
  let current = board
  let exploded: number | null = null
  let changed = false
  for (const n of ns) {
    const c = current.cells[n]
    if (c.revealed || c.mark === 'flag') continue
    const result = reveal(current, n)
    current = result.board
    changed = changed || result.changed
    if (result.exploded !== null && exploded === null) exploded = result.exploded
  }
  return { board: current, exploded, changed }
}

const MARK_CYCLE: Record<Mark, Mark> = { none: 'flag', flag: 'question', question: 'none' }

export function toggleMark(board: Board, index: number): Board {
  const cell = board.cells[index]
  if (cell.revealed) return board
  const cells = board.cells.slice()
  cells[index] = { ...cell, mark: MARK_CYCLE[cell.mark] }
  return { ...board, cells }
}

export function countFlags(board: Board): number {
  let n = 0
  for (const c of board.cells) if (c.mark === 'flag') n++
  return n
}

export function isWon(board: Board): boolean {
  if (!board.armed) return false
  return board.cells.every((c) => c.mine || c.revealed)
}

/** End-of-game reveal: show every mine (and keep wrong flags visible as wrong). */
export function revealAllMines(board: Board): Board {
  const cells = board.cells.map((c) => (c.mine && c.mark !== 'flag' ? { ...c, revealed: true } : c))
  return { ...board, cells }
}

/** Win reveal: flag every remaining mine so the counter reads 0. */
export function flagAllMines(board: Board): Board {
  const cells = board.cells.map((c) => (c.mine ? { ...c, mark: 'flag' as Mark } : c))
  return { ...board, cells }
}
