import { COLOR_HEX, MORSE, PAINTING, type Stage } from '../../game'

export function PaintingView() {
  return (
    <div className="puzzle painting-view">
      <div className="painting-big">
        {PAINTING.map((c, i) => (
          <div key={i} className="stripe" style={{ background: COLOR_HEX[c] }}>
            <span className="stripe-label">{c}</span>
          </div>
        ))}
        <div className="canvas-moon" />
        <div className="canvas-reeds" />
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

export function LampView({ on, stage }: { on: boolean; stage: Stage }) {
  return (
    <div className="puzzle lamp-view">
      <div className={`lamp-big ${on ? 'on' : ''}`}>
        <span className="lamp-big-bulb" />
      </div>
      {stage < 2 && <p className="puzzle-lead">A green-shaded desk lamp. The socket is empty — no bulb.</p>}
      {stage === 2 && (
        <p className="puzzle-lead">
          The new bulb flickers in a pattern that repeats: short blinks and long blinks with pauses between letters.
          Watch a full cycle, then take the word to the typewriter.
        </p>
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
