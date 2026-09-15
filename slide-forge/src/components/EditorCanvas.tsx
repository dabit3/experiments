import { useEffect, useRef, useState, type CSSProperties, type PointerEvent as ReactPointerEvent } from 'react'
import type { Slide, SlideElement, Theme } from '../types'
import { SLIDE_H, SLIDE_W } from '../types'
import { ElementBody } from './ElementBody'
import { elementStyle, themeVars } from './SlideView'

type Box = { x: number; y: number; w: number; h: number }
type HandleDir = 'nw' | 'n' | 'ne' | 'e' | 'se' | 's' | 'sw' | 'w'
const HANDLES: HandleDir[] = ['nw', 'n', 'ne', 'e', 'se', 's', 'sw', 'w']
const MIN_SIZE = 24

type Drag =
  | { mode: 'move'; id: string; startX: number; startY: number; box: Box; moved: boolean }
  | { mode: 'resize'; id: string; dir: HandleDir; startX: number; startY: number; box: Box; moved: boolean }
  | { mode: 'rotate'; id: string; cx: number; cy: number; moved: boolean }

interface Props {
  slide: Slide
  theme: Theme
  selectedId: string | null
  editingId: string | null
  onSelect: (id: string | null) => void
  onStartEdit: (id: string) => void
  onStopEdit: () => void
  onCheckpoint: () => void
  onPatch: (id: string, patch: Partial<SlideElement>, record: boolean) => void
  onCommitText: (id: string, value: string, contentHeight: number) => void
}

function resizeBox(box: Box, dir: HandleDir, dx: number, dy: number): Box {
  let { x, y, w, h } = box
  if (dir.includes('e')) w = Math.max(MIN_SIZE, box.w + dx)
  if (dir.includes('s')) h = Math.max(MIN_SIZE, box.h + dy)
  if (dir.includes('w')) {
    w = Math.max(MIN_SIZE, box.w - dx)
    x = box.x + box.w - w
  }
  if (dir.includes('n')) {
    h = Math.max(MIN_SIZE, box.h - dy)
    y = box.y + box.h - h
  }
  return { x: Math.round(x), y: Math.round(y), w: Math.round(w), h: Math.round(h) }
}

