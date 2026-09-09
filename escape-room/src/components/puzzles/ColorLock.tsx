import { COLOR_HEX, type Color } from '../../game'

interface Props {
  dials: Color[]
  solved: boolean
  onCycle: (index: number) => void
  onTry: () => void
}

export function ColorLock({ dials, solved, onCycle, onTry }: Props) {
  return (
    <div className="puzzle lock-puzzle">
      <p className="puzzle-lead">
        {solved
          ? 'The lockbox stands open and empty — its bulb now lives in the lamp.'
          : 'Four enamel dials, stacked in a column. Each turns through six colours. A brass latch waits below.'}
      </p>
      <div className="lock-column">
        {dials.map((c, i) => (
          <button
            key={i}
            className="lock-dial"
            style={{ background: COLOR_HEX[c] }}
            onClick={() => onCycle(i)}
            disabled={solved}
            aria-label={`Dial ${i + 1}: ${c}. Click to turn.`}
          >
            <span className="lock-dial-name">{c}</span>
          </button>
        ))}
      </div>
      <button className="btn btn-primary" onClick={onTry} disabled={solved}>
        Turn the latch
      </button>
    </div>
  )
}
