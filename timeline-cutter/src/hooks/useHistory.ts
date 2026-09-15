import { useCallback, useState } from 'react'

interface Stack<T> {
  past: T[]
  present: T
  future: T[]
}

const LIMIT = 80

/**
 * Undo/redo over immutable snapshots. `set` replaces the present without recording
 * (used while dragging); `commit` records the previous present as an undo step.
 */
export function useHistory<T>(initial: T) {
  const [stack, setStack] = useState<Stack<T>>({ past: [], present: initial, future: [] })

  const set = useCallback((next: T) => {
    setStack((s) => (s.present === next ? s : { ...s, present: next }))
  }, [])

  const commit = useCallback((next: T) => {
    setStack((s) => {
      if (next === s.present) return s
      return { past: [...s.past.slice(-(LIMIT - 1)), s.present], present: next, future: [] }
    })
  }, [])

  /** Record `base` as the undo step for a change that was already applied live with `set`. */
  const commitFrom = useCallback((base: T) => {
    setStack((s) => {
      if (base === s.present) return s
      return { past: [...s.past.slice(-(LIMIT - 1)), base], present: s.present, future: [] }
    })
  }, [])

  const undo = useCallback(() => {
    setStack((s) => {
      if (s.past.length === 0) return s
      const prev = s.past[s.past.length - 1]
      return { past: s.past.slice(0, -1), present: prev, future: [...s.future, s.present] }
    })
  }, [])

  const redo = useCallback(() => {
    setStack((s) => {
      if (s.future.length === 0) return s
      const next = s.future[s.future.length - 1]
      return { past: [...s.past, s.present], present: next, future: s.future.slice(0, -1) }
    })
  }, [])

  return {
    present: stack.present,
    set,
    commit,
    commitFrom,
    undo,
    redo,
    canUndo: stack.past.length > 0,
    canRedo: stack.future.length > 0,
  }
}
