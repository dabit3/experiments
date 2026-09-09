import { nextRandom } from './rng.ts'

export const SIZE = 4
export const WIN_TILE = 512
export const UNDO_DEPTH = 5

export type Direction = 'up' | 'down' | 'left' | 'right'

export type TileKind = 'normal' | 'new' | 'merged' | 'ghost'

export interface Tile {
  id: number
  value: number
  row: number
  col: number
  kind: TileKind
}

export interface Snapshot {
  tiles: Tile[]
  score: number
  rng: number
  nextId: number
  moves: number
}

export type Banner = 'none' | 'won' | 'over'

export interface GameState {
  seed: number
  tiles: Tile[]
  score: number
  rng: number
  nextId: number
  moves: number
  banner: Banner
  wonShown: boolean
  history: Snapshot[]
}

const VECTORS: Record<Direction, { dr: number; dc: number }> = {
  up: { dr: -1, dc: 0 },
  down: { dr: 1, dc: 0 },
  left: { dr: 0, dc: -1 },
  right: { dr: 0, dc: 1 },
}

function liveTiles(tiles: Tile[]): Tile[] {
  return tiles.filter((t) => t.kind !== 'ghost')
}

function toGrid(tiles: Tile[]): (Tile | null)[][] {
  const grid: (Tile | null)[][] = Array.from({ length: SIZE }, () =>
    Array.from({ length: SIZE }, () => null),
  )
  for (const t of liveTiles(tiles)) grid[t.row][t.col] = t
  return grid
}

interface SpawnResult {
  tiles: Tile[]
  rng: number
  nextId: number
}

function spawnTile(tiles: Tile[], rng: number, nextId: number): SpawnResult {
  const grid = toGrid(tiles)
  const empty: { row: number; col: number }[] = []
  for (let r = 0; r < SIZE; r++) {
    for (let c = 0; c < SIZE; c++) {
      if (!grid[r][c]) empty.push({ row: r, col: c })
    }
  }
  if (empty.length === 0) return { tiles, rng, nextId }
  const pick = nextRandom(rng)
  const cell = empty[Math.floor(pick.value * empty.length)]
  const roll = nextRandom(pick.state)
  const value = roll.value < 0.9 ? 2 : 4
  const tile: Tile = { id: nextId, value, row: cell.row, col: cell.col, kind: 'new' }
  return { tiles: [...tiles, tile], rng: roll.state, nextId: nextId + 1 }
}

export function newGame(seed: number): GameState {
  let spawn: SpawnResult = { tiles: [], rng: seed, nextId: 1 }
  spawn = spawnTile(spawn.tiles, spawn.rng, spawn.nextId)
  spawn = spawnTile(spawn.tiles, spawn.rng, spawn.nextId)
  return {
    seed,
    tiles: spawn.tiles,
    score: 0,
    rng: spawn.rng,
    nextId: spawn.nextId,
    moves: 0,
    banner: 'none',
    wonShown: false,
    history: [],
  }
}

interface SlideResult {
  tiles: Tile[]
  gained: number
  moved: boolean
  nextId: number
}

function slide(tiles: Tile[], dir: Direction, nextId: number): SlideResult {
  const grid = toGrid(tiles)
  const { dr, dc } = VECTORS[dir]
  const out: Tile[] = []
  let gained = 0
  let moved = false
  let id = nextId

  // Each "line" is a row or column read from the edge we are moving toward.
  for (let i = 0; i < SIZE; i++) {
    const line: Tile[] = []
    for (let j = 0; j < SIZE; j++) {
      const row = dr === 0 ? i : dr < 0 ? j : SIZE - 1 - j
      const col = dc === 0 ? i : dc < 0 ? j : SIZE - 1 - j
      const t = grid[row][col]
      if (t) line.push(t)
    }

    let slot = 0
    for (let k = 0; k < line.length; k++) {
      const row = dr === 0 ? i : dr < 0 ? slot : SIZE - 1 - slot
      const col = dc === 0 ? i : dc < 0 ? slot : SIZE - 1 - slot
      const a = line[k]
      const b = line[k + 1]
      if (b && b.value === a.value) {
        out.push({ ...a, row, col, kind: 'ghost' })
        out.push({ ...b, row, col, kind: 'ghost' })
        out.push({ id: id++, value: a.value * 2, row, col, kind: 'merged' })
        gained += a.value * 2
        moved = true
        k++
      } else {
        if (a.row !== row || a.col !== col) moved = true
        out.push({ ...a, row, col, kind: 'normal' })
      }
      slot++
    }
  }

  return { tiles: out, gained, moved, nextId: id }
}

export function canMove(tiles: Tile[]): boolean {
  const grid = toGrid(tiles)
  for (let r = 0; r < SIZE; r++) {
    for (let c = 0; c < SIZE; c++) {
      const t = grid[r][c]
      if (!t) return true
      if (c + 1 < SIZE && grid[r][c + 1]?.value === t.value) return true
      if (r + 1 < SIZE && grid[r + 1][c]?.value === t.value) return true
    }
  }
  return false
}

export function highestTile(tiles: Tile[]): number {
  return liveTiles(tiles).reduce((m, t) => Math.max(m, t.value), 0)
}

export function move(state: GameState, dir: Direction): GameState {
  const result = slide(state.tiles, dir, state.nextId)
  if (!result.moved) return state

  const snapshot: Snapshot = {
    tiles: liveTiles(state.tiles).map((t) => ({ ...t, kind: 'normal' })),
    score: state.score,
    rng: state.rng,
    nextId: state.nextId,
    moves: state.moves,
  }
  const history = [...state.history, snapshot].slice(-UNDO_DEPTH)

  const spawn = spawnTile(result.tiles, state.rng, result.nextId)
  const tiles = spawn.tiles
  const reached = highestTile(tiles) >= WIN_TILE

  let banner: Banner = 'none'
  let wonShown = state.wonShown
  if (reached && !wonShown) {
    banner = 'won'
    wonShown = true
  } else if (!canMove(tiles)) {
    banner = 'over'
  }

  return {
    ...state,
    tiles,
    score: state.score + result.gained,
    rng: spawn.rng,
    nextId: spawn.nextId,
    moves: state.moves + 1,
    banner,
    wonShown,
    history,
  }
}

export function undo(state: GameState): GameState {
  const snapshot = state.history[state.history.length - 1]
  if (!snapshot) return state
  return {
    ...state,
    tiles: snapshot.tiles,
    score: snapshot.score,
    rng: snapshot.rng,
    nextId: snapshot.nextId,
    moves: snapshot.moves,
    banner: 'none',
    wonShown: highestTile(snapshot.tiles) >= WIN_TILE,
    history: state.history.slice(0, -1),
  }
}

export function dismissBanner(state: GameState): GameState {
  return state.banner === 'none' ? state : { ...state, banner: 'none' }
}

/** Drop ghost tiles once their slide animation has finished. */
export function pruneGhosts(state: GameState): GameState {
  if (!state.tiles.some((t) => t.kind === 'ghost')) return state
  return { ...state, tiles: liveTiles(state.tiles) }
}
