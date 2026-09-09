import { useMemo, useRef, useState, type PointerEvent as ReactPointerEvent } from 'react'
import { SceneSvg } from '../components/SceneSvg'
import { clamp } from '../lib/geometry'
import { jigsawPath, type Tab } from '../lib/jigsaw'
import { mulberry32, pick, rangeInt } from '../lib/rng'
import { buildScene } from '../lib/scene'
import { STAGE_TOLERANCE, type StageProps } from './types'
import './SliderStage.css'

const W = 560
const H = 320
const PIECE = 64
const START_X = 8
const TABS_CHOICES: readonly Tab[] = [1, -1]

export function SliderStage({ seed, locked, onPass, onFail }: StageProps) {
  const spec = useMemo(() => {
    const rng = mulberry32(seed)
    const targetX = rangeInt(rng, 220, W - PIECE - 48)
    const pieceY = rangeInt(rng, 60, H - PIECE - 56)
    const tabs = [pick(rng, TABS_CHOICES), pick(rng, TABS_CHOICES), pick(rng, TABS_CHOICES), pick(rng, TABS_CHOICES)] as const
    return { targetX, pieceY, tabs, path: jigsawPath(PIECE, tabs), scene: buildScene(seed, W, H) }
  }, [seed])

  const [x, setXState] = useState(START_X)
  const xRef = useRef(START_X)
  const setX = (next: number) => {
    xRef.current = next
    setXState(next)
  }
  const [dragging, setDragging] = useState(false)
  const drag = useRef<{ startClient: number; startX: number } | null>(null)

  const onPointerDown = (e: ReactPointerEvent<HTMLElement | SVGElement>) => {
    if (locked) return
    e.currentTarget.setPointerCapture(e.pointerId)
    drag.current = { startClient: e.clientX, startX: xRef.current }
    setDragging(true)
  }
  const onPointerMove = (e: ReactPointerEvent<HTMLElement | SVGElement>) => {
    if (!drag.current) return
    setX(clamp(Math.round(drag.current.startX + (e.clientX - drag.current.startClient)), 0, W - PIECE))
  }
  const onPointerUp = () => {
    if (!drag.current) return
    drag.current = null
    setDragging(false)
    const delta = xRef.current - spec.targetX
    if (Math.abs(delta) <= STAGE_TOLERANCE.slidePx) {
      setX(spec.targetX)
      onPass()
    } else {
      setX(START_X)
      onFail(`Piece released ${Math.abs(delta)} px ${delta < 0 ? 'short of' : 'past'} the notch (tolerance ±${STAGE_TOLERANCE.slidePx} px).`)
    }
  }

  const handlers = { onPointerDown, onPointerMove, onPointerUp, onPointerCancel: onPointerUp }
  const clipId = `slide-clip-${seed}`

  return (
    <div className="slide">
      <svg className="slide__image" width={W} height={H} viewBox={`0 0 ${W} ${H}`} role="img" aria-label="Puzzle image with a missing piece">
        <defs>
          <clipPath id={clipId}>
            <path d={spec.path} />
          </clipPath>
          <filter id="slide-shadow" x="-30%" y="-30%" width="160%" height="160%">
            <feDropShadow dx="0" dy="4" stdDeviation="4" floodColor="#000" floodOpacity="0.5" />
          </filter>
        </defs>
        <g id={`slide-scene-${seed}`}>
          <SceneSvg spec={spec.scene} id={`slide-${seed}`} />
        </g>
        <path
          className="slide__notch"
          d={spec.path}
          transform={`translate(${spec.targetX} ${spec.pieceY})`}
          fill="rgba(2, 6, 23, 0.72)"
          stroke="rgba(255,255,255,0.85)"
          strokeWidth={1.5}
          strokeDasharray="4 3"
        />
        <g
          className={`slide__piece${dragging ? ' is-dragging' : ''}${locked ? ' is-locked' : ''}`}
          transform={`translate(${x} ${spec.pieceY})`}
          filter="url(#slide-shadow)"
          {...handlers}
        >
          <g clipPath={`url(#${clipId})`}>
            <g transform={`translate(${-spec.targetX} ${-spec.pieceY})`}>
              <SceneSvg spec={spec.scene} id={`slide-piece-${seed}`} />
            </g>
          </g>
          <path d={spec.path} fill="none" stroke={locked ? '#4ade80' : '#fff'} strokeWidth={2} />
        </g>
      </svg>

      <div className="slide__track" style={{ width: W }}>
        <div className="slide__rail" />
        <div className="slide__fill" style={{ width: x + PIECE / 2 }} />
        <button
          type="button"
          className={`slide__handle${dragging ? ' is-dragging' : ''}${locked ? ' is-locked' : ''}`}
          style={{ left: x, width: PIECE }}
          aria-label="Slider handle"
          aria-valuemin={0}
          aria-valuemax={W - PIECE}
          aria-valuenow={x}
          role="slider"
          disabled={locked}
          {...handlers}
        >
          <span className="slide__grip" />
          <span className="slide__grip" />
          <span className="slide__grip" />
        </button>
      </div>

      <div className="telemetry">
        <span>
          piece.x = <b>{x}</b> px
        </span>
        <span>
          notch tolerance = <b>±{STAGE_TOLERANCE.slidePx}</b> px
        </span>
        <span>
          state = <b>{locked ? 'LOCKED' : dragging ? 'DRAGGING' : 'IDLE'}</b>
        </span>
      </div>
    </div>
  )
}
