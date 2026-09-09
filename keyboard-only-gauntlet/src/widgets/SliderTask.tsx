import { useState } from 'react'
import type { KeyboardEvent } from 'react'
import type { WidgetProps } from './types'

export const SLIDER_TARGET = 42
const MIN = 0
const MAX = 100
const START = 17

const clamp = (v: number) => Math.min(MAX, Math.max(MIN, v))

export function SliderTask({ onComplete }: WidgetProps) {
  const [value, setValue] = useState(START)
  const [locked, setLocked] = useState<number | null>(null)

  const onKeyDown = (e: KeyboardEvent<HTMLDivElement>) => {
    switch (e.key) {
      case 'ArrowRight':
      case 'ArrowUp':
        setValue((v) => clamp(v + 1))
        break
      case 'ArrowLeft':
      case 'ArrowDown':
        setValue((v) => clamp(v - 1))
        break
      case 'PageUp':
        setValue((v) => clamp(v + 10))
        break
      case 'PageDown':
        setValue((v) => clamp(v - 10))
        break
      case 'Home':
        setValue(MIN)
        break
      case 'End':
        setValue(MAX)
        break
      case 'Enter':
      case ' ':
        setLocked(value)
        if (value === SLIDER_TARGET) onComplete()
        break
      default:
        return
    }
    e.preventDefault()
    if (e.key !== 'Enter' && e.key !== ' ') setLocked(null)
  }

  const pct = ((value - MIN) / (MAX - MIN)) * 100
  const targetPct = ((SLIDER_TARGET - MIN) / (MAX - MIN)) * 100

  return (
    <div className="slider-shell">
      <div className="slider-header">
        <span id="signal-label" className="field-label">
          Signal strength
        </span>
        <span className="slider-readout">
          <span className={`slider-value${value === SLIDER_TARGET ? ' on-target' : ''}`}>{value}</span>
          <span className="slider-target">/ target {SLIDER_TARGET}</span>
        </span>
      </div>
      <div
        role="slider"
        tabIndex={0}
        aria-labelledby="signal-label"
        aria-valuemin={MIN}
        aria-valuemax={MAX}
        aria-valuenow={value}
        aria-valuetext={`${value} percent`}
        className={`slider${value === SLIDER_TARGET ? ' on-target' : ''}`}
        onKeyDown={onKeyDown}
      >
        <div className="slider-track">
          <div className="slider-fill" style={{ width: `${pct}%` }} />
          <div className="slider-target-mark" style={{ left: `${targetPct}%` }} aria-hidden="true" />
          <div className="slider-thumb" style={{ left: `${pct}%` }}>
            <span className="slider-bubble">{value}</span>
          </div>
        </div>
        <div className="slider-scale" aria-hidden="true">
          {[0, 25, 50, 75, 100].map((t) => (
            <span key={t} style={{ left: `${t}%` }}>
              {t}
            </span>
          ))}
        </div>
      </div>
      <p className="widget-status" aria-live="polite">
        {locked === null ? (
          '← → ±1 · PgUp PgDn ±10 · Home End · Enter locks the value'
        ) : locked === SLIDER_TARGET ? (
          <>
            Locked at <strong>{locked}</strong>
          </>
        ) : (
          <>
            Locked at <strong>{locked}</strong>
            <span className="status-hint"> — needs exactly {SLIDER_TARGET}</span>
          </>
        )}
      </p>
    </div>
  )
}
