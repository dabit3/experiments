import { useCallback, useEffect, useRef, useState, type FormEvent } from 'react'
import './App.css'
import sparky from './assets/sparky.svg'
import { Board } from './components/Board'
import { Counter } from './components/Counter'
import { Face } from './components/Face'
import { useGame } from './hooks/useGame'
import { LEVELS, LEVEL_ORDER, isLevel, type Level } from './lib/board'
import { parseSeed, randomSeed } from './lib/rng'

function readUrl(): { level: Level; seed: number } {
  const params = new URLSearchParams(window.location.search)
  const levelParam = params.get('level')
  return {
    level: isLevel(levelParam) ? levelParam : 'beginner',
    seed: parseSeed(params.get('seed')) ?? randomSeed(),
  }
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
  idle: 'Your first click is always safe. Make your move.',
  playing: 'Trust the numbers. Keep your cool.',
  won: 'Board cleared. Every mine is flagged.',
  lost: 'Boom! A little wiser. Try this board again.',
} as const
const LEVEL_TAGLINES = {
  beginner: 'Find your feet.',
  intermediate: 'Trust your instincts.',
  expert: 'Live on the edge.',
} as const

function Spark({ className = '' }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" aria-hidden="true">
      <path d="m12 0 3.3 8.7L24 12l-8.7 3.3L12 24l-3.3-8.7L0 12l8.7-3.3z" fill="currentColor" />
    </svg>
  )
}

function Trophy() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        d="M7 3h10v7a5 5 0 0 1-10 0V3ZM7 5H3v3a4 4 0 0 0 4 4m10-7h4v3a4 4 0 0 1-4 4M12 15v5m-4 1h8"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

function Mouse({ button }: { button: 'left' | 'right' | 'middle' }) {
  return (
    <svg viewBox="0 0 30 38" aria-hidden="true">
      <rect x="4" y="2" width="22" height="33" rx="11" fill="none" stroke="currentColor" strokeWidth="2" />
      {button === 'left' && <path d="M14 5C9 5 7 9 7 13v4h7V5Z" fill="currentColor" />}
      {button === 'right' && <path d="M16 5c5 0 7 4 7 8v4h-7V5Z" fill="currentColor" />}
      <path d="M15 3v13M5 18h20" fill="none" stroke="currentColor" strokeWidth="1.5" />
      {button === 'middle' && <rect x="12" y="8" width="6" height="8" rx="3" fill="currentColor" />}
    </svg>
  )
}

