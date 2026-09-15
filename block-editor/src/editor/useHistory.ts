import { useCallback, useRef, useState } from 'react'

interface HistoryState<T> {
  past: T[]
  present: T
  future: T[]
}

/**
 * Undo/redo stack. Consecutive commits that share the same non-null `key`
 * (e.g. keystrokes in one block) collapse into a single undo step.
 */
export function useHistory<T>(initial: () => T, limit = 200) {
  const [state, setState] = useState<HistoryState<T>>(() => ({ past: [], present: initial(), future: [] }))
  const groupKey = useRef<string | null>(null)

  const commit = useCallback(
    (next: T, key: string | null = null) => {
      const coalesce = key !== null && key === groupKey.current
      groupKey.current = key
      setState((s) =>
        coalesce
          ? { ...s, present: next, future: [] }
          : { past: [...s.past, s.present].slice(-limit), present: next, future: [] },
      )
    },
    [limit],
  )

  /** Ends the current group so the next commit starts a fresh undo step. */
  const seal = useCallback(() => {
    groupKey.current = null
  }, [])

  const undo = useCallback(() => {
    groupKey.current = null
    setState((s) => {
      if (s.past.length === 0) return s
      const present = s.past[s.past.length - 1]
      return { past: s.past.slice(0, -1), present, future: [s.present, ...s.future] }
    })
  }, [])

  const redo = useCallback(() => {
    groupKey.current = null
    setState((s) => {
      if (s.future.length === 0) return s
      const [present, ...future] = s.future
      return { past: [...s.past, s.present], present, future }
    })
  }, [])

  return {
    present: state.present,
    canUndo: state.past.length > 0,
    canRedo: state.future.length > 0,
    peekUndo: () => state.past[state.past.length - 1],
    peekRedo: () => state.future[0],
    commit,
    seal,
    undo,
    redo,
  }
}
