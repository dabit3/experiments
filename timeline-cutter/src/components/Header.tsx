import { useEffect, useRef, useState } from 'react'
import { Icon } from './Icon'
import { timecode } from '../lib/time'

interface Props {
  time: number
  duration: number
  speed: number
  isPlaying: boolean
  onTogglePlay: () => void
  onShuttle: (dir: 1 | -1) => void
  onPause: () => void
  onGoStart: () => void
  onGoEnd: () => void
  canUndo: boolean
  canRedo: boolean
  onUndo: () => void
  onRedo: () => void
  onExport: (format: 'json' | 'csv') => void
}

export function Header(p: Props) {
  const [menu, setMenu] = useState(false)
  const menuRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!menu) return
    const close = (e: PointerEvent) => {
      if (!menuRef.current?.contains(e.target as Node)) setMenu(false)
    }
    window.addEventListener('pointerdown', close)
    return () => window.removeEventListener('pointerdown', close)
  }, [menu])

  return (
    <header className="app-header">
      <div className="brand">
        <span className="brand-mark" aria-hidden="true">
          <span />
          <span />
          <span />
        </span>
        <div>
          <h1>Timeline Cutter</h1>
          <p>Trim · split · ripple</p>
        </div>
      </div>

      <div className="transport" role="group" aria-label="Transport">
        <button className="icon-btn" onClick={p.onGoStart} title="Go to start (Home)" aria-label="Go to start">
          <Icon name="skip-start" size={20} />
        </button>
        <button className={`icon-btn ${p.speed < 0 ? 'active' : ''}`} onClick={() => p.onShuttle(-1)} title="Shuttle backwards (J)" aria-label="Shuttle backwards">
          <Icon name="rewind" size={20} />
          <kbd>J</kbd>
        </button>
        <button className={`icon-btn ${p.speed === 0 ? 'active' : ''}`} onClick={p.onPause} title="Stop (K)" aria-label="Stop">
          <Icon name="pause" size={20} />
          <kbd>K</kbd>
        </button>
        <button className="play-btn" onClick={p.onTogglePlay} title="Play / pause (Space)" aria-label={p.isPlaying ? 'Pause' : 'Play'}>
          <Icon name={p.isPlaying ? 'pause' : 'play'} size={24} />
        </button>
        <button className={`icon-btn ${p.speed > 0 ? 'active' : ''}`} onClick={() => p.onShuttle(1)} title="Shuttle forwards (L)" aria-label="Shuttle forwards">
          <Icon name="forward" size={20} />
          <kbd>L</kbd>
        </button>
        <button className="icon-btn" onClick={p.onGoEnd} title="Go to end (End)" aria-label="Go to end">
          <Icon name="skip-end" size={20} />
        </button>
        <div className="tc-display" aria-live="off">
          <span className="tc-current">{timecode(p.time)}</span>
          <span className="tc-sep">/</span>
          <span className="tc-total">{timecode(p.duration)}</span>
        </div>
      </div>

      <div className="header-actions">
        <button className="icon-btn" onClick={p.onUndo} disabled={!p.canUndo} title="Undo (Ctrl+Z)" aria-label="Undo">
          <Icon name="undo" size={18} />
        </button>
        <button className="icon-btn" onClick={p.onRedo} disabled={!p.canRedo} title="Redo (Ctrl+Shift+Z)" aria-label="Redo">
          <Icon name="redo" size={18} />
        </button>
        <div className="export-menu" ref={menuRef}>
          <button className="btn primary" onClick={() => setMenu((m) => !m)} aria-haspopup="menu" aria-expanded={menu} data-testid="export-btn">
            <Icon name="download" size={16} /> Export EDL <Icon name="chevron" size={14} />
          </button>
          {menu && (
            <div className="menu" role="menu">
              <button role="menuitem" onClick={() => { setMenu(false); p.onExport('json') }} data-testid="export-json">
                <strong>JSON</strong> <span>timeline-cutter-edl.json</span>
              </button>
              <button role="menuitem" onClick={() => { setMenu(false); p.onExport('csv') }} data-testid="export-csv">
                <strong>CSV</strong> <span>timeline-cutter-edl.csv</span>
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  )
}
