import { useEffect, useRef, useState } from 'react'
import { Icon } from './Icon'

interface Props {
  canUndo: boolean
  canRedo: boolean
  onUndo: () => void
  onRedo: () => void
  onExport: (format: 'json' | 'csv') => void
}

export function Header(p: Props) {
  const [menu, setMenu] = useState(false)
  const menuRef = useRef<HTMLDivElement>(null)
  const triggerRef = useRef<HTMLButtonElement>(null)

  useEffect(() => {
    if (!menu) return
    const close = (e: PointerEvent) => {
      if (!menuRef.current?.contains(e.target as Node)) setMenu(false)
    }
    const escape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        setMenu(false)
        triggerRef.current?.focus()
      }
    }
    window.addEventListener('pointerdown', close)
    window.addEventListener('keydown', escape)
    return () => {
      window.removeEventListener('pointerdown', close)
      window.removeEventListener('keydown', escape)
    }
  }, [menu])

  return (
    <header className="app-header">
      <div className="brand">
        <span className="brand-mark" aria-hidden="true">Tc</span>
        <div className="brand-type">
          <h1>Timeline Cutter</h1>
          <span>POST-PRODUCTION</span>
        </div>
      </div>
      <div className="project-heading">
        <span className="project-folder"><Icon name="folder" size={16} /> Untitled project</span>
        <span className="breadcrumb-slash">/</span>
        <strong>Sequence 01</strong>
        <span className="session-label" title="Edits stay in this tab until you export">Local session</span>
      </div>
      <div className="header-actions">
        <div className="history-actions">
          <button className="icon-btn" onClick={p.onUndo} disabled={!p.canUndo} title="Undo (Ctrl+Z)" aria-label="Undo"><Icon name="undo" size={17} /></button>
          <button className="icon-btn" onClick={p.onRedo} disabled={!p.canRedo} title="Redo (Ctrl+Shift+Z)" aria-label="Redo"><Icon name="redo" size={17} /></button>
        </div>
        <div className="export-menu" ref={menuRef}>
          <button ref={triggerRef} className="btn primary" onClick={() => setMenu((m) => !m)} aria-expanded={menu} aria-controls="export-options" data-testid="export-btn">
            <Icon name="download" size={16} /> Export EDL <Icon name="chevron" size={14} />
          </button>
          {menu && (
            <div className="menu" id="export-options">
              <div className="menu-title">Export edit decision list<span>Your edit, ready for the next step.</span></div>
              <button onClick={() => { setMenu(false); p.onExport('json') }} data-testid="export-json">
                <span className="menu-icon">{'{ }'}</span>
                <strong>JSON</strong><span>Structured timeline data</span>
              </button>
              <button onClick={() => { setMenu(false); p.onExport('csv') }} data-testid="export-csv">
                <span className="menu-icon">CSV</span>
                <strong>CSV</strong><span>Spreadsheet-compatible list</span>
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  )
}
