import { useCallback, useState } from 'react'

interface HistoryState<T> {
  past: T[]
  present: T
  future: T[]
}

const LIMIT = 100

export function useHistory<T>(initial: () => T) {
  const [history, setHistory] = useState<HistoryState<T>>(() => ({ past: [], present: initial(), future: [] }))

  /** Apply an update. With `record` (default) the previous state is pushed onto the undo stack. */
  const update = useCallback((updater: (prev: T) => T, record = true) => {
    setHistory((h) => {
      const next = updater(h.present)
      if (next === h.present) return h
      if (!record) return { ...h, present: next }
      return { past: [...h.past.slice(-(LIMIT - 1)), h.present], present: next, future: [] }
    })
  }, [])

  /** Push the current state onto the undo stack without changing it (call before a drag). */
  const checkpoint = useCallback(() => {
    setHistory((h) => ({ past: [...h.past.slice(-(LIMIT - 1)), h.present], present: h.present, future: [] }))
  }, [])

  const undo = useCallback(() => {
    setHistory((h) => {
      if (h.past.length === 0) return h
      const previous = h.past[h.past.length - 1]
      return { past: h.past.slice(0, -1), present: previous, future: [h.present, ...h.future] }
    })
  }, [])

  const redo = useCallback(() => {
    setHistory((h) => {
      if (h.future.length === 0) return h
      const [next, ...rest] = h.future
      return { past: [...h.past, h.present], present: next, future: rest }
    })
  }, [])

  return {
    state: history.present,
    update,
    checkpoint,
    undo,
    redo,
    canUndo: history.past.length > 0,
    canRedo: history.future.length > 0,
  }
}
