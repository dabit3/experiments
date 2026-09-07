import { useLayoutEffect, useRef, useState, type CSSProperties } from 'react'

const MARGIN = 8

/** Positions a fixed element at (x, y), nudging it so it stays inside the viewport. */
export function useClampedPosition<T extends HTMLElement = HTMLDivElement>(x: number, y: number) {
  const ref = useRef<T>(null)
  const [position, setPosition] = useState({ left: x, top: y })

  useLayoutEffect(() => {
    const el = ref.current
    if (!el) return
    const { width, height } = el.getBoundingClientRect()
    setPosition({
      left: Math.max(MARGIN, Math.min(x, window.innerWidth - width - MARGIN)),
      top: Math.max(MARGIN, Math.min(y, window.innerHeight - height - MARGIN)),
    })
  }, [x, y])

  const style: CSSProperties = { left: position.left, top: position.top }
  return { ref, style }
}
