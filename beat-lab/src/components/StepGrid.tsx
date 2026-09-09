import type { CSSProperties, MouseEvent } from 'react'
import { STEPS, TRACKS, VELOCITY_LABEL, type Velocity } from '../types'

interface Props {
  drums: Velocity[][]
  muted: boolean[]
  soloed: boolean[]
  currentStep: number | null
  onToggle: (track: number, step: number) => void
  onCycleVelocity: (track: number, step: number) => void
  onMute: (track: number) => void
  onSolo: (track: number) => void
}

export function StepHeader({ currentStep }: { currentStep: number | null }) {
  return (
    <div className="step-header" aria-hidden="true">
      {Array.from({ length: STEPS }, (_, s) => (
        <span
          key={s}
          className={`step-num ${s % 4 === 0 ? 'is-beat' : ''} ${currentStep === s ? 'is-now' : ''}`}
        >
          {s + 1}
        </span>
      ))}
    </div>
  )
}

export function StepGrid(p: Props) {
  const anySolo = p.soloed.some(Boolean)

  const onContext = (e: MouseEvent, t: number, s: number) => {
    e.preventDefault()
    p.onCycleVelocity(t, s)
  }

  return (
    <div className="grid" role="grid" aria-label="Drum step grid">
      <div className="grid-row grid-row-head">
        <div className="track-cell" />
        <StepHeader currentStep={p.currentStep} />
      </div>
      {TRACKS.map((track, t) => {
        const silenced = anySolo ? !p.soloed[t] : p.muted[t]
        return (
          <div
            key={track.id}
            className={`grid-row ${silenced ? 'is-silenced' : ''}`}
            role="row"
            style={{ '--track': track.color } as CSSProperties}
          >
            <div className="track-cell">
              <span className="track-swatch" />
              <span className="track-name">{track.name}</span>
              <span className="track-short">{track.short}</span>
              <div className="track-toggles">
                <button
                  type="button"
                  className={`ms ms-mute ${p.muted[t] ? 'is-active' : ''}`}
                  aria-pressed={p.muted[t]}
                  aria-label={`Mute ${track.name}`}
                  onClick={() => p.onMute(t)}
                >
                  M
                </button>
                <button
                  type="button"
                  className={`ms ms-solo ${p.soloed[t] ? 'is-active' : ''}`}
                  aria-pressed={p.soloed[t]}
                  aria-label={`Solo ${track.name}`}
                  onClick={() => p.onSolo(t)}
                >
                  S
                </button>
              </div>
            </div>
            <div className="steps">
              {p.drums[t].map((vel, s) => (
                <button
                  key={s}
                  type="button"
                  role="gridcell"
                  className={`step v${vel} ${s % 4 === 0 ? 'is-beat' : ''} ${p.currentStep === s ? 'is-now' : ''}`}
                  aria-label={`${track.name} step ${s + 1}: ${VELOCITY_LABEL[vel]}`}
                  aria-pressed={vel > 0}
                  title={`${track.name} · step ${s + 1} · ${VELOCITY_LABEL[vel]}\nLeft click: toggle · Right click: velocity`}
                  onClick={() => p.onToggle(t, s)}
                  onContextMenu={(e) => onContext(e, t, s)}
                >
                  <span className="step-fill" />
                </button>
              ))}
            </div>
          </div>
        )
      })}
    </div>
  )
}
