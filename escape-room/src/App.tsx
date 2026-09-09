import { useCallback, useEffect, useState } from 'react'
import {
  BOOK_ORDER,
  CIPHER_SHIFT,
  HINTS,
  MORSE_WORD,
  PAINTING,
  SAFE_CODE,
  STAGE_TITLES,
  formatTime,
  type Color,
  type Stage,
} from './game'
import { useMorseLamp } from './hooks/useMorseLamp'
import { Room } from './components/Room'
import { Modal } from './components/Modal'
import { ColorLock } from './components/puzzles/ColorLock'
import { Typewriter } from './components/puzzles/Typewriter'
import { Safe } from './components/puzzles/Safe'
import { Sampler } from './components/puzzles/Sampler'
import { Letter } from './components/puzzles/Letter'
import { PaintingView, PosterView, LampView, DrawerView } from './components/puzzles/Inspect'

export type ModalId =
  | 'painting'
  | 'lockbox'
  | 'lamp'
  | 'typewriter'
  | 'poster'
  | 'safe'
  | 'drawer'
  | 'sampler'
  | 'letter'
  | null

export interface GameState {
  started: boolean
  startedAt: number
  finishedAt: number | null
  stage: Stage
  hintsLeft: number
  hint: string | null
  journal: string
  lockDials: Color[]
  safeDials: number[]
  rugOffset: { x: number; y: number }
  keyState: 'hidden' | 'revealed' | 'used'
  drawerOpen: boolean
  shift: number
  pulledBooks: string[]
  doorOpen: boolean
}

const INITIAL: GameState = {
  started: false,
  startedAt: 0,
  finishedAt: null,
  stage: 1,
  hintsLeft: 3,
  hint: null,
  journal:
    'You wake in a quiet study. The door is bolted from the inside, yet there is no bolt you can reach. Everything you need is in this room.',
  lockDials: ['ivory', 'ivory', 'ivory', 'ivory'],
  safeDials: [0, 0, 0],
  rugOffset: { x: 0, y: 0 },
  keyState: 'hidden',
  drawerOpen: false,
  shift: 0,
  pulledBooks: [],
  doorOpen: false,
}

