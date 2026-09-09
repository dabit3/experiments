import { useCallback, useRef, useState } from 'react'
import type { PointerEvent as ReactPointerEvent } from 'react'
import type { SignatureImage } from '../types'
import { renderTypedSignature, SCRIPT_FONT } from '../lib/typedSignature'
import './SignaturePad.css'

type Point = { x: number; y: number }
type Stroke = Point[]

const INK = '#1b2a4a'

function mid(a: Point, b: Point): Point {
  return { x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 }
}

function paintStroke(ctx: CanvasRenderingContext2D, stroke: Stroke, lineWidth: number) {
  ctx.strokeStyle = INK
  ctx.fillStyle = INK
  ctx.lineWidth = lineWidth
  ctx.lineCap = 'round'
  ctx.lineJoin = 'round'
  if (stroke.length === 1) {
    ctx.beginPath()
    ctx.arc(stroke[0].x, stroke[0].y, lineWidth / 2, 0, Math.PI * 2)
    ctx.fill()
    return
  }
  ctx.beginPath()
  ctx.moveTo(stroke[0].x, stroke[0].y)
  let last = stroke[0]
  for (let i = 1; i < stroke.length - 1; i++) {
    const m = mid(stroke[i], stroke[i + 1])
    ctx.quadraticCurveTo(stroke[i].x, stroke[i].y, m.x, m.y)
    last = m
  }
  const end = stroke[stroke.length - 1]
  ctx.quadraticCurveTo(last.x, last.y, end.x, end.y)
  ctx.stroke()
}

function exportStrokes(strokes: Stroke[], width: number, height: number, lineWidth: number): SignatureImage {
  const scale = 2
  const canvas = document.createElement('canvas')
  canvas.width = width * scale
  canvas.height = height * scale
  const ctx = canvas.getContext('2d')!
  ctx.scale(scale, scale)
  for (const s of strokes) paintStroke(ctx, s, lineWidth)
  return { dataUrl: canvas.toDataURL('image/png'), width, height, mode: 'drawn', strokes: strokes.length, paths: strokes }
}

export interface SignaturePadProps {
  id: string
  width: number
  height: number
  value: SignatureImage | null
  onChange: (next: SignatureImage | null, reason: 'stroke' | 'undo' | 'clear' | 'typed') => void
  /** Show the “Draw / Type” toggle and the typed-signature input. */
  allowTyped?: boolean
  typedDefault?: string
  lineWidth?: number
  placeholder?: string
  invalid?: boolean
  compact?: boolean
}

