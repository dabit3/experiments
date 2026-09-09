import { useEffect, useMemo } from 'react'
import { starsFor, type Dir } from '../game/engine'
import { LEVELS, type LevelDef } from '../game/levels'
import type { LevelResult } from '../game/progress'
import { useSokoban } from '../game/useSokoban'
import { Board } from './Board'
import { Stars } from './Stars'

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

export function PlayScreen({ level, best, onSolved, onNext, onExit }: PlayScreenProps) {
  const { board, state, canUndo, solved, stuck, step, undo, restart } = useSokoban(level)
  const stuckIds = useMemo(() => new Set(stuck.map((c) => c.id)), [stuck])
  const isLast = level.id === LEVELS.length
  const stars = solved ? starsFor(state.moves, level.par) : null
  const cratesHome = state.crates.filter((c) => board.targets.some((t) => t.x === c.x && t.y === c.y)).length

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
      <div className="play-main">
        <div className="board-frame">
          <Board board={board} state={state} stuckIds={stuckIds} maxWidth={720} maxHeight={560} />

          {solved && stars && (
            <div className="win-overlay" role="dialog" aria-modal="true" aria-labelledby="win-title">
              <div className="win-card">
                <p className="win-eyebrow">Level {level.id} cleared</p>
                <h2 id="win-title">{level.name}</h2>
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
                    ? 'Perfect — you matched par.'
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
            </div>
          )}
        </div>

        <div className={`banner banner-stuck ${stuck.length > 0 && !solved ? 'visible' : ''}`} role="alert">
          {stuck.length > 0 && !solved && (
            <>
              <strong>Crate wedged in a corner.</strong> It can never reach a target from there — press <Kbd>Z</Kbd> to
              undo or <Kbd>R</Kbd> to restart.
            </>
          )}
        </div>
      </div>

      <aside className="sidebar">
        <div className="panel">
          <p className="eyebrow">Level {String(level.id).padStart(2, '0')} of {LEVELS.length}</p>
          <h2 className="level-title">{level.name}</h2>
          <p className="muted">
            {cratesHome} / {state.crates.length} crates on target
          </p>
        </div>

        <div className="panel stats">
          <div className="stat">
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
          <div className="stat">
            <span className="stat-label">Par</span>
            <span className="stat-value">{level.par}</span>
          </div>
        </div>

        <div className="panel">
          <p className="eyebrow">Star thresholds</p>
          <ul className="thresholds">
            <li>
              <Stars count={3} size="sm" /> <span>≤ {level.par} moves</span>
            </li>
            <li>
              <Stars count={2} size="sm" /> <span>≤ {Math.ceil(level.par * 1.5)} moves</span>
            </li>
            <li>
              <Stars count={1} size="sm" /> <span>any finish</span>
            </li>
          </ul>
          {best && (
            <p className="muted best">
              Best: {best.bestMoves} moves · <Stars count={best.stars} size="sm" />
            </p>
          )}
        </div>

        <div className="panel actions">
          <button className="btn" onClick={undo} disabled={!canUndo || solved}>
            Undo <Kbd>Z</Kbd>
          </button>
          <button className="btn" onClick={restart} disabled={state.moves === 0}>
            Restart <Kbd>R</Kbd>
          </button>
          <button className="btn btn-ghost" onClick={onExit}>
            Level select <Kbd>Esc</Kbd>
          </button>
        </div>

        <div className="panel help">
          <p className="eyebrow">Controls</p>
          <div className="keys">
            <Kbd>↑</Kbd>
            <Kbd>↓</Kbd>
            <Kbd>←</Kbd>
            <Kbd>→</Kbd> <span className="muted">or</span> <Kbd>W</Kbd>
            <Kbd>A</Kbd>
            <Kbd>S</Kbd>
            <Kbd>D</Kbd>
          </div>
          <p className="muted">Push every crate onto a yellow target. You can only push one crate at a time.</p>
        </div>
      </aside>
    </section>
  )
}
