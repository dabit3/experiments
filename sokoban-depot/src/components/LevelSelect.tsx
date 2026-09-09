import { useMemo } from 'react'
import { crateAt, isTarget, parseLevel } from '../game/engine'
import { LEVELS, type LevelDef } from '../game/levels'
import { isUnlocked, type Progress } from '../game/progress'
import { CrateIcon } from './Sprites'
import { Stars } from './Stars'

interface LevelSelectProps {
  progress: Progress
  onPlay: (levelId: number) => void
  onReset: () => void
}

function MiniMap({ level }: { level: LevelDef }) {
  const { board, state } = useMemo(() => parseLevel(level.rows), [level])
  const cells: React.ReactNode[] = []
  for (let y = 0; y < board.height; y++) {
    for (let x = 0; x < board.width; x++) {
      const pos = { x, y }
      let cls = 'mm-empty'
      if (board.walls[y][x]) cls = 'mm-wall'
      else if (board.floor[y][x]) {
        const crate = crateAt(state, pos)
        const target = isTarget(board, pos)
        if (state.player.x === x && state.player.y === y) cls = 'mm-player'
        else if (crate && target) cls = 'mm-crate-on'
        else if (crate) cls = 'mm-crate'
        else if (target) cls = 'mm-target'
        else cls = 'mm-floor'
      }
      cells.push(<span key={`${x},${y}`} className={`mm ${cls}`} />)
    }
  }
  const cell = Math.floor(Math.min(120 / board.height, 200 / board.width))
  return (
    <div className="minimap-wrap" aria-hidden="true">
      <div
        className="minimap"
        style={{
          gridTemplateColumns: `repeat(${board.width}, ${cell}px)`,
          gridAutoRows: `${cell}px`,
        }}
      >
        {cells}
      </div>
    </div>
  )
}

export function LevelSelect({ progress, onPlay, onReset }: LevelSelectProps) {
  const earned = Object.values(progress).reduce((sum, r) => sum + r.stars, 0)
  const completed = Object.keys(progress).length

  return (
    <section className="level-select">
      <header className="ls-header">
        <div>
          <h2>Pick a warehouse</h2>
          <p className="muted">
            {completed} of {LEVELS.length} levels cleared · <strong className="accent">{earned}</strong> / {LEVELS.length * 3}{' '}
            stars
          </p>
        </div>
        <button className="btn btn-ghost" onClick={onReset} disabled={completed === 0}>
          Reset progress
        </button>
      </header>

      <ul className="level-grid">
        {LEVELS.map((level) => {
          const result = progress[level.id]
          const unlocked = isUnlocked(progress, level.id)
          return (
            <li key={level.id}>
              <button
                className={`level-card${unlocked ? '' : ' locked'}${result ? ' cleared' : ''}`}
                onClick={() => unlocked && onPlay(level.id)}
                disabled={!unlocked}
                aria-label={`Level ${level.id}: ${level.name}${unlocked ? '' : ' (locked)'}`}
                data-level={level.id}
              >
                <div className="lc-top">
                  <span className="lc-number">{String(level.id).padStart(2, '0')}</span>
                  <Stars count={result?.stars ?? 0} size="sm" />
                </div>
                <MiniMap level={level} />
                <div className="lc-bottom">
                  <span>
                    <span className="lc-name">{level.name}</span>
                    <span className="lc-meta">
                      {result ? (
                        <>
                          best <strong>{result.bestMoves}</strong> · par {level.par}
                        </>
                      ) : (
                        <>par {level.par} moves</>
                      )}
                    </span>
                  </span>
                  {result && (
                    <span className="lc-badge">
                      <CrateIcon className="lc-badge-icon" /> cleared
                    </span>
                  )}
                </div>
                {!unlocked && (
                  <span className="lc-lock" aria-hidden="true">
                    <svg viewBox="0 0 24 24">
                      <path d="M7 10V8a5 5 0 0 1 10 0v2h1a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h1zm2 0h6V8a3 3 0 0 0-6 0v2z" />
                    </svg>
                    Clear level {level.id - 1} to unlock
                  </span>
                )}
              </button>
            </li>
          )
        })}
      </ul>
    </section>
  )
}
