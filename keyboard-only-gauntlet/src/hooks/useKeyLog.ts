import { useCallback, useEffect, useRef, useState } from 'react'
import { formatKey, isModifierKey } from '../lib/keys'

export interface KeyChip {
  id: number
  label: string
}

const MAX_CHIPS = 9

/** Records every non-modifier keydown for the on-screen key HUD. */
export function useKeyLog(onKey: (label: string) => void) {
  const [recent, setRecent] = useState<KeyChip[]>([])
  const [total, setTotal] = useState(0)
  const nextId = useRef(0)
  const callback = useRef(onKey)

  useEffect(() => {
    callback.current = onKey
  }, [onKey])

  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (isModifierKey(e.key)) return
      const label = formatKey(e)
      nextId.current += 1
      const chip = { id: nextId.current, label }
      setRecent((r) => [...r, chip].slice(-MAX_CHIPS))
      setTotal((t) => t + 1)
      callback.current(label)
    }
    window.addEventListener('keydown', onKeyDown, true)
    return () => window.removeEventListener('keydown', onKeyDown, true)
  }, [])

  const reset = useCallback(() => {
    setRecent([])
    setTotal(0)
  }, [])

  return { recent, total, reset }
}
