import { useCallback, useEffect, useState, type FormEvent } from 'react'
import './App.css'
import { Board } from './components/Board'
import { Counter } from './components/Counter'
import { Face } from './components/Face'
import { useGame } from './hooks/useGame'
import { LEVELS, LEVEL_ORDER, isLevel, type Level } from './lib/board'
import { parseSeed, randomSeed } from './lib/rng'

function readUrl(): { level: Level; seed: number } {
  const params = new URLSearchParams(window.location.search)
  const levelParam = params.get('level')
  const level: Level = isLevel(levelParam) ? levelParam : 'beginner'
  const seed = parseSeed(params.get('seed')) ?? randomSeed()
  return { level, seed }
}

function writeUrl(level: Level, seed: number) {
  const params = new URLSearchParams(window.location.search)
  params.set('level', level)
  params.set('seed', String(seed))
  const next = `${window.location.pathname}?${params.toString()}`
  if (next !== `${window.location.pathname}${window.location.search}`) {
    window.history.replaceState(null, '', next)
  }
}

const initial = readUrl()

const STATUS_TEXT = {
  idle: 'Click any cell to start. The first click is always safe.',
  playing: 'Sweeping…',
  won: 'Cleared! Every mine is flagged.',
  lost: 'Boom — you hit a mine.',
} as const

export default function App() {
  const game = useGame(initial.level, initial.seed)
  const { state, seconds, minesLeft } = game
  const { bestTimes, newRecord } = state
  const [pressing, setPressing] = useState(false)

  useEffect(() => {
    writeUrl(state.level, state.seed)
  }, [state.level, state.seed])

  const changeLevel = useCallback((level: Level) => game.reset(level, state.seed), [game, state.seed])

  const applySeed = useCallback(
    (e: FormEvent<HTMLFormElement>) => {
      e.preventDefault()
      const input = e.currentTarget.elements.namedItem('seed')
      if (!(input instanceof HTMLInputElement)) return
      const parsed = parseSeed(input.value)
      if (parsed === null) {
        input.value = String(state.seed)
        return
      }
      game.reset(state.level, parsed)
    },
    [game, state.level, state.seed],
  )

  const shuffle = useCallback(() => game.reset(state.level, randomSeed()), [game, state.level])

  const spec = LEVELS[state.level]
  const best = bestTimes[state.level]

  return (
    <div className={`app level-${state.level} status-${state.status}`}>
      <header className="masthead">
        <div className="brand">
          <span className="brand-mark" aria-hidden="true" />
          <div>
            <h1>Minesweeper Lab</h1>
            <p className="tagline">Seeded boards · right-click flags · chord reveals</p>
          </div>
        </div>
        <nav className="levels" aria-label="Difficulty">
          {LEVEL_ORDER.map((level) => {
            const s = LEVELS[level]
            return (
              <button
                key={level}
                type="button"
                className={`level-tab${level === state.level ? ' is-active' : ''}`}
                aria-pressed={level === state.level}
                onClick={() => changeLevel(level)}
              >
                <span className="level-name">{s.label}</span>
                <span className="level-meta">
                  {s.cols}×{s.rows} · {s.mines} mines
                </span>
              </button>
            )
          })}
        </nav>
      </header>

      <main className="stage">
        <section className="panel game-panel" aria-label="Game">
          <div className="hud">
            <Counter value={minesLeft} label="Mines remaining" testId="mine-counter" />
            <Face status={state.status} pressing={pressing} onClick={() => game.reset()} />
            <Counter value={seconds} label="Seconds elapsed" testId="timer" />
          </div>
          <Board
            key={`${state.level}-${state.generation}`}
            board={state.board}
            status={state.status}
            exploded={state.exploded}
            onReveal={game.reveal}
            onChord={game.chord}
            onMark={game.mark}
            onPressChange={setPressing}
          />
          <p className={`status-line status-${state.status}`} role="status" data-testid="status-line">
            {STATUS_TEXT[state.status]}
            {state.status === 'won' && (
              <>
                {' '}
                Time <strong>{seconds}s</strong>
                {newRecord && <span className="record-badge">New best time</span>}
              </>
            )}
          </p>
        </section>

        <aside className="sidebar">
          <section className="panel" aria-labelledby="seed-heading">
            <h2 id="seed-heading">Seed</h2>
            <p className="muted">
              Same seed + same first click = same board. The URL updates so you can share or replay it.
            </p>
            <form className="seed-form" onSubmit={applySeed}>
              <label className="visually-hidden" htmlFor="seed-input">
                Seed
              </label>
              <input
                key={state.seed}
                id="seed-input"
                name="seed"
                inputMode="numeric"
                pattern="[0-9]*"
                defaultValue={String(state.seed)}
                aria-label="Seed"
              />
              <button type="submit" className="btn btn-primary">
                Apply
              </button>
              <button type="button" className="btn" onClick={shuffle}>
                Shuffle
              </button>
            </form>
            <dl className="facts">
              <div>
                <dt>Level</dt>
                <dd>{spec.label}</dd>
              </div>
              <div>
                <dt>Grid</dt>
                <dd>
                  {spec.cols}×{spec.rows}
                </dd>
              </div>
              <div>
                <dt>Mines</dt>
                <dd>{spec.mines}</dd>
              </div>
              <div>
                <dt>Seed</dt>
                <dd>
                  <code>{state.seed}</code>
                </dd>
              </div>
            </dl>
          </section>

          <section className="panel" aria-labelledby="best-heading">
            <h2 id="best-heading">Best times</h2>
            <ul className="best-list" data-testid="best-times">
              {LEVEL_ORDER.map((level) => {
                const entry = bestTimes[level]
                return (
                  <li key={level} className={level === state.level ? 'is-current' : ''}>
                    <span className="best-level">{LEVELS[level].label}</span>
                    <span className="best-time">{entry ? `${entry.seconds}s` : '—'}</span>
                    <span className="best-seed">{entry ? `seed ${entry.seed}` : 'not yet cleared'}</span>
                  </li>
                )
              })}
            </ul>
            {best && <p className="muted small">Saved in this browser (localStorage).</p>}
          </section>

          <section className="panel" aria-labelledby="controls-heading">
            <h2 id="controls-heading">Controls</h2>
            <ul className="controls">
              <li>
                <kbd>Left click</kbd> reveal a cell
              </li>
              <li>
                <kbd>Right click</kbd> flag → question → clear
              </li>
              <li>
                <kbd>Middle click</kbd> or <kbd>Left + Right</kbd> on a number whose flags match it: chord-reveal its
                neighbours
              </li>
              <li>
                <kbd>Face</kbd> restart the same seed
              </li>
              <li>
                <kbd>Enter</kbd> / <kbd>F</kbd> reveal / flag the focused cell
              </li>
            </ul>
          </section>
        </aside>
      </main>
    </div>
  )
}
