import { BASS_HIGH, BASS_LOW, STEPS, isBlackKey, midiToName } from '../types'
import { StepHeader } from './StepGrid'

interface Props {
  bass: (number | null)[]
  currentStep: number | null
  onToggle: (step: number, midi: number) => void
}

const PITCHES = Array.from({ length: BASS_HIGH - BASS_LOW + 1 }, (_, i) => BASS_HIGH - i)

export function PianoRoll(p: Props) {
  const count = p.bass.filter((n) => n !== null).length
  return (
    <div className="piano-roll" role="grid" aria-label="Bass piano roll">
      <div className="grid-row grid-row-head">
        <div className="key-cell key-head">
          <span>Bass · 1 bar</span>
          <span className="key-count">{count} note{count === 1 ? '' : 's'}</span>
        </div>
        <StepHeader currentStep={p.currentStep} />
      </div>
      {PITCHES.map((midi) => {
        const black = isBlackKey(midi)
        const isC = midi % 12 === 0
        return (
          <div key={midi} className={`grid-row roll-row ${black ? 'is-black' : ''} ${isC ? 'is-c' : ''}`} role="row">
            <div className="key-cell">
              <span className="key-name">{midiToName(midi)}</span>
            </div>
            <div className="steps steps-roll">
              {Array.from({ length: STEPS }, (_, s) => {
                const on = p.bass[s] === midi
                return (
                  <button
                    key={s}
                    type="button"
                    role="gridcell"
                    className={`note ${on ? 'is-on' : ''} ${s % 4 === 0 ? 'is-beat' : ''} ${p.currentStep === s ? 'is-now' : ''}`}
                    aria-pressed={on}
                    aria-label={`${midiToName(midi)} step ${s + 1}`}
                    title={`${midiToName(midi)} · step ${s + 1}`}
                    onClick={() => p.onToggle(s, midi)}
                  />
                )
              })}
            </div>
          </div>
        )
      })}
    </div>
  )
}
