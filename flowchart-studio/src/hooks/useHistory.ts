import { useCallback, useRef, useState } from 'react'

const LIMIT = 100

export interface History<T> {
  state: T
  /** Replace the current state without creating an undo step (used mid-drag). */
  replace: (next: T | ((prev: T) => T)) => void
  /** Push `snapshot` (the state before a change) onto the undo stack. */
  record: (snapshot: T) => void
  /** Convenience: record the current state and then replace it. */
  commit: (next: T | ((prev: T) => T)) => void
  undo: () => void
  redo: () => void
  canUndo: boolean
  canRedo: boolean
  reset: (next: T) => void
}

interface Stacks<T> {
  present: T
  past: T[]
  future: T[]
}

export function useHistory<T>(initial: T): History<T> {
  const [stacks, setStacks] = useState<Stacks<T>>({ present: initial, past: [], future: [] })
  const ref = useRef(stacks)

  const apply = useCallback((next: Stacks<T>) => {
    ref.current = next
    setStacks(next)
  }, [])

  const replace = useCallback(
    (next: T | ((prev: T) => T)) => {
      const cur = ref.current
      const value = typeof next === 'function' ? (next as (prev: T) => T)(cur.present) : next
      apply({ ...cur, present: value })
    },
    [apply],
  )

  const record = useCallback(
    (snapshot: T) => {
      const cur = ref.current
      apply({ present: cur.present, past: [...cur.past.slice(-(LIMIT - 1)), snapshot], future: [] })
    },
    [apply],
  )

  const commit = useCallback(
    (next: T | ((prev: T) => T)) => {
      const cur = ref.current
      const value = typeof next === 'function' ? (next as (prev: T) => T)(cur.present) : next
      apply({ present: value, past: [...cur.past.slice(-(LIMIT - 1)), cur.present], future: [] })
    },
    [apply],
  )

  const undo = useCallback(() => {
    const cur = ref.current
    if (cur.past.length === 0) return
    const prev = cur.past[cur.past.length - 1]
    apply({ present: prev, past: cur.past.slice(0, -1), future: [cur.present, ...cur.future] })
  }, [apply])

  const redo = useCallback(() => {
    const cur = ref.current
    if (cur.future.length === 0) return
    const next = cur.future[0]
    apply({ present: next, past: [...cur.past, cur.present], future: cur.future.slice(1) })
  }, [apply])

  const reset = useCallback(
    (next: T) => {
      apply({ present: next, past: [], future: [] })
    },
    [apply],
  )

  return {
    state: stacks.present,
    replace,
    record,
    commit,
    undo,
    redo,
    canUndo: stacks.past.length > 0,
    canRedo: stacks.future.length > 0,
    reset,
  }
}
