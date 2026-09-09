import { MORSE, PAINTING, type Stage } from '../../game'
import type { Pulse } from '../../hooks/useMorseLamp'
import { PaintingArt } from '../Room'

export function PaintingView() {
  return (
    <div className="puzzle painting-view">
      <div className="painting-big">
        <PaintingArt />
        <div className="stripe-labels" aria-hidden>
          {PAINTING.map((c, i) => (
            <span key={i} className="stripe-label">
              {c}
            </span>
          ))}
        </div>
      </div>
      <p className="puzzle-lead">
        Four broad bands of colour laid one above the other, sky to water. The painter left a note on the back of the
        frame: <em>“Read it top to bottom, as you would a column of dials.”</em>
      </p>
    </div>
  )
}

export function PosterView() {
  const letters = Object.keys(MORSE)
  return (
    <div className="puzzle poster-view">
      <p className="puzzle-lead">A printed reference card. Dot is a short blink, dash is a long one.</p>
      <div className="morse-table">
        {letters.map((l) => (
          <div key={l} className="morse-cell">
            <strong>{l}</strong>
            <span>{MORSE[l].replace(/\./g, '·').replace(/-/g, '−')}</span>
          </div>
        ))}
      </div>
    </div>
  )
}

export function LampView({ on, tape, stage }: { on: boolean; tape: Pulse[]; stage: Stage }) {
  return (
    <div className="puzzle lamp-view">
      <div className={`lamp-big ${on ? 'on' : ''}`}>
        <span className="lamp-big-bulb" />
      </div>
      {stage < 2 && <p className="puzzle-lead">A green-shaded desk lamp. The socket is empty — no bulb.</p>}
      {stage === 2 && (
        <>
          <p className="puzzle-lead">
            The new bulb flickers in a pattern that repeats: short blinks and long blinks with pauses between letters.
            Watch a full cycle, then take the word to the typewriter.
          </p>
          <div className="lamp-tape" aria-label="Recorded blink pattern" role="img">
            {tape.length === 0 && <span className="lamp-tape-empty">watching…</span>}
            {tape.map((pulse, i) => (
              <span
                key={i}
                className={`lamp-tape-seg ${pulse.on ? 'lit' : ''}`}
                style={{ flexBasis: `${pulse.units * 0.7}rem` }}
              />
            ))}
          </div>
          <p className="puzzle-note">The strip above records each phase as it happens: lit bars are blinks, dark gaps are pauses. A long lit bar is a dash; a short one is a dot.</p>
        </>
      )}
      {stage > 2 && <p className="puzzle-lead">The lamp burns steadily now. Its message has been received.</p>}
    </div>
  )
}

export function DrawerView({ open }: { open: boolean }) {
  return (
    <div className="puzzle drawer-view">
      {open ? (
        <p className="puzzle-lead">
          The drawer is open. The brass cipher dial that was inside has been fitted beneath the sampler on the wall.
        </p>
      ) : (
        <p className="puzzle-lead">
          A single desk drawer with a small brass keyhole. Locked. Whatever fits it is small, and probably not far
          away.
        </p>
      )}
    </div>
  )
}
