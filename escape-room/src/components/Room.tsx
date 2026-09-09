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
    <div ref={roomRef} className={`room ${lampOn ? 'lamp-on' : ''}`} data-stage={game.stage}>
      <div className="wall" />
      <div className="crown" />
      <div className="rail" />
      <div className="wainscot" />
      <div className="skirting" />
      <div className="floor" />
      <div className="lamp-glow" aria-hidden />

      {/* ---- Painting ---- */}
      <button
        className="obj painting"
        data-label="Painting"
        style={{ left: '4%', top: '7%', width: '18%', height: '24%' }}
        onClick={() => onInspect('painting')}
        aria-label="Painting: Dusk over the Marsh"
      >
        <div className="frame">
          <div className="canvas">
            <PaintingArt />
          </div>
        </div>
        <span className="plaque">Dusk over the Marsh</span>
      </button>

      {/* ---- Corkboard with note ---- */}
      <div className="obj corkboard" style={{ left: '25%', top: '10%', width: '11%', height: '17%' }}>
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
      <button
        className="obj poster"
        data-label="Wall chart"
        style={{ left: '38.5%', top: '8%', width: '8.5%', height: '22%' }}
        onClick={() => onInspect('poster')}
        aria-label="Morse code wall chart"
      >
        <h4>Morse</h4>
        <div className="poster-grid">
          {['A ·−', 'E ·', 'L ·−··', 'O −−−', 'S ···', 'W ·−−'].map((t) => (
            <span key={t}>{t}</span>
          ))}
        </div>
        <small>full alphabet inside</small>
      </button>

      {/* ---- Door ---- */}
      <div
        className={`obj door-frame ${game.stage === 7 ? 'unlocked' : ''} ${game.doorOpen ? 'open' : ''}`}
        data-label={game.stage === 7 ? 'Door — unbolted' : 'Door'}
        style={{ left: '49.5%', top: '6.5%', width: '15%', height: '63.5%' }}
      >
        <div className="lintel" />
        <div className="door-dark" />
        <button className="door" onClick={onDoor} aria-label={game.stage === 7 ? 'Door — unbolted' : 'Door — bolted'}>
          <div className="panel panel-top" />
          <div className="panel panel-mid" />
          <div className="panel panel-bottom" />
          <span className="knob" />
          <span className={`bolt ${game.stage === 7 ? 'drawn' : ''}`} />
        </button>
      </div>

      {/* ---- Sampler (Caesar cipher) ---- */}
      <button
        className="obj sampler"
        data-label="Sampler"
        style={{ left: '67%', top: '8%', width: '13.5%', height: '14%' }}
        onClick={() => onInspect('sampler')}
        aria-label="Embroidered sampler"
      >
        <div className="sampler-cloth">
          <p>{CIPHER_TEXT}</p>
        </div>
      </button>

      {/* ---- Safe ---- */}
      <button
        className={`obj safe ${game.stage >= 4 ? 'open' : ''}`}
        data-label="Wall safe"
        style={{ left: '68.5%', top: '26%', width: '10.5%', height: '15%' }}
        onClick={() => onInspect('safe')}
        aria-label="Wall safe"
      >
        <div className="safe-door">
          <span className="safe-dial" />
          <span className="safe-handle" />
        </div>
        <div className="safe-inside">{game.stage >= 4 && <Crowbar />}</div>
      </button>

      {/* ---- Bookshelf ---- */}
      <div className="obj bookshelf" style={{ left: '83.5%', top: '7%', width: '13%', height: '63%' }}>
        <div className="shelf-row shelf-top">
          <Owl />
          <Globe />
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
          <Jar />
          <BookStack />
        </div>
      </div>

      {/* ---- Desk ---- */}
      <div className="obj desk" style={{ left: '4%', top: '46%', width: '42%', height: '31%' }}>
        <div className="desk-shadow" />
        <div className="desk-top" />
        <div className="desk-leather" />
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
      <button
        className="obj lamp z-front"
        data-label={lampOn ? 'Lamp — lit' : 'Lamp'}
        style={{ left: '5.5%', top: '25%', width: '9%', height: '22%' }}
        onClick={() => onInspect('lamp')}
        aria-label={lampOn ? 'Desk lamp (lit)' : 'Desk lamp (dark)'}
        data-lit={lampOn}
      >
        <BankersLamp on={lampOn} />
      </button>

      <button
        className={`obj lockbox z-front ${game.stage > 1 ? 'open' : ''}`}
        data-label="Lockbox"
        style={{ left: '16.5%', top: '37.5%', width: '8.5%', height: '9.5%' }}
        onClick={() => onInspect('lockbox')}
        aria-label="Brass lockbox"
      >
        <div className="lockbox-lid" />
        <div className="lockbox-body">
          {game.lockDials.map((c, i) => (
            <span key={i} className="mini-dial" style={{ background: COLOR_HEX[c] }} />
          ))}
        </div>
      </button>

      <button
        className="obj typewriter z-front"
        data-label="Typewriter"
        style={{ left: '26.5%', top: '31%', width: '12.5%', height: '16%' }}
        onClick={() => onInspect('typewriter')}
        aria-label="Typewriter"
      >
        <TypewriterArt />
      </button>

      <button
        className="obj letter z-front"
        data-label="Letter"
        style={{ left: '39.5%', top: '39.5%', width: '6.5%', height: '7.5%' }}
        onClick={() => onInspect('letter')}
        aria-label="A letter"
      >
        <span />
        <span />
        <span />
        <span />
        <i className="seal" />
      </button>

      {/* ---- Key under the rug ---- */}
      {game.keyState === 'revealed' && (
        <div
          className={`obj key ${keyDrag ? 'dragging' : ''}`}
          style={
            keyDrag
              ? { position: 'fixed', left: keyDrag.x, top: keyDrag.y, width: '5vw', height: '3vw', transform: 'translate(-50%, -50%)' }
              : { left: '63%', top: '85%', width: '5%', height: '5%' }
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
          top: '78%',
          width: '32%',
          height: '17%',
          transform: `translate(${(game.rugOffset.x / 32) * 100}%, ${(game.rugOffset.y / 17) * 100}%)`,
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
            <span className="tack" style={{ left: '3%', top: '9%' }} />
            <span className="tack" style={{ right: '3%', top: '9%' }} />
            <span className="tack" style={{ left: '3%', bottom: '9%' }} />
            <span className="tack" style={{ right: '3%', bottom: '9%' }} />
          </>
        )}
      </div>
    </div>
  )
}

