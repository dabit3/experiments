import { CIPHER_TEXT, caesar, type Stage } from '../../game'
import { Dial } from '../Room'

interface Props {
  stage: Stage
  shift: number
  onShift: (shift: number) => void
}

export function Sampler({ stage, shift, onShift }: Props) {
  const hasDial = stage >= 5
  const solved = stage >= 6
  const decoded = caesar(CIPHER_TEXT, -shift)

  return (
    <div className="puzzle sampler-puzzle">
      <div className="sampler-big">
        <p>{CIPHER_TEXT}</p>
        <small>cross-stitch, unsigned</small>
      </div>
      {!hasDial ? (
        <p className="puzzle-lead">
          Someone spent a long winter stitching gibberish. The letters look shifted — as if each were a few steps
          along the alphabet from where it belongs. You would need some way to turn them back.
        </p>
      ) : (
        <>
          <p className="puzzle-lead">
            {solved
              ? 'The dial rests on the right notch. The sampler reads plainly now.'
              : 'The brass dial from the drawer. Each notch turns every letter back one step.'}
          </p>
          <div className="dial-row">
            <button className="btn btn-step" onClick={() => onShift(shift - 1)} disabled={solved} aria-label="Turn dial back">
              −
            </button>
            <div className="dial-wrap">
              <Dial angle={(shift * 360) / 26} />
              <span className="dial-readout">shift {shift}</span>
            </div>
            <button className="btn btn-step" onClick={() => onShift(shift + 1)} disabled={solved} aria-label="Turn dial forward">
              +
            </button>
          </div>
          <div className={`decoded ${solved ? 'solved' : ''}`} aria-live="polite">
            {decoded}
          </div>
        </>
      )}
    </div>
  )
}
