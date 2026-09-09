import { useRef, useState, type PointerEvent as ReactPointerEvent } from 'react'
import type { GameState, ModalId } from '../App'
import { BOOKS, CIPHER_TEXT, COLOR_HEX, NOTE_TEXT, PAINTING } from '../game'

interface Props {
  game: GameState
  lampOn: boolean
  onInspect: (id: ModalId) => void
  onMoveRug: (offset: { x: number; y: number }) => void
  onDropKeyOnDrawer: () => void
  onPullBook: (id: string) => void
  onDoor: () => void
  onSay: (text: string) => void
}

export function Room({ game, lampOn, onInspect, onMoveRug, onDropKeyOnDrawer, onPullBook, onDoor, onSay }: Props) {
  const roomRef = useRef<HTMLDivElement>(null)
  const rugStart = useRef<{ px: number; py: number; ox: number; oy: number } | null>(null)
  const [keyDrag, setKeyDrag] = useState<{ x: number; y: number } | null>(null)
  const [noteWarm, setNoteWarm] = useState(false)
  const noteTimer = useRef(0)

  const rugDraggable = game.stage >= 4

  // ---- Rug drag (offset stored as % of room size so it scales with the scene) ----
  const onRugDown = (e: ReactPointerEvent<HTMLDivElement>) => {
    if (!rugDraggable) {
      onSay('A heavy wool rug, tacked to the floorboards at every corner. It will not shift.')
      return
    }
    e.currentTarget.setPointerCapture(e.pointerId)
    rugStart.current = { px: e.clientX, py: e.clientY, ox: game.rugOffset.x, oy: game.rugOffset.y }
  }
  const onRugMove = (e: ReactPointerEvent<HTMLDivElement>) => {
    const start = rugStart.current
    const room = roomRef.current
    if (!start || !room) return
    const rect = room.getBoundingClientRect()
    const dx = ((e.clientX - start.px) / rect.width) * 100
    const dy = ((e.clientY - start.py) / rect.height) * 100
    onMoveRug({
      x: Math.max(-45, Math.min(20, start.ox + dx)),
      y: Math.max(-10, Math.min(8, start.oy + dy)),
    })
  }
  const onRugUp = () => {
    rugStart.current = null
  }

  // ---- Key drag (follows the pointer; dropped on whatever is under it) ----
  const onKeyDown = (e: ReactPointerEvent<HTMLDivElement>) => {
    if (game.keyState !== 'revealed') return
    e.preventDefault()
    e.currentTarget.setPointerCapture(e.pointerId)
    setKeyDrag({ x: e.clientX, y: e.clientY })
  }
  const onKeyMove = (e: ReactPointerEvent<HTMLDivElement>) => {
    if (!keyDrag) return
    setKeyDrag({ x: e.clientX, y: e.clientY })
  }
  const onKeyUp = (e: ReactPointerEvent<HTMLDivElement>) => {
    if (!keyDrag) return
    setKeyDrag(null)
    const under = document.elementsFromPoint(e.clientX, e.clientY)
    if (under.some((el) => el.closest('[data-drop="drawer"]'))) {
      onDropKeyOnDrawer()
    } else {
      onSay('The key does not fit there. You keep hold of it.')
    }
  }

  // ---- Note hover (reveal after a short warm-up) ----
  const onNoteEnter = () => {
    if (game.stage < 3) return
    noteTimer.current = window.setTimeout(() => setNoteWarm(true), 500)
  }
  const onNoteLeave = () => {
    window.clearTimeout(noteTimer.current)
    setNoteWarm(false)
  }

  const revealNote = game.stage >= 3 && noteWarm

  return (
    <div
      ref={roomRef}
      className={`room ${lampOn ? 'lamp-on' : ''} ${game.stage >= 2 ? 'lamp-wired' : ''}`}
      data-stage={game.stage}
    >
      <div className="wall" />
      <div className="wainscot" />
      <div className="floor" />
      <div className="lamp-glow" aria-hidden />

      {/* ---- Painting ---- */}
      <button className="obj painting" style={{ left: '5%', top: '8%', width: '17%', height: '22%' }} onClick={() => onInspect('painting')} aria-label="Painting">
        <div className="frame">
          <div className="canvas">
            {PAINTING.map((c, i) => (
              <div key={i} className="stripe" style={{ background: COLOR_HEX[c] }} />
            ))}
            <div className="canvas-moon" />
            <div className="canvas-reeds" />
          </div>
        </div>
        <span className="plaque">Dusk over the Marsh</span>
      </button>

      {/* ---- Corkboard with note ---- */}
      <div className="obj corkboard" style={{ left: '25%', top: '12%', width: '11%', height: '15%' }}>
        <div
          className={`note ${revealNote ? 'warm' : ''} ${game.stage >= 3 ? 'ready' : ''}`}
          onPointerEnter={onNoteEnter}
          onPointerLeave={onNoteLeave}
          role="img"
          aria-label={revealNote ? NOTE_TEXT : 'A blank card pinned to the corkboard'}
        >
          <span className="pin" />
          <p className="note-text">{revealNote ? NOTE_TEXT : ''}</p>
        </div>
      </div>

      {/* ---- Morse poster ---- */}
      <button className="obj poster" style={{ left: '38%', top: '9%', width: '9%', height: '20%' }} onClick={() => onInspect('poster')} aria-label="Morse code wall chart">
        <h4>Morse</h4>
        <div className="poster-grid">
          {['A ·−', 'E ·', 'L ·−··', 'O −−−', 'S ···', 'W ·−−'].map((t) => (
            <span key={t}>{t}</span>
          ))}
        </div>
        <small>tap to read</small>
      </button>

      {/* ---- Door ---- */}
      <div className={`obj door-frame ${game.stage === 7 ? 'unlocked' : ''} ${game.doorOpen ? 'open' : ''}`} style={{ left: '50%', top: '7%', width: '15%', height: '65%' }}>
        <div className="door-dark" />
        <button className="door" onClick={onDoor} aria-label={game.stage === 7 ? 'Door — unbolted' : 'Door — bolted'}>
          <div className="panel panel-top" />
          <div className="panel panel-bottom" />
          <span className="knob" />
          <span className={`bolt ${game.stage === 7 ? 'drawn' : ''}`} />
        </button>
      </div>

      {/* ---- Sampler (Caesar cipher) ---- */}
      <button className="obj sampler" style={{ left: '68%', top: '9%', width: '13%', height: '13%' }} onClick={() => onInspect('sampler')} aria-label="Embroidered sampler">
        <div className="sampler-cloth">
          <p>{CIPHER_TEXT}</p>
        </div>
      </button>

      {/* ---- Safe ---- */}
      <button className={`obj safe ${game.stage >= 4 ? 'open' : ''}`} style={{ left: '69.5%', top: '26%', width: '10%', height: '13%' }} onClick={() => onInspect('safe')} aria-label="Wall safe">
        <div className="safe-door">
          <span className="safe-dial" />
          <span className="safe-handle" />
        </div>
        <div className="safe-inside">{game.stage >= 4 && <Crowbar />}</div>
      </button>

      {/* ---- Bookshelf ---- */}
      <div className="obj bookshelf" style={{ left: '83%', top: '10%', width: '13.5%', height: '62%' }}>
        <div className="shelf-row shelf-top">
          <span className="deco owl" title="A brass owl" />
          <span className="deco globe" />
        </div>
        <div className="shelf-row shelf-books">
          {BOOKS.map((b) => {
            const pulled = game.pulledBooks.includes(b.id)
            return (
              <button
                key={b.id}
                className={`book ${pulled ? 'pulled' : ''}`}
                style={{ background: `linear-gradient(90deg, ${b.color}, ${b.spine})` }}
                onClick={() => onPullBook(b.id)}
                aria-label={`Book: ${b.title}${pulled ? ' (pulled out)' : ''}`}
              >
                <span>{b.title}</span>
              </button>
            )
          })}
        </div>
        <div className="shelf-row shelf-bottom">
          <span className="deco jar" />
          <span className="deco stack" />
        </div>
      </div>

      {/* ---- Desk ---- */}
      <div className="obj desk" style={{ left: '5%', top: '48%', width: '41%', height: '28%' }}>
        <div className="desk-top" />
        <div className="desk-front">
          <button
            className={`drawer ${game.drawerOpen ? 'open' : ''} ${game.stage === 4 ? 'target' : ''}`}
            data-drop="drawer"
            onClick={() => onInspect('drawer')}
            aria-label={game.drawerOpen ? 'Open drawer' : 'Locked drawer'}
          >
            <span className="drawer-face">
              <span className="keyhole" />
            </span>
            <span className="drawer-inside">{game.drawerOpen && <Dial small />}</span>
          </button>
          <div className="desk-panel" />
        </div>
        <div className="desk-leg left" />
        <div className="desk-leg right" />
      </div>

      {/* Items on the desk */}
      <button className="obj lamp" style={{ left: '7%', top: '29%', width: '8%', height: '20%' }} onClick={() => onInspect('lamp')} aria-label={lampOn ? 'Desk lamp (lit)' : 'Desk lamp (dark)'} data-lit={lampOn}>
        <Lamp on={lampOn} />
      </button>

      <button className={`obj lockbox ${game.stage > 1 ? 'open' : ''}`} style={{ left: '17%', top: '39%', width: '8%', height: '9.5%' }} onClick={() => onInspect('lockbox')} aria-label="Brass lockbox">
        <div className="lockbox-lid" />
        <div className="lockbox-body">
          {game.lockDials.map((c, i) => (
            <span key={i} className="mini-dial" style={{ background: COLOR_HEX[c] }} />
          ))}
        </div>
      </button>

      <button className="obj typewriter" style={{ left: '27%', top: '35%', width: '12%', height: '14%' }} onClick={() => onInspect('typewriter')} aria-label="Typewriter">
        <div className="tw-paper" />
        <div className="tw-body">
          <div className="tw-keys">
            {Array.from({ length: 12 }).map((_, i) => (
              <span key={i} />
            ))}
          </div>
        </div>
      </button>

      <button className="obj letter" style={{ left: '39.5%', top: '41.5%', width: '6.5%', height: '7%' }} onClick={() => onInspect('letter')} aria-label="A letter">
        <span />
        <span />
        <span />
      </button>

      {/* ---- Key under the rug ---- */}
      {game.keyState === 'revealed' && (
        <div
          className={`obj key ${keyDrag ? 'dragging' : ''}`}
          style={
            keyDrag
              ? { position: 'fixed', left: keyDrag.x, top: keyDrag.y, width: '5vw', height: '4vw', transform: 'translate(-50%, -50%)' }
              : { left: '63%', top: '84%', width: '5%', height: '5%' }
          }
          onPointerDown={onKeyDown}
          onPointerMove={onKeyMove}
          onPointerUp={onKeyUp}
          onPointerCancel={onKeyUp}
          role="button"
          aria-label="Brass key — drag it to a lock"
        >
          <Key />
        </div>
      )}

      {/* ---- Rug ---- */}
      <div
        className={`obj rug ${rugDraggable ? 'loose' : ''}`}
        style={{
          left: '50%',
          top: '77%',
          width: '31%',
          height: '17%',
          transform: `translate(${(game.rugOffset.x / 31) * 100}%, ${(game.rugOffset.y / 17) * 100}%)`,
        }}
        onPointerDown={onRugDown}
        onPointerMove={onRugMove}
        onPointerUp={onRugUp}
        onPointerCancel={onRugUp}
        role="button"
        aria-label={rugDraggable ? 'Rug — drag to move' : 'Rug, tacked down'}
      >
        <div className="rug-border">
          <div className="rug-inner" />
        </div>
        {!rugDraggable && (
          <>
            <span className="tack" style={{ left: '4%', top: '10%' }} />
            <span className="tack" style={{ right: '4%', top: '10%' }} />
            <span className="tack" style={{ left: '4%', bottom: '10%' }} />
            <span className="tack" style={{ right: '4%', bottom: '10%' }} />
          </>
        )}
      </div>
    </div>
  )
}

