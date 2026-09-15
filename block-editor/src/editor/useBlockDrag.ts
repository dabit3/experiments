import { useRef, useState } from 'react'
import type { PointerEvent as ReactPointerEvent, RefObject } from 'react'

export interface DragState {
  from: number
  /** Insertion index (0..n) the pointer is currently hovering. */
  over: number
  /** Offset (within the list) of the drop indicator line, or null when dropping here is a no-op. */
  indicatorTop: number | null
}

const ROW_SELECTOR = '[data-block-row]'

/** Pointer-driven reordering of block rows inside `listRef`. */
export function useBlockDrag(listRef: RefObject<HTMLElement | null>, onMove: (from: number, to: number) => void) {
  const [drag, setDrag] = useState<DragState | null>(null)
  const dragRef = useRef<DragState | null>(null)

  const update = (next: DragState | null) => {
    dragRef.current = next
    setDrag(next)
  }

  const rows = () => Array.from(listRef.current?.querySelectorAll<HTMLElement>(ROW_SELECTOR) ?? [])

  const handleProps = (index: number) => ({
    onPointerDown(e: ReactPointerEvent<HTMLElement>) {
      e.preventDefault()
      const handle = e.currentTarget
      handle.setPointerCapture(e.pointerId)
      document.body.classList.add('is-dragging')
      update({ from: index, over: index, indicatorTop: null })

      const onMoveEvent = (ev: PointerEvent) => {
        const current = dragRef.current
        if (!current) return
        const all = rows()
        const over = insertionIndex(all, ev.clientY)
        if (over !== current.over) update({ ...current, over, indicatorTop: indicatorOffset(all, current.from, over) })
      }
      const finish = () => {
        handle.removeEventListener('pointermove', onMoveEvent)
        handle.removeEventListener('pointerup', finish)
        handle.removeEventListener('pointercancel', finish)
        document.body.classList.remove('is-dragging')
        const current = dragRef.current
        update(null)
        if (!current) return
        const to = current.over > current.from ? current.over - 1 : current.over
        if (to !== current.from) onMove(current.from, to)
      }
      handle.addEventListener('pointermove', onMoveEvent)
      handle.addEventListener('pointerup', finish)
      handle.addEventListener('pointercancel', finish)
    },
  })

  return { drag, handleProps }
}

function indicatorOffset(rows: HTMLElement[], from: number, over: number): number | null {
  if (over === from || over === from + 1) return null
  const last = rows[rows.length - 1]
  return over < rows.length ? rows[over].offsetTop : last.offsetTop + last.offsetHeight
}

function insertionIndex(rows: HTMLElement[], y: number): number {
  for (let i = 0; i < rows.length; i++) {
    const rect = rows[i].getBoundingClientRect()
    if (y < rect.top + rect.height / 2) return i
  }
  return rows.length
}
