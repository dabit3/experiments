import { useCallback, useEffect, useMemo, useState, type FormEvent } from 'react'
import { Certificate, type RunSummary } from './components/Certificate'
import { ProgressBar } from './components/ProgressBar'
import { parseSeed, stageSeed } from './lib/rng'
import { JigsawStage } from './stages/JigsawStage'
import { PathStage } from './stages/PathStage'
import { RotateStage } from './stages/RotateStage'
import { SliderStage } from './stages/SliderStage'
import { TilesStage } from './stages/TilesStage'
import { STAGES, type StageProps } from './stages/types'
import './App.css'

type StageComponent = (props: StageProps) => React.JSX.Element
const STAGE_COMPONENTS: StageComponent[] = [SliderStage, RotateStage, TilesStage, JigsawStage, PathStage]

interface Feedback {
  id: number
  tone: 'fail' | 'pass'
  text: string
}

interface Run {
  phase: 'intro' | 'stage' | 'certificate'
  stage: number
  passed: boolean
  attempts: number[]
  feedback: Feedback | null
  startedAt: number
  finishedAt: number
  printable: boolean
}

const freshRun = (): Run => ({
  phase: 'intro',
  stage: 0,
  passed: false,
  attempts: STAGES.map(() => 1),
  feedback: null,
  startedAt: 0,
  finishedAt: 0,
  printable: false,
})

const PASS_LINES = [
  'Slide accepted. Actuators nominal.',
  'Orientation locked. Gyroscope satisfied.',
  'Classification complete. Cones detected.',
  'Piece seated. Zero-gap fit confirmed.',
  'Corridor traced. Motor control exemplary.',
]

