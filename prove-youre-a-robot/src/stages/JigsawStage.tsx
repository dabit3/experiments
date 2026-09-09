import { useMemo, useRef, useState, type PointerEvent as ReactPointerEvent } from 'react'
import { SceneSvg } from '../components/SceneSvg'
import { clamp, type Point } from '../lib/geometry'
import { jigsawPath, type Tab } from '../lib/jigsaw'
import { mulberry32, pick, rangeInt } from '../lib/rng'
import { buildScene } from '../lib/scene'
import { STAGE_TOLERANCE, type StageProps } from './types'
import './JigsawStage.css'

const BOARD_W = 480
const BOARD_H = 300
const GAP = 24
const TRAY_W = 168
const W = BOARD_W + GAP + TRAY_W
const H = BOARD_H
const PIECE = 96
const TABS_CHOICES: readonly Tab[] = [1, -1]

export function JigsawStage({ seed, locked, onPass, onFail }: StageProps) {
  const spec = useMemo(() => {
    const rng = mulberry32(seed)
    const hole: Point = { x: rangeInt(rng, 60, BOARD_W - PIECE - 60), y: rangeInt(rng, 40, BOARD_H - PIECE - 40) }
    const tabs = [pick(rng, TABS_CHOICES), pick(rng, TABS_CHOICES), pick(rng, TABS_CHOICES), pick(rng, TABS_CHOICES)] as const
    const tray: Point = { x: BOARD_W + GAP + (TRAY_W - PIECE) / 2, y: rangeInt(rng, 50, BOARD_H - PIECE - 50) }
    return { hole, tray, path: jigsawPath(PIECE, tabs), scene: buildScene(seed, BOARD_W, BOARD_H) }
  }, [seed])

  const [pos, setPosState] = useState<Point>(spec.tray)
  const posRef = useRef<Point>(spec.tray)
  const setPos = (p: Point) => {
    posRef.current = p
    setPosState(p)
  }
  const [dragging, setDragging] = useState(false)
  const drag = useRef<{ client: Point; start: Point } | null>(null)

  const onPointerDown = (e: ReactPointerEvent<SVGGElement>) => {
    if (locked) return
    e.currentTarget.setPointerCapture(e.pointerId)
    drag.current = { client: { x: e.clientX, y: e.clientY }, start: posRef.current }
    setDragging(true)
  }
  const onPointerMove = (e: ReactPointerEvent<SVGGElement>) => {
    if (!drag.current) return
    setPos({
      x: clamp(Math.round(drag.current.start.x + e.clientX - drag.current.client.x), -20, W - PIECE + 20),
      y: clamp(Math.round(drag.current.start.y + e.clientY - drag.current.client.y), -20, H - PIECE + 20),
    })
  }
  const onPointerUp = () => {
    if (!drag.current) return
    drag.current = null
    setDragging(false)
    const dx = posRef.current.x - spec.hole.x
    const dy = posRef.current.y - spec.hole.y
    const tol = STAGE_TOLERANCE.jigsawPx
    if (Math.abs(dx) <= tol && Math.abs(dy) <= tol) {
      setPos(spec.hole)
      onPass()
    } else {
      const fmt = (n: number) => `${n > 0 ? '+' : ''}${n}`
      setPos(spec.tray)
      onFail(`Dropped ${fmt(dx)} px / ${fmt(dy)} px from the hole (tolerance ±${tol} px on each axis).`)
    }
  }

  const clipId = `jigsaw-clip-${seed}`
  const boardClip = `jigsaw-board-${seed}`

  return (
    <div className="jigsaw">
      <svg className="jigsaw__svg" width={W} height={H} viewBox={`0 0 ${W} ${H}`} role="img" aria-label="Jigsaw board and tray">
        <defs>
          <clipPath id={clipId}>
            <path d={spec.path} />
          </clipPath>
          <clipPath id={boardClip}>
            <rect width={BOARD_W} height={BOARD_H} rx={14} />
          </clipPath>
          <filter id="jigsaw-shadow" x="-30%" y="-30%" width="160%" height="160%">
            <feDropShadow dx="0" dy="6" stdDeviation="5" floodColor="#000" floodOpacity="0.55" />
          </filter>
        </defs>

        <g clipPath={`url(#${boardClip})`}>
          <SceneSvg spec={spec.scene} id={`jigsaw-${seed}`} />
          <path
            d={spec.path}
            transform={`translate(${spec.hole.x} ${spec.hole.y})`}
            fill="rgba(2, 6, 23, 0.8)"
            stroke="rgba(255,255,255,0.9)"
            strokeWidth={1.5}
            strokeDasharray="4 3"
          />
        </g>
        <rect width={BOARD_W} height={BOARD_H} rx={14} fill="none" stroke="var(--line)" />

        <rect x={BOARD_W + GAP} y={0} width={TRAY_W} height={H} rx={14} fill="var(--well)" stroke="var(--line)" />
        <text x={BOARD_W + GAP + TRAY_W / 2} y={22} textAnchor="middle" className="jigsaw__tray-label">
          TRAY
        </text>

        <g
          className={`jigsaw__piece${dragging ? ' is-dragging' : ''}${locked ? ' is-locked' : ''}`}
          transform={`translate(${pos.x} ${pos.y})`}
          filter={locked ? undefined : 'url(#jigsaw-shadow)'}
          opacity={dragging ? 0.82 : 1}
          onPointerDown={onPointerDown}
          onPointerMove={onPointerMove}
          onPointerUp={onPointerUp}
          onPointerCancel={onPointerUp}
        >
          <g clipPath={`url(#${clipId})`}>
            <g transform={`translate(${-spec.hole.x} ${-spec.hole.y})`}>
              <SceneSvg spec={spec.scene} id={`jigsaw-piece-${seed}`} />
            </g>
          </g>
          <path d={spec.path} fill="none" stroke={locked ? '#4ade80' : '#fff'} strokeWidth={2} />
        </g>
      </svg>

      <div className="telemetry">
        <span>
          piece @ (<b>{pos.x}</b>, <b>{pos.y}</b>)
        </span>
        <span>
          drop tolerance = <b>±{STAGE_TOLERANCE.jigsawPx}</b> px
        </span>
        <span>
          state = <b>{locked ? 'LOCKED' : dragging ? 'CARRYING' : 'IDLE'}</b>
        </span>
      </div>
    </div>
  )
}
