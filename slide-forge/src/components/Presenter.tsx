import { useEffect, useState } from 'react'
import type { Deck, Theme } from '../types'
import { SLIDE_H, SLIDE_W } from '../types'
import { SlideView } from './SlideView'

interface Props {
  deck: Deck
  theme: Theme
  startIndex: number
  onExit: () => void
}

function useElapsed(): string {
  const [elapsed, setElapsed] = useState(0)
  useEffect(() => {
    const start = Date.now()
    const id = window.setInterval(() => setElapsed(Date.now() - start), 500)
    return () => window.clearInterval(id)
  }, [])
  const total = Math.floor(elapsed / 1000)
  const m = Math.floor(total / 60)
  const s = total % 60
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
}

function useViewport() {
  const [size, setSize] = useState({ w: window.innerWidth, h: window.innerHeight })
  useEffect(() => {
    const onResize = () => setSize({ w: window.innerWidth, h: window.innerHeight })
    window.addEventListener('resize', onResize)
    return () => window.removeEventListener('resize', onResize)
  }, [])
  return size
}

function fitWidth(maxW: number, maxH: number): number {
  return Math.floor(Math.min(maxW, maxH * (SLIDE_W / SLIDE_H)))
}

export function Presenter({ deck, theme, startIndex, onExit }: Props) {
  const [index, setIndex] = useState(startIndex)
  const [presenterView, setPresenterView] = useState(false)
  const [hint, setHint] = useState(true)
  const elapsed = useElapsed()
  const viewport = useViewport()
  const count = deck.slides.length

  useEffect(() => {
    const id = window.setTimeout(() => setHint(false), 3500)
    return () => window.clearTimeout(id)
  }, [])

  useEffect(() => {
    const next = () => setIndex((i) => Math.min(count - 1, i + 1))
    const prev = () => setIndex((i) => Math.max(0, i - 1))
    const onKey = (e: KeyboardEvent) => {
      switch (e.key) {
        case 'ArrowRight':
        case 'ArrowDown':
        case 'PageDown':
        case ' ':
        case 'Enter':
          e.preventDefault()
          next()
          break
        case 'ArrowLeft':
        case 'ArrowUp':
        case 'PageUp':
        case 'Backspace':
          e.preventDefault()
          prev()
          break
        case 'Home':
          setIndex(0)
          break
        case 'End':
          setIndex(count - 1)
          break
        case 'p':
        case 'P':
          setPresenterView((v) => !v)
          break
        case 'Escape':
          onExit()
          break
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [count, onExit])

  const slide = deck.slides[index]
  const nextSlide = deck.slides[index + 1]

  if (presenterView) {
    const mainW = fitWidth(viewport.w * 0.62 - 48, viewport.h - 140)
    const nextW = fitWidth(viewport.w * 0.38 - 64, viewport.h * 0.32)
    return (
      <div className="presenter presenter-view" onClick={() => setIndex((i) => Math.min(count - 1, i + 1))}>
        <div className="pv-main">
          <div className="pv-label">Current · {index + 1} / {count}</div>
          <SlideView slide={slide} theme={theme} width={mainW} className="pv-slide" />
        </div>
        <div className="pv-side">
          <div className="pv-timer" aria-label="Elapsed time">{elapsed}</div>
          <div className="pv-label">Next</div>
          {nextSlide ? (
            <SlideView slide={nextSlide} theme={theme} width={nextW} className="pv-slide" />
          ) : (
            <div className="pv-end" style={{ width: nextW, height: nextW * (SLIDE_H / SLIDE_W) }}>
              End of deck
            </div>
          )}
          <div className="pv-label">Notes</div>
          <div className="pv-notes">{slide.notes || <span className="pv-muted">No notes for this slide.</span>}</div>
          <div className="pv-help">
            <span><kbd>←</kbd> <kbd>→</kbd> navigate</span>
            <span><kbd>P</kbd> audience view</span>
            <span><kbd>Esc</kbd> exit</span>
          </div>
        </div>
      </div>
    )
  }

  const width = fitWidth(viewport.w, viewport.h)
  return (
    <div className="presenter" onClick={() => setIndex((i) => Math.min(count - 1, i + 1))}>
      <SlideView key={slide.id} slide={slide} theme={theme} width={width} className="present-slide" />
      <div className={`present-hint ${hint ? '' : 'is-hidden'}`}>
        ← → to navigate · <strong>P</strong> for presenter view · <strong>Esc</strong> to exit
      </div>
      <div className="present-counter">
        {index + 1} / {count}
      </div>
      <div className="present-progress" aria-hidden="true">
        <i style={{ width: `${((index + 1) / count) * 100}%` }} />
      </div>
    </div>
  )
}
