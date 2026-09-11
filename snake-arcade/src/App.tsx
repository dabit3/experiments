import { useEffect, useState } from 'react'
import { GameCanvas } from './components/GameCanvas'
import { Icon } from './components/Icon'
import { Overlay } from './components/Overlay'
import { SnakeMascot } from './components/SnakeMascot'
import { Telemetry } from './components/Telemetry'
import { APPLES_PER_SPEED_UP, DIFFICULTIES, MAX_CELLS_PER_SECOND } from './game/engine'
import type { Difficulty, Direction } from './game/types'
import { useArcadeSound } from './game/useArcadeSound'
import { useSnakeGame } from './game/useSnakeGame'

const MODES: { id: Difficulty; caption: string; symbol: string }[] = [
  { id: 'chill', caption: 'Find your flow', symbol: 'I' },
  { id: 'normal', caption: 'The original', symbol: 'II' },
  { id: 'fast', caption: 'All adrenaline', symbol: 'III' },
]
const DIRECTIONS: { direction: Direction; arrow: string }[] = [
  { direction: 'up', arrow: '↑' },
  { direction: 'left', arrow: '←' },
  { direction: 'down', arrow: '↓' },
  { direction: 'right', arrow: '→' },
]
const PHASES = {
  ready: 'Ready when you are',
  playing: 'You’re on a roll',
  paused: 'Take a breather',
  over: 'One more round?',
}