export default function App() {
  const game = useGame(initial.level, initial.seed)
  const { state, seconds, minesLeft } = game
  const { bestTimes, newRecord } = state
  const [pressing, setPressing] = useState(false)
  const helpDialog = useRef<HTMLDialogElement>(null)

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

  const spec = LEVELS[state.level]
  const revealed = state.board.cells.filter((c) => c.revealed && !c.mine).length
  const safeCells = spec.rows * spec.cols - spec.mines
  const progress = Math.round((revealed / safeCells) * 100)
  const roundTitle =
    state.status === 'won' ? 'YOU SWEPT IT!' : state.status === 'lost' ? 'ONE MORE ROUND?' : 'LET’S PLAY.'

  return (
    <div className={`app level-${state.level} status-${state.status}`}>
      <header className="topbar">
        <a className="brand" href={window.location.pathname} aria-label="Minesweeper Lab home">
          <span className="brand-mark">
            <Spark />
          </span>
          MINESWEEPER<span className="brand-lab">LAB</span>
        </a>
        <span className="topbar-edition">
          THE CLASSICS, RECHARGED. <span>VOL. 01</span>
        </span>
        <button className="help-button" onClick={() => helpDialog.current?.showModal()}>
          <span aria-hidden="true">?</span> How to play
        </button>
      </header>

      <main className="arcade">
        <aside className="player-panel">
          <div className="hero">
            <div className="eyebrow">
              <span /> THE THINKING PERSON’S ARCADE
            </div>
            <h1>
              MINE<span>SWEEPER</span>
              <span className="title-tag">SMALL TILES. BIG THRILLS.</span>
            </h1>
            <div className="mascot-scene">
              <div className="mascot-orbit" aria-hidden="true" />
              <span className="mascot-sticker">
                ALL BRAINS.
                <br />
                NO LUCK?*
              </span>
              <img
                className="mascot"
                src={sparky}
                alt="Sparky, a smiling bomb mascot with golden sneakers and a sparkling fuse"
                draggable={false}
              />
              <span className="mascot-caption">MEET SPARKY. KEEP HIM HAPPY.</span>
            </div>
            <p className="hero-copy">
              Read the numbers. Flag the danger.
              <br />
              One clean sweep from glory.
            </p>
          </div>

          <nav className="levels" aria-label="Difficulty">
            <div className="section-label">
              <span>01 / PICK YOUR CHALLENGE</span>
              <Spark />
            </div>
            {LEVEL_ORDER.map((level, index) => (
              <button
                key={level}
                type="button"
                className={`level-tab${level === state.level ? ' is-active' : ''}`}
                aria-pressed={level === state.level}
                onClick={() => changeLevel(level)}
              >
                <span className="difficulty-icon" aria-hidden="true">
                  {Array.from({ length: 3 }, (_, i) => (
                    <i key={i} className={i <= index ? 'filled' : ''} />
                  ))}
                </span>
                <span className="level-text">
                  <span className="level-name">{LEVELS[level].label}</span>
                  <span className="level-meta">
                    {LEVELS[level].cols}×{LEVELS[level].rows} <b>·</b> {LEVELS[level].mines} mines
                  </span>
                </span>
                <span className="level-arrow" aria-hidden="true">
                  ↗
                </span>
              </button>
            ))}
          </nav>

          <form className="seed-form" onSubmit={applySeed} aria-label="Seed">
            <label htmlFor="seed-input" className="section-label">
              02 / CHOOSE YOUR BOARD
            </label>
            <div className="seed-controls">
              <span className="seed-hash" aria-hidden="true">
                #
              </span>
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
              <button type="submit" className="seed-apply" title="Apply seed" aria-label="Apply seed">
                Go <span aria-hidden="true">↗</span>
              </button>
              <button
                type="button"
                className="shuffle-button"
                onClick={() => game.reset(state.level, randomSeed())}
                title="Random seed"
                aria-label="Random seed"
              >
                <svg viewBox="0 0 24 24" aria-hidden="true">
                  <path
                    d="M3 6h3c4 0 8 12 12 12h3M3 18h3c1 0 2-1 3-2M15 8c1-1 2-2 3-2h3m-3-3 3 3-3 3m0 6 3 3-3 3"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
              </button>
            </div>
            <p>Same seed. Same first click. Same adventure.</p>
          </form>
        </aside>

        <div className="play-area">
          <div className="cabinet-topline">
            <span>
              <i /> PLAYER 01
            </span>
            <span>
              NO COINS NEEDED <Spark />
            </span>
          </div>
          <section className="game-panel" aria-label="Game">
            <div className="cabinet-marquee">
              <div>
                <span className="marquee-kicker">
                  {spec.label.toUpperCase()} / {LEVEL_TAGLINES[state.level]}
                </span>
                <h2>{roundTitle}</h2>
              </div>
              <span className={`round-badge ${state.status}`}>
                <span />
                {state.status === 'idle'
                  ? 'READY WHEN YOU ARE'
                  : state.status === 'playing'
                    ? 'GAME ON'
                    : state.status === 'won'
                      ? 'STAGE CLEAR'
                      : 'TRY AGAIN'}
              </span>
            </div>
            <div className="console">
              <div className="hud">
                <div className="hud-group">
                  <span className="hud-caption">
                    <span className="tiny-flag" aria-hidden="true">
                      ⚑
                    </span>{' '}
                    MINES LEFT
                  </span>
                  <Counter value={minesLeft} label="Mines remaining" testId="mine-counter" />
                </div>
                <div className="face-group">
                  <Face status={state.status} pressing={pressing} onClick={() => game.reset()} />
                  <span>PRESS TO RESTART</span>
                </div>
                <div className="hud-group hud-group-right">
                  <span className="hud-caption">
                    <span aria-hidden="true">◷</span> TIME / SEC
                  </span>
                  <Counter value={seconds} label="Seconds elapsed" testId="timer" />
                </div>
              </div>
              <div className="board-scroll" tabIndex={0} role="region" aria-label="Minefield viewport">
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
              </div>
              <div className="status-bar">
                <p className={`status-line status-${state.status}`} role="status" data-testid="status-line">
                  <span className="status-dot" aria-hidden="true" />
                  {STATUS_TEXT[state.status]}
                  {state.status === 'won' && newRecord && <span className="record-badge">NEW BEST!</span>}
                </p>
                <div className="progress-row">
                  <span>FIELD CLEARED</span>
                  <div
                    className="progress-track"
                    role="progressbar"
                    aria-label="Field cleared"
                    aria-valuemin={0}
                    aria-valuemax={100}
                    aria-valuenow={progress}
                  >
                    <div style={{ width: `${progress}%` }} />
                  </div>
                  <strong>{progress}%</strong>
                </div>
                <dl className="stats">
                  <div>
                    <dt>Safe cells</dt>
                    <dd>
                      {revealed}
                      <span>/{safeCells}</span>
                    </dd>
                  </div>
                  <div>
                    <dt>Chords</dt>
                    <dd>{state.chords}</dd>
                  </div>
                  <div>
                    <dt>Seed</dt>
                    <dd>{state.seed}</dd>
                  </div>
                </dl>
              </div>
            </div>
            <div className="cabinet-controls" aria-label="Quick controls">
              <div>
                <Mouse button="left" />
                <span>
                  <strong>REVEAL</strong>Left click
                </span>
              </div>
              <div>
                <Mouse button="right" />
                <span>
                  <strong>FLAG IT</strong>Right click
                </span>
              </div>
              <div>
                <Mouse button="middle" />
                <span>
                  <strong>CLEAR AROUND</strong>Middle or L + R
                </span>
              </div>
            </div>
            <span className="cabinet-screw screw-left" aria-hidden="true" />
            <span className="cabinet-screw screw-right" aria-hidden="true" />
          </section>

          <section className="records" aria-labelledby="best-heading">
            <div className="records-title">
              <Trophy />
              <h2 id="best-heading">
                PERSONAL
                <br />
                <span>BEST TIMES</span>
              </h2>
            </div>
            <ul className="best-list" data-testid="best-times">
              {LEVEL_ORDER.map((level) => {
                const entry = bestTimes[level]
                return (
                  <li key={level} className={level === state.level ? 'is-current' : ''}>
                    <span className="best-level">{LEVELS[level].label}</span>
                    <strong className={`best-time${entry ? '' : ' is-empty'}`}>
                      {entry ? String(entry.seconds).padStart(3, '0') : '—'}
                      {entry && <small>s</small>}
                    </strong>
                    <span className="best-seed">{entry ? `SEED ${entry.seed}` : 'SET THE FIRST RECORD'}</span>
                  </li>
                )
              })}
            </ul>
          </section>
        </div>
      </main>

      <footer className="footer">
        <span>
          <Spark /> A CLASSIC NEVER GETS OLD. JUST BETTER.
        </span>
        <span>
          *A LITTLE LUCK NEVER HURTS. <b>ONE PLAYER / ENDLESS POSSIBILITIES</b>
        </span>
      </footer>

      <dialog
        ref={helpDialog}
        className="help-dialog"
        aria-labelledby="help-title"
        onClick={(event) => {
          if (event.target === event.currentTarget) helpDialog.current?.close()
        }}
      >
        <div className="help-content">
          <button className="dialog-close" aria-label="Close how to play" onClick={() => helpDialog.current?.close()}>
            ×
          </button>
          <span className="eyebrow">THE RULES ARE SIMPLE.</span>
          <h2 id="help-title">
            STAY SHARP.
            <br />
            <span>STAY IN ONE PIECE.</span>
          </h2>
          <p>
            Reveal every safe tile without hitting a mine. A number tells you how many mines touch that tile, including
            diagonals.
          </p>
          <ul className="instructions">
            <li>
              <Mouse button="left" />
              <div>
                <strong>Reveal a tile</strong>
                <p>Left click. Your first tile and its neighbours are always safe.</p>
              </div>
            </li>
            <li>
              <Mouse button="right" />
              <div>
                <strong>Mark the danger</strong>
                <p>Right click cycles flag → question mark → clear. A flag protects a tile from accidental reveals.</p>
              </div>
            </li>
            <li>
              <Mouse button="middle" />
              <div>
                <strong>Make a clean sweep</strong>
                <p>
                  When a number has enough neighbouring flags, middle click it (or hold left + right) to reveal the
                  rest. Wrong flags can trigger a mine!
                </p>
              </div>
            </li>
          </ul>
          <div className="keyboard-tip">
            <kbd>Enter</kbd> / <kbd>Space</kbd> Reveal or chord <span>·</span> <kbd>F</kbd> Flag focused tile
          </div>
          <p className="restart-tip">
            Hit the smiley to retry the same board. Best times save automatically on this device.
          </p>
          <button className="play-button" onClick={() => helpDialog.current?.close()}>
            GOT IT. LET’S PLAY. <span aria-hidden="true">↗</span>
          </button>
        </div>
      </dialog>
    </div>
  )
}
