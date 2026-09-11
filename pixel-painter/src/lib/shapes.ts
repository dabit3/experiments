import type { Point, Tool } from '../types'

export interface StrokeStyle {
  color: string
  size: number
  fillShape: boolean
}

export function constrainPoint(from: Point, to: Point, tool: Tool): Point {
  const dx = to.x - from.x
  const dy = to.y - from.y
  if (tool === 'rect' || tool === 'circle') {
    const side = Math.max(Math.abs(dx), Math.abs(dy))
    return {
      x: from.x + (dx < 0 ? -side : side),
      y: from.y + (dy < 0 ? -side : side),
    }
  }
  const angle = Math.round(Math.atan2(dy, dx) / (Math.PI / 4)) * (Math.PI / 4)
  const length = Math.hypot(dx, dy)
  return {
    x: from.x + Math.cos(angle) * length,
    y: from.y + Math.sin(angle) * length,
  }
}

export function drawPath(
  ctx: CanvasRenderingContext2D,
  points: Point[],
  smooth: boolean,
  closed: boolean,
): void {
  if (!points.length) return
  ctx.beginPath()
  ctx.moveTo(points[0].x, points[0].y)
  for (let i = 1; i < points.length; i++) {
    const current = points[i]
    const next = points[i + 1]
    if (smooth && next)
      ctx.quadraticCurveTo(
        current.x,
        current.y,
        (current.x + next.x) / 2,
        (current.y + next.y) / 2,
      )
    else ctx.lineTo(current.x, current.y)
  }
  if (closed) {
    ctx.closePath()
    ctx.fill()
  } else ctx.stroke()
}

export function applyStyle(
  ctx: CanvasRenderingContext2D,
  style: StrokeStyle,
): void {
  ctx.strokeStyle = style.color
  ctx.fillStyle = style.color
  ctx.lineWidth = style.size
  ctx.lineCap = 'round'
  ctx.lineJoin = 'round'
}

export function drawSegment(
  ctx: CanvasRenderingContext2D,
  from: Point,
  to: Point,
): void {
  ctx.beginPath()
  ctx.moveTo(from.x, from.y)
  ctx.lineTo(to.x, to.y)
  ctx.stroke()
}

export function drawDot(
  ctx: CanvasRenderingContext2D,
  at: Point,
  size: number,
): void {
  ctx.beginPath()
  ctx.arc(at.x, at.y, size / 2, 0, Math.PI * 2)
  ctx.fill()
}

export function drawShape(
  ctx: CanvasRenderingContext2D,
  tool: Tool,
  from: Point,
  to: Point,
  fillShape: boolean,
): void {
  ctx.beginPath()
  switch (tool) {
    case 'line':
      ctx.moveTo(from.x, from.y)
      ctx.lineTo(to.x, to.y)
      ctx.stroke()
      return
    case 'rect': {
      const x = Math.min(from.x, to.x)
      const y = Math.min(from.y, to.y)
      const w = Math.abs(to.x - from.x)
      const h = Math.abs(to.y - from.y)
      ctx.rect(x, y, w, h)
      break
    }
    case 'circle': {
      const cx = (from.x + to.x) / 2
      const cy = (from.y + to.y) / 2
      const rx = Math.abs(to.x - from.x) / 2
      const ry = Math.abs(to.y - from.y) / 2
      ctx.ellipse(cx, cy, rx, ry, 0, 0, Math.PI * 2)
      break
    }
    default:
      return
  }
  if (fillShape) ctx.fill()
  ctx.stroke()
}
