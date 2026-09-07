import { useCallback, useRef, useState } from 'react'

const MAX_HISTORY = 40

/**
 * Undo/redo stack of canvas snapshots. Snapshots are stored as ImageData so
 * undo/redo is a single putImageData call and never re-encodes the canvas.
 */
export function useHistory() {
  const past = useRef<ImageData[]>([])
  const future = useRef<ImageData[]>([])
  const [counts, setCounts] = useState({ undo: 0, redo: 0 })

  const sync = () => setCounts({ undo: past.current.length, redo: future.current.length })

  const push = useCallback((snapshot: ImageData) => {
    past.current.push(snapshot)
    if (past.current.length > MAX_HISTORY) past.current.shift()
    future.current = []
    sync()
  }, [])

  const undo = useCallback((current: ImageData): ImageData | null => {
    const previous = past.current.pop()
    if (!previous) return null
    future.current.push(current)
    sync()
    return previous
  }, [])

  const redo = useCallback((current: ImageData): ImageData | null => {
    const next = future.current.pop()
    if (!next) return null
    past.current.push(current)
    sync()
    return next
  }, [])

  return { push, undo, redo, canUndo: counts.undo > 0, canRedo: counts.redo > 0 }
}
