import { useEffect, useRef, type PointerEvent, type RefObject } from 'react'
import { floodFill } from '../lib/floodFill'
import { applyStyle, drawDot, drawSegment, drawShape } from '../lib/shapes'
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
  onBeforeChange: () => void
  onPointerPosition: (point: Point | null) => void
}

const SHAPE_TOOLS: Tool[] = ['line', 'rect', 'circle']

export function PaintCanvas({
  canvasRef,
  tool,
  color,
  size,
  fillShape,
  onBeforeChange,
  onPointerPosition,
}: Props) {
  const cursorRef = useRef<HTMLDivElement>(null)
  const drawing = useRef(false)
  const start = useRef<Point>({ x: 0, y: 0 })
  const last = useRef<Point>({ x: 0, y: 0 })
  const shapeBase = useRef<ImageData | null>(null)

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

  const strokeColor = tool === 'eraser' ? CANVAS_BACKGROUND : color

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
    e.currentTarget.setPointerCapture(e.pointerId)
    const point = toCanvasPoint(e)
    onBeforeChange()

    if (tool === 'fill') {
      floodFill(ctx, point, color)
      return
    }

    drawing.current = true
    start.current = point
    last.current = point
    applyStyle(ctx, { color: strokeColor, size, fillShape })

    if (SHAPE_TOOLS.includes(tool)) {
      shapeBase.current = ctx.getImageData(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT)
    } else {
      drawDot(ctx, point, size)
    }
  }

  const handlePointerMove = (e: PointerEvent<HTMLCanvasElement>) => {
    positionCursor(e)
    const point = toCanvasPoint(e)
    onPointerPosition(point)
    if (!drawing.current) return
    const ctx = getContext()
    if (!ctx) return

    if (SHAPE_TOOLS.includes(tool)) {
      if (shapeBase.current) ctx.putImageData(shapeBase.current, 0, 0)
      drawShape(ctx, tool, start.current, point, fillShape)
    } else {
      drawSegment(ctx, last.current, point)
      last.current = point
    }
  }

  const finishStroke = () => {
    drawing.current = false
    shapeBase.current = null
  }

  const handlePointerLeave = () => {
    onPointerPosition(null)
    if (cursorRef.current) cursorRef.current.style.transform = 'translate(-9999px, -9999px)'
  }

  return (
    <div className="canvas-frame" data-tool={tool}>
      <canvas
        ref={canvasRef}
        width={CANVAS_WIDTH}
        height={CANVAS_HEIGHT}
        className="paint-canvas"
        aria-label="Drawing canvas"
        onPointerDown={handlePointerDown}
        onPointerMove={handlePointerMove}
        onPointerUp={finishStroke}
        onPointerCancel={finishStroke}
        onPointerLeave={handlePointerLeave}
      />
      <div
        ref={cursorRef}
        className="brush-cursor"
        style={{ borderColor: tool === 'eraser' ? '#555' : color }}
      />
    </div>
  )
}
