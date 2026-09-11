import { useId, useRef, type ChangeEvent, type CSSProperties } from 'react'
import { BPM_MAX, BPM_MIN, SWING_MAX, type PatternId } from '../types'

interface Props {
  playing: boolean
  bpm: number
  swing: number
  chain: boolean
  nowPlaying: PatternId | null
  currentStep: number | null
  onTogglePlay: () => void
  onBpm: (bpm: number) => void
  onSwing: (swing: number) => void
  onChain: (on: boolean) => void
}

interface FileProps {
  onSave: () => void
  onLoadFile: (file: File) => void
}

interface FaderProps {
  id: string
  label: string
  unit: string
  value: number
  min: number
  max: number
  onChange: (v: number) => void
}

function Fader(f: FaderProps) {
  const pct = ((f.value - f.min) / (f.max - f.min)) * 100
  return (
    <div className="fader">
      <div className="fader-head">
        <label htmlFor={f.id}>{f.label}</label>
        <output htmlFor={f.id} className="readout">
          {f.value}
          <small>{f.unit}</small>
        </output>
      </div>
      <div className="fader-row">
        <button
          type="button"
          className="nudge"
          aria-label={`${f.label} down`}
          onClick={() => f.onChange(Math.max(f.min, f.value - 1))}
        >
          <svg viewBox="0 0 12 12" aria-hidden="true">
            <path d="M2.5 6h7" />
          </svg>
        </button>
        <div className="fader-track">
          <input
            id={f.id}
            type="range"
            min={f.min}
            max={f.max}
            step={1}
            value={f.value}
            style={{ '--pct': `${pct}%` } as CSSProperties}
            onChange={(e) => f.onChange(Number(e.target.value))}
          />
        </div>
        <button
          type="button"
          className="nudge"
          aria-label={`${f.label} up`}
          onClick={() => f.onChange(Math.min(f.max, f.value + 1))}
        >
          <svg viewBox="0 0 12 12" aria-hidden="true">
            <path d="M2.5 6h7M6 2.5v7" />
          </svg>
        </button>
      </div>
    </div>
  )
}

export function Transport(p: Props) {
  const bpmId = useId()
  const swingId = useId()
  const beat = p.currentStep === null ? -1 : Math.floor(p.currentStep / 4)

  return (
    <section className="transport" aria-label="Transport">
      <div className="transport-main">
        <button
          type="button"
          className={`play ${p.playing ? 'is-playing' : ''}`}
          onClick={p.onTogglePlay}
          aria-pressed={p.playing}
          title="Play / stop (Space)"
        >
          {p.playing ? (
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <rect x="6.5" y="6.5" width="11" height="11" rx="2" />
            </svg>
          ) : (
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <path d="M8 5.7v12.6a1 1 0 0 0 1.53.85l10-6.3a1 1 0 0 0 0-1.7l-10-6.3A1 1 0 0 0 8 5.7Z" />
            </svg>
          )}
          <span className="play-label">{p.playing ? 'Stop' : 'Play'}</span>
          <kbd aria-hidden="true">↵</kbd>
        </button>

        <Fader
          id={bpmId}
          label="Tempo"
          unit="BPM"
          value={p.bpm}
          min={BPM_MIN}
          max={BPM_MAX}
          onChange={p.onBpm}
        />
        <Fader
          id={swingId}
          label="Swing"
          unit="%"
          value={p.swing}
          min={0}
          max={SWING_MAX}
          onChange={p.onSwing}
        />
      </div>

      <div className="transport-side">
        <div className="position-display" aria-label="Playback position">
          <span className="group-label">Position</span>
          <div className="position-value">
            <span>{p.nowPlaying ?? '—'}</span>
            <span>{String((p.currentStep ?? -1) + 1).padStart(2, '0')}</span>
            <small>/ 16</small>
          </div>
        </div>
        <div className="beat-leds" aria-hidden="true">
          {[0, 1, 2, 3].map((b) => (
            <i key={b} className={beat === b ? 'is-lit' : ''} />
          ))}
        </div>
        <div className="chain-control">
          <span className="group-label">Playback</span>
          <button
            type="button"
            className={`chip ${p.chain ? 'is-active' : ''}`}
            aria-pressed={p.chain}
            onClick={() => p.onChain(!p.chain)}
            title="Play A then B in a loop"
          >
            <svg viewBox="0 0 20 20" aria-hidden="true">
              <path d="M4 7h12l-3-3M16 13H4l3 3" />
            </svg>
            Chain A→B
            <i className="switch" aria-hidden="true" />
          </button>
        </div>
      </div>
    </section>
  )
}

export function ProjectActions(p: FileProps) {
  const fileRef = useRef<HTMLInputElement>(null)

  const handleFile = (e: ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0]
    if (f) p.onLoadFile(f)
    e.target.value = ''
  }

  return (
    <div className="file-actions" role="group" aria-label="File">
      <button
        type="button"
        className="btn"
        onClick={() => fileRef.current?.click()}
      >
        <svg viewBox="0 0 20 20" aria-hidden="true">
          <path d="M3 6V4h5l2 2h7v3M3 8h15l-2 8H2z" />
        </svg>
        Load JSON
      </button>
      <input
        ref={fileRef}
        type="file"
        accept="application/json,.json"
        onChange={handleFile}
        hidden
        aria-label="Load pattern file"
      />
      <button type="button" className="btn btn-save" onClick={p.onSave}>
        <svg viewBox="0 0 20 20" aria-hidden="true">
          <path d="M10 3v10m0 0 4-4m-4 4L6 9M3 13v4h14v-4" />
        </svg>
        Save JSON
      </button>
    </div>
  )
}
