import { useRef, type CSSProperties, type PointerEvent } from 'react'
import { SIZE, WIN_TILE, type Banner, type Direction, type Tile } from '../lib/game.ts'
import './Board.css'

interface BoardProps {
  tiles: Tile[]
  banner: Banner
  score: number
  canUndo: boolean
  onSwipe: (dir: Direction) => void
  onKeepGoing: () => void
  onUndo: () => void
  onNewGame: () => void
}

const SWIPE_THRESHOLD = 24

export function Board({
  tiles,
  banner,
  score,
  canUndo,
  onSwipe,
  onKeepGoing,
  onUndo,
  onNewGame,
}: BoardProps) {
  const start = useRef<{ x: number; y: number } | null>(null)

  const onPointerDown = (e: PointerEvent<HTMLDivElement>) => {
    start.current = { x: e.clientX, y: e.clientY }
  }

  const onPointerUp = (e: PointerEvent<HTMLDivElement>) => {
    const s = start.current
    start.current = null
    if (!s) return
    const dx = e.clientX - s.x
    const dy = e.clientY - s.y
    if (Math.max(Math.abs(dx), Math.abs(dy)) < SWIPE_THRESHOLD) return
    if (Math.abs(dx) > Math.abs(dy)) onSwipe(dx > 0 ? 'right' : 'left')
    else onSwipe(dy > 0 ? 'down' : 'up')
  }

  const cells = []
  for (let i = 0; i < SIZE * SIZE; i++) cells.push(<div key={i} className="cell" />)

  return (
    <div
      className="board"
      role="grid"
      aria-label="2048 board"
      onPointerDown={onPointerDown}
      onPointerUp={onPointerUp}
      onPointerCancel={() => (start.current = null)}
    >
      <div className="cells">{cells}</div>
      <div className="tiles">
        {tiles.map((t) => (
          <div
            key={t.id}
            className={`tile tile-${t.value > 2048 ? 'super' : t.value} kind-${t.kind}`}
            style={{ '--r': t.row, '--c': t.col } as CSSProperties}
            data-value={t.value}
            data-row={t.row}
            data-col={t.col}
            aria-hidden={t.kind === 'ghost'}
          >
            {t.value}
          </div>
        ))}
      </div>

      {banner !== 'none' && (
        <div className={`banner banner-${banner}`} role="status">
          <div className="banner-title">
            {banner === 'won' ? `You reached ${WIN_TILE}!` : 'Game over'}
          </div>
          <div className="banner-score">Score {score.toLocaleString()}</div>
          <div className="banner-actions">
            {banner === 'won' ? (
              <button type="button" className="btn btn-primary" onClick={onKeepGoing}>
                Keep going
              </button>
            ) : (
              <button
                type="button"
                className="btn btn-primary"
                onClick={onUndo}
                disabled={!canUndo}
              >
                Undo last move
              </button>
            )}
            <button type="button" className="btn" onClick={onNewGame}>
              New game
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