export default function App() {
  const seed = useMemo(() => parseSeed(window.location.search), [])
  const [run, setRun] = useState<Run>(freshRun)
  const [seedInput, setSeedInput] = useState(String(seed))

  useEffect(() => {
    document.title = `Prove You're a Robot · seed ${seed}`
  }, [seed])

  const begin = () => setRun((r) => ({ ...r, phase: 'stage', startedAt: Date.now() }))

  const onPass = useCallback(() => {
    setRun((r) => ({
      ...r,
      passed: true,
      feedback: { id: Date.now(), tone: 'pass', text: PASS_LINES[r.stage] },
    }))
  }, [])

  const onFail = useCallback((reason: string) => {
    setRun((r) => {
      const attempts = [...r.attempts]
      attempts[r.stage] += 1
      return { ...r, attempts, feedback: { id: Date.now(), tone: 'fail', text: reason } }
    })
  }, [])

  const next = () => {
    setRun((r) => {
      if (r.stage + 1 >= STAGES.length) {
        return { ...r, phase: 'certificate', stage: STAGES.length, passed: false, feedback: null, finishedAt: Date.now() }
      }
      return { ...r, stage: r.stage + 1, passed: false, feedback: null }
    })
  }

  const restart = () => setRun(freshRun())

  const changeSeed = (e: FormEvent) => {
    e.preventDefault()
    const n = parseSeed(`?seed=${seedInput}`)
    const url = new URL(window.location.href)
    url.searchParams.set('seed', String(n))
    window.location.assign(url.toString())
  }

  const stageMeta = STAGES[Math.min(run.stage, STAGES.length - 1)]
  const Stage = STAGE_COMPONENTS[Math.min(run.stage, STAGES.length - 1)]

  const summary: RunSummary | null =
    run.phase === 'certificate'
      ? { seed, attempts: run.attempts, elapsedMs: run.finishedAt - run.startedAt, finishedAt: run.finishedAt }
      : null

  return (
    <div className={`app${run.printable ? ' is-printable' : ''}`}>
      <header className="app__header">
        <div className="brand">
          <span className="brand__mark" aria-hidden="true">
            <svg viewBox="0 0 40 40" width={36} height={36}>
              <rect x={7} y={12} width={26} height={20} rx={5} fill="currentColor" />
              <circle cx={16} cy={21} r={3} fill="#041018" />
              <circle cx={24} cy={21} r={3} fill="#041018" />
              <path d="M15 27h10" stroke="#041018" strokeWidth={2.5} strokeLinecap="round" />
              <path d="M20 12V6" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round" />
              <circle cx={20} cy={5} r={2.5} fill="currentColor" />
            </svg>
          </span>
          <div>
            <h1 className="brand__title">Prove You&rsquo;re a Robot</h1>
            <p className="brand__sub">A reverse-CAPTCHA gauntlet. Humans need not apply.</p>
          </div>
        </div>
        <form className="seed" onSubmit={changeSeed}>
          <label htmlFor="seed">seed</label>
          <input
            id="seed"
            className="seed__input"
            inputMode="numeric"
            value={seedInput}
            onChange={(e) => setSeedInput(e.target.value)}
            aria-label="Seed"
          />
          <button type="submit" className="btn seed__go">
            Load
          </button>
        </form>
      </header>

      <div className="app__progress">
        <ProgressBar current={run.stage} currentPassed={run.passed} />
      </div>

      <main className="app__main">
        {run.phase === 'intro' && (
          <section className="card intro">
            <span className="card__kicker">Verification required</span>
            <h2 className="intro__title">
              Before you continue, we need to make sure you&rsquo;re <em>not</em> a human.
            </h2>
            <p className="intro__text">
              Five short challenges test the sub-pixel motor control, angular judgement and steady hand that only a
              machine possesses. Content is generated deterministically from <code>?seed={seed}</code>, so the exact
              same gauntlet can be replayed.
            </p>
            <ul className="intro__list">
              {STAGES.map((s, i) => (
                <li key={s.id}>
                  <span className="intro__num">{i + 1}</span>
                  <span>
                    <b>{s.title}</b> <span className="intro__hint">— {s.instruction}</span>
                  </span>
                </li>
              ))}
            </ul>
            <button className="btn btn--primary btn--lg" onClick={begin} autoFocus>
              Begin verification
            </button>
          </section>
        )}

        {run.phase === 'stage' && (
          <section className="card stage" key={stageMeta.id}>
            <header className="stage__head">
              <div>
                <span className="card__kicker">
                  Stage {run.stage + 1} of {STAGES.length} · {stageMeta.label}
                </span>
                <h2 className="stage__title">{stageMeta.title}</h2>
                <p className="stage__instruction">{stageMeta.instruction}</p>
              </div>
              <div className="stage__attempt">
                <span>attempt</span>
                <b>{run.attempts[run.stage]}</b>
              </div>
            </header>

            <div className={`stage__body${run.passed ? ' is-passed' : ''}`}>
              <Stage seed={stageSeed(seed, run.stage)} locked={run.passed} onPass={onPass} onFail={onFail} />
            </div>

            <div className="stage__foot">
              {run.feedback ? (
                <div key={run.feedback.id} className={`feedback feedback--${run.feedback.tone}`} role="status">
                  <span className="feedback__icon" aria-hidden="true">
                    {run.feedback.tone === 'pass' ? '✓' : '✕'}
                  </span>
                  <span className="feedback__text">
                    <b>{run.feedback.tone === 'pass' ? 'VERIFIED' : 'REJECTED'}</b> {run.feedback.text}
                    {run.feedback.tone === 'fail' && ' Try again.'}
                  </span>
                </div>
              ) : (
                <div className="feedback feedback--idle" role="status">
                  <span className="feedback__icon" aria-hidden="true">
                    ◦
                  </span>
                  <span className="feedback__text">Awaiting input…</span>
                </div>
              )}
              <button className="btn btn--ok btn--lg" onClick={next} disabled={!run.passed} autoFocus={run.passed}>
                {run.stage + 1 === STAGES.length ? 'Claim certificate' : 'Continue'}
                <span aria-hidden="true">→</span>
              </button>
            </div>
          </section>
        )}

        {summary && (
          <Certificate
            summary={summary}
            printable={run.printable}
            onTogglePrintable={() => setRun((r) => ({ ...r, printable: !r.printable }))}
            onRestart={restart}
          />
        )}
      </main>

      <footer className="app__footer">
        <span>No network. No sound. No humans.</span>
        <span>
          seed <b>{seed}</b> · deterministic content
        </span>
      </footer>
    </div>
  )
}