function Lamp({ on }: { on: boolean }) {
  return (
    <svg viewBox="0 0 100 160" className="lamp-svg" aria-hidden>
      <defs>
        <radialGradient id="bulbGlow" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor="#fff6c8" stopOpacity="1" />
          <stop offset="100%" stopColor="#ffd36a" stopOpacity="0" />
        </radialGradient>
      </defs>
      <ellipse cx="50" cy="150" rx="26" ry="7" fill="#3b2a1c" />
      <rect x="46" y="70" width="8" height="80" fill="#7a5a30" />
      <path d="M50 74 Q40 56 62 40" stroke="#7a5a30" strokeWidth="7" fill="none" strokeLinecap="round" />
      {on && <circle cx="52" cy="54" r="34" fill="url(#bulbGlow)" />}
      <path d="M30 20 L94 20 L82 56 L42 56 Z" fill={on ? '#d99a3a' : '#5a4a2c'} stroke="#3b2a1c" strokeWidth="2" />
      <ellipse cx="62" cy="56" rx="20" ry="4" fill={on ? '#fff0b8' : '#2a2117'} />
    </svg>
  )
}

function Key() {
  return (
    <svg viewBox="0 0 120 60" className="key-svg" aria-hidden>
      <circle cx="24" cy="30" r="18" fill="none" stroke="#d9a441" strokeWidth="9" />
      <rect x="40" y="26" width="72" height="9" fill="#d9a441" />
      <rect x="92" y="35" width="8" height="12" fill="#d9a441" />
      <rect x="76" y="35" width="8" height="9" fill="#d9a441" />
    </svg>
  )
}

