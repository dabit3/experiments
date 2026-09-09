import { useCallback, useEffect, useRef, useState } from 'react'

const TOAST_MS = 2200
const BLOCKED_EVENTS = ['mouseup', 'dblclick', 'auxclick', 'contextmenu'] as const

/**
 * Disables the mouse for the whole document: every mouse press is swallowed
 * (preventDefault on mousedown also stops it from stealing focus), counted as
 * a violation and surfaced through a toast.
 */
export function useMouseGuard() {
  const [violations, setViolations] = useState(0)
  const [toastKey, setToastKey] = useState(0)
  const [toastVisible, setToastVisible] = useState(false)
  const timer = useRef<number | undefined>(undefined)

  useEffect(() => {
    const onMouseDown = (e: MouseEvent) => {
      e.preventDefault()
      setViolations((v) => v + 1)
      setToastKey((k) => k + 1)
      setToastVisible(true)
      window.clearTimeout(timer.current)
      timer.current = window.setTimeout(() => setToastVisible(false), TOAST_MS)
    }
    const block = (e: Event) => e.preventDefault()

    document.addEventListener('mousedown', onMouseDown, true)
    for (const type of BLOCKED_EVENTS) document.addEventListener(type, block, true)
    return () => {
      document.removeEventListener('mousedown', onMouseDown, true)
      for (const type of BLOCKED_EVENTS) document.removeEventListener(type, block, true)
      window.clearTimeout(timer.current)
    }
  }, [])

  const reset = useCallback(() => setViolations(0), [])

  return { violations, toastKey, toastVisible, reset }
}
