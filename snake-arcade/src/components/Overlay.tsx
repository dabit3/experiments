import { DIFFICULTIES } from '../game/engine'
import type { Difficulty, GameState } from '../game/types'

interface OverlayProps {
  state: GameState
  onSelectDifficulty: (difficulty: Difficulty) => void
}

function DifficultyPicker({ state, onSelectDifficulty }: OverlayProps) {
  return (
    <div className="difficulty" role="radiogroup" aria-label="Difficulty">
      {(Object.keys(DIFFICULTIES) as Difficulty[]).map((difficulty, index) => (
        <button
          key={difficulty}
          type="button"
          role="radio"
          aria-checked={state.difficulty === difficulty}
          className={`difficulty-option${state.difficulty === difficulty ? ' is-selected' : ''}`}
          onClick={() => onSelectDifficulty(difficulty)}
          data-testid={`difficulty-${difficulty}`}
        >
          <span className="difficulty-key">{index + 1}</span>
          {DIFFICULTIES[difficulty].label}
          <span className="difficulty-speed">{DIFFICULTIES[difficulty].cellsPerSecond} cells/s</span>
        </button>
      ))}
    </div>
  )
}

export function Overlay(props: OverlayProps) {
  const { state } = props

  if (state.phase === 'playing') return null

  if (state.phase === 'paused') {
    return (
      <div className="overlay" data-testid="overlay-paused">
        <h2 className="overlay-title">Paused</h2>
        <p className="overlay-hint">
          Press <kbd>P</kbd> to resume
        </p>
      </div>
    )
  }

  if (state.phase === 'over') {
    return (
      <div className="overlay" data-testid="overlay-game-over">
        <h2 className="overlay-title is-danger">Game Over</h2>
        <p className="overlay-score">
          Final score <strong data-testid="final-score">{state.score}</strong>
        </p>
        {state.isNewHighScore && (
          <p className="overlay-badge" data-testid="new-high-score">
            New high score!
          </p>
        )}
        <p className="overlay-hint blink">
          Press <kbd>Space</kbd> to restart
        </p>
      </div>
    )
  }

  return (
    <div className="overlay" data-testid="overlay-start">
      <h2 className="overlay-title">Snake</h2>
      <p className="overlay-hint blink">
        Press <kbd>Space</kbd> to start
      </p>
      <DifficultyPicker {...props} />
      <p className="overlay-controls">
        Arrows / WASD to steer · <kbd>P</kbd> to pause
      </p>
    </div>
  )
}