export function EditorCanvas({
  slide,
  theme,
  selectedId,
  editingId,
  onSelect,
  onStartEdit,
  onStopEdit,
  onCheckpoint,
  onPatch,
  onCommitText,
}: Props) {
  const wrapRef = useRef<HTMLDivElement>(null)
  const surfaceRef = useRef<HTMLDivElement>(null)
  const [scale, setScale] = useState(0.8)
  const dragRef = useRef<Drag | null>(null)
  const captureRef = useRef<Element | null>(null)

  useEffect(() => {
    const wrap = wrapRef.current
    if (!wrap) return
    const ro = new ResizeObserver(([entry]) => {
      const { width, height } = entry.contentRect
      const s = Math.min((width - 40) / SLIDE_W, (height - 40) / SLIDE_H)
      setScale(Math.max(0.2, Math.floor(s * 1000) / 1000))
    })
    ro.observe(wrap)
    return () => ro.disconnect()
  }, [])

  const toLogical = (clientX: number, clientY: number) => {
    const rect = surfaceRef.current?.getBoundingClientRect()
    if (!rect) return { x: 0, y: 0 }
    return { x: (clientX - rect.left) / scale, y: (clientY - rect.top) / scale }
  }

  const beginDrag = (e: ReactPointerEvent, drag: Drag) => {
    dragRef.current = drag
    captureRef.current = e.currentTarget
    e.currentTarget.setPointerCapture(e.pointerId)
  }

  const onElementPointerDown = (e: ReactPointerEvent, el: SlideElement) => {
    if (e.button !== 0) return
    if (editingId === el.id) return
    e.stopPropagation()
    onSelect(el.id)
    const p = toLogical(e.clientX, e.clientY)
    beginDrag(e, { mode: 'move', id: el.id, startX: p.x, startY: p.y, box: { x: el.x, y: el.y, w: el.w, h: el.h }, moved: false })
  }

  const onHandlePointerDown = (e: ReactPointerEvent, el: SlideElement, dir: HandleDir) => {
    if (e.button !== 0) return
    e.stopPropagation()
    const p = toLogical(e.clientX, e.clientY)
    beginDrag(e, { mode: 'resize', id: el.id, dir, startX: p.x, startY: p.y, box: { x: el.x, y: el.y, w: el.w, h: el.h }, moved: false })
  }

  const onRotatePointerDown = (e: ReactPointerEvent, el: SlideElement) => {
    if (e.button !== 0) return
    e.stopPropagation()
    beginDrag(e, { mode: 'rotate', id: el.id, cx: el.x + el.w / 2, cy: el.y + el.h / 2, moved: false })
  }

  const onPointerMove = (e: ReactPointerEvent) => {
    const drag = dragRef.current
    if (!drag) return
    const p = toLogical(e.clientX, e.clientY)
    if (!drag.moved) {
      if (drag.mode !== 'rotate' && Math.hypot(p.x - drag.startX, p.y - drag.startY) < 3 / scale) return
      drag.moved = true
      onCheckpoint()
    }
    if (drag.mode === 'move') {
      const nx = Math.round(drag.box.x + (p.x - drag.startX))
      const ny = Math.round(drag.box.y + (p.y - drag.startY))
      onPatch(drag.id, { x: nx, y: ny }, false)
    } else if (drag.mode === 'resize') {
      const box = resizeBox(drag.box, drag.dir, p.x - drag.startX, p.y - drag.startY)
      onPatch(drag.id, box, false)
    } else {
      const angle = (Math.atan2(p.y - drag.cy, p.x - drag.cx) * 180) / Math.PI + 90
      let deg = Math.round(angle)
      const snap = [0, 90, 180, 270, 360, -90, -180, -270].find((a) => Math.abs(deg - a) <= 4)
      if (snap !== undefined) deg = snap
      onPatch(drag.id, { rotation: ((deg % 360) + 360) % 360 }, false)
    }
  }

  const onPointerUp = (e: ReactPointerEvent) => {
    if (dragRef.current) {
      dragRef.current = null
      captureRef.current?.releasePointerCapture(e.pointerId)
      captureRef.current = null
    }
  }

  const onSurfacePointerDown = (e: ReactPointerEvent) => {
    if (e.button !== 0) return
    onSelect(null)
  }

  const handleSize = 12 / scale

  return (
    <div ref={wrapRef} className="canvas-wrap">
      <div className="slide-frame editor-frame" style={{ width: SLIDE_W * scale, height: SLIDE_H * scale }}>
        <div
          ref={surfaceRef}
          className={`slide-surface theme-${theme.id}`}
          style={{ ...themeVars(theme), transform: `scale(${scale})` }}
          onPointerDown={onSurfacePointerDown}
          onPointerMove={onPointerMove}
          onPointerUp={onPointerUp}
          onPointerCancel={onPointerUp}
        >
          <div className="slide-decor" aria-hidden="true" />
          {slide.elements.map((el) => {
            const selected = el.id === selectedId
            const editing = el.id === editingId
            const editable = el.kind === 'text' || el.kind === 'rect' || el.kind === 'ellipse'
            return (
              <div
                key={el.id}
                className={`slide-el kind-${el.kind} ${selected ? 'is-selected' : ''} ${editing ? 'is-editing' : ''}`}
                style={elementStyle(el)}
                data-element-id={el.id}
                onPointerDown={(e) => onElementPointerDown(e, el)}
                onDoubleClick={(e) => {
                  e.stopPropagation()
                  if (editable) onStartEdit(el.id)
                }}
              >
                <ElementBody
                  el={el}
                  editing={editing}
                  placeholders
                  onCommitText={(v, h) => onCommitText(el.id, v, h)}
                  onCancelEdit={onStopEdit}
                />
                {selected && !editing && (
                  <div className="selection" style={{ '--hs': `${handleSize}px`, '--bw': `${2 / scale}px` } as CSSProperties}>
                    {HANDLES.map((dir) => (
                      <div
                        key={dir}
                        className={`handle handle-${dir}`}
                        onPointerDown={(e) => onHandlePointerDown(e, el, dir)}
                      />
                    ))}
                    <div className="rotate-stem" />
                    <div className="handle handle-rotate" title="Drag to rotate" onPointerDown={(e) => onRotatePointerDown(e, el)} />
                  </div>
                )}
              </div>
            )
          })}
        </div>
      </div>
    </div>
  )
}
