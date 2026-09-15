import { useMemo } from 'react'
import { crateAt, isTarget, parseLevel } from '../game/engine'
import { LEVELS, type LevelDef } from '../game/levels'
import { isUnlocked, type Progress } from '../game/progress'
import { DepotScene } from './DepotScene'
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
  const cell = Math.floor(Math.min(78 / board.height, 124 / board.width))
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
  const nextLevel = LEVELS.find((level) => !progress[level.id] && isUnlocked(progress, level.id)) ?? LEVELS[0]

  return (
    <section className="level-select">
      <header className="hero">
        <div className="hero-copy">
          <p className="eyebrow hero-eyebrow">
            <span /> A small puzzle. A proper challenge.
          </p>
          <h1 className="hero-title">
            A LITTLE PUSH.
            <br />
            <span>A BIG WIN.</span>
          </h1>
          <p className="hero-sub">
            Clock in. Think ahead. Make every move count.
            <br />
            Eight tiny warehouses. One very satisfying job.
          </p>
          <div className="hero-actions">
            <button className="btn btn-primary start-button" onClick={() => onPlay(nextLevel.id)}>
              {completed === LEVELS.length ? 'One more round' : completed ? 'Continue shift' : 'Let’s get moving'}{' '}
              <span aria-hidden="true">↗</span>
            </button>
            <span className="hero-stage">
              STAGE {String(nextLevel.id).padStart(2, '0')}
              <strong>{nextLevel.name}</strong>
            </span>
          </div>
          <p className="hero-footnote">NO TIMER. NO PRESSURE. JUST ONE MORE TRY.</p>
        </div>
        <div className="hero-art">
          <span className="edition-stamp">
            HAND-PACKED
            <br />
            <strong>08</strong>
            <br />
            LITTLE CHALLENGES
          </span>
          <DepotScene />
          <span className="art-caption">GOOD THINGS COME IN SMALL BOXES.</span>
        </div>
      </header>

      <div className="shift-strip">
        <span>
          <b>01</b> Push the crates
        </span>
        <i aria-hidden="true">→</i>
        <span>
          <b>02</b> Fill every target
        </span>
        <i aria-hidden="true">→</i>
        <span>
          <b>03</b> Bring home the stars
        </span>
        <span className="strip-tag">PUSH. PLAN. REPEAT.</span>
      </div>
      <div className="selection-heading">
        <div>
          <p className="eyebrow">YOUR NEXT CHALLENGE</p>
          <h2>
            Pick your shift<span>.</span>
          </h2>
        </div>
        <div className="shift-card" aria-label="Progress">
          <span>
            <strong>
              {String(completed).padStart(2, '0')}
              <small> / 08</small>
            </strong>
            WAREHOUSES CLEARED
          </span>
          <span className="star-total">
            <strong>
              <i aria-hidden="true">★</i> {String(earned).padStart(2, '0')}
              <small> / 24</small>
            </strong>
            STARS COLLECTED
          </span>
        </div>
      </div>
      <ul className="level-grid">
        {LEVELS.map((level, i) => {
          const result = progress[level.id]
          const unlocked = isUnlocked(progress, level.id)
          return (
            <li key={level.id} style={{ '--i': i } as React.CSSProperties}>
              <button
                className={`level-card${unlocked ? '' : ' locked'}${result ? ' cleared' : ''}${level.id === nextLevel.id ? ' next-stage' : ''}`}
                onClick={() => unlocked && onPlay(level.id)}
                disabled={!unlocked}
                aria-label={`Level ${level.id}: ${level.name}${unlocked ? '' : ' (locked)'}`}
                data-level={level.id}
              >
                <div className="lc-top">
                  <span className="lc-number">
                    <small>STAGE</small>
                    {String(level.id).padStart(2, '0')}
                  </span>
                  <MiniMap level={level} />
                </div>
                <div className="lc-bottom">
                  <span>
                    <span className="lc-name">{level.name}</span>
                    <span className="lc-meta">
                      {result ? (
                        <>
                          Best {result.bestMoves} · Par {level.par}
                        </>
                      ) : (
                        <>Par {level.par} moves</>
                      )}
                    </span>
                  </span>
                  <span className="lc-arrow" aria-hidden="true">
                    {unlocked ? '↗' : '−'}
                  </span>
                </div>
                <div className="lc-footer">
                  <Stars count={result?.stars ?? 0} size="sm" />
                  <span>
                    {result
                      ? '✓ CLEARED'
                      : unlocked
                        ? 'READY TO PLAY'
                        : `CLEAR STAGE ${String(level.id - 1).padStart(2, '0')}`}
                  </span>
                </div>
              </button>
            </li>
          )
        })}
      </ul>
      <footer className="select-footer">
        <span>Made for the joy of figuring it out.</span>
        <button
          className="text-button"
          onClick={() => {
            if (window.confirm('Reset all earned stars and unlocks?')) onReset()
          }}
          disabled={completed === 0}
        >
          Reset progress
        </button>
      </footer>
    </section>
  )
}
