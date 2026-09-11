import { useEffect, useMemo, useRef } from 'react'
import { starsFor, type Dir } from '../game/engine'
import { LEVELS, type LevelDef } from '../game/levels'
import type { LevelResult } from '../game/progress'
import { useSokoban } from '../game/useSokoban'
import { Board } from './Board'
import { Stars } from './Stars'
import { WorkerSprite } from './Sprites'

interface PlayScreenProps {
  level: LevelDef
  best?: LevelResult
  onSolved: (levelId: number, result: LevelResult) => void
  onNext: () => void
  onExit: () => void
}

const KEY_TO_DIR: Record<string, Dir> = {
  ArrowUp: 'up',
  ArrowDown: 'down',
  ArrowLeft: 'left',
  ArrowRight: 'right',
  w: 'up',
  s: 'down',
  a: 'left',
  d: 'right',
  W: 'up',
  S: 'down',
  A: 'left',
  D: 'right',
}

function Kbd({ children }: { children: React.ReactNode }) {
  return <kbd className="kbd">{children}</kbd>
}

const CONFETTI_COLORS = ['#ffb020', '#ffd166', '#34d399', '#ff7a2f', '#f1f3f8']

function Confetti() {
  return (
    <span className="confetti" aria-hidden="true">
      {Array.from({ length: 28 }, (_, i) => (
        <i
          key={i}
          style={
            {
              '--x': `${(i * 37) % 100}%`,
              '--d': `${(i % 7) * 90}ms`,
              '--r': `${((i * 131) % 720) - 360}deg`,
              '--c': CONFETTI_COLORS[i % CONFETTI_COLORS.length],
            } as React.CSSProperties
          }
        />
      ))}
    </span>
  )
}