/* =====================================================================
   Scene art
   ===================================================================== */

/** Four horizontal bands (sky → water) with a moon, hills and reeds. The bands are the lock code. */
export function PaintingArt() {
  const bands = PAINTING.map((c) => COLOR_HEX[c])
  return (
    <svg viewBox="0 0 400 300" preserveAspectRatio="none" aria-hidden>
      <defs>
        <radialGradient id="moonGlow" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor="#fff7dc" stopOpacity="0.95" />
          <stop offset="60%" stopColor="#fff2c8" stopOpacity="0.25" />
          <stop offset="100%" stopColor="#fff2c8" stopOpacity="0" />
        </radialGradient>
      </defs>
      {bands.map((hex, i) => (
        <rect key={i} x="0" y={i * 75} width="400" height="75" fill={hex} />
      ))}
      {/* texture: soft horizontal brush strokes */}
      {Array.from({ length: 18 }).map((_, i) => (
        <rect key={i} x="0" y={i * 17 + 4} width="400" height="3" fill="rgba(255,255,255,0.06)" />
      ))}
      <circle cx="300" cy="38" r="40" fill="url(#moonGlow)" />
      <circle cx="300" cy="38" r="20" fill="#fff5d6" />
      {/* distant hills on the second band */}
      <path d="M0 110 Q60 82 120 104 T240 100 T400 96 L400 150 L0 150 Z" fill="rgba(0,0,0,0.22)" />
      {/* reeds in the water */}
      <g stroke="#1b1a14" strokeWidth="3" strokeLinecap="round" fill="none">
        <path d="M40 300 L52 232" />
        <path d="M60 300 L66 222" />
        <path d="M80 300 L84 240" />
        <path d="M330 300 L344 236" />
        <path d="M352 300 L356 226" />
        <path d="M372 300 L380 244" />
      </g>
      <g fill="#1b1a14">
        <ellipse cx="53" cy="228" rx="3" ry="9" />
        <ellipse cx="66" cy="218" rx="3" ry="9" />
        <ellipse cx="356" cy="222" rx="3" ry="9" />
      </g>
      {/* birds */}
      <g stroke="#1b1a14" strokeWidth="2.5" fill="none" strokeLinecap="round">
        <path d="M150 40 q8 -8 16 0 q8 -8 16 0" />
        <path d="M190 58 q6 -6 12 0 q6 -6 12 0" />
      </g>
    </svg>
  )
}

