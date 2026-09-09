import { useEffect, useRef, type CSSProperties } from 'react'

interface HoldButtonProps {
  label: string
  hint: string
  /** 0..100 progress rendered as a ring around the button */
  progress: number
  active: boolean
  disabled?: boolean
  onHoldStart: () => void
  onHoldEnd: () => void
}

/**
 * A press-and-hold control. Starts on pointerdown / Space / Enter and stops on
 * release, pointer leaving the button, or the window losing focus, so a hold
 * can never get stuck "on" if the user alt-tabs away mid-press.
 */
export function HoldButton({ label, hint, progress, active, disabled, onHoldStart, onHoldEnd }: HoldButtonProps) {
  const holding = useRef(false)

  const start = () => {
    if (disabled || holding.current) return
    holding.current = true
    onHoldStart()
  }
  const stop = () => {
    if (!holding.current) return
    holding.current = false
    onHoldEnd()
  }

  useEffect(() => {
    window.addEventListener('blur', stop)
    window.addEventListener('pointerup', stop)
    return () => {
      window.removeEventListener('blur', stop)
      window.removeEventListener('pointerup', stop)
    }
  })

  const ring = Math.max(0, Math.min(100, progress))
  const style = { '--ring': `${ring}%` } as CSSProperties

  return (
    <div className={`hold${active ? ' hold--active' : ''}${disabled ? ' hold--disabled' : ''}`} style={style}>
      <button
        type="button"
        className="hold__button display"
        disabled={disabled}
        aria-pressed={active}
        onPointerDown={(e) => {
          e.preventDefault()
          start()
        }}
        onPointerUp={stop}
        onPointerLeave={stop}
        onPointerCancel={stop}
        onKeyDown={(e) => {
          if (e.key === ' ' || e.key === 'Enter') {
            e.preventDefault()
            start()
          }
        }}
        onKeyUp={(e) => {
          if (e.key === ' ' || e.key === 'Enter') stop()
        }}
      >
        <span className="hold__label">{label}</span>
        <span className="hold__value mono">{Math.round(ring)}%</span>
      </button>
      <p className="hold__hint">{hint}</p>
    </div>
  )
}