function Crowbar() {
  return (
    <svg viewBox="0 0 120 40" className="crowbar-svg" aria-hidden>
      <path d="M8 22 Q4 8 20 8 L110 8" stroke="#6b6b70" strokeWidth="9" fill="none" strokeLinecap="round" />
      <path d="M104 8 L116 20" stroke="#6b6b70" strokeWidth="9" strokeLinecap="round" />
    </svg>
  )
}

export function Dial({ small, angle = 0 }: { small?: boolean; angle?: number }) {
  return (
    <svg viewBox="0 0 100 100" className={`dial-svg ${small ? 'small' : ''}`} aria-hidden>
      <circle cx="50" cy="50" r="46" fill="#c69a3b" stroke="#6b4a15" strokeWidth="3" />
      <circle cx="50" cy="50" r="34" fill="#e0b757" />
      <g transform={`rotate(${angle} 50 50)`}>
        <path d="M50 12 L46 24 L54 24 Z" fill="#2a1f16" />
      </g>
      {Array.from({ length: 26 }).map((_, i) => (
        <line
          key={i}
          x1="50"
          y1="6"
          x2="50"
          y2={i % 13 === 0 ? 14 : 10}
          stroke="#2a1f16"
          strokeWidth="1.5"
          transform={`rotate(${(i * 360) / 26} 50 50)`}
        />
      ))}
    </svg>
  )
}