function BankersLamp({ on }: { on: boolean }) {
  return (
    <svg viewBox="0 0 120 160" className="lamp-svg" aria-hidden>
      <defs>
        <radialGradient id="lampSpill" cx="50%" cy="20%" r="70%">
          <stop offset="0%" stopColor="#fff2c0" stopOpacity="0.95" />
          <stop offset="100%" stopColor="#ffd36a" stopOpacity="0" />
        </radialGradient>
        <linearGradient id="brassV" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stopColor="#7a5418" />
          <stop offset="45%" stopColor="#efcf7c" />
          <stop offset="100%" stopColor="#8d6a24" />
        </linearGradient>
        <linearGradient id="shadeG" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={on ? '#3f9a70' : '#1f4a3a'} />
          <stop offset="100%" stopColor={on ? '#1f5f4e' : '#12302a'} />
        </linearGradient>
      </defs>
      {/* base */}
      <ellipse cx="60" cy="150" rx="34" ry="8" fill="rgba(0,0,0,0.45)" />
      <ellipse cx="60" cy="146" rx="30" ry="7" fill="url(#brassV)" />
      <rect x="30" y="138" width="60" height="8" rx="3" fill="url(#brassV)" />
      {/* stem */}
      <rect x="56" y="70" width="8" height="70" fill="url(#brassV)" />
      <circle cx="60" cy="70" r="6" fill="#efcf7c" />
      {/* pull chain */}
      <line x1="72" y1="72" x2="74" y2="98" stroke="#d2b06a" strokeWidth="1.5" strokeDasharray="2 2" />
      {/* light spill under shade */}
      {on && <ellipse cx="60" cy="60" rx="58" ry="26" fill="url(#lampSpill)" />}
      {/* shade */}
      <path d="M12 56 Q60 22 108 56 L104 66 Q60 40 16 66 Z" fill="url(#shadeG)" stroke="#0f2a22" strokeWidth="1.5" />
      <path d="M16 66 Q60 40 104 66 L100 74 Q60 52 20 74 Z" fill={on ? '#fff0b8' : '#2a2117'} />
      <path d="M18 56 Q60 26 102 56" fill="none" stroke="rgba(255,255,255,0.28)" strokeWidth="2" />
      {/* bulb */}
      <ellipse cx="60" cy="68" rx="14" ry="6" fill={on ? '#fff6d0' : '#4a4032'} />
    </svg>
  )
}

