import { useCallback, useEffect, useMemo, useRef, useState, type PointerEvent as ReactPointerEvent } from 'react'
import { MIN_CLIP_DURATION, type Project, type Selection, type TitleClip, type Tool } from '../types'
import { mediaById } from '../lib/media'
import { drawFrame } from '../lib/render'
import {
  insertionIndex,
  placeVideo,
  reorderClip,
  sequenceDuration,
  snapPoints,
  snapTime,
  trimClip,
  updateTitle,
  type PlacedClip,
} from '../lib/timeline'
import { clamp, fmtSeconds, shortTime, timecode } from '../lib/time'
import { Icon } from './Icon'

export const PAD = 12
const SNAP_PX = 10
const DRAG_THRESHOLD_PX = 4
export const ZOOM_MIN = 12
export const ZOOM_MAX = 320
const CLIP_H = 78

interface Props {
  project: Project
  setProject: (p: Project) => void
  commitFrom: (base: Project) => void
  commit: (p: Project) => void
  playhead: number
  setPlayhead: (t: number) => void
  selection: Selection
  setSelection: (s: Selection) => void
  tool: Tool
  setTool: (t: Tool) => void
  snap: boolean
  setSnap: (v: boolean) => void
  pxPerSec: number
  setPxPerSec: (v: number) => void
  onSplitAt: (time: number) => void
}

interface MoveView {
  kind: 'move'
  id: string
  ghostStart: number
  insertIndex: number
  snapped: number | null
}
interface TrimView {
  kind: 'trim'
  id: string
  edge: 'head' | 'tail'
  label: string
  x: number
  snapped: number | null
}
interface TitleMoveView {
  kind: 'title-move'
  id: string
  snapped: number | null
}
type DragView = MoveView | TrimView | TitleMoveView | null

