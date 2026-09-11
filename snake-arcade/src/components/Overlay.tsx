import type { GameState } from '../game/types'
import { Icon } from './Icon'

interface OverlayProps {
  state: GameState
  onStart: () => void
  onResume: () => void
}

export function Overlay({ state, onStart, onResume }: OverlayProps) {
  if (state.phase === 'playing') return null
  const paused = state.phase === 'paused'
  const over = state.phase === 'over'

  return (
    <div
      className={`overlay overlay-${state.phase}`}
      data-testid={paused ? 'overlay-paused' : over ? 'overlay-game-over' : 'overlay-start'}
    >
      <div className="overlay-content">
        <span className="overlay-kicker">
          {paused
            ? 'GOOD THINGS CAN WAIT'
            : over
              ? 'THAT WAS A GOOD RUN'
              : 'A CLASSIC WITH A FRESH BITE'}
        </span>
        <div className={`overlay-emblem ${over ? 'is-danger' : ''}`}>
          <Icon name={paused ? 'pause' : over ? 'trophy' : 'apple'} />
        </div>
        <h2 className="overlay-title">
          {paused ? (
            'PAUSED.'
          ) : over ? (
            <>
              GAME
              <br />
              <span>OVER.</span>
            </>
          ) : (
            <>
              ONE MORE
              <br />
              <span>BITE.</span>
            </>
          )}
        </h2>
        {over ? (
          <div className="result-row">
            <div>
              <span>FINAL SCORE</span>
              <strong data-testid="final-score">{String(state.score).padStart(3, '0')}</strong>
            </div>
            <div>
              <span>BEST SCORE</span>
              <strong>{String(state.highScore).padStart(3, '0')}</strong>
            </div>
          </div>
        ) : (
          <p className="overlay-description">
            {paused ? (
              'Your next apple isn’t going anywhere.'
            ) : (
              <>
                Chase the apples. Beat your best.
                <br />
                Try not to eat your own tail.
              </>
            )}
          </p>
        )}
        {over && state.isNewHighScore && (
          <span className="overlay-badge" data-testid="new-high-score">
            <Icon name="trophy" />
            New high score!
          </span>
        )}
        <button className="start-button" type="button" onClick={paused ? onResume : onStart}>
          <Icon name="play" />
          <span>{paused ? 'BACK TO IT' : over ? 'GO AGAIN' : 'LET’S PLAY'}</span>
          <Icon name="arrow" />
        </button>
        <p className="overlay-hint">
          Press <kbd>{paused ? 'P' : 'Space'}</kbd> to{' '}
          {paused ? 'resume' : over ? 'restart' : 'start'}
        </p>
      </div>
      {!paused && !over && (
        <span className="overlay-bottom">SIMPLE RULES. ENDLESS “ONE MORE.”</span>
      )}
    </div>
  )
}