export function PlayScreen({ level, best, onSolved, onNext, onExit }: PlayScreenProps) {
  const { board, state, canUndo, solved, stuck, step, undo, restart } = useSokoban(level)
  const winDialog = useRef<HTMLDialogElement>(null)
  const stuckIds = useMemo(() => new Set(stuck.map((c) => c.id)), [stuck])
  const isLast = level.id === LEVELS.length
  const stars = solved ? starsFor(state.moves, level.par) : null
  const cratesHome = state.crates.filter((c) => board.targets.some((t) => t.x === c.x && t.y === c.y)).length

  useEffect(() => {
    const dialog = winDialog.current
    if (solved) dialog?.showModal()
    return () => dialog?.close()
  }, [solved])

  useEffect(() => {
    if (!solved) return
    onSolved(level.id, { bestMoves: state.moves, bestPushes: state.pushes, stars: starsFor(state.moves, level.par) })
  }, [solved, level.id, level.par, state.moves, state.pushes, onSolved])

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.ctrlKey || e.metaKey || e.altKey) return
      const dir = KEY_TO_DIR[e.key]
      if (dir) {
        e.preventDefault()
        step(dir)
        return
      }
      switch (e.key) {
        case 'z':
        case 'Z':
        case 'Backspace':
          e.preventDefault()
          if (!solved) undo()
          break
        case 'r':
        case 'R':
          e.preventDefault()
          restart()
          break
        case 'Escape':
        case 'l':
        case 'L':
          e.preventDefault()
          onExit()
          break
        case 'Enter':
        case ' ':
          if (e.target instanceof HTMLButtonElement) break
          if (solved) {
            e.preventDefault()
            if (isLast) onExit()
            else onNext()
          }
          break
        case 'n':
        case 'N':
          if (solved) {
            e.preventDefault()
            if (isLast) onExit()
            else onNext()
          }
          break
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [step, undo, restart, onExit, onNext, solved, isLast])

  return (
    <section className="play">
      <header className="play-heading">
        <div>
          <p className="eyebrow">WAREHOUSE {String(level.id).padStart(2, '0')} / 08</p>
          <h1>
            {level.name}
            <span>.</span>
          </h1>
        </div>
        <span className="play-tag">
          <i /> {solved ? 'SHIFT COMPLETE' : 'TAKE YOUR TIME. FIND YOUR FLOW.'}
        </span>
      </header>
      <div className="play-main">
        <div className="cabinet">
          <div className="cabinet-marquee">
            <span>
              <i /> DEPOT PUZZLE CO.
            </span>
            <strong>SHIFT {String(level.id).padStart(2, '0')}</strong>
            <span>ONE PLAYER · ALL BRAIN</span>
          </div>
          <div className="board-frame">
            <span className="bay-label" aria-hidden="true">
              LOADING ZONE
            </span>
            <Board board={board} state={state} stuckIds={stuckIds} />

            {solved && stars && (
              <dialog ref={winDialog} className="win-overlay" aria-labelledby="win-title" onCancel={onExit}>
                <Confetti />
                <div className="win-card">
                  <p className="win-eyebrow">Level {level.id} cleared</p>
                  <h2 id="win-title">
                    {stars === 3 ? 'SIGNED. SEALED.' : 'NICE SHIFT.'}
                    <br />
                    <span>{stars === 3 ? 'DELIVERED!' : 'GREAT WORK!'}</span>
                  </h2>
                  <p className="win-level">
                    {level.name} · Shift {String(level.id).padStart(2, '0')}
                  </p>
                  <Stars count={stars} size="lg" label={`${stars} of 3 stars earned`} />
                  <dl className="win-stats">
                    <div>
                      <dt>Moves</dt>
                      <dd>{state.moves}</dd>
                    </div>
                    <div>
                      <dt>Pushes</dt>
                      <dd>{state.pushes}</dd>
                    </div>
                    <div>
                      <dt>Par</dt>
                      <dd>{level.par}</dd>
                    </div>
                  </dl>
                  <p className="muted win-hint">
                    {stars === 3
                      ? 'Right on par. That’s some world-class box work.'
                      : stars === 2
                        ? `Within 1.5× par. Finish in ${level.par} moves for three stars.`
                        : `Cleared! Finish in ${level.par} moves for three stars.`}
                  </p>
                  <div className="win-actions">
                    {isLast ? (
                      <button className="btn btn-primary" onClick={onExit} autoFocus>
                        Back to levels <Kbd>Enter</Kbd>
                      </button>
                    ) : (
                      <button className="btn btn-primary" onClick={onNext} autoFocus>
                        Next level <Kbd>Enter</Kbd>
                      </button>
                    )}
                    <button className="btn" onClick={restart}>
                      Replay <Kbd>R</Kbd>
                    </button>
                    <button className="btn btn-ghost" onClick={onExit}>
                      Levels <Kbd>Esc</Kbd>
                    </button>
                  </div>
                </div>
              </dialog>
            )}
          </div>
          <div className="control-deck">
            <div className="direction-pad" aria-label="Movement controls">
              <button onClick={() => step('up')} disabled={solved} aria-label="Move up">
                ↑
              </button>
              <button onClick={() => step('left')} disabled={solved} aria-label="Move left">
                ←
              </button>
              <button onClick={() => step('down')} disabled={solved} aria-label="Move down">
                ↓
              </button>
              <button onClick={() => step('right')} disabled={solved} aria-label="Move right">
                →
              </button>
            </div>
            <span className="deck-label">
              MAKE YOUR MOVE<small>Arrow keys or WASD</small>
            </span>
            <div className="deck-actions">
              <button className="btn" onClick={undo} disabled={!canUndo || solved}>
                ↶ Undo <Kbd>Z</Kbd>
              </button>
              <button className="btn" onClick={restart} disabled={state.moves === 0}>
                ↻ Restart <Kbd>R</Kbd>
              </button>
            </div>
          </div>
        </div>

        <div className={`banner banner-stuck ${stuck.length > 0 && !solved ? 'visible' : ''}`} role="alert">
          {stuck.length > 0 && !solved && (
            <>
              <span aria-hidden="true">↶</span>
              <span>
                <strong>Crate wedged in a corner.</strong> No worries. Press <Kbd>Z</Kbd> to undo and try another route.
              </span>
            </>
          )}
        </div>
      </div>

      <aside className="sidebar">
        <div className="panel mission-panel">
          <p className="eyebrow">THE JOB AT HAND</p>
          <div className="level-head">
            <div>
              <h2 className="level-title">A place for every crate.</h2>
              <p>Push each box onto a marked target.</p>
            </div>
          </div>
          <div className="progress-row">
            <span className="progress-bar">
              <i style={{ width: `${(cratesHome / state.crates.length) * 100}%` }} />
            </span>
            <span>
              {cratesHome} / {state.crates.length}
            </span>
          </div>
        </div>

        <div className="score-panel">
          <p className="eyebrow">YOUR SHIFT IN NUMBERS</p>
          <div className="stats">
            <div className={`stat${state.moves > level.par ? ' over' : ''}`}>
              <span className="stat-label">Moves</span>
              <span className="stat-value" data-testid="moves">
                {state.moves}
              </span>
            </div>
            <div className="stat">
              <span className="stat-label">Pushes</span>
              <span className="stat-value" data-testid="pushes">
                {state.pushes}
              </span>
            </div>
            <div className="stat stat-par">
              <span className="stat-label">Par</span>
              <span className="stat-value">{level.par}</span>
            </div>
          </div>
        </div>

        <div className="panel">
          <p className="eyebrow">MAKE IT A GOLD-STAR SHIFT</p>
          <ul className="thresholds">
            <li className={state.moves <= level.par ? 'hit' : ''}>
              <Stars count={3} size="sm" /> <span>≤ {level.par} moves</span>
            </li>
            <li className={state.moves <= Math.ceil(level.par * 1.5) ? 'hit' : ''}>
              <Stars count={2} size="sm" /> <span>≤ {Math.ceil(level.par * 1.5)} moves</span>
            </li>
            <li className="hit">
              <Stars count={1} size="sm" /> <span>any finish</span>
            </li>
          </ul>
          {best && (
            <p className="muted best">
              Best: {best.bestMoves} moves · <Stars count={best.stars} size="sm" />
            </p>
          )}
        </div>

        <div className="mentor-note">
          <WorkerSprite facing="down" />
          <p>
            <strong>You’ve got this.</strong>Think two pushes ahead. A corner is no place for a crate.
          </p>
        </div>
        <button className="btn btn-ghost exit-button" onClick={onExit}>
          ← All warehouses <Kbd>Esc</Kbd>
        </button>
      </aside>
    </section>
  )
}
