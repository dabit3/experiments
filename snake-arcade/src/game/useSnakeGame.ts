import { useEffect, useReducer } from 'react'
import { createInitialState, gameReducer } from './engine'
import type { Difficulty, Direction } from './types'

const KEY_DIRECTIONS: Record<string, Direction> = {
  ArrowUp: 'up',
  ArrowDown: 'down',
  ArrowLeft: 'left',
  ArrowRight: 'right',
  w: 'up',
  s: 'down',
  a: 'left',
  d: 'right',
}

const KEY_DIFFICULTIES: Record<string, Difficulty> = {
  '1': 'chill',
  '2': 'normal',
  '3': 'fast',
}

export function useSnakeGame() {
  const [state, dispatch] = useReducer(gameReducer, undefined, () => createInitialState())

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      const key = event.key.length === 1 ? event.key.toLowerCase() : event.key
      if (key === ' ') {
        event.preventDefault()
        dispatch({ type: 'start' })
      } else if (key === 'p') {
        dispatch({ type: 'togglePause' })
      } else if (key in KEY_DIRECTIONS) {
        event.preventDefault()
        dispatch({ type: 'turn', direction: KEY_DIRECTIONS[key] })
      } else if (key in KEY_DIFFICULTIES) {
        dispatch({ type: 'setDifficulty', difficulty: KEY_DIFFICULTIES[key] })
      }
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [])

  // Restarting the interval on every speed change (and on resume) means the
  // first move always lands exactly one full period after the change.
  const { phase, cellsPerSecond } = state
  useEffect(() => {
    if (phase !== 'playing') return
    const id = window.setInterval(() => dispatch({ type: 'tick' }), 1000 / cellsPerSecond)
    return () => window.clearInterval(id)
  }, [phase, cellsPerSecond])

  const setDifficulty = (difficulty: Difficulty) => dispatch({ type: 'setDifficulty', difficulty })

  return { state, setDifficulty }
}
