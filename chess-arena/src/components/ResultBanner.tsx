import type { GameResult } from '../lib/useGame'
import { describeResult } from '../lib/result'

interface ResultBannerProps {
  result: GameResult
  moveCount: number
  onNewGame: () => void
  onDismiss: () => void
}

export function ResultBanner({ result, moveCount, onNewGame, onDismiss }: ResultBannerProps) {
  const { title, subtitle, tone } = describeResult(result)
  return (
    <div className="overlay banner-overlay" role="dialog" aria-modal="true" aria-live="assertive">
      <div className={`banner ${tone}`} data-testid="result-banner">
        <div className="banner-glyph" aria-hidden="true">
          {tone === 'win' ? '♔' : tone === 'loss' ? '♚' : '½'}
        </div>
        <h2>{title}</h2>
        <p>{subtitle}</p>
        <p className="banner-meta">
          {Math.ceil(moveCount / 2)} move{moveCount === 2 ? '' : 's'} ·{' '}
          {result.kind === 'checkmate' ? (result.winner === 'w' ? '1-0' : '0-1') : '½-½'}
        </p>
        <div className="banner-actions">
          <button type="button" className="btn primary" onClick={onNewGame}>
            New game
          </button>
          <button type="button" className="btn ghost" onClick={onDismiss}>
            View board
          </button>
        </div>
      </div>
    </div>
  )
}
