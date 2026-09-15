import type { CSSProperties } from 'react'
import { STEPS, TRACKS, type Velocity } from '../types'
import type { ReferencePattern, StepDiff } from '../reference'

interface Props {
  reference: ReferencePattern
  referenceDrums: Velocity[][]
  result: StepDiff[] | null
  onCompare: () => void
}

export function ReferencePanel(p: Props) {
  return (
    <aside className="reference" aria-label="Reference pattern">
      <header className="ref-head">
        <div>
          <span className="eyebrow">Reference pattern</span>
          <div className="ref-title">
            <h2>{p.reference.name}</h2>
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <path d="M5 6v12M10 3v18M15 8v8M20 5v14" />
            </svg>
          </div>
          <p className="ref-desc">{p.reference.description}</p>
          <div className="ref-meta">
            <span>{p.reference.bpm} BPM</span>
            <span>8 voices</span>
            <span>1 bar</span>
          </div>
        </div>
      </header>

      <div
        className="ref-grid"
        role="img"
        aria-label={`${p.reference.name} target pattern`}
      >
        <div className="ref-row ref-row-head">
          <span />
          <div className="ref-steps">
            {Array.from({ length: STEPS }, (_, s) => (
              <span
                key={s}
                className={`ref-num ${s % 4 === 0 ? 'is-beat' : ''}`}
              >
                {s + 1}
              </span>
            ))}
          </div>
        </div>
        {TRACKS.map((track, t) => (
          <div
            key={track.id}
            className="ref-row"
            style={{ '--track': `var(--track-${track.id})` } as CSSProperties}
          >
            <span className="ref-name">{track.short}</span>
            <div className="ref-steps">
              {p.referenceDrums[t].map((v, s) => (
                <span
                  key={s}
                  className={`ref-step ${v > 0 ? 'is-on' : ''} ${s % 4 === 0 ? 'is-beat' : ''}`}
                />
              ))}
            </div>
          </div>
        ))}
      </div>

      <p className="ref-instruction">
        Recreate these steps in the drum grid, then check your pattern.
      </p>
      <button
        type="button"
        className="btn btn-primary compare"
        onClick={p.onCompare}
      >
        Compare with reference
        <svg viewBox="0 0 20 20" aria-hidden="true">
          <path d="M3 10h13m-5-5 5 5-5 5" />
        </svg>
      </button>

      {p.result !== null && (
        <div
          className={`compare-result ${p.result.length === 0 ? 'is-match' : 'is-diff'}`}
          role="status"
        >
          {p.result.length === 0 ? (
            <>
              <strong>Perfect match</strong>
              <span>0 differences — every step matches the reference.</span>
            </>
          ) : (
            <>
              <strong>
                {p.result.length} step{p.result.length === 1 ? '' : 's'} differ
              </strong>
              <ul className="diff-list">
                {p.result.map((d) => (
                  <li
                    key={`${d.track}-${d.step}`}
                    style={
                      {
                        '--track': `var(--track-${TRACKS[d.track].id})`,
                      } as CSSProperties
                    }
                  >
                    <span className="diff-swatch" />
                    <span className="diff-track">{TRACKS[d.track].name}</span>
                    <span className="diff-step">step {d.step + 1}</span>
                    <span className={`diff-kind is-${d.kind}`}>{d.kind}</span>
                  </li>
                ))}
              </ul>
            </>
          )}
        </div>
      )}
      <div className="reference-guide">
        <h3>A little feel goes a long way.</h3>
        <p>
          Use swing to loosen the timing. Right-click a drum step to give it a
          softer touch.
        </p>
        <div className="velocity-legend" aria-hidden="true">
          {['Soft', 'Medium', 'Full'].map((label, index) => (
            <span key={label}>
              <i className={`velocity-sample velocity-${index + 1}`} />
              {label}
            </span>
          ))}
        </div>
      </div>
    </aside>
  )
}
