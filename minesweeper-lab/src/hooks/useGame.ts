import { useCallback, useEffect, useMemo, useReducer, useState } from 'react'
import {
  LEVELS,
  chord,
  countFlags,
  emptyBoard,
  flagAllMines,
  isWon,
  placeMines,
  reveal,
  revealAllMines,
  toggleMark,
  type Board,
  type Level,
} from '../lib/board'
import { loadBestTimes, recordTime, saveBestTimes, type BestTimes } from '../lib/bestTimes'

export type Status = 'idle' | 'playing' | 'won' | 'lost'

export interface GameState {
  level: Level
  seed: number
  board: Board
  status: Status
  /** Index of the mine that ended the game, if lost. */
  exploded: number | null
  /** Incremented on every reset so the board remounts and animations restart. */
  generation: number
  startedAt: number | null
  endedAt: number | null
  bestTimes: BestTimes
  /** True when the current win set a new best time. */
  newRecord: boolean
  /** Number of chord reveals that changed the board this game. */
  chords: number
}

type Action =
  | { type: 'reset'; level: Level; seed: number }
  | { type: 'reveal'; index: number; now: number }
  | { type: 'chord'; index: number; now: number }
  | { type: 'mark'; index: number }

export function elapsedSeconds(state: Pick<GameState, 'startedAt' | 'endedAt'>, now: number): number {
  if (state.startedAt === null) return 0
  const end = state.endedAt ?? now
  return Math.max(0, Math.min(999, Math.floor((end - state.startedAt) / 1000)))
}

function fresh(level: Level, seed: number, generation: number, bestTimes: BestTimes): GameState {
  return {
    level,
    seed,
    board: emptyBoard(LEVELS[level]),
    status: 'idle',
    exploded: null,
    generation,
    startedAt: null,
    endedAt: null,
    bestTimes,
    newRecord: false,
    chords: 0,
  }
}

function finish(state: GameState, board: Board, exploded: number | null, now: number): GameState {
  const startedAt = state.startedAt ?? now
  if (exploded !== null) {
    return { ...state, board: revealAllMines(board), status: 'lost', exploded, startedAt, endedAt: now }
  }
  if (isWon(board)) {
    const seconds = Math.max(1, elapsedSeconds({ startedAt, endedAt: now }, now))
    const { times, isRecord } = recordTime(state.bestTimes, state.level, seconds, state.seed)
    return { ...state, board: flagAllMines(board), status: 'won', startedAt, endedAt: now, bestTimes: times, newRecord: isRecord }
  }
  return { ...state, board, status: 'playing', startedAt }
}

function reducer(state: GameState, action: Action): GameState {
  switch (action.type) {
    case 'reset':
      return fresh(action.level, action.seed, state.generation + 1, state.bestTimes)
    case 'reveal': {
      if (state.status === 'won' || state.status === 'lost') return state
      let board = state.board
      if (!board.armed) board = placeMines(board, state.seed, action.index)
      const result = reveal(board, action.index)
      if (!result.changed) return state
      return finish(state, result.board, result.exploded, action.now)
    }
    case 'chord': {
      if (state.status !== 'playing') return state
      const result = chord(state.board, action.index)
      if (result === null || !result.changed) return state
      return finish({ ...state, chords: state.chords + 1 }, result.board, result.exploded, action.now)
    }
    case 'mark': {
      if (state.status === 'won' || state.status === 'lost') return state
      const board = toggleMark(state.board, action.index)
      if (board === state.board) return state
      return { ...state, board }
    }
  }
}

export interface Game {
  state: GameState
  seconds: number
  minesLeft: number
  reveal: (index: number) => void
  chord: (index: number) => void
  mark: (index: number) => void
  reset: (level?: Level, seed?: number) => void
}

export function useGame(initialLevel: Level, initialSeed: number): Game {
  const [state, dispatch] = useReducer(reducer, undefined, () => fresh(initialLevel, initialSeed, 0, loadBestTimes()))
  const [now, setNow] = useState(() => Date.now())

  // Tick while a game is running so the timer read-out stays live.
  useEffect(() => {
    if (state.status !== 'playing') return
    const id = window.setInterval(() => setNow(Date.now()), 200)
    return () => window.clearInterval(id)
  }, [state.status, state.generation])

  useEffect(() => {
    saveBestTimes(state.bestTimes)
  }, [state.bestTimes])

  const seconds = elapsedSeconds(state, now)
  const minesLeft = useMemo(() => state.board.mines - countFlags(state.board), [state.board])

  const revealCell = useCallback((index: number) => dispatch({ type: 'reveal', index, now: Date.now() }), [])
  const chordCell = useCallback((index: number) => dispatch({ type: 'chord', index, now: Date.now() }), [])
  const markCell = useCallback((index: number) => dispatch({ type: 'mark', index }), [])
  const reset = useCallback(
    (level?: Level, seed?: number) => dispatch({ type: 'reset', level: level ?? state.level, seed: seed ?? state.seed }),
    [state.level, state.seed],
  )

  return { state, seconds, minesLeft, reveal: revealCell, chord: chordCell, mark: markCell, reset }
}
