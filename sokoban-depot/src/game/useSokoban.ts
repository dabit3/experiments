import { useCallback, useMemo, useState } from 'react'
import { isSolved, move, parseLevel, stuckCrates, type Dir, type GameState } from './engine'
import type { LevelDef } from './levels'

interface History {
  current: GameState
  past: GameState[]
}

export function useSokoban(level: LevelDef) {
  const { board, state: initial } = useMemo(() => parseLevel(level.rows), [level])
  const [history, setHistory] = useState<History>({ current: initial, past: [] })

  const current = history.current
  const solved = isSolved(board, current)
  const stuck = useMemo(() => stuckCrates(board, current), [board, current])

  const step = useCallback(
    (dir: Dir) => {
      setHistory((h) => {
        if (isSolved(board, h.current)) return h
        const result = move(board, h.current, dir)
        if (!result) {
          // Still turn to face the wall so the input is visibly acknowledged.
          if (h.current.facing === dir) return h
          return { ...h, current: { ...h.current, facing: dir } }
        }
        return { current: result.state, past: [...h.past, h.current] }
      })
    },
    [board],
  )

  const undo = useCallback(() => {
    setHistory((h) => {
      if (h.past.length === 0) return h
      const past = h.past.slice(0, -1)
      return { current: h.past[h.past.length - 1], past }
    })
  }, [])

  const restart = useCallback(() => {
    setHistory({ current: initial, past: [] })
  }, [initial])

  return {
    board,
    state: current,
    canUndo: history.past.length > 0,
    solved,
    stuck,
    step,
    undo,
    restart,
  }
}
