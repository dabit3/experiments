import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { LEVELS, SCENE_H, SCENE_W, type Level } from './levels.ts'
import { PART_DEFS, PART_ORDER, ROTATION_STEP, snapAngle, type PartType, type PlacedPart } from './parts.ts'
import { Sim, type SimStatus } from './physics/sim.ts'
import type { Ghost, RenderState } from './render.ts'
import { Scene } from './Scene.tsx'
import { Tray } from './Tray.tsx'
import { loadSave, storeSave, type SaveData } from './storage.ts'

interface Drag {
  type: PartType
  angle: number
  x: number
  y: number
  /** Set when an already-placed part is being moved. */
  fromId: string | null
  offX: number
  offY: number
  inScene: boolean
}

function nextPartId(partsByLevel: Record<number, PlacedPart[]>): number {
  let max = 0
  for (const parts of Object.values(partsByLevel)) {
    for (const p of parts) {
      const n = Number(p.id.slice(1))
      if (Number.isFinite(n) && n > max) max = n
    }
  }
  return max + 1
}

const NO_PARTS: PlacedPart[] = []

const FAIL_TEXT = {
  rest: 'The ball came to rest before reaching the bell.',
  stalled: 'The ball stopped making progress toward the bell.',
  lost: 'The ball rolled out of the scene.',
  timeout: 'Thirty seconds passed without ringing the bell.',
} as const

