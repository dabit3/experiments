import { useState, type PointerEvent } from 'react'
import { PALETTE } from '../types'
import { hexToHsv, hsvToHex } from '../lib/color'

export function ColorPanel({
  color,
  onChange,
}: {
  color: string
  onChange: (color: string) => void
}) {
  const hsv = hexToHsv(color)
  const [hue, setHue] = useState(hsv.h)
  const [draft, setDraft] = useState<string | null>(null)
  const displayHue = hsv.s === 0 ? hue : hsv.h
  const pick = (e: PointerEvent<HTMLDivElement>) => {
    const rect = e.currentTarget.getBoundingClientRect()
    const s = Math.max(0, Math.min(1, (e.clientX - rect.left) / rect.width))
    const v = Math.max(0, Math.min(1, 1 - (e.clientY - rect.top) / rect.height))
    onChange(hsvToHex(displayHue, s, v))
  }
  const commitHex = () => {
    const hex = `#${(draft ?? color).replace('#', '')}`
    if (/^#[0-9a-f]{6}$/i.test(hex)) onChange(hex.toLowerCase())
    setDraft(null)
  }
  return (
    <section className="inspector-section color-section">
      <div className="section-heading">
        <h2>Color</h2>
        <span>HSB</span>
      </div>
      <div
        className="color-field"
        role="group"
        aria-label="Color saturation and brightness"
        style={{ backgroundColor: `hsl(${displayHue} 100% 50%)` }}
        onPointerDown={(e) => {
          e.currentTarget.setPointerCapture(e.pointerId)
          pick(e)
        }}
        onPointerMove={(e) => {
          if (e.buttons === 1) pick(e)
        }}
      >
        <span
          className="color-target"
          style={{ left: `${hsv.s * 100}%`, top: `${(1 - hsv.v) * 100}%` }}
        />
      </div>
      <input
        className="hue-slider"
        type="range"
        aria-label="Hue"
        min="0"
        max="359"
        value={Math.round(displayHue)}
        onChange={(e) => {
          const h = Number(e.target.value)
          setHue(h)
          onChange(hsvToHex(h, hsv.s || 1, hsv.v || 1))
        }}
      />
      <div className="hex-row">
        <input
          type="color"
          aria-label="Custom color"
          value={color}
          onChange={(e) => onChange(e.target.value)}
        />
        <label>
          <span>HEX</span>
          <input
            aria-label="Hex color"
            value={draft ?? color.slice(1).toUpperCase()}
            maxLength={7}
            onChange={(e) => setDraft(e.target.value)}
            onBlur={commitHex}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                commitHex()
                e.currentTarget.blur()
              }
            }}
          />
        </label>
        <span className="color-alpha">100%</span>
      </div>
      <div className="palette-heading">
        Studio palette<span>16 colors</span>
      </div>
      <div className="palette">
        {PALETTE.map((swatch) => (
          <button
            key={swatch}
            aria-label={`Color ${swatch}`}
            title={swatch}
            aria-pressed={color === swatch}
            className={`swatch ${color === swatch ? 'selected' : ''}`}
            style={{ background: swatch }}
            onClick={() => onChange(swatch)}
          />
        ))}
      </div>
    </section>
  )
}
