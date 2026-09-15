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
      const target = event.target
      if (
        target instanceof HTMLElement &&
        (target.isContentEditable || ['INPUT', 'TEXTAREA', 'SELECT'].includes(target.tagName))
      )
        return
      if (event.altKey || event.ctrlKey || event.metaKey) return
      if (key === ' ') {
        if (target instanceof HTMLElement && target.closest('button, summary')) return
        event.preventDefault()
        if (event.repeat) return
        dispatch({ type: 'start' })
      } else if (key === 'p') {
        if (event.repeat) return
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

  const start = () => dispatch({ type: 'start' })
  const togglePause = () => dispatch({ type: 'togglePause' })
  const turn = (direction: Direction) => dispatch({ type: 'turn', direction })

  return { state, setDifficulty, start, togglePause, turn }
}
