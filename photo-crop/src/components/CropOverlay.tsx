import { useRef } from 'react'
import type { PointerEvent as ReactPointerEvent } from 'react'
import { HANDLES, moveRect, resizeRect } from '../lib/crop'
import type { Handle, Rect, Size } from '../lib/crop'

interface Props {
  rect: Rect
  bounds: Size
  /** Display pixels per image pixel. */
  scale: number
  ratio: number | null
  onChange: (rect: Rect) => void
}

interface DragState {
  handle: Handle | 'move'
  startRect: Rect
  startX: number
  startY: number
}

export function CropOverlay({ rect, bounds, scale, ratio, onChange }: Props) {
  const drag = useRef<DragState | null>(null)

  const begin = (handle: Handle | 'move') => (e: ReactPointerEvent<HTMLElement>) => {
    e.preventDefault()
    e.stopPropagation()
    e.currentTarget.setPointerCapture(e.pointerId)
    drag.current = { handle, startRect: rect, startX: e.clientX, startY: e.clientY }
  }

  const onPointerMove = (e: ReactPointerEvent<HTMLElement>) => {
    const d = drag.current
    if (!d) return
    const dx = (e.clientX - d.startX) / scale
    const dy = (e.clientY - d.startY) / scale
    const next =
      d.handle === 'move'
        ? moveRect(d.startRect, dx, dy, bounds)
        : resizeRect(d.startRect, d.handle, dx, dy, ratio, bounds)
    onChange(next)
  }

  const onPointerUp = () => {
    drag.current = null
  }

  const style = {
    left: rect.x * scale,
    top: rect.y * scale,
    width: rect.w * scale,
    height: rect.h * scale,
  }

  return (
    <>
      <div className="crop-mask" aria-hidden>
        <div className="crop-mask-hole" style={style} />
      </div>
      <div
        className="crop-box"
        style={style}
        data-testid="crop-box"
        onPointerDown={begin('move')}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerCancel={onPointerUp}
      >
        <div className="crop-grid" aria-hidden />
        {HANDLES.map((h) => (
          <div
            key={h}
            className={`crop-handle handle-${h}`}
            data-testid={`handle-${h}`}
            onPointerDown={begin(h)}
            onPointerMove={onPointerMove}
            onPointerUp={onPointerUp}
            onPointerCancel={onPointerUp}
          />
        ))}
        <div className="crop-size-badge">
          {Math.round(rect.w)} × {Math.round(rect.h)}
        </div>
      </div>
    </>
  )
}