function TypewriterArt() {
  return (
    <svg viewBox="0 0 220 150" className="tw-svg" aria-hidden>
      <defs>
        <linearGradient id="twBody" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#3a3d44" />
          <stop offset="100%" stopColor="#15171b" />
        </linearGradient>
      </defs>
      {/* paper */}
      <rect x="66" y="0" width="88" height="66" fill="#f4ecd8" />
      <g stroke="#a89a7a" strokeWidth="2" strokeLinecap="round">
        <line x1="78" y1="14" x2="140" y2="14" />
        <line x1="78" y1="26" x2="128" y2="26" />
        <line x1="78" y1="38" x2="136" y2="38" />
      </g>
      {/* platen */}
      <rect x="30" y="56" width="160" height="16" rx="8" fill="#23262b" />
      <rect x="14" y="58" width="14" height="12" rx="3" fill="#8a8f97" />
      <rect x="192" y="58" width="14" height="12" rx="3" fill="#8a8f97" />
      {/* body */}
      <path d="M20 74 L200 74 L214 132 Q214 140 206 140 L14 140 Q6 140 6 132 Z" fill="url(#twBody)" stroke="#0b0c0f" strokeWidth="2" />
      <rect x="60" y="78" width="100" height="10" rx="2" fill="#0d0e11" />
      {/* keys */}
      {Array.from({ length: 3 }).map((_, row) =>
        Array.from({ length: 10 - row }).map((_, i) => (
          <circle
            key={`${row}-${i}`}
            cx={36 + row * 8 + i * 16.5}
            cy={100 + row * 13}
            r="5.5"
            fill="#e8e2d2"
            stroke="#5a5a5a"
            strokeWidth="1"
          />
        )),
      )}
      <rect x="66" y="134" width="90" height="4" rx="2" fill="#e8e2d2" />
    </svg>
  )
}

function Owl() {
  return (
    <svg viewBox="0 0 60 80" className="deco-svg" aria-hidden>
      <ellipse cx="30" cy="78" rx="18" ry="3" fill="rgba(0,0,0,0.4)" />
      <path d="M14 74 Q10 40 22 28 L20 16 L30 24 L40 16 L38 28 Q50 40 46 74 Z" fill="#c99a3e" />
      <ellipse cx="30" cy="54" rx="11" ry="14" fill="#8d6a24" />
      <circle cx="24" cy="36" r="5.5" fill="#fff3d0" />
      <circle cx="36" cy="36" r="5.5" fill="#fff3d0" />
      <circle cx="24" cy="36" r="2.5" fill="#1b1a14" />
      <circle cx="36" cy="36" r="2.5" fill="#1b1a14" />
      <path d="M30 40 L27 46 L33 46 Z" fill="#5c3a13" />
    </svg>
  )
}

function Globe() {
  return (
    <svg viewBox="0 0 70 90" className="deco-svg" aria-hidden>
      <ellipse cx="35" cy="88" rx="18" ry="3" fill="rgba(0,0,0,0.4)" />
      <rect x="32" y="66" width="6" height="18" fill="#8d6a24" />
      <ellipse cx="35" cy="84" rx="16" ry="4" fill="#a8782a" />
      <path d="M12 26 A26 26 0 1 0 12 62" fill="none" stroke="#c99a3e" strokeWidth="3" />
      <circle cx="35" cy="42" r="24" fill="#2f5f8a" />
      <path d="M18 38 q10 -10 22 -4 q8 4 12 -2 v14 q-10 8 -22 4 q-8 -3 -12 2 z" fill="#5a8a4e" />
      <path d="M24 56 q8 -4 16 0 q6 2 8 6 q-14 6 -26 0 z" fill="#5a8a4e" />
      <circle cx="35" cy="42" r="24" fill="none" stroke="#c99a3e" strokeWidth="1.5" />
    </svg>
  )
}

function Jar() {
  return (
    <svg viewBox="0 0 50 80" className="deco-svg short" aria-hidden>
      <rect x="16" y="6" width="18" height="8" rx="2" fill="#8a6a24" />
      <path d="M10 18 Q10 12 16 12 L34 12 Q40 12 40 18 L40 72 Q40 78 34 78 L16 78 Q10 78 10 72 Z" fill="rgba(140,190,200,0.35)" stroke="rgba(255,255,255,0.35)" strokeWidth="1.5" />
      <rect x="14" y="40" width="22" height="34" fill="#4a6e3a" opacity="0.8" />
      <rect x="15" y="30" width="20" height="14" fill="#f1e8d3" />
    </svg>
  )
}

