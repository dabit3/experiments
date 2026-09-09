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
          <span className="eyebrow">Reference</span>
          <h2>{p.reference.name}</h2>
          <p className="ref-desc">
            {p.reference.description} Suggested tempo {p.reference.bpm} BPM.
          </p>
        </div>
      </header>

      <div className="ref-grid" role="img" aria-label={`${p.reference.name} target pattern`}>
        <div className="ref-row ref-row-head">
          <span />
          <div className="ref-steps">
            {Array.from({ length: STEPS }, (_, s) => (
              <span key={s} className={`ref-num ${s % 4 === 0 ? 'is-beat' : ''}`}>
                {s + 1}
              </span>
            ))}
          </div>
        </div>
        {TRACKS.map((track, t) => (
          <div key={track.id} className="ref-row" style={{ '--track': track.color } as CSSProperties}>
            <span className="ref-name">{track.short}</span>
            <div className="ref-steps">
              {p.referenceDrums[t].map((v, s) => (
                <span key={s} className={`ref-step ${v > 0 ? 'is-on' : ''} ${s % 4 === 0 ? 'is-beat' : ''}`} />
              ))}
            </div>
          </div>
        ))}
      </div>

      <button type="button" className="btn btn-primary compare" onClick={p.onCompare}>
        Compare with reference
      </button>

      {p.result !== null && (
        <div className={`compare-result ${p.result.length === 0 ? 'is-match' : 'is-diff'}`} role="status">
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
                  <li key={`${d.track}-${d.step}`} style={{ '--track': TRACKS[d.track].color } as CSSProperties}>
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
    </aside>
  )
}
