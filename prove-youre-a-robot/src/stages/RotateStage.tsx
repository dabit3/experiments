import { useMemo, useRef, useState, type PointerEvent as ReactPointerEvent } from 'react'
import { SceneSvg } from '../components/SceneSvg'
import { normalizeAngle } from '../lib/geometry'
import { mulberry32, pick, rangeInt } from '../lib/rng'
import { buildScene } from '../lib/scene'
import { STAGE_TOLERANCE, type StageProps } from './types'
import './RotateStage.css'

const SIZE = 460
const C = SIZE / 2
const IMG_R = 150
const DIAL_R = 205
const KNOB_R = 20
const SCENE_W = 400
const SCENE_H = 300

export function RotateStage({ seed, locked, onPass, onFail }: StageProps) {
  const spec = useMemo(() => {
    const rng = mulberry32(seed)
    const sign = pick(rng, [-1, 1] as const)
    const initial = sign * rangeInt(rng, 40, 150)
    return { initial, scene: buildScene(seed, SCENE_W, SCENE_H) }
  }, [seed])

  const [delta, setDeltaState] = useState(0)
  const deltaRef = useRef(0)
  const setDelta = (d: number) => {
    deltaRef.current = d
    setDeltaState(d)
  }
  const [dragging, setDragging] = useState(false)
  const svgRef = useRef<SVGSVGElement>(null)
  const lastAngle = useRef<number | null>(null)

  const angleOf = (e: ReactPointerEvent<SVGElement>): number => {
    const rect = svgRef.current!.getBoundingClientRect()
    const cx = rect.left + rect.width / 2
    const cy = rect.top + rect.height / 2
    return (Math.atan2(e.clientY - cy, e.clientX - cx) * 180) / Math.PI
  }

  const onPointerDown = (e: ReactPointerEvent<SVGElement>) => {
    if (locked) return
    const rect = svgRef.current!.getBoundingClientRect()
    const dx = e.clientX - (rect.left + rect.width / 2)
    const dy = e.clientY - (rect.top + rect.height / 2)
    const r = Math.hypot(dx, dy)
    if (r < DIAL_R - 34 || r > DIAL_R + 34) return
    svgRef.current!.setPointerCapture(e.pointerId)
    lastAngle.current = angleOf(e)
    setDragging(true)
  }
  const onPointerMove = (e: ReactPointerEvent<SVGElement>) => {
    if (lastAngle.current === null) return
    const a = angleOf(e)
    const diff = normalizeAngle(a - lastAngle.current)
    lastAngle.current = a
    setDelta(deltaRef.current + diff)
  }
  const onPointerUp = () => {
    if (lastAngle.current === null) return
    lastAngle.current = null
    setDragging(false)
    const total = normalizeAngle(spec.initial + deltaRef.current)
    if (Math.abs(total) <= STAGE_TOLERANCE.rotateDeg) {
      setDelta(-spec.initial)
      onPass()
    } else {
      setDelta(0)
      onFail(`Image is ${Math.abs(Math.round(total))}° from upright (tolerance ±${STAGE_TOLERANCE.rotateDeg}°).`)
    }
  }

  const rotation = spec.initial + delta
  const knobAngle = ((delta - 90) * Math.PI) / 180
  const knob = { x: C + DIAL_R * Math.cos(knobAngle), y: C + DIAL_R * Math.sin(knobAngle) }
  const shown = Math.round(normalizeAngle(delta))
  const ticks = Array.from({ length: 36 }, (_, i) => i * 10)

  return (
    <div className="rotate">
      <svg
        ref={svgRef}
        className={`rotate__svg${dragging ? ' is-dragging' : ''}${locked ? ' is-locked' : ''}`}
        width={SIZE}
        height={SIZE}
        viewBox={`0 0 ${SIZE} ${SIZE}`}
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerCancel={onPointerUp}
        role="img"
        aria-label="Rotation dial"
      >
        <defs>
          <clipPath id={`rotate-clip-${seed}`}>
            <circle cx={C} cy={C} r={IMG_R} />
          </clipPath>
        </defs>
        <circle cx={C} cy={C} r={DIAL_R} fill="none" stroke="var(--well)" strokeWidth={30} />
        <circle cx={C} cy={C} r={DIAL_R + 15} fill="none" stroke="var(--line)" strokeWidth={1} />
        <circle cx={C} cy={C} r={DIAL_R - 15} fill="none" stroke="var(--line)" strokeWidth={1} />
        {ticks.map((t) => {
          const a = ((t - 90) * Math.PI) / 180
          const major = t % 90 === 0
          const r1 = DIAL_R - (major ? 10 : 6)
          const r2 = DIAL_R + (major ? 10 : 6)
          return (
            <line
              key={t}
              x1={C + r1 * Math.cos(a)}
              y1={C + r1 * Math.sin(a)}
              x2={C + r2 * Math.cos(a)}
              y2={C + r2 * Math.sin(a)}
              stroke={major ? 'rgba(255,255,255,0.7)' : 'rgba(255,255,255,0.28)'}
              strokeWidth={major ? 2 : 1}
            />
          )
        })}
        <path
          d={`M ${C - 10} ${C - DIAL_R - 30} L ${C + 10} ${C - DIAL_R - 30} L ${C} ${C - DIAL_R - 18} Z`}
          fill="var(--accent)"
        />
        <circle cx={C} cy={C} r={IMG_R + 6} fill="#020617" />
        <g clipPath={`url(#rotate-clip-${seed})`} transform={`rotate(${rotation} ${C} ${C})`}>
          <g transform={`translate(${C - SCENE_W / 2} ${C - SCENE_H / 2})`}>
            <SceneSvg spec={spec.scene} id={`rotate-${seed}`} />
          </g>
        </g>
        <circle cx={C} cy={C} r={IMG_R} fill="none" stroke={locked ? '#4ade80' : 'rgba(255,255,255,0.6)'} strokeWidth={2} />
        <line x1={C} y1={C} x2={knob.x} y2={knob.y} stroke="var(--accent)" strokeWidth={2} opacity={0.35} strokeDasharray="3 5" />
        <circle className="rotate__knob-glow" cx={knob.x} cy={knob.y} r={KNOB_R + 10} fill="var(--accent)" opacity={dragging ? 0.3 : 0.15} />
        <circle className="rotate__knob" cx={knob.x} cy={knob.y} r={KNOB_R} fill={locked ? '#22c55e' : 'var(--accent)'} stroke="#fff" strokeWidth={2} />
        <circle cx={knob.x} cy={knob.y} r={5} fill="#fff" />
      </svg>

      <div className="telemetry">
        <span>
          dial = <b>{shown >= 0 ? '+' : ''}{shown}°</b>
        </span>
        <span>
          upright tolerance = <b>±{STAGE_TOLERANCE.rotateDeg}°</b>
        </span>
        <span>
          state = <b>{locked ? 'LOCKED' : dragging ? 'TURNING' : 'IDLE'}</b>
        </span>
      </div>
    </div>
  )
}