export default function App() {
  const [game, setGame] = useState<GameState>(INITIAL)
  const [modal, setModal] = useState<ModalId>(null)
  const [now, setNow] = useState(() => Date.now())
  const [escapedShown, setEscapedShown] = useState(false)

  const lamp = useMorseLamp(MORSE_WORD, game.started && game.stage === 2)
  const lampOn = lamp.on || (game.started && game.stage >= 3)

  useEffect(() => {
    if (!game.started || game.finishedAt !== null) return
    const id = window.setInterval(() => setNow(Date.now()), 250)
    return () => window.clearInterval(id)
  }, [game.started, game.finishedAt])

  useEffect(() => {
    if (!game.doorOpen) return
    const id = window.setTimeout(() => setEscapedShown(true), 1600)
    return () => window.clearTimeout(id)
  }, [game.doorOpen])

  const patch = useCallback((p: Partial<GameState>) => setGame((g) => ({ ...g, ...p })), [])

  const say = useCallback((journal: string) => patch({ journal, hint: null }), [patch])

  const start = () => {
    setGame({ ...INITIAL, started: true, startedAt: Date.now() })
    setNow(Date.now())
  }

  const reset = () => {
    setGame(INITIAL)
    setModal(null)
    setEscapedShown(false)
  }

  const useHint = () => {
    if (game.hintsLeft <= 0) return
    patch({ hintsLeft: game.hintsLeft - 1, hint: HINTS[game.stage] })
  }

  // ---- Puzzle 1: colour lock ----
  const cycleDial = (i: number) => {
    const order: Color[] = ['ivory', 'crimson', 'amber', 'teal', 'violet', 'emerald']
    const next = order[(order.indexOf(game.lockDials[i]) + 1) % order.length]
    const dials = game.lockDials.map((c, j) => (j === i ? next : c))
    patch({ lockDials: dials })
  }
  const tryLock = () => {
    if (game.stage !== 1) return
    if (game.lockDials.every((c, i) => c === PAINTING[i])) {
      patch({
        stage: 2,
        hint: null,
        journal:
          'The latch gives. Inside the lockbox: a single light bulb. You screw it into the desk lamp and it flickers — not steadily. Long and short. It is spelling something.',
      })
      setModal(null)
    } else {
      say('The latch holds. The dials are not right.')
    }
  }

  // ---- Puzzle 2: typewriter ----
  const typeWord = (word: string) => {
    if (game.stage !== 2) return false
    if (word.toUpperCase() === MORSE_WORD) {
      patch({
        stage: 3,
        hint: null,
        journal:
          'The typewriter clacks out O-W-L and the carriage jams a hidden page forward: "The card on the corkboard is written in lemon ink. Warm it under your hand."',
      })
      setModal(null)
      return true
    }
    say('The keys strike, but the page stays meaningless. That is not the word the lamp is spelling.')
    return false
  }

  // ---- Puzzle 3: note + safe ----
  const spinSafe = (i: number, delta: number) => {
    const dials = game.safeDials.map((d, j) => (j === i ? (d + delta + 10) % 10 : d))
    patch({ safeDials: dials })
  }
  const trySafe = () => {
    if (game.stage !== 3) return
    if (game.safeDials.every((d, i) => d === SAFE_CODE[i])) {
      patch({
        stage: 4,
        hint: null,
        journal:
          'The safe door swings open. Inside lies a short iron crowbar. You pry loose the tacks holding the rug to the floorboards — it will move now.',
      })
      setModal(null)
    } else {
      say('The handle will not turn. Wrong combination.')
    }
  }

  // ---- Puzzle 4: rug, key, drawer ----
  const moveRug = (offset: { x: number; y: number }) => {
    if (game.stage < 4) return
    const revealed = game.keyState !== 'hidden' || Math.abs(offset.x) > 18 || Math.abs(offset.y) > 12
    patch({
      rugOffset: offset,
      keyState: revealed && game.keyState === 'hidden' ? 'revealed' : game.keyState,
      ...(revealed && game.keyState === 'hidden'
        ? { journal: 'Under the rug, a small brass key catches the light. Somewhere in this room is the lock it fits.' }
        : {}),
    })
  }
  const dropKeyOnDrawer = () => {
    if (game.stage !== 4 || game.keyState !== 'revealed') return
    patch({
      stage: 5,
      keyState: 'used',
      drawerOpen: true,
      hint: null,
      journal:
        'The key turns and the drawer slides out. Inside: a brass cipher dial, worn smooth. The embroidered sampler on the wall suddenly looks less like nonsense.',
    })
  }

  // ---- Puzzle 5: Caesar sampler ----
  const setShift = (shift: number) => {
    if (game.stage !== 5) return
    const s = ((shift % 26) + 26) % 26
    if (s === CIPHER_SHIFT) {
      patch({
        shift: s,
        stage: 6,
        hint: null,
        journal:
          'The letters fall into place: THE LETTER ON THE DESK NUMBERS THE BOOKS. You look again at the long letter lying on the desk.',
      })
    } else {
      patch({ shift: s })
    }
  }

  // ---- Puzzle 6: bookshelf ----
  const pullBook = (id: string) => {
    if (game.stage !== 6) {
      say(game.stage < 6 ? 'The books are wedged tight. They will not budge — yet.' : 'The shelf has already given up its secret.')
      return
    }
    const next = [...game.pulledBooks, id]
    const expected = BOOK_ORDER[game.pulledBooks.length]
    if (id !== expected) {
      patch({ pulledBooks: [], journal: 'A click, and every book you pulled slides back into place. Wrong order — start again.' })
      return
    }
    if (next.length === BOOK_ORDER.length) {
      patch({
        pulledBooks: next,
        stage: 7,
        hint: null,
        journal: 'Deep in the wall something heavy slides. The bolt on the door draws back. Go.',
      })
    } else {
      patch({ pulledBooks: next, journal: `${next.length} of ${BOOK_ORDER.length} — the book stays out. Keep going.` })
    }
  }

  // ---- Door ----
  const openDoor = () => {
    if (game.stage !== 7) {
      say('The door is bolted from the far side. There is no keyhole — the room must let you out.')
      return
    }
    if (game.doorOpen) return
    patch({ doorOpen: true, finishedAt: Date.now(), journal: 'The door swings open onto a cold, bright corridor.' })
  }

  const elapsed = (game.finishedAt ?? now) - game.startedAt
  const solvedCount = Math.min(6, game.stage - 1)
  const hintsUsed = 3 - game.hintsLeft
  const escaped = game.finishedAt !== null

  const inventory: { id: string; name: string; have: boolean; spent: boolean }[] = [
    { id: 'bulb', name: 'Bulb', have: game.stage >= 2, spent: game.stage >= 2 },
    { id: 'page', name: 'Page', have: game.stage >= 3, spent: false },
    { id: 'crowbar', name: 'Crowbar', have: game.stage >= 4, spent: game.stage >= 4 },
    { id: 'key', name: 'Key', have: game.keyState !== 'hidden', spent: game.keyState === 'used' },
    { id: 'dial', name: 'Dial', have: game.stage >= 5, spent: false },
  ]

  return (
    <div className="app">
      <header className="topbar">
        <div className="brand">
          <span className="brand-mark" aria-hidden>
            S
          </span>
          <div>
            <h1>The Study</h1>
            <span className="brand-sub">Escape room · six chained puzzles</span>
          </div>
        </div>
        <div className="top-status" aria-live="polite">
          <span className={`dot ${!game.started ? 'idle' : escaped ? 'done' : ''}`} aria-hidden />
          <span>{!game.started ? 'Waiting at the door' : escaped ? 'Escaped' : `${solvedCount} of 6 puzzles solved`}</span>
        </div>
      </header>

      <main className="stage">
        <Room
          game={game}
          lampOn={lampOn}
          onInspect={setModal}
          onMoveRug={moveRug}
          onDropKeyOnDrawer={dropKeyOnDrawer}
          onPullBook={pullBook}
          onDoor={openDoor}
          onSay={say}
        />
      </main>

      <aside className="casebook" aria-label="Casebook">
        <div className="casebook-head">
          <div>
            <div className="casebook-title">Casebook</div>
            <span className="casebook-sub">{escaped ? 'Case closed' : game.stage === 7 ? 'The door is unbolted' : `Puzzle ${game.stage} of 6`}</span>
          </div>
          <div className={`timer ${escaped ? 'stopped' : game.started ? 'running' : ''}`} aria-label="Elapsed time">
            <svg viewBox="0 0 24 24" width="16" height="16" aria-hidden>
              <circle cx="12" cy="13" r="8" fill="none" stroke="currentColor" strokeWidth="2" />
              <path d="M12 9v4l3 2M9 2h6" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
            </svg>
            <span>{game.started ? formatTime(Math.max(0, elapsed)) : '00:00'}</span>
          </div>
        </div>

        <ol className="objectives" aria-label="Puzzles">
          {([1, 2, 3, 4, 5, 6] as Stage[]).map((s) => {
            const state = s < game.stage ? 'done' : s === game.stage ? 'current' : 'locked'
            return (
              <li key={s} className={state}>
                <span className="obj-mark" aria-hidden>
                  {state === 'done' ? '✓' : s}
                </span>
                <span className="obj-title">{state === 'locked' ? '· · ·' : STAGE_TITLES[s]}</span>
                <span className="obj-tag">{state === 'done' ? 'Solved' : state === 'current' ? 'Now' : ''}</span>
              </li>
            )
          })}
        </ol>

        <div className="journal" aria-live="polite">
          <span className="journal-label">Journal</span>
          <p className="journal-text" key={game.journal}>
            {game.journal}
          </p>
          {game.hint && (
            <p className="journal-hint">
              <strong>Hint</strong>
              {game.hint}
            </p>
          )}
        </div>

        <div className="casebook-actions">
          <button className="btn btn-ghost" onClick={useHint} disabled={!game.started || game.hintsLeft === 0 || escaped}>
            Ask for a hint
            <span className="hint-pips" aria-label={`${game.hintsLeft} hints left`}>
              {[0, 1, 2].map((i) => (
                <i key={i} className={i < game.hintsLeft ? '' : 'spent'} />
              ))}
            </span>
          </button>
          <button className="btn btn-ghost" onClick={reset} title="Reset the room and the timer">
            Reset
          </button>
        </div>

        <div className="inventory">
          <span className="inventory-label">Found in the room</span>
          <div className="inventory-grid">
            {inventory.map((item) => (
              <div
                key={item.id}
                className={`inv ${item.have ? 'have' : ''} ${item.spent ? 'spent' : ''}`}
                data-name={item.have ? item.name : undefined}
                aria-label={item.have ? `${item.name}${item.spent ? ' (used)' : ''}` : 'Not yet found'}
              >
                {item.have ? <InvIcon id={item.id} /> : <span aria-hidden>?</span>}
              </div>
            ))}
          </div>
        </div>
      </aside>

      {!game.started && (
        <div className="overlay intro">
          <div className="card">
            <p className="eyebrow">A point-and-click escape</p>
            <h2>The Study</h2>
            <p>
              Six puzzles, unlocked in order. Every answer is somewhere in the room — look closely, hover, drag,
              and listen with your eyes. The clock starts when you step inside.
            </p>
            <div className="skills-row" aria-label="What the room will ask of you">
              {['Look', 'Hover', 'Wait', 'Drag', 'Decode', 'Scroll'].map((s) => (
                <span key={s}>{s}</span>
              ))}
            </div>
            <button className="btn btn-primary" onClick={start}>
              Step inside
            </button>
            <p className="fine">Three hints are tucked into the casebook. Reset at any time.</p>
          </div>
        </div>
      )}

      {escapedShown && (
        <div className="overlay escaped">
          <div className="card">
            <p className="eyebrow">You escaped the study</p>
            <div className="big-time">{formatTime(Math.max(0, elapsed))}</div>
            <div className="stats">
              <div className="stat">
                <b>6 / 6</b>
                <span>Puzzles</span>
              </div>
              <div className="stat">
                <b>{hintsUsed}</b>
                <span>Hints used</span>
              </div>
              <div className="stat">
                <b>{formatTime(Math.max(0, elapsed))}</b>
                <span>Escape time</span>
              </div>
            </div>
            <button className="btn btn-primary" onClick={reset}>
              Play again
            </button>
          </div>
        </div>
      )}

      {modal === 'painting' && (
        <Modal kicker="Oil on canvas" title="Dusk over the Marsh" onClose={() => setModal(null)}>
          <PaintingView />
        </Modal>
      )}
      {modal === 'lockbox' && (
        <Modal kicker="Puzzle 1" title="Brass lockbox" onClose={() => setModal(null)}>
          <ColorLock dials={game.lockDials} solved={game.stage > 1} onCycle={cycleDial} onTry={tryLock} />
        </Modal>
      )}
      {modal === 'lamp' && (
        <Modal kicker="Puzzle 2" title="Banker’s lamp" onClose={() => setModal(null)}>
          <LampView on={lampOn} tape={lamp.tape} stage={game.stage} />
        </Modal>
      )}
      {modal === 'typewriter' && (
        <Modal kicker="Puzzle 2" title="Typewriter" onClose={() => setModal(null)}>
          <Typewriter stage={game.stage} onSubmit={typeWord} />
        </Modal>
      )}
      {modal === 'poster' && (
        <Modal kicker="Wall chart" title="International Morse Code" onClose={() => setModal(null)}>
          <PosterView />
        </Modal>
      )}
      {modal === 'safe' && (
        <Modal kicker="Puzzle 3" title="Wall safe" onClose={() => setModal(null)}>
          <Safe dials={game.safeDials} stage={game.stage} onSpin={spinSafe} onTry={trySafe} />
        </Modal>
      )}
      {modal === 'drawer' && (
        <Modal kicker="Puzzle 4" title="Desk drawer" onClose={() => setModal(null)}>
          <DrawerView open={game.drawerOpen} />
        </Modal>
      )}
      {modal === 'sampler' && (
        <Modal kicker="Puzzle 5" title="Embroidered sampler" onClose={() => setModal(null)}>
          <Sampler stage={game.stage} shift={game.shift} onShift={setShift} />
        </Modal>
      )}
      {modal === 'letter' && (
        <Modal kicker="Puzzle 6" title="A letter, left on the desk" onClose={() => setModal(null)} wide>
          <Letter stage={game.stage} />
        </Modal>
      )}
    </div>
  )
}

function InvIcon({ id }: { id: string }) {
  switch (id) {
    case 'bulb':
      return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" aria-hidden>
          <path d="M9 18h6M10 21h4M8.5 14.5a6 6 0 1 1 7 0c-.9.7-1.5 1.5-1.5 2.5h-4c0-1-.6-1.8-1.5-2.5Z" />
        </svg>
      )
    case 'page':
      return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" aria-hidden>
          <path d="M7 3h7l4 4v14H7zM14 3v4h4M10 12h5M10 16h5" />
        </svg>
      )
    case 'crowbar':
      return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" aria-hidden>
          <path d="M5 8q0-3 3-3h11M17 5l3 3" />
          <path d="M8 5 5 20" />
        </svg>
      )
    case 'key':
      return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" aria-hidden>
          <circle cx="8" cy="12" r="3.5" />
          <path d="M11.5 12H21M18 12v3M15 12v2" />
        </svg>
      )
    default:
      return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" aria-hidden>
          <circle cx="12" cy="12" r="8.5" />
          <circle cx="12" cy="12" r="3" />
          <path d="M12 3.5v3M12 17.5v3M3.5 12h3M17.5 12h3" />
        </svg>
      )
  }
}
