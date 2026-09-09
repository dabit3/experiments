import type { Stage } from '../../game'

interface Props {
  dials: number[]
  stage: Stage
  onSpin: (index: number, delta: number) => void
  onTry: () => void
}

export function Safe({ dials, stage, onSpin, onTry }: Props) {
  const open = stage >= 4
  const locked = stage < 3
  return (
    <div className="puzzle safe-puzzle">
      <p className="puzzle-lead">
        {open
          ? 'The safe hangs open. The crowbar that was inside has done its work on the rug tacks.'
          : locked
            ? 'A squat steel safe set into the wall. Three numbered wheels, 0 to 9. You have no idea what they should read.'
            : 'Three numbered wheels, 0 to 9, and a handle. Set the combination and turn.'}
      </p>
      <div className="safe-wheels">
        {dials.map((d, i) => (
          <div key={i} className="wheel">
            <button className="btn btn-step" onClick={() => onSpin(i, 1)} disabled={open} aria-label={`Wheel ${i + 1} up`}>
              ▲
            </button>
            <div className="wheel-face" aria-label={`Wheel ${i + 1} reads ${d}`}>
              <span className="ghost">{(d + 9) % 10}</span>
              <span className="digit">{d}</span>
              <span className="ghost">{(d + 1) % 10}</span>
            </div>
            <button className="btn btn-step" onClick={() => onSpin(i, -1)} disabled={open} aria-label={`Wheel ${i + 1} down`}>
              ▼
            </button>
          </div>
        ))}
      </div>
      <button className="btn btn-primary" onClick={onTry} disabled={open || locked}>
        Turn the handle
      </button>
    </div>
  )
}
