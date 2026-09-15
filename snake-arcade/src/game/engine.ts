import type { Difficulty, Direction, GameAction, GameState, Point } from './types'

export const GRID_SIZE = 20
export const APPLES_PER_SPEED_UP = 5
export const SPEED_UP_FACTOR = 1.1
export const MAX_CELLS_PER_SECOND = 20
const INPUT_QUEUE_LIMIT = 3
const HIGH_SCORE_KEY = 'snake-arcade:high-score'

export const DIFFICULTIES: Record<Difficulty, { label: string; cellsPerSecond: number }> = {
  chill: { label: 'Chill', cellsPerSecond: 4 },
  normal: { label: 'Normal', cellsPerSecond: 6 },
  fast: { label: 'Fast', cellsPerSecond: 9 },
}

export const DIRECTION_VECTORS: Record<Direction, Point> = {
  up: { x: 0, y: -1 },
  down: { x: 0, y: 1 },
  left: { x: -1, y: 0 },
  right: { x: 1, y: 0 },
}

const OPPOSITES: Record<Direction, Direction> = {
  up: 'down',
  down: 'up',
  left: 'right',
  right: 'left',
}

export function pointsEqual(a: Point, b: Point): boolean {
  return a.x === b.x && a.y === b.y
}

function loadHighScore(): number {
  const stored = Number(localStorage.getItem(HIGH_SCORE_KEY))
  return Number.isFinite(stored) && stored > 0 ? stored : 0
}

function saveHighScore(score: number): void {
  localStorage.setItem(HIGH_SCORE_KEY, String(score))
}

function initialSnake(): Point[] {
  const mid = Math.floor(GRID_SIZE / 2)
  return [
    { x: mid, y: mid },
    { x: mid - 1, y: mid },
    { x: mid - 2, y: mid },
  ]
}

export function randomFreeCell(occupied: Point[]): Point {
  const free: Point[] = []
  for (let y = 0; y < GRID_SIZE; y++) {
    for (let x = 0; x < GRID_SIZE; x++) {
      if (!occupied.some((p) => p.x === x && p.y === y)) free.push({ x, y })
    }
  }
  return free[Math.floor(Math.random() * free.length)]
}

export function createInitialState(difficulty: Difficulty = 'normal'): GameState {
  const snake = initialSnake()
  return {
    phase: 'ready',
    difficulty,
    snake,
    direction: 'right',
    inputQueue: [],
    apple: randomFreeCell(snake),
    score: 0,
    highScore: loadHighScore(),
    cellsPerSecond: DIFFICULTIES[difficulty].cellsPerSecond,
    isNewHighScore: false,
  }
}

function startRun(state: GameState): GameState {
  const snake = initialSnake()
  return {
    ...state,
    phase: 'playing',
    snake,
    direction: 'right',
    inputQueue: [],
    apple: randomFreeCell(snake),
    score: 0,
    cellsPerSecond: DIFFICULTIES[state.difficulty].cellsPerSecond,
    isNewHighScore: false,
  }
}

function queueTurn(state: GameState, direction: Direction): GameState {
  if (state.phase !== 'playing') return state
  const last = state.inputQueue.at(-1) ?? state.direction
  if (direction === last || direction === OPPOSITES[last]) return state
  if (state.inputQueue.length >= INPUT_QUEUE_LIMIT) return state
  return { ...state, inputQueue: [...state.inputQueue, direction] }
}

function endRun(state: GameState): GameState {
  const isNewHighScore = state.score > state.highScore
  if (isNewHighScore) saveHighScore(state.score)
  return {
    ...state,
    phase: 'over',
    inputQueue: [],
    highScore: Math.max(state.score, state.highScore),
    isNewHighScore,
  }
}

function tick(state: GameState): GameState {
  if (state.phase !== 'playing') return state

  const [direction = state.direction, ...inputQueue] = state.inputQueue
  const vector = DIRECTION_VECTORS[direction]
  const head = state.snake[0]
  const next = { x: head.x + vector.x, y: head.y + vector.y }

  const hitWall = next.x < 0 || next.y < 0 || next.x >= GRID_SIZE || next.y >= GRID_SIZE
  if (hitWall) return endRun({ ...state, direction })

  const eating = pointsEqual(next, state.apple)
  // The tail cell frees up this tick unless the snake grows into it.
  const body = eating ? state.snake : state.snake.slice(0, -1)
  if (body.some((segment) => pointsEqual(segment, next))) {
    return endRun({ ...state, direction })
  }

  const snake = [next, ...body]
  if (!eating) {
    return { ...state, snake, direction, inputQueue }
  }

  const score = state.score + 1
  const speedsUp = score % APPLES_PER_SPEED_UP === 0
  return {
    ...state,
    snake,
    direction,
    inputQueue,
    score,
    apple: randomFreeCell(snake),
    cellsPerSecond: speedsUp
      ? Math.min(MAX_CELLS_PER_SECOND, state.cellsPerSecond * SPEED_UP_FACTOR)
      : state.cellsPerSecond,
  }
}

export function gameReducer(state: GameState, action: GameAction): GameState {
  switch (action.type) {
    case 'start':
      return state.phase === 'ready' || state.phase === 'over' ? startRun(state) : state
    case 'tick':
      return tick(state)
    case 'turn':
      return queueTurn(state, action.direction)
    case 'togglePause':
      if (state.phase === 'playing') return { ...state, phase: 'paused' }
      if (state.phase === 'paused') return { ...state, phase: 'playing' }
      return state
    case 'setDifficulty':
      if (state.phase === 'playing' || state.phase === 'paused') return state
      return {
        ...state,
        difficulty: action.difficulty,
        cellsPerSecond: DIFFICULTIES[action.difficulty].cellsPerSecond,
      }
  }
}
