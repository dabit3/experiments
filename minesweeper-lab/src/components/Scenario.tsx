import { LEVELS } from '../lib/board'
import { SCENARIO } from '../lib/scenario'
import type { GameState } from '../hooks/useGame'

interface Props {
  state: GameState
  minesLeft: number
  seconds: number
  onLoad: () => void
}

type StepState = 'todo' | 'active' | 'done' | 'failed'

interface Step {
  title: string
  detail: string
  state: StepState
  progress?: { value: number; max: number }
}

function Check({ state }: { state: StepState }) {
  return (
    <span className={`step-check is-${state}`} aria-hidden="true">
      {state === 'done' && (
        <svg viewBox="0 0 16 16">
          <path d="M3.5 8.5l3 3 6-7" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      )}
      {state === 'failed' && (
        <svg viewBox="0 0 16 16">
          <path d="M4.5 4.5l7 7M11.5 4.5l-7 7" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" />
        </svg>
      )}
    </span>
  )
}

export function Scenario({ state, minesLeft, seconds, onLoad }: Props) {
  const spec = LEVELS[SCENARIO.level]
  const onTarget = state.level === SCENARIO.level && state.seed === SCENARIO.seed
  const started = state.status !== 'idle'
  const won = state.status === 'won'
  const lost = state.status === 'lost'
  const safeCells = spec.rows * spec.cols - spec.mines
  const revealed = state.board.cells.filter((c) => c.revealed && !c.mine).length
  const flags = state.board.cells.filter((c) => c.mark === 'flag').length

  const gate = (ok: boolean, active: boolean): StepState => (ok ? 'done' : active ? 'active' : 'todo')

  const steps: Step[] = [
    {
      title: `Open ${spec.label} · seed ${SCENARIO.seed}`,
      detail: `${spec.cols}×${spec.rows}, ${spec.mines} mines. Same seed + same first click = same board.`,
      state: gate(onTarget, true),
    },
    {
      title: 'Left-click to open the board',
      detail: 'The first click and its neighbours are always safe.',
      state: onTarget ? gate(started, true) : 'todo',
    },
    {
      title: 'Right-click to flag every mine',
      detail: 'Flag → question mark → clear. Counter must reach 000.',
      state: !onTarget || !started ? 'todo' : won ? 'done' : lost ? 'failed' : 'active',
      progress: { value: won ? spec.mines : Math.min(flags, spec.mines), max: spec.mines },
    },
    {
      title: `Chord-click at least ${SCENARIO.minChords === 2 ? 'twice' : `${SCENARIO.minChords} times`}`,
      detail: 'Middle-click or left+right on a number whose flags match it.',
      state: !onTarget || !started ? 'todo' : state.chords >= SCENARIO.minChords ? 'done' : lost ? 'failed' : 'active',
      progress: { value: Math.min(state.chords, SCENARIO.minChords), max: SCENARIO.minChords },
    },
    {
      title: 'Reveal every safe cell by deduction',
      detail: lost ? 'Hit a mine — restart the same seed and use what you learned.' : `${safeCells} safe cells, no guessing needed.`,
      state: !onTarget || !started ? 'todo' : won ? 'done' : lost ? 'failed' : 'active',
      progress: { value: revealed, max: safeCells },
    },
    {
      title: 'Win: timer stopped, counter at 000',
      detail: won ? `Cleared in ${seconds}s · counter reads ${String(minesLeft).padStart(3, '0')}` : 'The face puts on sunglasses when the board is clear.',
      state: !onTarget || !started ? 'todo' : won ? 'done' : lost ? 'failed' : 'active',
    },
  ]

  const overall: StepState = !onTarget ? 'todo' : won ? 'done' : lost ? 'failed' : started ? 'active' : 'todo'
  const overallText = { todo: 'Ready', active: 'Running', done: 'Passed', failed: 'Failed' }[overall]
  const done = steps.filter((s) => s.state === 'done').length

  return (
    <section className={`panel scenario is-${overall}`} aria-labelledby="scenario-heading" data-testid="scenario">
      <header className="scenario-head">
        <div>
          <h2 id="scenario-heading">Test scenario</h2>
          <p className="scenario-sub">README scenario · live checklist</p>
        </div>
        <span className={`scenario-badge is-${overall}`} data-testid="scenario-status">
          <span className="dot" />
          {overallText}
        </span>
      </header>

      <ol className="steps">
        {steps.map((step, i) => (
          <li key={i} className={`step is-${step.state}`}>
            <Check state={step.state} />
            <div className="step-body">
              <div className="step-title">
                <span className="step-index">{i + 1}</span>
                <span className="step-text">{step.title}</span>
                {step.progress && (
                  <span className="step-count">
                    {step.progress.value}/{step.progress.max}
                  </span>
                )}
              </div>
              <div className="step-detail">{step.detail}</div>
              {step.progress && (
                <div className="step-progress" role="progressbar" aria-valuemin={0} aria-valuemax={step.progress.max} aria-valuenow={step.progress.value}>
                  <span className="bar" style={{ width: `${(100 * step.progress.value) / step.progress.max}%` }} />
                </div>
              )}
            </div>
          </li>
        ))}
      </ol>

      <footer className="scenario-foot">
        <span className="scenario-summary">
          {done}/{steps.length} steps
        </span>
        {!onTarget && (
          <button type="button" className="btn btn-primary btn-sm" onClick={onLoad}>
            Load scenario
          </button>
        )}
        {lost && (
          <span className="scenario-hint">Press the face to retry seed {SCENARIO.seed}</span>
        )}
      </footer>
    </section>
  )
}
