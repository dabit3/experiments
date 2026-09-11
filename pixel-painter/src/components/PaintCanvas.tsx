import { useEffect, useRef, type PointerEvent, type RefObject } from 'react'
import { floodFill } from '../lib/floodFill'
import {
  applyStyle,
  constrainPoint,
  drawDot,
  drawPath,
  drawShape,
} from '../lib/shapes'
import {
  CANVAS_BACKGROUND,
  CANVAS_HEIGHT,
  CANVAS_WIDTH,
  type Point,
  type Tool,
} from '../types'
import './PaintCanvas.css'

interface Props {
  canvasRef: RefObject<HTMLCanvasElement | null>
  tool: Tool
  color: string
  size: number
  fillShape: boolean
  opacity: number
  smooth: boolean
  scale: number
  grid: boolean
  onBeforeChange: () => void
  onPointerPosition: (point: Point | null) => void
  onColorPick: (color: string) => void
}

const SHAPE_TOOLS: Tool[] = ['line', 'rect', 'circle']

export function PaintCanvas({
  canvasRef,
  tool,
  color,
  size,
  fillShape,
  opacity,
  smooth,
  scale,
  grid,
  onBeforeChange,
  onPointerPosition,
  onColorPick,
}: Props) {
  const cursorRef = useRef<HTMLDivElement>(null)
  const stroke = useRef<{
    tool: Tool
    color: string
    size: number
    opacity: number
    fillShape: boolean
    smooth: boolean
    points: Point[]
    base: ImageData
  } | null>(null)

  useEffect(() => {
    const ctx = canvasRef.current?.getContext('2d')
    if (!ctx) return
    ctx.fillStyle = CANVAS_BACKGROUND
    ctx.fillRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT)
  }, [canvasRef])

  const getContext = () => canvasRef.current?.getContext('2d') ?? null

  const toCanvasPoint = (e: PointerEvent<HTMLCanvasElement>): Point => {
    const rect = e.currentTarget.getBoundingClientRect()
    return {
      x: ((e.clientX - rect.left) / rect.width) * CANVAS_WIDTH,
      y: ((e.clientY - rect.top) / rect.height) * CANVAS_HEIGHT,
    }
  }

  const positionCursor = (e: PointerEvent<HTMLCanvasElement>) => {
    const cursor = cursorRef.current
    if (!cursor) return
    const rect = e.currentTarget.getBoundingClientRect()
    const scale = rect.width / CANVAS_WIDTH
    const diameter = Math.max(size * scale, 4)
    cursor.style.width = `${diameter}px`
    cursor.style.height = `${diameter}px`
    cursor.style.transform = `translate(${e.clientX - rect.left - diameter / 2}px, ${
      e.clientY - rect.top - diameter / 2
    }px)`
  }

  const handlePointerDown = (e: PointerEvent<HTMLCanvasElement>) => {
    if (e.button !== 0) return
    const ctx = getContext()
    if (!ctx) return
    if (stroke.current) return
    const point = toCanvasPoint(e)
    if (tool === 'eyedropper') {
      const pixel = ctx.getImageData(
        Math.min(CANVAS_WIDTH - 1, Math.max(0, Math.floor(point.x))),
        Math.min(CANVAS_HEIGHT - 1, Math.max(0, Math.floor(point.y))),
        1,
        1,
      ).data
      onColorPick(
        `#${[pixel[0], pixel[1], pixel[2]].map((channel) => channel.toString(16).padStart(2, '0')).join('')}`,
      )
      return
    }
    onBeforeChange()

    if (tool === 'fill') {
      floodFill(ctx, point, color)
      return
    }
    e.currentTarget.setPointerCapture(e.pointerId)
    stroke.current = {
      tool,
      color: tool === 'eraser' ? CANVAS_BACKGROUND : color,
      size,
      opacity,
      fillShape,
      smooth,
      points: [point],
      base: ctx.getImageData(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT),
    }
    renderStroke(point, false)
  }

  const renderStroke = (point: Point, constrained: boolean) => {
    const active = stroke.current
    const ctx = getContext()
    if (!active || !ctx) return
    const from = active.points[0]
    const to = constrained ? constrainPoint(from, point, active.tool) : point
    ctx.putImageData(active.base, 0, 0)
    ctx.save()
    applyStyle(ctx, active)
    ctx.globalAlpha = active.opacity
    if (SHAPE_TOOLS.includes(active.tool)) {
      drawShape(ctx, active.tool, from, to, active.fillShape)
    } else if (active.points.length === 1 && active.tool !== 'freeform') {
      drawDot(ctx, from, active.size)
    } else {
      drawPath(
        ctx,
        constrained ? [from, to] : active.points,
        active.smooth,
        active.tool === 'freeform',
      )
    }
    ctx.restore()
  }

  const handlePointerMove = (e: PointerEvent<HTMLCanvasElement>) => {
    positionCursor(e)
    const point = toCanvasPoint(e)
    onPointerPosition(point)
    if (!stroke.current) return
    stroke.current.points.push(point)
    renderStroke(point, e.shiftKey)
  }

  const finishStroke = (e: PointerEvent<HTMLCanvasElement>) => {
    if (!stroke.current) return
    const point = toCanvasPoint(e)
    stroke.current.points.push(point)
    renderStroke(point, e.shiftKey)
    stroke.current = null
  }

  const cancelStroke = () => {
    if (stroke.current) getContext()?.putImageData(stroke.current.base, 0, 0)
    stroke.current = null
  }

  const handlePointerLeave = () => {
    onPointerPosition(null)
    if (cursorRef.current)
      cursorRef.current.style.transform = 'translate(-9999px, -9999px)'
  }

  return (
    <div
      className="canvas-frame"
      data-tool={tool}
      style={{ width: CANVAS_WIDTH * scale }}
    >
      <canvas
        ref={canvasRef}
        width={CANVAS_WIDTH}
        height={CANVAS_HEIGHT}
        className="paint-canvas"
        aria-label="Drawing canvas"
        onPointerDown={handlePointerDown}
        onPointerMove={handlePointerMove}
        onPointerUp={finishStroke}
        onPointerCancel={cancelStroke}
        onLostPointerCapture={cancelStroke}
        onPointerLeave={handlePointerLeave}
      />
      {grid && (
        <div
          className="canvas-grid"
          style={{ backgroundSize: `${40 * scale}px ${40 * scale}px` }}
        />
      )}
      <div
        ref={cursorRef}
        className="brush-cursor"
        style={{ borderColor: tool === 'eraser' ? '#555' : color }}
      />
    </div>
  )
}
