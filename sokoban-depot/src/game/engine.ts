export type Dir = 'up' | 'down' | 'left' | 'right'

export interface Pos {
  x: number
  y: number
}

export interface Crate extends Pos {
  /** Stable identity so the DOM node (and its CSS transition) survives a push. */
  id: number
}

export interface Board {
  width: number
  height: number
  /** `true` where a tile is a wall. Indexed [y][x]. */
  walls: boolean[][]
  /** `true` where a tile is walkable floor (inside the warehouse). Indexed [y][x]. */
  floor: boolean[][]
  targets: Pos[]
}

export interface GameState {
  player: Pos
  facing: Dir
  crates: Crate[]
  moves: number
  pushes: number
}

export const DIR_DELTA: Record<Dir, Pos> = {
  up: { x: 0, y: -1 },
  down: { x: 0, y: 1 },
  left: { x: -1, y: 0 },
  right: { x: 1, y: 0 },
}

export function parseLevel(rows: string[]): { board: Board; state: GameState } {
  const height = rows.length
  const width = Math.max(...rows.map((r) => r.length))
  const walls: boolean[][] = []
  const floor: boolean[][] = []
  const targets: Pos[] = []
  const crates: Crate[] = []
  let player: Pos = { x: 0, y: 0 }

  for (let y = 0; y < height; y++) {
    walls.push([])
    floor.push([])
    for (let x = 0; x < width; x++) {
      const ch = rows[y][x] ?? ' '
      walls[y][x] = ch === '#'
      floor[y][x] = false
      if (ch === '.' || ch === '*' || ch === '+') targets.push({ x, y })
      if (ch === '$' || ch === '*') crates.push({ id: crates.length, x, y })
      if (ch === '@' || ch === '+') player = { x, y }
    }
  }

  // Flood-fill from the player to mark the interior floor, so that the empty
  // cells outside the outer wall are rendered as "nothing" rather than floor.
  const stack: Pos[] = [player]
  floor[player.y][player.x] = true
  while (stack.length) {
    const p = stack.pop()!
    for (const d of Object.values(DIR_DELTA)) {
      const n = { x: p.x + d.x, y: p.y + d.y }
      if (n.x < 0 || n.y < 0 || n.x >= width || n.y >= height) continue
      if (walls[n.y][n.x] || floor[n.y][n.x]) continue
      floor[n.y][n.x] = true
      stack.push(n)
    }
  }

  return {
    board: { width, height, walls, floor, targets },
    state: { player, facing: 'down', crates, moves: 0, pushes: 0 },
  }
}

export function isWall(board: Board, p: Pos): boolean {
  if (p.x < 0 || p.y < 0 || p.x >= board.width || p.y >= board.height) return true
  return board.walls[p.y][p.x]
}

export function crateAt(state: GameState, p: Pos): Crate | undefined {
  return state.crates.find((c) => c.x === p.x && c.y === p.y)
}

export function isTarget(board: Board, p: Pos): boolean {
  return board.targets.some((t) => t.x === p.x && t.y === p.y)
}

export interface MoveResult {
  state: GameState
  pushed: boolean
}

/** Returns the new state after moving, or `null` when the move is blocked. */
export function move(board: Board, state: GameState, dir: Dir): MoveResult | null {
  const d = DIR_DELTA[dir]
  const next = { x: state.player.x + d.x, y: state.player.y + d.y }
  if (isWall(board, next)) return null

  const crate = crateAt(state, next)
  if (!crate) {
    return {
      pushed: false,
      state: { ...state, player: next, facing: dir, moves: state.moves + 1 },
    }
  }

  const beyond = { x: next.x + d.x, y: next.y + d.y }
  if (isWall(board, beyond) || crateAt(state, beyond)) return null

  return {
    pushed: true,
    state: {
      ...state,
      player: next,
      facing: dir,
      moves: state.moves + 1,
      pushes: state.pushes + 1,
      crates: state.crates.map((c) => (c.id === crate.id ? { ...c, x: beyond.x, y: beyond.y } : c)),
    },
  }
}

export function isSolved(board: Board, state: GameState): boolean {
  return state.crates.every((c) => isTarget(board, c))
}

/**
 * Simple deadlock detection: a crate that is not on a target and is wedged
 * into a corner (walls on two perpendicular sides) can never be moved again.
 */
export function stuckCrates(board: Board, state: GameState): Crate[] {
  return state.crates.filter((c) => {
    if (isTarget(board, c)) return false
    const up = isWall(board, { x: c.x, y: c.y - 1 })
    const down = isWall(board, { x: c.x, y: c.y + 1 })
    const left = isWall(board, { x: c.x - 1, y: c.y })
    const right = isWall(board, { x: c.x + 1, y: c.y })
    return (up || down) && (left || right)
  })
}

export function starsFor(moves: number, par: number): 1 | 2 | 3 {
  if (moves <= par) return 3
  if (moves <= Math.ceil(par * 1.5)) return 2
  return 1
}
