import { useCallback, useEffect, useState, type FormEvent } from 'react'
import './App.css'
import appIcon from './assets/app-icon.webp'
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
  idle: 'Click any cell to start — the first click is always safe.',
  playing: 'Sweeping…',
  won: 'Board cleared. Every mine is flagged.',
  lost: 'Boom — you hit a mine.',
} as const

function ShuffleIcon() {
  return (
    <svg viewBox="0 0 20 20" aria-hidden="true">
      <path
        d="M3 5h3.2c1.4 0 2.6.7 3.4 1.8L11.4 13c.8 1.1 2 1.8 3.4 1.8H17M3 15h3.2c1.4 0 2.6-.7 3.4-1.8M17 5h-2.2c-1.4 0-2.6.7-3.4 1.8M15 3l2 2-2 2M15 13l2 2-2 2"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

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
  const revealed = state.board.cells.filter((c) => c.revealed && !c.mine).length
  const safeCells = spec.rows * spec.cols - spec.mines

  return (
    <div className={`app level-${state.level} status-${state.status}`}>
      <header className="masthead">
        <div className="brand">
          <img className="brand-icon" src={appIcon} alt="" width={52} height={52} draggable={false} />
          <div className="brand-text">
            <h1>
              Minesweeper <span className="brand-accent">Lab</span>
            </h1>
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

        <form className="seed-form" onSubmit={applySeed} aria-label="Seed">
          <label htmlFor="seed-input" className="seed-label">
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
            className="seed-input"
          />
          <button type="submit" className="btn btn-primary">
            Apply
          </button>
          <button type="button" className="btn btn-icon" onClick={shuffle} title="Random seed" aria-label="Random seed">
            <ShuffleIcon />
          </button>
        </form>
      </header>

      <main className="stage">
        <section className="game-panel" aria-label="Game">
          <div className="hud">
            <div className="hud-group">
              <Counter value={minesLeft} label="Mines remaining" testId="mine-counter" />
              <span className="hud-caption">Mines</span>
            </div>
            <Face status={state.status} pressing={pressing} onClick={() => game.reset()} />
            <div className="hud-group hud-group-right">
              <Counter value={seconds} label="Seconds elapsed" testId="timer" />
              <span className="hud-caption">Time</span>
            </div>
          </div>

          <div className="board-frame">
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
          </div>

          <div className="status-bar">
            <p className={`status-line status-${state.status}`} role="status" data-testid="status-line">
              <span className="status-dot" aria-hidden="true" />
              {STATUS_TEXT[state.status]}
              {state.status === 'won' && (
                <>
                  {' '}
                  <strong>{seconds}s</strong>
                  {newRecord && <span className="record-badge">New best</span>}
                </>
              )}
            </p>
            <dl className="stats">
              <div>
                <dt>Safe cells</dt>
                <dd>
                  {revealed}
                  <span className="stat-of">/{safeCells}</span>
                </dd>
              </div>
              <div>
                <dt>Chords</dt>
                <dd>{state.chords}</dd>
              </div>
              <div>
                <dt>Seed</dt>
                <dd className="stat-seed">{state.seed}</dd>
              </div>
            </dl>
          </div>
        </section>

        <aside className="sidebar">
          <section className="panel" aria-labelledby="best-heading">
            <h2 id="best-heading">Best times</h2>
            <ul className="best-list" data-testid="best-times">
              {LEVEL_ORDER.map((level) => {
                const entry = bestTimes[level]
                return (
                  <li key={level} className={level === state.level ? 'is-current' : ''}>
                    <span className="best-level">{LEVELS[level].label}</span>
                    <span className="best-seed">{entry ? `seed ${entry.seed}` : 'not yet cleared'}</span>
                    <span className={`best-time${entry ? '' : ' is-empty'}`}>{entry ? `${entry.seconds}s` : '—'}</span>
                  </li>
                )
              })}
            </ul>
          </section>

          <section className="panel" aria-labelledby="controls-heading">
            <h2 id="controls-heading">Controls</h2>
            <ul className="controls">
              <li>
                <kbd>Left click</kbd>
                <span>Reveal a cell</span>
              </li>
              <li>
                <kbd>Right click</kbd>
                <span>Flag → question → clear</span>
              </li>
              <li>
                <kbd>Middle</kbd> <em>or</em> <kbd>L + R</kbd>
                <span>Chord-reveal around a satisfied number</span>
              </li>
              <li>
                <kbd>Face</kbd>
                <span>Restart the same seed</span>
              </li>
              <li>
                <kbd>Enter</kbd> <em>/</em> <kbd>F</kbd>
                <span>Reveal / flag the focused cell</span>
              </li>
            </ul>
          </section>
        </aside>
      </main>
    </div>
  )
}