export function SignaturePad({
  id,
  width,
  height,
  value,
  onChange,
  allowTyped = false,
  typedDefault = '',
  lineWidth = 2.6,
  placeholder = 'Sign here',
  invalid = false,
  compact = false,
}: SignaturePadProps) {
  const [strokes, setStrokes] = useState<Stroke[]>(() => (value?.mode === 'drawn' ? (value.paths ?? []) : []))
  const [mode, setMode] = useState<'draw' | 'type'>('draw')
  const [typed, setTyped] = useState(typedDefault)
  const drawing = useRef<{ points: Stroke; lastMid: Point } | null>(null)

  // Repaints whenever the canvas mounts (e.g. after toggling Draw/Type) or the strokes change.
  const attachCanvas = useCallback(
    (canvas: HTMLCanvasElement | null) => {
      if (!canvas) return
      const dpr = window.devicePixelRatio || 1
      canvas.width = Math.round(width * dpr)
      canvas.height = Math.round(height * dpr)
      const ctx = canvas.getContext('2d')
      if (!ctx) return
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
      ctx.clearRect(0, 0, width, height)
      for (const s of strokes) paintStroke(ctx, s, lineWidth)
    },
    [strokes, width, height, lineWidth],
  )

  const pointFromEvent = (e: ReactPointerEvent<HTMLCanvasElement>): Point => {
    const rect = e.currentTarget.getBoundingClientRect()
    return {
      x: ((e.clientX - rect.left) / rect.width) * width,
      y: ((e.clientY - rect.top) / rect.height) * height,
    }
  }

  const onPointerDown = (e: ReactPointerEvent<HTMLCanvasElement>) => {
    if (e.button !== 0) return
    e.currentTarget.setPointerCapture(e.pointerId)
    const p = pointFromEvent(e)
    drawing.current = { points: [p], lastMid: p }
    const ctx = e.currentTarget.getContext('2d')
    if (ctx) paintStroke(ctx, [p], lineWidth)
  }

  const onPointerMove = (e: ReactPointerEvent<HTMLCanvasElement>) => {
    const d = drawing.current
    if (!d) return
    const p = pointFromEvent(e)
    const prev = d.points[d.points.length - 1]
    if (Math.hypot(p.x - prev.x, p.y - prev.y) < 0.75) return
    d.points.push(p)
    const ctx = e.currentTarget.getContext('2d')
    if (!ctx) return
    const m = mid(prev, p)
    ctx.strokeStyle = INK
    ctx.lineWidth = lineWidth
    ctx.lineCap = 'round'
    ctx.lineJoin = 'round'
    ctx.beginPath()
    ctx.moveTo(d.lastMid.x, d.lastMid.y)
    ctx.quadraticCurveTo(prev.x, prev.y, m.x, m.y)
    ctx.stroke()
    d.lastMid = m
  }

  const endStroke = (e: ReactPointerEvent<HTMLCanvasElement>) => {
    const d = drawing.current
    if (!d) return
    drawing.current = null
    if (e.currentTarget.hasPointerCapture(e.pointerId)) e.currentTarget.releasePointerCapture(e.pointerId)
    const next = [...strokes, d.points]
    setStrokes(next)
    onChange(exportStrokes(next, width, height, lineWidth), 'stroke')
  }

  const undo = () => {
    if (!strokes.length) return
    const next = strokes.slice(0, -1)
    setStrokes(next)
    onChange(next.length ? exportStrokes(next, width, height, lineWidth) : null, 'undo')
  }

  const clear = () => {
    if (!strokes.length && !value) return
    setStrokes([])
    onChange(null, 'clear')
  }

  const adoptTyped = async () => {
    const img = await renderTypedSignature(typed, width, height)
    setStrokes([])
    setMode('draw')
    onChange(img, 'typed')
  }

  const isEmpty = !value
  const showTypedPreview = mode === 'type'

  return (
    <div className={`sigpad ${compact ? 'sigpad--compact' : ''} ${invalid ? 'sigpad--invalid' : ''}`} data-testid={id}>
      {allowTyped && (
        <div className="sigpad__modes" role="tablist" aria-label="Signature method">
          <button
            type="button"
            role="tab"
            aria-selected={mode === 'draw'}
            className={`sigpad__mode ${mode === 'draw' ? 'is-active' : ''}`}
            onClick={() => setMode('draw')}
          >
            <PenIcon /> Draw
          </button>
          <button
            type="button"
            role="tab"
            aria-selected={mode === 'type'}
            className={`sigpad__mode ${mode === 'type' ? 'is-active' : ''}`}
            onClick={() => {
              setMode('type')
              if (!typed.trim() && typedDefault) setTyped(typedDefault)
            }}
          >
            <KeyboardIcon /> Type
          </button>
        </div>
      )}

      <div className="sigpad__surface" style={{ width, height }}>
        {showTypedPreview ? (
          <div className="sigpad__typed-preview" style={{ fontFamily: SCRIPT_FONT }}>
            {typed.trim() || <span className="sigpad__typed-empty">Your signature will appear here</span>}
          </div>
        ) : (
          <canvas
            ref={attachCanvas}
            id={id}
            className="sigpad__canvas"
            style={{ width, height }}
            aria-label={placeholder}
            onPointerDown={onPointerDown}
            onPointerMove={onPointerMove}
            onPointerUp={endStroke}
            onPointerCancel={endStroke}
            onPointerLeave={(e) => {
              if (drawing.current && !e.currentTarget.hasPointerCapture(e.pointerId)) endStroke(e)
            }}
          />
        )}
        {!showTypedPreview && value?.mode === 'typed' && (
          <img className="sigpad__adopted" src={value.dataUrl} alt="Typed signature" draggable={false} />
        )}
        <div className="sigpad__baseline" aria-hidden="true">
          <span className="sigpad__x">×</span>
        </div>
        {isEmpty && !showTypedPreview && (
          <div className="sigpad__placeholder" aria-hidden="true">
            {placeholder}
          </div>
        )}
      </div>

      <div className="sigpad__toolbar">
        {showTypedPreview ? (
          <>
            <input
              className="sigpad__typed-input"
              type="text"
              autoFocus
              value={typed}
              placeholder="Type your full name"
              aria-label="Typed signature"
              onChange={(e) => setTyped(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') void adoptTyped()
              }}
            />
            <button type="button" className="btn btn--secondary btn--sm" disabled={!typed.trim()} onClick={() => void adoptTyped()}>
              Use typed signature
            </button>
          </>
        ) : (
          <>
            <span className="sigpad__status">
              {value?.mode === 'drawn'
                ? `${value.strokes} stroke${value.strokes === 1 ? '' : 's'}`
                : value?.mode === 'typed'
                  ? 'Typed signature adopted'
                  : 'Draw with your mouse'}
            </span>
            <span className="sigpad__spacer" />
            <button type="button" className="btn btn--ghost btn--sm" onClick={undo} disabled={!strokes.length} aria-label="Undo last stroke">
              <UndoIcon /> Undo
            </button>
            <button type="button" className="btn btn--ghost btn--sm" onClick={clear} disabled={isEmpty} aria-label="Clear">
              <ClearIcon /> Clear
            </button>
          </>
        )}
      </div>
    </div>
  )
}

function PenIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M12 19l7-7 3 3-7 7-3-3z" />
      <path d="M18 13l-1.5-7.5L2 2l3.5 14.5L13 18l5-5z" />
      <path d="M2 2l7.586 7.586" />
      <circle cx="11" cy="11" r="2" />
    </svg>
  )
}

function KeyboardIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <rect x="2" y="6" width="20" height="12" rx="2" />
      <path d="M6 10h.01M10 10h.01M14 10h.01M18 10h.01M8 14h8" />
    </svg>
  )
}

function UndoIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M9 14L4 9l5-5" />
      <path d="M4 9h10a6 6 0 0 1 0 12h-3" />
    </svg>
  )
}

function ClearIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M3 6h18M8 6V4h8v2M6 6l1 14h10l1-14" />
    </svg>
  )
}