function App() {
  const { state, setDifficulty, start, togglePause, turn } = useSnakeGame()
  const { soundEnabled, toggleSound } = useArcadeSound(state)
  const [fullscreen, setFullscreen] = useState(false)
  const [screenMessage, setScreenMessage] = useState('')
  const locked = state.phase === 'playing' || state.phase === 'paused'
  const level = Math.floor(state.score / APPLES_PER_SPEED_UP) + 1
  const maxSpeed = state.cellsPerSecond >= MAX_CELLS_PER_SECOND
  const progress = state.score % APPLES_PER_SPEED_UP

  useEffect(() => {
    const syncFullscreen = () => setFullscreen(Boolean(document.fullscreenElement))
    document.addEventListener('fullscreenchange', syncFullscreen)
    return () => document.removeEventListener('fullscreenchange', syncFullscreen)
  }, [])

  async function toggleFullscreen() {
    try {
      if (document.fullscreenElement) await document.exitFullscreen()
      else await document.documentElement.requestFullscreen()
      setScreenMessage('')
    } catch {
      setScreenMessage('Fullscreen is unavailable in this browser.')
    }
  }

  return (
    <div className="arcade">
      <header className="topbar">
        <a className="brand" href="./" aria-label="Devin's turn arcade home">
          <span className="brand-mark" aria-hidden="true">
            d<span />
          </span>
          <span>
            Devin's turn<span className="brand-caption">THE BROWSER IS OUR ARCADE</span>
          </span>
        </a>
        <div className="edition">
          <span className="status-dot" /> INTERACTIVE SERIES{' '}
          <span className="edition-number">NO. 001</span>
        </div>
      </header>

      <main>
        <div className="marquee">
          <div className="game-title">
            <h1>
              SNAKE<span className="title-dot">.</span>
            </h1>
            <span className="title-tag">
              ARCADE
              <br />
              EDITION
            </span>
          </div>
          <div className="marquee-right">
            <p>A little nostalgia. A lot of “one more try.”</p>
            <div className="utility-buttons">
              <button
                className="utility-button"
                type="button"
                onClick={toggleSound}
                aria-pressed={soundEnabled}
                aria-label={soundEnabled ? 'Mute sound' : 'Enable sound'}
              >
                <Icon name={soundEnabled ? 'sound' : 'mute'} />
                <span>SOUND {soundEnabled ? 'ON' : 'OFF'}</span>
              </button>
              <button
                className="utility-button square"
                type="button"
                onClick={toggleFullscreen}
                aria-label={fullscreen ? 'Exit fullscreen' : 'Enter fullscreen'}
              >
                <Icon name={fullscreen ? 'shrink' : 'expand'} />
              </button>
            </div>
          </div>
        </div>
        {screenMessage && (
          <p className="screen-message" role="status">
            {screenMessage}
          </p>
        )}

        <div className="cabinet">
          <section className="game-station" aria-label="Snake Arcade">
            <div className="hud">
              <div className="hud-stat">
                <span className="eyebrow">
                  <span className="player-indicator" /> PLAYER 01
                </span>
                <span className="score-value" data-testid="score" key={state.score}>
                  {String(state.score).padStart(3, '0')}
                </span>
              </div>
              <div className="hud-center">
                <span className="mini-snake" aria-hidden="true">
                  S
                </span>
                <span>THE CLASSIC. RECHARGED.</span>
              </div>
              <div className="hud-stat record-stat">
                <span className="eyebrow">
                  <Icon name="trophy" /> PERSONAL BEST
                </span>
                <span className="record-value" data-testid="high-score">
                  {String(state.highScore).padStart(3, '0')}
                </span>
              </div>
            </div>

            <div className="screen-shell">
              <div className="screen-label">
                <span>
                  <span className="status-dot" />{' '}
                  {DIFFICULTIES[state.difficulty].label.toUpperCase()} MODE
                </span>
                <span>20 × 20 PLAYFIELD</span>
              </div>
              <div className="board" data-phase={state.phase}>
                <GameCanvas state={state} />
                <Overlay state={state} onStart={start} onResume={togglePause} />
                {state.phase === 'playing' && state.score > 0 && (
                  <div key={state.score} className="bite-feedback" aria-hidden="true">
                    {progress === 0 ? 'SPEED UP!' : '+1'}
                  </div>
                )}
              </div>
              <div className="screen-footer">
                <span className={`phase-label phase-${state.phase}`}>
                  <span className="status-dot" />
                  {PHASES[state.phase]}
                </span>
                <button
                  type="button"
                  className="pause-button"
                  disabled={!locked}
                  onClick={togglePause}
                  aria-label={state.phase === 'paused' ? 'Resume game' : 'Pause game'}
                >
                  <Icon name={state.phase === 'paused' ? 'play' : 'pause'} />
                  {state.phase === 'paused' ? 'RESUME' : 'PAUSE'}
                  <kbd>P</kbd>
                </button>
              </div>
            </div>

            <div className="control-deck">
              <div className="control-hint">
                <span className="arrow-keys">
                  <kbd>←</kbd>
                  <kbd>↑</kbd>
                  <kbd>↓</kbd>
                  <kbd>→</kbd>
                </span>
                <span>
                  or <strong>W A S D</strong> to steer
                </span>
              </div>
              <span className="deck-note">EAT. GROW. REPEAT.</span>
            </div>
            <div className="touch-controls" aria-label="Touch steering controls">
              {DIRECTIONS.map(({ direction, arrow }) => (
                <button
                  key={direction}
                  className={`touch-${direction}`}
                  type="button"
                  aria-label={`Steer ${direction}`}
                  onClick={() => turn(direction)}
                  disabled={state.phase !== 'playing'}
                >
                  {arrow}
                </button>
              ))}
            </div>
          </section>

          <aside className="side-panel" aria-label="Game options and run details">
            <section className="art-card">
              <div className="art-caption">
                <span>OLD SCHOOL SOUL.</span>
                <span>NEW HIGH SCORES.</span>
              </div>
              <h2>STAY HUNGRY.</h2>
              <SnakeMascot />
              <div className="art-bottom">
                <span className="free-play">FREE PLAY</span>
                <span>
                  NO COINS. JUST REFLEXES.
                  <Icon name="arrow" />
                </span>
              </div>
            </section>

            <section className="mode-panel">
              <div className="section-heading">
                <h2>Pick your pace</h2>
                <span>01 / DIFFICULTY</span>
              </div>
              <div className="difficulty" role="group" aria-label="Difficulty">
                {MODES.map(({ id, caption, symbol }, index) => (
                  <button
                    key={id}
                    type="button"
                    aria-pressed={state.difficulty === id}
                    disabled={locked}
                    className={`difficulty-option${state.difficulty === id ? ' is-selected' : ''}`}
                    onClick={(event) => {
                      setDifficulty(id)
                      if (event.detail > 0) event.currentTarget.blur()
                    }}
                    data-testid={`difficulty-${id}`}
                  >
                    <span className="mode-symbol" aria-hidden="true">
                      {symbol}
                    </span>
                    <span className="mode-name">
                      {DIFFICULTIES[id].label}
                      <small>{caption}</small>
                    </span>
                    <span className="mode-speed">
                      {DIFFICULTIES[id].cellsPerSecond}
                      <small>CELLS / S</small>
                    </span>
                    <span className="mode-radio" aria-hidden="true">
                      {state.difficulty === id ? '●' : index + 1}
                    </span>
                  </button>
                ))}
              </div>
              <p className="mode-note">
                {locked
                  ? 'Pace locked until the next round.'
                  : 'Choose with your mouse or keys 1, 2, 3.'}
              </p>
            </section>

            <section className="run-panel">
              <div className="section-heading">
                <h2>In the zone</h2>
                <span>02 / LIVE RUN</span>
              </div>
              <div className="run-stats">
                <div>
                  <span className="eyebrow">SPEED</span>
                  <strong>
                    {state.cellsPerSecond.toFixed(1)}
                    <small> / s</small>
                  </strong>
                </div>
                <div>
                  <span className="eyebrow">LENGTH</span>
                  <strong>
                    {String(state.snake.length).padStart(2, '0')}
                    <small> cells</small>
                  </strong>
                </div>
                <span className="level-badge">
                  LVL<strong>{String(level).padStart(2, '0')}</strong>
                </span>
              </div>
              <div
                className="speed-meter"
                role="progressbar"
                aria-label="Apples toward next speed increase"
                aria-valuemin={0}
                aria-valuemax={5}
                aria-valuenow={maxSpeed ? 5 : progress}
              >
                {Array.from({ length: 5 }, (_, i) => (
                  <span key={i} className={maxSpeed || i < progress ? 'filled' : ''} />
                ))}
              </div>
              <p className="speed-note">
                <Icon name="bolt" />
                {maxSpeed
                  ? 'Top speed. You’re unstoppable.'
                  : `${5 - progress} ${progress === 4 ? 'apple' : 'apples'} until the next speed boost`}
              </p>
            </section>
            <Telemetry state={state} />
          </aside>
        </div>
        <footer className="page-footer">
          <span>
            <span className="status-dot" /> BUILT FOR THE JOY OF PLAY.
          </span>
          <span>
            A COMPUTER-USE SHOWCASE BY <strong>DEVIN</strong>
            <span className="footer-cross">✳</span>
          </span>
        </footer>
      </main>
    </div>
  )
}

export default App