export function Timeline(props: Props) {
  const { project, playhead, selection, tool, snap, pxPerSec } = props
  const scrollRef = useRef<HTMLDivElement>(null)
  const contentRef = useRef<HTMLDivElement>(null)
  const [drag, setDrag] = useState<DragView>(null)
  const [viewportWidth, setViewportWidth] = useState(1200)

  useEffect(() => {
    const el = scrollRef.current
    if (!el) return
    const ro = new ResizeObserver(() => setViewportWidth(el.clientWidth))
    ro.observe(el)
    setViewportWidth(el.clientWidth)
    return () => ro.disconnect()
  }, [])

  const duration = sequenceDuration(project)
  const contentSeconds = Math.max(duration + 8, (viewportWidth - PAD * 2) / pxPerSec)
  const contentWidth = Math.ceil(contentSeconds * pxPerSec + PAD * 2)
  const xOf = useCallback((t: number) => PAD + t * pxPerSec, [pxPerSec])

  const timeAt = useCallback(
    (clientX: number) => {
      const rect = contentRef.current?.getBoundingClientRect()
      if (!rect) return 0
      return (clientX - rect.left - PAD) / pxPerSec
    },
    [pxPerSec],
  )

  // Keep the playhead in view while it moves (playback / keyboard).
  useEffect(() => {
    const el = scrollRef.current
    if (!el || drag) return
    const x = xOf(playhead)
    if (x < el.scrollLeft + PAD || x > el.scrollLeft + el.clientWidth - PAD) {
      el.scrollLeft = Math.max(0, x - el.clientWidth * 0.3)
    }
  }, [playhead, xOf, drag])

  /* ------------------------------------------------------------------ */
  /* pointer helpers                                                     */
  /* ------------------------------------------------------------------ */

  const track = (
    onMove: (e: PointerEvent, dx: number) => void,
    onUp: (e: PointerEvent, moved: boolean) => void,
    startX: number,
  ) => {
    let moved = false
    const move = (e: PointerEvent) => {
      const dx = e.clientX - startX
      if (!moved && Math.abs(dx) < DRAG_THRESHOLD_PX) return
      moved = true
      onMove(e, dx)
    }
    const up = (e: PointerEvent) => {
      window.removeEventListener('pointermove', move)
      window.removeEventListener('pointerup', up)
      window.removeEventListener('pointercancel', up)
      onUp(e, moved)
    }
    window.addEventListener('pointermove', move)
    window.addEventListener('pointerup', up)
    window.addEventListener('pointercancel', up)
  }

  const snapThreshold = SNAP_PX / pxPerSec

  const startScrub = (e: ReactPointerEvent) => {
    if (e.button !== 0) return
    e.preventDefault()
    props.setPlayhead(clamp(timeAt(e.clientX), 0, Math.max(duration, contentSeconds)))
    const el = e.currentTarget as HTMLElement
    el.classList.add('scrubbing')
    track(
      (ev) => props.setPlayhead(clamp(timeAt(ev.clientX), 0, Math.max(duration, contentSeconds))),
      () => el.classList.remove('scrubbing'),
      e.clientX,
    )
  }

  const startVideoBody = (e: ReactPointerEvent, placed: PlacedClip) => {
    if (e.button !== 0) return
    e.stopPropagation()
    if (tool === 'razor') {
      const raw = timeAt(e.clientX)
      const s = snap ? snapTime(raw, [playhead], snapThreshold) : { time: raw, snapped: null }
      props.onSplitAt(s.time)
      return
    }
    props.setSelection({ kind: 'video', id: placed.clip.id })
    const base = project
    const dur = placed.end - placed.start
    const offset = timeAt(e.clientX) - placed.start
    const others = placeVideo(base.video.filter((c) => c.id !== placed.clip.id))
    const points = snapPoints({ ...base, video: base.video.filter((c) => c.id !== placed.clip.id) }, playhead)
    const othersEnd = others.length ? others[others.length - 1].end : 0
    let view: MoveView | null = null
    track(
      (ev) => {
        let start = clamp(timeAt(ev.clientX) - offset, 0, othersEnd)
        let snapped: number | null = null
        if (snap) {
          const a = snapTime(start, points, snapThreshold)
          const b = snapTime(start + dur, points, snapThreshold)
          const da = a.snapped === null ? Infinity : Math.abs(a.time - start)
          const db = b.snapped === null ? Infinity : Math.abs(b.time - start - dur)
          if (da <= db && a.snapped !== null) {
            start = a.time
            snapped = a.snapped
          } else if (b.snapped !== null) {
            start = b.time - dur
            snapped = b.snapped
          }
        }
        const insertIndex = insertionIndex(others, start + dur / 2)
        view = { kind: 'move', id: placed.clip.id, ghostStart: start, insertIndex, snapped }
        setDrag(view)
      },
      (_ev, moved) => {
        setDrag(null)
        if (moved && view) props.commit(reorderClip(base, placed.clip.id, view.insertIndex))
      },
      e.clientX,
    )
  }

  const startVideoTrim = (e: ReactPointerEvent, placed: PlacedClip, edge: 'head' | 'tail') => {
    if (e.button !== 0) return
    e.stopPropagation()
    props.setSelection({ kind: 'video', id: placed.clip.id })
    const base = project
    const clip = placed.clip
    const media = mediaById(clip.mediaId)
    const points = snapPoints(base, playhead, [clip.id])
    track(
      (_ev, dx) => {
        const dt = dx / pxPerSec
        let snapped: number | null = null
        let next: Project
        let label: string
        let x: number
        if (edge === 'tail') {
          let edgeTime = placed.end + dt
          if (snap) {
            const s = snapTime(edgeTime, points, snapThreshold)
            edgeTime = s.time
            snapped = s.snapped
          }
          const newOut = clamp(clip.in + (edgeTime - placed.start), clip.in + MIN_CLIP_DURATION, media.duration)
          next = trimClip(base, clip.id, 'tail', newOut)
          const delta = newOut - clip.out
          label = `Out ${delta >= 0 ? '+' : '−'}${Math.abs(delta).toFixed(2)}s → ${fmtSeconds(newOut - clip.in)}`
          x = xOf(placed.start + (newOut - clip.in))
        } else {
          const newIn = clamp(clip.in + dt, 0, clip.out - MIN_CLIP_DURATION)
          next = trimClip(base, clip.id, 'head', newIn)
          const delta = newIn - clip.in
          label = `In ${delta >= 0 ? '+' : '−'}${Math.abs(delta).toFixed(2)}s → ${fmtSeconds(clip.out - newIn)}`
          x = xOf(placed.start)
        }
        props.setProject(next)
        setDrag({ kind: 'trim', id: clip.id, edge, label, x, snapped })
      },
      (_ev, moved) => {
        setDrag(null)
        if (moved) props.commitFrom(base)
      },
      e.clientX,
    )
  }

  const startTitleBody = (e: ReactPointerEvent, title: TitleClip) => {
    if (e.button !== 0) return
    e.stopPropagation()
    props.setSelection({ kind: 'title', id: title.id })
    const base = project
    const points = snapPoints(base, playhead, [title.id])
    track(
      (_ev, dx) => {
        let start = Math.max(0, title.start + dx / pxPerSec)
        let snapped: number | null = null
        if (snap) {
          const a = snapTime(start, points, snapThreshold)
          const b = snapTime(start + title.duration, points, snapThreshold)
          const da = a.snapped === null ? Infinity : Math.abs(a.time - start)
          const db = b.snapped === null ? Infinity : Math.abs(b.time - start - title.duration)
          if (da <= db && a.snapped !== null) {
            start = a.time
            snapped = a.snapped
          } else if (b.snapped !== null) {
            start = Math.max(0, b.time - title.duration)
            snapped = b.snapped
          }
        }
        props.setProject(updateTitle(base, title.id, { start }))
        setDrag({ kind: 'title-move', id: title.id, snapped })
      },
      (_ev, moved) => {
        setDrag(null)
        if (moved) props.commitFrom(base)
      },
      e.clientX,
    )
  }

  const startTitleTrim = (e: ReactPointerEvent, title: TitleClip, edge: 'head' | 'tail') => {
    if (e.button !== 0) return
    e.stopPropagation()
    props.setSelection({ kind: 'title', id: title.id })
    const base = project
    const points = snapPoints(base, playhead, [title.id])
    const end = title.start + title.duration
    track(
      (_ev, dx) => {
        const dt = dx / pxPerSec
        let snapped: number | null = null
        let patch: Partial<TitleClip>
        let label: string
        let x: number
        if (edge === 'head') {
          let start = clamp(title.start + dt, 0, end - MIN_CLIP_DURATION)
          if (snap) {
            const s = snapTime(start, points, snapThreshold)
            if (s.snapped !== null && s.time <= end - MIN_CLIP_DURATION) {
              start = s.time
              snapped = s.snapped
            }
          }
          patch = { start, duration: end - start }
          label = `In → ${fmtSeconds(end - start)}`
          x = xOf(start)
        } else {
          let newEnd = Math.max(title.start + MIN_CLIP_DURATION, end + dt)
          if (snap) {
            const s = snapTime(newEnd, points, snapThreshold)
            if (s.snapped !== null && s.time >= title.start + MIN_CLIP_DURATION) {
              newEnd = s.time
              snapped = s.snapped
            }
          }
          patch = { duration: newEnd - title.start }
          label = `Out → ${fmtSeconds(newEnd - title.start)}`
          x = xOf(newEnd)
        }
        props.setProject(updateTitle(base, title.id, patch))
        setDrag({ kind: 'trim', id: title.id, edge, label, x, snapped })
      },
      (_ev, moved) => {
        setDrag(null)
        if (moved) props.commitFrom(base)
      },
      e.clientX,
    )
  }

  const onTrackBackground = (e: ReactPointerEvent) => {
    if (e.button !== 0 || e.target !== e.currentTarget) return
    props.setSelection(null)
    startScrub(e)
  }

  // Ctrl+wheel zooms; React registers wheel listeners as passive, so attach natively.
  const { setPxPerSec } = props
  useEffect(() => {
    const el = scrollRef.current
    if (!el) return
    const onWheel = (e: WheelEvent) => {
      if (!e.ctrlKey) return
      e.preventDefault()
      const factor = e.deltaY < 0 ? 1.15 : 1 / 1.15
      setPxPerSec(clamp(pxPerSec * factor, ZOOM_MIN, ZOOM_MAX))
    }
    el.addEventListener('wheel', onWheel, { passive: false })
    return () => el.removeEventListener('wheel', onWheel)
  }, [pxPerSec, setPxPerSec])

  /* ------------------------------------------------------------------ */
  /* derived render data                                                 */
  /* ------------------------------------------------------------------ */

  const displayProject = useMemo(() => {
    if (drag?.kind === 'move') return reorderClip(project, drag.id, drag.insertIndex)
    return project
  }, [project, drag])
  const placed = useMemo(() => placeVideo(displayProject.video), [displayProject])

  const ticks = useMemo(() => buildTicks(contentSeconds, pxPerSec), [contentSeconds, pxPerSec])
  const gridPx = majorStep(pxPerSec) * pxPerSec

  const fit = () => {
    const target = Math.max(duration, 1)
    props.setPxPerSec(clamp((viewportWidth - PAD * 2 - 24) / target, ZOOM_MIN, ZOOM_MAX))
    if (scrollRef.current) scrollRef.current.scrollLeft = 0
  }

  const snapGuide = drag && drag.snapped !== null ? drag.snapped : null

  return (
    <section className="panel timeline" aria-label="Timeline">
      <header className="sequence-bar">
        <span className="sequence-tab"><Icon name="film" size={15} /> Sequence 01 <span className="tab-indicator" /></span>
        <span className="sequence-format">HD 720p <span>/</span> 30 fps</span>
        <span className="sequence-mode"><i className="status-dot" /> Magnetic timeline</span>
      </header>
      <div className="tl-toolbar">
        <div className="tool-group" role="group" aria-label="Tool">
          <button
            className={`tool-btn ${tool === 'select' ? 'active' : ''}`}
            onClick={() => props.setTool('select')}
            title="Select / move tool (V)"
            aria-pressed={tool === 'select'}
          >
            <Icon name="select" size={16} /> Select <kbd>V</kbd>
          </button>
          <button
            className={`tool-btn ${tool === 'razor' ? 'active' : ''}`}
            onClick={() => props.setTool('razor')}
            title="Razor tool: click a clip to cut it (B)"
            aria-pressed={tool === 'razor'}
          >
            <Icon name="razor" size={16} /> Razor <kbd>B</kbd>
          </button>
        </div>
        <button
          className={`tool-btn toggle ${snap ? 'active' : ''}`}
          onClick={() => props.setSnap(!snap)}
          title="Magnetic snapping to clip edges and the playhead (N)"
          aria-pressed={snap}
        >
          <Icon name="magnet" size={16} /> Snap <kbd>N</kbd>
        </button>
        <div className="zoom-group">
          <button className="icon-btn" onClick={() => props.setPxPerSec(clamp(pxPerSec / 1.4, ZOOM_MIN, ZOOM_MAX))} title="Zoom out (-)" aria-label="Zoom out">
            <Icon name="zoom-out" size={16} />
          </button>
          <input
            type="range"
            min={ZOOM_MIN}
            max={ZOOM_MAX}
            step={1}
            value={Math.round(pxPerSec)}
            onChange={(e) => props.setPxPerSec(Number(e.target.value))}
            aria-label="Timeline zoom"
            className="zoom-slider"
          />
          <button className="icon-btn" onClick={() => props.setPxPerSec(clamp(pxPerSec * 1.4, ZOOM_MIN, ZOOM_MAX))} title="Zoom in (+)" aria-label="Zoom in">
            <Icon name="zoom-in" size={16} />
          </button>
          <button className="tool-btn" onClick={fit} title="Fit sequence to view">
            <Icon name="fit" size={16} /> Fit
          </button>
          <span className="zoom-readout">{Math.round(pxPerSec)} px/s</span>
        </div>
        <div className="tl-summary">
          <span>{project.video.length} video · {project.titles.length} title</span>
          <span className="sep" />
          <span>
            Sequence <strong data-testid="sequence-duration">{fmtSeconds(duration)}</strong>
            <span className="dim mono"> {timecode(duration)}</span>
          </span>
        </div>
      </div>

      <div className="tl-body">
        <div className="tl-headers">
          <div className="tl-header ruler-header">
            <span className="mono">{timecode(playhead)}</span>
          </div>
          <div className="tl-header">
            <span className="track-badge title">T1</span> Titles
            <span className="track-count">{project.titles.length}</span>
          </div>
          <div className="tl-header">
            <span className="track-badge video">V1</span> Video
            <span className="track-count">{project.video.length}</span>
          </div>
        </div>

        <div className={`tl-scroll ${tool === 'razor' ? 'razor' : ''}`} ref={scrollRef}>
          <div className="tl-content" ref={contentRef} style={{ width: contentWidth, ['--grid-px' as string]: `${gridPx}px` }}>
            <div className="tl-ruler" onPointerDown={startScrub} data-testid="ruler">
              {ticks.map((t) => (
                <div key={t.time} className={`tick ${t.major ? 'major' : ''}`} style={{ left: xOf(t.time) }}>
                  {t.major && <span>{shortTime(t.time)}</span>}
                </div>
              ))}
              <div className="playhead-head" style={{ left: xOf(playhead) }} />
            </div>

            <div className="tl-track title-track" onPointerDown={onTrackBackground}>
              {project.titles.length === 0 && <span className="title-track-hint">Graphics & titles <kbd>T</kbd></span>}
              {project.titles.map((t) => (
                <TitleClipView
                  key={t.id}
                  title={t}
                  x={xOf(t.start)}
                  width={t.duration * pxPerSec}
                  selected={selection?.kind === 'title' && selection.id === t.id}
                  onBody={(e) => startTitleBody(e, t)}
                  onHead={(e) => startTitleTrim(e, t, 'head')}
                  onTail={(e) => startTitleTrim(e, t, 'tail')}
                />
              ))}
            </div>

            <div className="tl-track video-track" onPointerDown={onTrackBackground}>
              {placed.length === 0 && (
                <div className="tl-empty" role="status">
                  <Icon name="film" size={14} />
                  <span>
                    <strong>Build your first cut.</strong> Add a clip from Project media to start editing.
                  </span>
                </div>
              )}
              {placed.map((p) => {
                const lifted = drag?.kind === 'move' && drag.id === p.clip.id
                return (
                  <VideoClipView
                    key={p.clip.id}
                    placed={p}
                    x={xOf(lifted && drag.kind === 'move' ? drag.ghostStart : p.start)}
                    width={(p.end - p.start) * pxPerSec}
                    selected={selection?.kind === 'video' && selection.id === p.clip.id}
                    lifted={lifted}
                    razor={tool === 'razor'}
                    onBody={(e) => startVideoBody(e, p)}
                    onHead={(e) => startVideoTrim(e, p, 'head')}
                    onTail={(e) => startVideoTrim(e, p, 'tail')}
                  />
                )
              })}
              {drag?.kind === 'move' &&
                (() => {
                  const slot = placed.find((p) => p.clip.id === drag.id)
                  return slot ? <div className="drop-slot" style={{ left: xOf(slot.start), width: (slot.end - slot.start) * pxPerSec }} /> : null
                })()}
            </div>

            {snapGuide !== null && (
              <div className="snap-guide" style={{ left: xOf(snapGuide) }}>
                <span>
                  <Icon name="magnet" size={11} /> {shortTime(snapGuide)}
                </span>
              </div>
            )}

            {drag?.kind === 'trim' && (
              <div className="trim-tip" style={{ left: drag.x }}>
                {drag.label}
              </div>
            )}

            <div className="playhead-line" style={{ left: xOf(playhead) }} onPointerDown={startScrub} data-testid="playhead" />
          </div>
        </div>
      </div>
      <footer className="timeline-footer">
        <span><Icon name="select" size={12} />{drag ? 'Editing clip' : tool === 'razor' ? 'Click a clip to cut' : 'Drag to move · Drag an edge to trim'}</span>
        <span><kbd>S</kbd> Split <span className="footer-divider">/</span><kbd>⌫</kbd> Ripple delete <span className="footer-divider">/</span><kbd>T</kbd> Add title</span>
        <span>Frame accuracy <span className="mono">1/30 s</span></span>
      </footer>
    </section>
  )
}

