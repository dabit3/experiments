import { useEffect, useRef, useState } from 'react'
import type { KeyboardEvent } from 'react'
import { createPortal } from 'react-dom'
import type { WidgetProps } from './types'

const FOCUSABLE = 'button:not([disabled]), [href], input:not([disabled]), select, textarea, [tabindex]:not([tabindex="-1"])'

export function DialogTask({ onComplete }: WidgetProps) {
  const [open, setOpen] = useState(false)
  const [armed, setArmed] = useState(false)
  const [note, setNote] = useState<string | null>(null)
  const [hint, setHint] = useState<string | null>(null)
  const openerRef = useRef<HTMLButtonElement>(null)
  const dialogRef = useRef<HTMLDivElement>(null)
  const firstButtonRef = useRef<HTMLButtonElement>(null)

  useEffect(() => {
    const root = document.getElementById('root')
    if (!open) return
    root?.setAttribute('inert', '')
    firstButtonRef.current?.focus()
    return () => root?.removeAttribute('inert')
  }, [open])

  const openDialog = () => {
    setArmed(false)
    setNote(null)
    setHint(null)
    setOpen(true)
  }

  const close = (via: 'escape' | 'button') => {
    setOpen(false)
    requestAnimationFrame(() => openerRef.current?.focus())
    if (via === 'escape' && armed) {
      setHint('Trap armed and closed with Escape.')
      onComplete()
    } else if (via === 'escape') {
      setHint('Closed with Escape, but the trap was never armed. Open it again and press Enter on the third button first.')
    } else {
      setHint('Closed with a button. The task needs Escape after arming the trap.')
    }
  }

  const onDialogKeyDown = (e: KeyboardEvent<HTMLDivElement>) => {
    if (e.key === 'Escape') {
      e.preventDefault()
      close('escape')
      return
    }
    if (e.key !== 'Tab' || !dialogRef.current) return
    const focusable = Array.from(dialogRef.current.querySelectorAll<HTMLElement>(FOCUSABLE))
    if (focusable.length === 0) return
    const first = focusable[0]
    const last = focusable[focusable.length - 1]
    const active = document.activeElement
    if (e.shiftKey && (active === first || !dialogRef.current.contains(active))) {
      e.preventDefault()
      last.focus()
    } else if (!e.shiftKey && (active === last || !dialogRef.current.contains(active))) {
      e.preventDefault()
      first.focus()
    }
  }

  return (
    <div className="dialog-shell">
      <div className="deploy-card" aria-hidden={open ? 'true' : undefined}>
        <div className="deploy-meta">
          <span className="deploy-env">production</span>
          <span className="deploy-sha">gauntlet@7f3e2a1</span>
        </div>
        <h3>Deploy to production</h3>
        <p>Opening the confirmation dialog traps keyboard focus inside it until it is dismissed.</p>
        <button type="button" className="btn btn-primary" ref={openerRef} onClick={openDialog}>
          Open confirmation dialog
        </button>
      </div>
      <p className="widget-status" aria-live="polite">
        {hint ?? 'Dialog closed'}
      </p>

      {open &&
        createPortal(
          <div className="dialog-backdrop">
            <div
              role="dialog"
              aria-modal="true"
              aria-labelledby="deploy-dialog-title"
              aria-describedby="deploy-dialog-desc"
              className="dialog"
              ref={dialogRef}
              onKeyDown={onDialogKeyDown}
            >
              <h2 id="deploy-dialog-title">Confirm deployment</h2>
              <p id="deploy-dialog-desc">
                Focus is trapped in this dialog: Tab cycles forward through the three buttons and wraps, Shift+Tab
                cycles backwards. Tab to the <strong>third</strong> button, press Enter, then press Escape.
              </p>
              <div className={`dialog-state${armed ? ' armed' : ''}`} role="status">
                {armed ? 'Trap armed — press Escape to close' : note ?? 'Trap not armed'}
              </div>
              <div className="dialog-actions">
                <button type="button" className="btn" ref={firstButtonRef} onClick={() => close('button')}>
                  Not now
                </button>
                <button type="button" className="btn" onClick={() => setNote('That is button 2 of 3 — one more Tab.')}>
                  View changelog
                </button>
                <button type="button" className="btn btn-primary" onClick={() => setArmed(true)}>
                  Arm the trap
                </button>
              </div>
            </div>
          </div>,
          document.body,
        )}
    </div>
  )
}
