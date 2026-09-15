export interface Point {
  x: number
  y: number
}

export type Direction = 'up' | 'down' | 'left' | 'right'

export type Phase = 'ready' | 'playing' | 'paused' | 'over'

export type Difficulty = 'chill' | 'normal' | 'fast'

export interface GameState {
  phase: Phase
  difficulty: Difficulty
  snake: Point[]
  direction: Direction
  /** Direction changes waiting to be consumed, one per tick. */
  inputQueue: Direction[]
  apple: Point
  score: number
  highScore: number
  /** Current speed in cells per second. */
  cellsPerSecond: number
  /** True when the last run set a new high score. */
  isNewHighScore: boolean
}

export type GameAction =
  | { type: 'start' }
  | { type: 'tick' }
  | { type: 'turn'; direction: Direction }
  | { type: 'togglePause' }
  | { type: 'setDifficulty'; difficulty: Difficulty }
