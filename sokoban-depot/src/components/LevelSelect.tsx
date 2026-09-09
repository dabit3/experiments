import { useMemo } from 'react'
import { crateAt, isTarget, parseLevel } from '../game/engine'
import { LEVELS, type LevelDef } from '../game/levels'
import { isUnlocked, type Progress } from '../game/progress'
import { Emblem, Wordmark } from './Logo'
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
      <header className="hero">
        <div className="hero-copy">
          <h1 className="hero-title">
            <Emblem className="hero-emblem" />
            <Wordmark />
          </h1>
          <p className="hero-sub">
            Eight warehouses, one forklift-free worker. Push every crate onto a target in as few moves as you can.
          </p>
        </div>
        <div className="hero-side">
          <div className="shift-card" aria-label="Progress">
            <span className="eyebrow">Cleared</span>
            <span className="eyebrow">Stars</span>
            <span className="shift-val">
              {completed}
              <small>/ {LEVELS.length}</small>
            </span>
            <span className="shift-val accent">
              {earned}
              <small>/ {LEVELS.length * 3}</small>
            </span>
          </div>
          <button className="btn btn-ghost" onClick={onReset} disabled={completed === 0}>
            Reset progress
          </button>
        </div>
      </header>

      <ul className="level-grid">
        {LEVELS.map((level, i) => {
          const result = progress[level.id]
          const unlocked = isUnlocked(progress, level.id)
          return (
            <li key={level.id} style={{ '--i': i } as React.CSSProperties}>
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
                      <svg viewBox="0 0 24 24" aria-hidden="true">
                        <path d="M5 12.5 10 17.5 19 7" />
                      </svg>
                      cleared
                    </span>
                  )}
                </div>
                {!unlocked && (
                  <span className="lc-lock" aria-hidden="true">
                    <span className="lc-lock-icon">
                      <svg viewBox="0 0 24 24">
                        <path d="M7 10V8a5 5 0 0 1 10 0v2h1a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h1zm2 0h6V8a3 3 0 0 0-6 0v2z" />
                      </svg>
                    </span>
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
