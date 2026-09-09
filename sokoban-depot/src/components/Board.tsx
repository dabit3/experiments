import type { Board as BoardModel, GameState } from '../game/engine'
import { isTarget } from '../game/engine'
import { CrateSprite, WallTile, WorkerSprite } from './Sprites'

interface BoardProps {
  board: BoardModel
  state: GameState
  stuckIds: Set<number>
  /** Board pixels available; the tile size is derived from it. */
  maxWidth: number
  maxHeight: number
}

function tileSizeFor(board: BoardModel, maxWidth: number, maxHeight: number) {
  const size = Math.floor(Math.min(maxWidth / board.width, maxHeight / board.height))
  return Math.max(32, Math.min(80, size))
}

export function Board({ board, state, stuckIds, maxWidth, maxHeight }: BoardProps) {
  const tile = tileSizeFor(board, maxWidth, maxHeight)
  const style = {
    '--tile': `${tile}px`,
    width: board.width * tile,
    height: board.height * tile,
  } as React.CSSProperties

  const tiles: React.ReactNode[] = []
  for (let y = 0; y < board.height; y++) {
    for (let x = 0; x < board.width; x++) {
      const key = `${x},${y}`
      const pos = { x, y }
      if (board.walls[y][x]) {
        tiles.push(
          <div key={key} className="tile tile-wall" style={{ left: x * tile, top: y * tile }}>
            <WallTile />
          </div>,
        )
      } else if (board.floor[y][x]) {
        const target = isTarget(board, pos)
        tiles.push(
          <div
            key={key}
            className={`tile tile-floor${target ? ' tile-target' : ''}`}
            style={{ left: x * tile, top: y * tile }}
          >
            {target && <span className="target-mark" />}
          </div>,
        )
      }
    }
  }

  return (
    <div className="board" style={style} role="img" aria-label="Sokoban board">
      {tiles}
      {state.crates.map((c) => {
        const onTarget = isTarget(board, c)
        const stuck = stuckIds.has(c.id)
        return (
          <div
            key={`crate-${c.id}`}
            className={`entity crate${onTarget ? ' on-target' : ''}${stuck ? ' stuck' : ''}`}
            style={{ transform: `translate(${c.x * tile}px, ${c.y * tile}px)` }}
          >
            <CrateSprite />
          </div>
        )
      })}
      <div
        className={`entity worker facing-${state.facing}`}
        style={{ transform: `translate(${state.player.x * tile}px, ${state.player.y * tile}px)` }}
      >
        <span key={state.moves} className="worker-step">
          <WorkerSprite facing={state.facing} />
        </span>
      </div>
    </div>
  )
}