function BookStack() {
  return (
    <svg viewBox="0 0 90 60" className="deco-svg short" aria-hidden>
      <rect x="4" y="44" width="80" height="14" rx="2" fill="#6b3a2a" />
      <rect x="10" y="30" width="72" height="14" rx="2" fill="#2d4a6e" />
      <rect x="16" y="16" width="60" height="14" rx="2" fill="#8a6a24" />
      <g stroke="rgba(234,199,120,0.7)" strokeWidth="1.5">
        <line x1="10" y1="51" x2="78" y2="51" />
        <line x1="16" y1="37" x2="76" y2="37" />
        <line x1="22" y1="23" x2="70" y2="23" />
      </g>
    </svg>
  )
}

function Key() {
  return (
    <svg viewBox="0 0 120 60" className="key-svg" aria-hidden>
      <defs>
        <linearGradient id="keyG" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#f3d68a" />
          <stop offset="100%" stopColor="#a8782a" />
        </linearGradient>
      </defs>
      <circle cx="24" cy="30" r="18" fill="none" stroke="url(#keyG)" strokeWidth="9" />
      <circle cx="24" cy="30" r="5" fill="#2a1d08" />
      <rect x="40" y="26" width="72" height="9" rx="2" fill="url(#keyG)" />
      <rect x="92" y="35" width="8" height="13" fill="url(#keyG)" />
      <rect x="76" y="35" width="8" height="10" fill="url(#keyG)" />
    </svg>
  )
}

function Crowbar() {
  return (
    <svg viewBox="0 0 120 40" className="crowbar-svg" aria-hidden>
      <path d="M8 22 Q4 8 20 8 L110 8" stroke="#8a8f97" strokeWidth="9" fill="none" strokeLinecap="round" />
      <path d="M104 8 L116 20" stroke="#8a8f97" strokeWidth="9" strokeLinecap="round" />
      <path d="M8 22 Q4 8 20 8 L110 8" stroke="rgba(255,255,255,0.25)" strokeWidth="2" fill="none" strokeLinecap="round" />
    </svg>
  )
}

export function Dial({ small, angle = 0 }: { small?: boolean; angle?: number }) {
  return (
    <svg viewBox="0 0 100 100" className={`dial-svg ${small ? 'small' : ''}`} aria-hidden>
      <defs>
        <radialGradient id="dialFace" cx="40%" cy="35%" r="70%">
          <stop offset="0%" stopColor="#f0d48a" />
          <stop offset="100%" stopColor="#b8873a" />
        </radialGradient>
      </defs>
      <circle cx="50" cy="50" r="47" fill="#8d6a24" />
      <circle cx="50" cy="50" r="44" fill="url(#dialFace)" stroke="#6b4a15" strokeWidth="2" />
      {Array.from({ length: 26 }).map((_, i) => (
        <line
          key={i}
          x1="50"
          y1="8"
          x2="50"
          y2={i % 13 === 0 ? 17 : 12}
          stroke="#2a1f16"
          strokeWidth="1.6"
          transform={`rotate(${(i * 360) / 26} 50 50)`}
        />
      ))}
      <g transform={`rotate(${angle} 50 50)`}>
        <circle cx="50" cy="50" r="24" fill="#e0b757" stroke="#6b4a15" strokeWidth="1.5" />
        <path d="M50 20 L44 34 L56 34 Z" fill="#2a1f16" />
        <rect x="47" y="34" width="6" height="30" rx="2" fill="#2a1f16" />
      </g>
      <circle cx="50" cy="50" r="4" fill="#6b4a15" />
    </svg>
  )
}