/* -------------------------------------------------------------------- */

interface Tick {
  time: number
  major: boolean
}

const MAJOR_STEPS = [0.1, 0.25, 0.5, 1, 2, 5, 10, 15, 30, 60]

function majorStep(pxPerSec: number) {
  return MAJOR_STEPS.find((c) => c * pxPerSec >= 80) ?? 60
}

function buildTicks(seconds: number, pxPerSec: number): Tick[] {
  const major = majorStep(pxPerSec)
  const minor = major / (major >= 1 ? (major === 1 || major === 5 || major === 15 ? 5 : 4) : 5)
  const ticks: Tick[] = []
  const n = Math.ceil(seconds / minor)
  for (let i = 0; i <= n; i++) {
    const t = Math.round(i * minor * 1000) / 1000
    const isMajor = Math.abs(t / major - Math.round(t / major)) < 1e-6
    ticks.push({ time: t, major: isMajor })
  }
  return ticks
}

interface VideoClipViewProps {
  placed: PlacedClip
  x: number
  width: number
  selected: boolean
  lifted: boolean
  razor: boolean
  onBody: (e: ReactPointerEvent) => void
  onHead: (e: ReactPointerEvent) => void
  onTail: (e: ReactPointerEvent) => void
}

function VideoClipView({ placed, x, width, selected, lifted, razor, onBody, onHead, onTail }: VideoClipViewProps) {
  const media = mediaById(placed.clip.mediaId)
  const dur = placed.end - placed.start
  return (
    <div
      className={`clip video-clip ${selected ? 'selected' : ''} ${lifted ? 'lifted' : ''} ${razor ? 'razor' : ''}`}
      style={{ left: x, width, ['--clip-color' as string]: media.primary, ['--clip-accent' as string]: media.secondary }}
      onPointerDown={onBody}
      data-testid={`clip-${placed.clip.id}`}
      data-media={media.id}
      role="button"
      tabIndex={-1}
      aria-label={`${media.name}, ${fmtSeconds(dur)}`}
    >
      <FilmStrip mediaId={media.id} inPoint={placed.clip.in} outPoint={placed.clip.out} width={width} />
      <div className="clip-shade" />
      <div className="clip-label">
        <span className="clip-name">
          <span className="media-reel" style={{ background: media.primary }}>{media.id}</span>
          {media.name}
        </span>
        <span className="clip-meta">
          <span className="clip-dur mono">{fmtSeconds(dur)}</span>
          <span className="clip-src mono">
            {timecode(placed.clip.in)} – {timecode(placed.clip.out)}
          </span>
        </span>
      </div>
      {!razor && (
        <>
          <div className="handle head" onPointerDown={onHead} title="Trim in-point" data-testid="handle-head" />
          <div className="handle tail" onPointerDown={onTail} title="Trim out-point" data-testid="handle-tail" />
        </>
      )}
    </div>
  )
}

