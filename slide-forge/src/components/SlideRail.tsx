import { useRef, useState, type PointerEvent as ReactPointerEvent } from 'react'
import type { Slide, Theme } from '../types'
import { SlideView } from './SlideView'

const THUMB_W = 184

interface Props {
  slides: Slide[]
  theme: Theme
  currentId: string
  onSelect: (id: string) => void
  onReorder: (from: number, to: number) => void
  onContextMenu: (slideId: string, x: number, y: number) => void
  onAddSlide: () => void
}

interface DragState {
  index: number
  startY: number
  pointerY: number
  active: boolean
  target: number
}

export function SlideRail({ slides, theme, currentId, onSelect, onReorder, onContextMenu, onAddSlide }: Props) {
  const listRef = useRef<HTMLDivElement>(null)
  const [drag, setDrag] = useState<DragState | null>(null)

  const computeTarget = (clientY: number): number => {
    const items = Array.from(listRef.current?.querySelectorAll<HTMLElement>('[data-slide-index]') ?? [])
    for (const item of items) {
      const r = item.getBoundingClientRect()
      if (clientY < r.top + r.height / 2) return Number(item.dataset.slideIndex)
    }
    return items.length
  }

  const onPointerDown = (e: ReactPointerEvent<HTMLDivElement>, index: number) => {
    if (e.button !== 0) return
    onSelect(slides[index].id)
    e.currentTarget.setPointerCapture(e.pointerId)
    setDrag({ index, startY: e.clientY, pointerY: e.clientY, active: false, target: index })
  }

  const onPointerMove = (e: ReactPointerEvent<HTMLDivElement>) => {
    if (!drag) return
    const active = drag.active || Math.abs(e.clientY - drag.startY) > 6
    setDrag({ ...drag, active, pointerY: e.clientY, target: active ? computeTarget(e.clientY) : drag.index })
  }

  const onPointerUp = (e: ReactPointerEvent<HTMLDivElement>) => {
    if (!drag) return
    e.currentTarget.releasePointerCapture(e.pointerId)
    if (drag.active) {
      let to = drag.target
      if (to > drag.index) to -= 1
      if (to !== drag.index) onReorder(drag.index, to)
    }
    setDrag(null)
  }

  const dragging = drag?.active ? drag : null

  return (
    <aside className="rail" aria-label="Slides">
      <div className="rail-list" ref={listRef}>
        {slides.map((slide, i) => {
          const isDragSource = dragging?.index === i
          const showIndicatorBefore = dragging && dragging.target === i && dragging.target !== dragging.index && dragging.target !== dragging.index + 1
          return (
            <div key={slide.id} className="rail-slot">
              {showIndicatorBefore && <div className="drop-indicator" />}
              <div
                className={`rail-item ${slide.id === currentId ? 'is-current' : ''} ${isDragSource ? 'is-drag-source' : ''}`}
                data-slide-index={i}
                onPointerDown={(e) => onPointerDown(e, i)}
                onPointerMove={onPointerMove}
                onPointerUp={onPointerUp}
                onPointerCancel={onPointerUp}
                onContextMenu={(e) => {
                  e.preventDefault()
                  onSelect(slide.id)
                  onContextMenu(slide.id, e.clientX, e.clientY)
                }}
                title={`Slide ${i + 1}`}
              >
                <span className="rail-number">{i + 1}</span>
                <SlideView slide={slide} theme={theme} width={THUMB_W} className="thumb" placeholders />
              </div>
            </div>
          )
        })}
        {dragging && dragging.target === slides.length && dragging.index !== slides.length - 1 && (
          <div className="rail-slot">
            <div className="drop-indicator" />
          </div>
        )}
      </div>
      {dragging && (
        <div className="rail-ghost" style={{ top: dragging.pointerY - 40 }}>
          <SlideView slide={slides[dragging.index]} theme={theme} width={THUMB_W} className="thumb" placeholders />
        </div>
      )}
      <button type="button" className="btn rail-add" onClick={onAddSlide}>
        <span className="plus">+</span> New slide
      </button>
    </aside>
  )
}
