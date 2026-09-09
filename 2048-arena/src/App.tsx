import { useCallback, useEffect, useMemo, useReducer, useState } from 'react'
import { Board } from './components/Board.tsx'
import {
  UNDO_DEPTH,
  WIN_TILE,
  dismissBanner,
  highestTile,
  move,
  newGame,
  pruneGhosts,
  undo,
  type Direction,
  type GameState,
} from './lib/game.ts'
import { randomSeed, seedFromString } from './lib/rng.ts'
import './App.css'

const BEST_KEY = '2048-arena:best'

const KEY_TO_DIR: Record<string, Direction> = {
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

function readSeedFromUrl(): number {
  const fromUrl = seedFromString(new URLSearchParams(window.location.search).get('seed'))
  return fromUrl ?? randomSeed()
}

function writeSeedToUrl(seed: number) {
  const url = new URL(window.location.href)
  url.searchParams.set('seed', String(seed))
  window.history.replaceState(null, '', url)
}

function readBest(): number {
  const raw = window.localStorage.getItem(BEST_KEY)
  const n = raw === null ? 0 : Number(raw)
  return Number.isFinite(n) ? n : 0
}

function SeedForm({ seed, onPlay }: { seed: number; onPlay: (seed: number) => void }) {
  const [value, setValue] = useState(String(seed))
  return (
    <form
      className="seed-form"
      onSubmit={(e) => {
        e.preventDefault()
        const next = seedFromString(value)
        if (next !== null) onPlay(next)
      }}
    >
      <input
        className="seed-input"
        inputMode="numeric"
        value={value}
        onChange={(e) => setValue(e.target.value)}
        aria-label="Seed"
      />
      <button type="submit" className="btn">
        Play
      </button>
    </form>
  )
}

interface AppState {
  game: GameState
  best: number
  lastMove: Direction | null
}

type Action =
  | { type: 'move'; dir: Direction }
  | { type: 'undo' }
  | { type: 'new'; seed: number }
  | { type: 'dismiss' }
  | { type: 'prune' }

function withGame(state: AppState, game: GameState): AppState {
  if (game === state.game) return state
  return { ...state, game, best: Math.max(state.best, game.score) }
}

function reducer(state: AppState, action: Action): AppState {
  switch (action.type) {
    case 'move': {
      const next =
        state.game.banner !== 'none' ? state.game : move(state.game, action.dir)
      return { ...withGame(state, next), lastMove: action.dir }
    }
    case 'undo':
      return withGame(state, undo(state.game))
    case 'new':
      return { ...state, game: newGame(action.seed), lastMove: null }
    case 'dismiss':
      return withGame(state, dismissBanner(state.game))
    case 'prune':
      return withGame(state, pruneGhosts(state.game))
  }
}

function initialState(): AppState {
  const seed = readSeedFromUrl()
  writeSeedToUrl(seed)
  return { game: newGame(seed), best: readBest(), lastMove: null }
}

export default function App() {
  const [{ game, best, lastMove }, dispatch] = useReducer(reducer, undefined, initialState)

  useEffect(() => {
    window.localStorage.setItem(BEST_KEY, String(best))
  }, [best])

  useEffect(() => {
    writeSeedToUrl(game.seed)
  }, [game.seed])

  useEffect(() => {
    if (!game.tiles.some((t) => t.kind === 'ghost')) return
    const id = window.setTimeout(() => dispatch({ type: 'prune' }), 140)
    return () => window.clearTimeout(id)
  }, [game.tiles])

  const doMove = useCallback((dir: Direction) => dispatch({ type: 'move', dir }), [])
  const doUndo = useCallback(() => dispatch({ type: 'undo' }), [])
  const startGame = useCallback((seed: number) => dispatch({ type: 'new', seed }), [])

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.target instanceof HTMLInputElement) return
      if ((e.ctrlKey || e.metaKey) && (e.key === 'z' || e.key === 'Z')) {
        e.preventDefault()
        doUndo()
        return
      }
      if (e.ctrlKey || e.metaKey || e.altKey) return
      if (e.key === 'z' || e.key === 'Z' || e.key === 'Backspace') {
        e.preventDefault()
        doUndo()
        return
      }
      const dir = KEY_TO_DIR[e.key]
      if (!dir) return
      e.preventDefault()
      doMove(dir)
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [doMove, doUndo])

  const highest = useMemo(() => highestTile(game.tiles), [game.tiles])
  const undosLeft = game.history.length
  const status =
    game.banner === 'over'
      ? 'Game over'
      : highest >= WIN_TILE
        ? `Reached ${WIN_TILE} — keep going`
        : `Highest tile ${highest}`

  return (
    <div className="app">
      <header className="topbar">
        <div className="brand">
          <h1>
            2048 <span>Arena</span>
          </h1>
          <p className="tagline">Reach the {WIN_TILE} tile</p>
        </div>
        <div className="scores">
          <div className="score-box">
            <span className="score-label">Score</span>
            <span className="score-value" data-testid="score">
              {game.score.toLocaleString()}
            </span>
          </div>
          <div className="score-box">
            <span className="score-label">Best</span>
            <span className="score-value" data-testid="best">
              {best.toLocaleString()}
            </span>
          </div>
        </div>
      </header>

      <main className="layout">
        <section className="play">
          <div className="toolbar">
            <button
              type="button"
              className="btn btn-primary"
              onClick={() => startGame(randomSeed())}
            >
              New game
            </button>
            <button type="button" className="btn" onClick={() => startGame(game.seed)}>
              Restart seed
            </button>
            <button
              type="button"
              className="btn btn-undo"
              onClick={doUndo}
              disabled={undosLeft === 0}
              aria-label={`Undo, ${undosLeft} of ${UNDO_DEPTH} available`}
            >
              Undo
              <span className="pill">
                {undosLeft}/{UNDO_DEPTH}
              </span>
            </button>
          </div>

          <Board
            tiles={game.tiles}
            banner={game.banner}
            score={game.score}
            canUndo={undosLeft > 0}
            onSwipe={doMove}
            onKeepGoing={() => dispatch({ type: 'dismiss' })}
            onUndo={doUndo}
            onNewGame={() => startGame(randomSeed())}
          />

          <div className="statusline" role="status" aria-live="polite">
            <span>{status}</span>
            <span className="dot">·</span>
            <span>
              Move {game.moves}
              {lastMove ? ` (${lastMove})` : ''}
            </span>
          </div>
        </section>

        <aside className="side">
          <div className="card">
            <h2>Seed</h2>
            <SeedForm key={game.seed} seed={game.seed} onPlay={startGame} />
            <p className="hint">
              Same seed + same moves = same game. Share <code>?seed={game.seed}</code> to let
              someone replay this run exactly.
            </p>
          </div>

          <div className="card">
            <h2>Controls</h2>
            <ul className="keys">
              <li>
                <kbd>↑</kbd>
                <kbd>↓</kbd>
                <kbd>←</kbd>
                <kbd>→</kbd> or <kbd>W</kbd>
                <kbd>A</kbd>
                <kbd>S</kbd>
                <kbd>D</kbd> to slide
              </li>
              <li>
                <kbd>Z</kbd> or <kbd>Ctrl</kbd>+<kbd>Z</kbd> to undo (up to {UNDO_DEPTH} moves)
              </li>
              <li>Swipe on the board on touch screens</li>
            </ul>
          </div>

          <div className="card">
            <h2>Strategy</h2>
            <p className="hint">
              Pick a corner, keep your biggest tile there, and only use the two directions
              that point at it. Break the rule only when nothing else moves — and undo if it
              goes wrong.
            </p>
          </div>
        </aside>
      </main>
    </div>
  )
}