function FilmStrip({ mediaId, inPoint, outPoint, width }: { mediaId: string; inPoint: number; outPoint: number; width: number }) {
  const ref = useRef<HTMLCanvasElement>(null)
  const w = Math.max(1, Math.round(width))
  useEffect(() => {
    const canvas = ref.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return
    const media = mediaById(mediaId)
    const h = canvas.height
    const fw = Math.round((h * 16) / 9)
    const frames = Math.max(1, Math.ceil(w / fw))
    ctx.clearRect(0, 0, w, h)
    for (let i = 0; i < frames; i++) {
      const t = inPoint + ((i + 0.5) / frames) * (outPoint - inPoint)
      ctx.save()
      ctx.translate(i * fw, 0)
      ctx.beginPath()
      ctx.rect(0, 0, fw, h)
      ctx.clip()
      drawFrame(ctx, media, t, fw, h, false)
      ctx.restore()
    }
  }, [mediaId, inPoint, outPoint, w])
  return <canvas ref={ref} width={w} height={CLIP_H} className="filmstrip" />
}

interface TitleClipViewProps {
  title: TitleClip
  x: number
  width: number
  selected: boolean
  onBody: (e: ReactPointerEvent) => void
  onHead: (e: ReactPointerEvent) => void
  onTail: (e: ReactPointerEvent) => void
}

function TitleClipView({ title, x, width, selected, onBody, onHead, onTail }: TitleClipViewProps) {
  return (
    <div
      className={`clip title-clip ${selected ? 'selected' : ''}`}
      style={{ left: x, width }}
      onPointerDown={onBody}
      data-testid={`title-${title.id}`}
      role="button"
      tabIndex={-1}
      aria-label={`Title "${title.text}", ${fmtSeconds(title.duration)}`}
    >
      <div className="clip-label">
        <span className="clip-name">
          <Icon name="title" size={12} /> {title.text}
        </span>
        <span className="clip-dur mono">{fmtSeconds(title.duration)}</span>
      </div>
      <div className="handle head" onPointerDown={onHead} title="Trim title start" />
      <div className="handle tail" onPointerDown={onTail} title="Trim title end" />
    </div>
  )
}
