import { useMemo, useRef, useState, type PointerEvent as ReactPointerEvent } from 'react'
import { catmullRom, dist, nearestOnPolyline, polylineToPath, type Point } from '../lib/geometry'
import { mulberry32, rangeInt } from '../lib/rng'
import { STAGE_TOLERANCE, type StageProps } from './types'
import './PathStage.css'

const W = 640
const H = 360
const HALF = STAGE_TOLERANCE.corridorHalfWidth
const END_R = HALF + 6
const SAMPLE_STEP = 2

type Phase = 'idle' | 'tracing'

export function PathStage({ seed, locked, onPass, onFail }: StageProps) {
  const spec = useMemo(() => {
    const rng = mulberry32(seed)
    const waypoints: Point[] = [{ x: 44, y: rangeInt(rng, 80, H - 80) }]
    const xs = [130, 230, 330, 430, 530]
    for (const x of xs) {
      const prev = waypoints[waypoints.length - 1].y
      let y = prev + (rangeInt(rng, 0, 1) === 0 ? -1 : 1) * rangeInt(rng, 70, 120)
      if (y < 50 || y > H - 50) y = prev - (y - prev)
      waypoints.push({ x: x + rangeInt(rng, -12, 12), y })
    }
    waypoints.push({ x: W - 44, y: rangeInt(rng, 80, H - 80) })
    const line = catmullRom(waypoints, 28)
    return { waypoints, line, d: polylineToPath(line), start: line[0], end: line[line.length - 1] }
  }, [seed])

  const svgRef = useRef<SVGSVGElement>(null)
  const phase = useRef<Phase>('idle')
  const last = useRef<Point | null>(null)
  const progressRef = useRef(0)
  const [progress, setProgress] = useState(0)
  const [trail, setTrail] = useState<Point[]>([])
  const [breach, setBreach] = useState<Point | null>(null)
  const [tracing, setTracing] = useState(false)

  const localPoint = (e: ReactPointerEvent<SVGElement>): Point => {
    const rect = svgRef.current!.getBoundingClientRect()
    return { x: e.clientX - rect.left, y: e.clientY - rect.top }
  }

  const reset = () => {
    phase.current = 'idle'
    last.current = null
    progressRef.current = 0
    setTracing(false)
  }

  const onPointerDown = (e: ReactPointerEvent<SVGSVGElement>) => {
    if (locked || phase.current !== 'idle') return
    const p = localPoint(e)
    if (dist(p, spec.start) > END_R) return
    svgRef.current!.setPointerCapture(e.pointerId)
    phase.current = 'tracing'
    last.current = p
    progressRef.current = 0
    setProgress(0)
    setTrail([p])
    setBreach(null)
    setTracing(true)
  }

  const onPointerMove = (e: ReactPointerEvent<SVGSVGElement>) => {
    if (phase.current !== 'tracing' || !last.current) return
    const from = last.current
    const to = localPoint(e)
    const steps = Math.max(1, Math.ceil(dist(from, to) / SAMPLE_STEP))
    let best = progressRef.current
    for (let i = 1; i <= steps; i++) {
      const t = i / steps
      const sample = { x: from.x + (to.x - from.x) * t, y: from.y + (to.y - from.y) * t }
      const near = nearestOnPolyline(spec.line, sample)
      if (near.distance > HALF) {
        setBreach(sample)
        setProgress(best)
        reset()
        onFail(`Left the corridor at ${Math.round(best * 100)}% of the path. Keep the cursor inside the lane.`)
        return
      }
      best = Math.max(best, near.t)
    }
    progressRef.current = best
    last.current = to
    setProgress(best)
    setTrail((prev) => [...prev, to])
  }

  const onPointerUp = (e: ReactPointerEvent<SVGSVGElement>) => {
    if (phase.current !== 'tracing') return
    const p = localPoint(e)
    const done = progressRef.current
    reset()
    if (dist(p, spec.end) <= END_R && done >= 0.97) {
      setProgress(1)
      onPass()
    } else {
      onFail(`Button released at ${Math.round(done * 100)}% of the path, not on END.`)
    }
  }

  const pct = Math.round(progress * 100)

  return (
    <div className="path">
      <svg
        ref={svgRef}
        className={`path__svg${tracing ? ' is-tracing' : ''}${locked ? ' is-locked' : ''}`}
        width={W}
        height={H}
        viewBox={`0 0 ${W} ${H}`}
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerCancel={onPointerUp}
        role="img"
        aria-label="Path tracing corridor"
      >
        <defs>
          <pattern id="path-grid" width={20} height={20} patternUnits="userSpaceOnUse">
            <path d="M 20 0 L 0 0 0 20" fill="none" stroke="rgba(148,163,184,0.12)" strokeWidth={1} />
          </pattern>
        </defs>
        <rect width={W} height={H} rx={14} fill="var(--well)" />
        <rect width={W} height={H} rx={14} fill="url(#path-grid)" />
        <path d={spec.d} fill="none" stroke="rgba(34,211,238,0.35)" strokeWidth={HALF * 2 + 6} strokeLinecap="round" strokeLinejoin="round" />
        <path d={spec.d} fill="none" stroke="#1e293b" strokeWidth={HALF * 2} strokeLinecap="round" strokeLinejoin="round" />
        <path d={spec.d} fill="none" stroke="rgba(255,255,255,0.18)" strokeWidth={1.5} strokeDasharray="6 8" strokeLinecap="round" />
        {trail.length > 1 && (
          <path d={polylineToPath(trail)} fill="none" stroke={locked ? '#4ade80' : 'var(--accent)'} strokeWidth={4} strokeLinecap="round" strokeLinejoin="round" />
        )}
        <g className="path__terminal">
          <circle cx={spec.start.x} cy={spec.start.y} r={END_R} fill="#16a34a" stroke="#bbf7d0" strokeWidth={2} />
          <text x={spec.start.x} y={spec.start.y + 4} textAnchor="middle" className="path__label">
            START
          </text>
        </g>
        <g className="path__terminal">
          <circle cx={spec.end.x} cy={spec.end.y} r={END_R} fill={locked ? '#16a34a' : '#7c3aed'} stroke="#ddd6fe" strokeWidth={2} />
          <text x={spec.end.x} y={spec.end.y + 4} textAnchor="middle" className="path__label">
            END
          </text>
        </g>
        {breach && (
          <g transform={`translate(${breach.x} ${breach.y})`}>
            <circle r={12} fill="rgba(248,113,113,0.25)" />
            <path d="M -6 -6 L 6 6 M 6 -6 L -6 6" stroke="#f87171" strokeWidth={3} strokeLinecap="round" />
          </g>
        )}
        {trail.length > 0 && !locked && (
          <circle cx={trail[trail.length - 1].x} cy={trail[trail.length - 1].y} r={6} fill="#fff" />
        )}
      </svg>

      <div className="path__meter" style={{ width: W }}>
        <div className="path__meter-fill" style={{ width: `${pct}%` }} />
      </div>

      <div className="telemetry">
        <span>
          trace = <b>{pct}%</b>
        </span>
        <span>
          corridor half-width = <b>{HALF}</b> px
        </span>
        <span>
          state = <b>{locked ? 'LOCKED' : tracing ? 'TRACING' : 'IDLE'}</b>
        </span>
      </div>
    </div>
  )
}
