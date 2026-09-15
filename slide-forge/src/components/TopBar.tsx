import { useEffect, useRef, useState } from 'react'
import type { ElementKind, SlideLayout } from '../types'
import { STICKERS, stickerArt } from '../lib/stickers'
import { Icon } from './Icons'

interface Props {
  title: string
  onTitleChange: (title: string) => void
  canUndo: boolean
  canRedo: boolean
  onUndo: () => void
  onRedo: () => void
  onInsert: (kind: ElementKind, emoji?: string) => void
  onAddSlide: (layout: SlideLayout) => void
  onPresent: () => void
  onExportPdf: () => void
  savedAt: number | null
}

type Popover = 'sticker' | 'layout' | null

export function TopBar({ title, onTitleChange, canUndo, canRedo, onUndo, onRedo, onInsert, onAddSlide, onPresent, onExportPdf, savedAt }: Props) {
  const [popover, setPopover] = useState<Popover>(null)
  const barRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!popover) return
    const onDown = (e: PointerEvent) => {
      if (barRef.current && !barRef.current.contains(e.target as Node)) setPopover(null)
    }
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setPopover(null)
    }
    window.addEventListener('pointerdown', onDown)
    window.addEventListener('keydown', onKey)
    return () => {
      window.removeEventListener('pointerdown', onDown)
      window.removeEventListener('keydown', onKey)
    }
  }, [popover])

  const toggle = (p: Popover) => setPopover((cur) => (cur === p ? null : p))

  return (
    <header className="topbar" ref={barRef}>
      <div className="brand">
        <span className="brand-mark">
          <Icon name="logo" size={20} />
        </span>
        <span className="brand-name">SlideForge</span>
      </div>

      <input
        className="deck-title"
        value={title}
        onChange={(e) => onTitleChange(e.target.value)}
        onFocus={(e) => e.target.select()}
        aria-label="Deck title"
        spellCheck={false}
      />

      <div className="tb-group">
        <button type="button" className="btn btn-icon" onClick={onUndo} disabled={!canUndo} title="Undo (Ctrl+Z)" aria-label="Undo">
          <Icon name="undo" />
        </button>
        <button type="button" className="btn btn-icon" onClick={onRedo} disabled={!canRedo} title="Redo (Ctrl+Y)" aria-label="Redo">
          <Icon name="redo" />
        </button>
      </div>

      <div className="tb-divider" />

      <div className="tb-group insert-group">
        <div className="popover-anchor">
          <button type="button" className={`btn ${popover === 'layout' ? 'is-active' : ''}`} onClick={() => toggle('layout')} title="New slide">
            <Icon name="plus" /> Slide
          </button>
          {popover === 'layout' && (
            <div className="popover layout-popover">
              {(
                [
                  ['title', 'Title slide', 'Big centred title with a subtitle'],
                  ['bullets', 'Title & bullets', 'Heading with a bulleted body'],
                  ['blank', 'Blank', 'Start from nothing'],
                ] as [SlideLayout, string, string][]
              ).map(([layout, name, desc]) => (
                <button
                  key={layout}
                  type="button"
                  className="layout-option"
                  onClick={() => {
                    onAddSlide(layout)
                    setPopover(null)
                  }}
                >
                  <span className={`layout-thumb layout-${layout}`}>
                    <i />
                    <i />
                  </span>
                  <span className="layout-text">
                    <strong>{name}</strong>
                    <small>{desc}</small>
                  </span>
                </button>
              ))}
            </div>
          )}
        </div>
        <button type="button" className="btn" onClick={() => onInsert('text')} title="Insert text box">
          <Icon name="text" /> Text
        </button>
        <button type="button" className="btn" onClick={() => onInsert('rect')} title="Insert rectangle">
          <Icon name="rect" /> Rect
        </button>
        <button type="button" className="btn" onClick={() => onInsert('ellipse')} title="Insert ellipse">
          <Icon name="ellipse" /> Ellipse
        </button>
        <button type="button" className="btn" onClick={() => onInsert('arrow')} title="Insert arrow">
          <Icon name="arrow" /> Arrow
        </button>
        <div className="popover-anchor">
          <button type="button" className={`btn ${popover === 'sticker' ? 'is-active' : ''}`} onClick={() => toggle('sticker')} title="Insert emoji sticker">
            <Icon name="sticker" /> Sticker
          </button>
          {popover === 'sticker' && (
            <div className="popover sticker-popover">
              {STICKERS.map((e) => (
                <button
                  key={e}
                  type="button"
                  className="emoji-btn"
                  onClick={() => {
                    onInsert('sticker', e)
                    setPopover(null)
                  }}
                >
                  <img src={stickerArt(e)} alt={e} draggable={false} />
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

      <div className="tb-spacer" />

      <span className={`save-state ${savedAt ? 'is-saved' : ''}`} title="Autosaved to localStorage">
        <span className="save-dot" />
        {savedAt ? 'Saved' : 'Saving…'}
      </span>

      <button type="button" className="btn btn-outline" onClick={onExportPdf} title="Export PDF (opens the print dialog)">
        <Icon name="pdf" /> Export PDF
      </button>
      <button type="button" className="btn btn-primary" onClick={onPresent} title="Present (F5)">
        <Icon name="play" /> Present
      </button>
    </header>
  )
}