export default function App() {
  const initial = useMemo(() => loadSave(), [])
  const [levelIdx, setLevelIdx] = useState(initial.level)
  const [partsByLevel, setPartsByLevel] = useState<Record<number, PlacedPart[]>>(initial.parts)
  const [solved, setSolved] = useState<number[]>(initial.solved)
  const [status, setStatus] = useState<SimStatus>({ mode: 'edit', steps: 0 })
  const [drag, setDrag] = useState<Drag | null>(null)
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [hoverId, setHoverId] = useState<string | null>(null)
  const [runTime, setRunTime] = useState(0)

  const level: Level = LEVELS[levelIdx]
  const parts = partsByLevel[level.id] ?? NO_PARTS
  const editable = status.mode === 'edit'

  const [sim] = useState(() => new Sim(level))
  const canvasRef = useRef<HTMLCanvasElement | null>(null)
  const wrapRef = useRef<HTMLDivElement | null>(null)
  const idCounter = useRef(nextPartId(initial.parts))
  const wonAtRef = useRef<number | null>(null)
  const dragRef = useRef<Drag | null>(null)
  useEffect(() => {
    dragRef.current = drag
  }, [drag])

  useEffect(
    () =>
      sim.subscribe((s) => {
        setStatus(s)
        if (s.mode === 'won') {
          const id = sim.level.id
          setSolved((prev) => (prev.includes(id) ? prev : [...prev, id]))
        }
      }),
    [sim],
  )

  useEffect(() => {
    sim.build(level, parts)
    wonAtRef.current = null
  }, [sim, level, parts])

  useEffect(() => {
    const save: SaveData = { level: levelIdx, parts: partsByLevel, solved }
    storeSave(save)
  }, [levelIdx, partsByLevel, solved])

  const setParts = useCallback(
    (update: (prev: PlacedPart[]) => PlacedPart[]) => {
      setPartsByLevel((all) => ({ ...all, [level.id]: update(all[level.id] ?? []) }))
    },
    [level.id],
  )

  const remaining = useMemo(() => {
    const out: Partial<Record<PartType, number>> = {}
    for (const type of PART_ORDER) {
      const total = level.tray[type] ?? 0
      if (total === 0) continue
      out[type] = total - parts.filter((p) => p.type === type).length
    }
    return out
  }, [level, parts])

  const toScene = useCallback((clientX: number, clientY: number) => {
    const canvas = canvasRef.current
    if (!canvas) return { x: -1, y: -1, inScene: false }
    const r = canvas.getBoundingClientRect()
    const x = ((clientX - r.left) / r.width) * SCENE_W
    const y = ((clientY - r.top) / r.height) * SCENE_H
    return { x, y, inScene: x >= 0 && x <= SCENE_W && y >= 0 && y <= SCENE_H }
  }, [])

  const rotate = useCallback(
    (dir: 1 | -1) => {
      if (drag) {
        if (!PART_DEFS[drag.type].rotatable) return
        setDrag({ ...drag, angle: snapAngle(drag.angle + dir * ROTATION_STEP) })
        return
      }
      if (!editable) return
      const targetId = hoverId ?? selectedId
      if (!targetId) return
      setParts((prev) =>
        prev.map((p) =>
          p.id === targetId && PART_DEFS[p.type].rotatable
            ? { ...p, angle: snapAngle(p.angle + dir * ROTATION_STEP) }
            : p,
        ),
      )
      setSelectedId(targetId)
    },
    [drag, editable, hoverId, selectedId, setParts],
  )

  const startTrayDrag = useCallback(
    (type: PartType, e: React.PointerEvent) => {
      if (!editable || (remaining[type] ?? 0) <= 0) return
      e.preventDefault()
      const p = toScene(e.clientX, e.clientY)
      setSelectedId(null)
      setDrag({ type, angle: 0, x: p.x, y: p.y, fromId: null, offX: 0, offY: 0, inScene: p.inScene })
    },
    [editable, remaining, toScene],
  )

  const onScenePointerDown = useCallback(
    (e: React.PointerEvent<HTMLDivElement>) => {
      if (e.button !== 0 || !(e.target instanceof HTMLCanvasElement)) return
      const p = toScene(e.clientX, e.clientY)
      if (!editable) return
      const hit = sim.partAt(p.x, p.y)
      if (!hit) {
        setSelectedId(null)
        return
      }
      e.preventDefault()
      setSelectedId(hit.id)
      setDrag({
        type: hit.type,
        angle: hit.angle,
        x: hit.x,
        y: hit.y,
        fromId: hit.id,
        offX: hit.x - p.x,
        offY: hit.y - p.y,
        inScene: true,
      })
    },
    [editable, sim, toScene],
  )

  const onScenePointerMove = useCallback(
    (e: React.PointerEvent<HTMLDivElement>) => {
      if (drag || !editable) {
        if (hoverId) setHoverId(null)
        return
      }
      const p = toScene(e.clientX, e.clientY)
      const hit = sim.partAt(p.x, p.y)
      setHoverId(hit ? hit.id : null)
    },
    [drag, editable, hoverId, sim, toScene],
  )

  const dragging = drag !== null
  useEffect(() => {
    if (!dragging) return
    const move = (e: PointerEvent) => {
      const p = toScene(e.clientX, e.clientY)
      setDrag((d) => (d ? { ...d, x: p.x + d.offX, y: p.y + d.offY, inScene: p.inScene } : d))
    }
    const up = (e: PointerEvent) => {
      const d = dragRef.current
      if (!d) return
      const p = toScene(e.clientX, e.clientY)
      const x = Math.round(p.x + d.offX)
      const y = Math.round(p.y + d.offY)
      const inScene = x >= 0 && x <= SCENE_W && y >= 0 && y <= SCENE_H
      if (d.fromId) {
        const id = d.fromId
        if (inScene) {
          setParts((prev) => prev.map((q) => (q.id === id ? { ...q, x, y, angle: d.angle } : q)))
          setSelectedId(id)
        } else {
          setParts((prev) => prev.filter((q) => q.id !== id))
          setSelectedId(null)
        }
      } else if (inScene) {
        const id = `p${String(idCounter.current++).padStart(4, '0')}`
        setParts((prev) => [...prev, { id, type: d.type, x, y, angle: d.angle }])
        setSelectedId(id)
      }
      setDrag(null)
    }
    const cancel = () => setDrag(null)
    window.addEventListener('pointermove', move)
    window.addEventListener('pointerup', up)
    window.addEventListener('pointercancel', cancel)
    return () => {
      window.removeEventListener('pointermove', move)
      window.removeEventListener('pointerup', up)
      window.removeEventListener('pointercancel', cancel)
    }
  }, [dragging, toScene, setParts])

  useEffect(() => {
    const el = wrapRef.current
    if (!el) return
    const onWheel = (e: WheelEvent) => {
      e.preventDefault()
      if (e.deltaY === 0) return
      rotate(e.deltaY > 0 ? 1 : -1)
    }
    el.addEventListener('wheel', onWheel, { passive: false })
    return () => el.removeEventListener('wheel', onWheel)
  }, [rotate])

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.target instanceof HTMLInputElement) return
      if (e.key === 'r' || e.key === 'R') {
        e.preventDefault()
        rotate(e.shiftKey ? -1 : 1)
      } else if (e.key === 'Escape') {
        setDrag(null)
        setSelectedId(null)
      } else if ((e.key === 'Delete' || e.key === 'Backspace') && selectedId && editable && !drag) {
        e.preventDefault()
        setParts((prev) => prev.filter((p) => p.id !== selectedId))
        setSelectedId(null)
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [rotate, selectedId, editable, drag, setParts])

  const handleRun = () => {
    if (sim.mode !== 'edit') sim.reset()
    setSelectedId(null)
    setHoverId(null)
    setDrag(null)
    sim.run()
  }
  const handleReset = () => {
    sim.reset()
    wonAtRef.current = null
    setRunTime(0)
  }
  const handleClear = () => {
    setSelectedId(null)
    setDrag(null)
    setParts(() => [])
  }
  const gotoLevel = (idx: number) => {
    setSelectedId(null)
    setHoverId(null)
    setDrag(null)
    setLevelIdx(idx)
  }

  const onFrame = useCallback(
    (now: number) => {
      sim.tick(now)
      if (sim.mode === 'won' && wonAtRef.current === null) wonAtRef.current = now
      const t = Math.round(sim.elapsed * 10) / 10
      if (sim.mode === 'running') setRunTime((prev) => (prev === t ? prev : t))
    },
    [sim],
  )

  const getState = useCallback((): RenderState => {
    const ghost: Ghost | null = drag
      ? { type: drag.type, x: drag.x, y: drag.y, angle: drag.angle, valid: drag.inScene }
      : null
    return {
      sim,
      level,
      parts,
      ghost,
      selectedId,
      hoverId: drag ? null : hoverId,
      hiddenId: drag?.fromId ?? null,
      now: performance.now(),
      wonAt: wonAtRef.current,
    }
  }, [sim, level, parts, drag, selectedId, hoverId])

  const placedCount = parts.length
  const trayTotal = Object.values(level.tray).reduce((a, b) => a + (b ?? 0), 0)
  const canGoNext = levelIdx < LEVELS.length - 1

  let statusText: string
  let statusTone: 'idle' | 'live' | 'win' | 'fail' = 'idle'
  if (status.mode === 'running') {
    statusText = `Running · ${runTime.toFixed(1)}s`
    statusTone = 'live'
  } else if (status.mode === 'won') {
    statusText = `Bell rung in ${(status.steps / 60).toFixed(2)}s`
    statusTone = 'win'
  } else if (status.mode === 'failed') {
    statusText = FAIL_TEXT[status.reason ?? 'rest']
    statusTone = 'fail'
  } else if (drag) {
    statusText = drag.inScene
      ? `Release to place · ${PART_DEFS[drag.type].rotatable ? 'scroll or press R to rotate' : 'this part does not rotate'}`
      : drag.fromId
        ? 'Release outside the scene to return this part to the tray'
        : 'Drag into the scene to place'
  } else if (placedCount === 0) {
    statusText = 'Drag parts from the tray into the scene, then press Run.'
  } else {
    statusText = `${placedCount} of ${trayTotal} parts placed · press Run to test your machine`
  }

  return (
    <div className="app">
      <header className="topbar">
        <div className="brand">
          <span className="brand-icon" aria-hidden="true">
            <svg viewBox="0 0 32 32" width="26" height="26">
              <path d="M16 4c-5 0-8 4-8 10v6h16v-6c0-6-3-10-8-10z" fill="#fbbf24" />
              <rect x="6" y="20" width="20" height="3" rx="1.5" fill="#b45309" />
              <circle cx="16" cy="26" r="3" fill="#f43f5e" />
            </svg>
          </span>
          <div>
            <div className="brand-title">Rube Goldberg Lab</div>
            <div className="brand-sub">Place parts so the ball rings the bell</div>
          </div>
        </div>
        <nav className="levels" aria-label="Levels">
          {LEVELS.map((l, i) => (
            <button
              key={l.id}
              type="button"
              className={`level-tab${i === levelIdx ? ' active' : ''}${solved.includes(l.id) ? ' solved' : ''}`}
              onClick={() => gotoLevel(i)}
              aria-current={i === levelIdx ? 'page' : undefined}
              title={l.name}
            >
              <span className="level-tab-num">{l.id}</span>
              <span className="level-tab-name">{l.name}</span>
              {solved.includes(l.id) && (
                <span className="level-tab-check" aria-label="solved">
                  ✓
                </span>
              )}
            </button>
          ))}
        </nav>
      </header>

      <main className="workspace">
        <Tray remaining={remaining} onPointerDown={startTrayDrag} disabled={!editable} dragging={drag?.type ?? null} />

        <section className="stage">
          <div className="level-head">
            <div className="level-kicker">Level {level.id} of {LEVELS.length}</div>
            <h1 className="level-name">{level.name}</h1>
            <p className="level-objective">{level.objective}</p>
          </div>

          <div
            ref={wrapRef}
            className={`scene-wrap mode-${status.mode}${drag ? ' dragging' : ''}`}
            onPointerDown={onScenePointerDown}
            onPointerMove={onScenePointerMove}
            onPointerLeave={() => setHoverId(null)}
            style={{ cursor: !editable ? 'default' : drag ? 'grabbing' : hoverId ? 'grab' : 'default' }}
          >
            <Scene canvasRef={canvasRef} getState={getState} onFrame={onFrame} className="scene" />
            {status.mode === 'won' && (
              <div className="overlay win" role="status">
                <div className="overlay-card">
                  <div className="overlay-bell" aria-hidden="true">
                    <svg viewBox="0 0 32 32" width="48" height="48">
                      <path d="M16 4c-5 0-8 4-8 10v6h16v-6c0-6-3-10-8-10z" fill="#fbbf24" />
                      <rect x="6" y="20" width="20" height="3" rx="1.5" fill="#b45309" />
                      <circle cx="16" cy="26" r="3" fill="#f43f5e" />
                    </svg>
                  </div>
                  <h2>Bell rung!</h2>
                  <p>
                    Level {level.id} complete in {(status.steps / 60).toFixed(2)} s.
                  </p>
                  <div className="overlay-actions">
                    <button type="button" className="btn ghost-btn" onClick={handleReset}>
                      Replay
                    </button>
                    {canGoNext && (
                      <button type="button" className="btn primary" onClick={() => gotoLevel(levelIdx + 1)} autoFocus>
                        Next level →
                      </button>
                    )}
                  </div>
                </div>
              </div>
            )}
            {status.mode === 'failed' && (
              <div className="overlay fail" role="status">
                <div className="fail-toast">
                  <strong>No ring.</strong> {FAIL_TEXT[status.reason ?? 'rest']} Reset, then move or rotate a part.
                  <button type="button" className="btn small" onClick={handleReset}>
                    Reset
                  </button>
                </div>
              </div>
            )}
          </div>

          <div className="controls">
            <div className="control-buttons">
              <button
                type="button"
                className="btn primary big"
                onClick={handleRun}
                disabled={status.mode === 'running' || status.mode === 'won'}
              >
                <span className="btn-icon" aria-hidden="true">
                  ▶
                </span>
                Run
              </button>
              <button
                type="button"
                className="btn big"
                onClick={handleReset}
                disabled={status.mode === 'edit' && placedCount === 0}
              >
                <span className="btn-icon" aria-hidden="true">
                  ↺
                </span>
                Reset
              </button>
              <button type="button" className="btn big danger" onClick={handleClear} disabled={placedCount === 0}>
                <span className="btn-icon" aria-hidden="true">
                  ✕
                </span>
                Clear
              </button>
            </div>
            <div className={`status status-${statusTone}`} aria-live="polite">
              <span className="status-dot" aria-hidden="true" />
              {statusText}
            </div>
          </div>
        </section>
      </main>
    </div>
  )
}
