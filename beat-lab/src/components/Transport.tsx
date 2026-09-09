import { useId, useRef, type ChangeEvent, type CSSProperties } from 'react'
import { BPM_MAX, BPM_MIN, SWING_MAX, type PatternId } from '../types'

interface Props {
  playing: boolean
  bpm: number
  swing: number
  editing: PatternId
  chain: boolean
  nowPlaying: PatternId | null
  onTogglePlay: () => void
  onBpm: (bpm: number) => void
  onSwing: (swing: number) => void
  onEditing: (id: PatternId) => void
  onChain: (on: boolean) => void
  onSave: () => void
  onLoadFile: (file: File) => void
  onClear: () => void
}

export function Transport(p: Props) {
  const bpmId = useId()
  const swingId = useId()
  const fileRef = useRef<HTMLInputElement>(null)

  const handleFile = (e: ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0]
    if (f) p.onLoadFile(f)
    e.target.value = ''
  }

  const bpmPct = ((p.bpm - BPM_MIN) / (BPM_MAX - BPM_MIN)) * 100
  const swingPct = (p.swing / SWING_MAX) * 100

  return (
    <section className="transport" aria-label="Transport">
      <button
        type="button"
        className={`play ${p.playing ? 'is-playing' : ''}`}
        onClick={p.onTogglePlay}
        aria-pressed={p.playing}
        title="Play / stop (Space)"
      >
        {p.playing ? (
          <svg viewBox="0 0 24 24" aria-hidden="true">
            <rect x="6" y="6" width="12" height="12" rx="2" />
          </svg>
        ) : (
          <svg viewBox="0 0 24 24" aria-hidden="true">
            <path d="M7 5.5v13a1 1 0 0 0 1.5.86l11-6.5a1 1 0 0 0 0-1.72l-11-6.5A1 1 0 0 0 7 5.5Z" />
          </svg>
        )}
        <span>{p.playing ? 'Stop' : 'Play'}</span>
      </button>

      <div className="knob">
        <div className="knob-head">
          <label htmlFor={bpmId}>Tempo</label>
          <output htmlFor={bpmId} className="readout">
            {p.bpm}
            <small>BPM</small>
          </output>
        </div>
        <div className="knob-row">
          <button
            type="button"
            className="nudge"
            aria-label="Tempo down"
            onClick={() => p.onBpm(Math.max(BPM_MIN, p.bpm - 1))}
          >
            −
          </button>
          <input
            id={bpmId}
            type="range"
            min={BPM_MIN}
            max={BPM_MAX}
            step={1}
            value={p.bpm}
            style={{ '--pct': `${bpmPct}%` } as CSSProperties}
            onChange={(e) => p.onBpm(Number(e.target.value))}
          />
          <button
            type="button"
            className="nudge"
            aria-label="Tempo up"
            onClick={() => p.onBpm(Math.min(BPM_MAX, p.bpm + 1))}
          >
            +
          </button>
        </div>
      </div>

      <div className="knob knob-swing">
        <div className="knob-head">
          <label htmlFor={swingId}>Swing</label>
          <output htmlFor={swingId} className="readout">
            {p.swing}
            <small>%</small>
          </output>
        </div>
        <div className="knob-row">
          <button
            type="button"
            className="nudge"
            aria-label="Swing down"
            onClick={() => p.onSwing(Math.max(0, p.swing - 1))}
          >
            −
          </button>
          <input
            id={swingId}
            type="range"
            min={0}
            max={SWING_MAX}
            step={1}
            value={p.swing}
            style={{ '--pct': `${swingPct}%` } as CSSProperties}
            onChange={(e) => p.onSwing(Number(e.target.value))}
          />
          <button
            type="button"
            className="nudge"
            aria-label="Swing up"
            onClick={() => p.onSwing(Math.min(SWING_MAX, p.swing + 1))}
          >
            +
          </button>
        </div>
      </div>

      <div className="patterns" role="group" aria-label="Pattern">
        <span className="group-label">Pattern</span>
        <div className="segmented">
          {(['A', 'B'] as PatternId[]).map((id) => (
            <button
              key={id}
              type="button"
              className={p.editing === id ? 'is-active' : ''}
              aria-pressed={p.editing === id}
              onClick={() => p.onEditing(id)}
            >
              {id}
              {p.nowPlaying === id && <i className="dot" aria-label="playing" />}
            </button>
          ))}
        </div>
        <button
          type="button"
          className={`chip ${p.chain ? 'is-active' : ''}`}
          aria-pressed={p.chain}
          onClick={() => p.onChain(!p.chain)}
          title="Play A then B in a loop"
        >
          Chain A→B
        </button>
      </div>

      <div className="file-actions" role="group" aria-label="File">
        <button type="button" className="btn" onClick={p.onSave}>
          Save JSON
        </button>
        <button type="button" className="btn" onClick={() => fileRef.current?.click()}>
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
        <button type="button" className="btn btn-danger" onClick={p.onClear}>
          Clear
        </button>
      </div>
    </section>
  )
}
