import { GRID, PORT_SIDES } from '../types'
import type { Diagram, EdgeStyle, FlowEdge, FlowNode, Point, PortSide, Rect, Viewport } from '../types'

export const DATA_SKEW = 18
export const PORT_OFFSET = 28
export const ARROW_LENGTH = 14
export const ARROW_WIDTH = 12

export function snap(value: number, enabled: boolean): number {
  return enabled ? Math.round(value / GRID) * GRID : Math.round(value)
}

/** Top-left origin for a node whose centre snaps to the grid, so ports on different shapes line up. */
export function snapOrigin(x: number, y: number, w: number, h: number, enabled: boolean): Point {
  return { x: snap(x + w / 2, enabled) - w / 2, y: snap(y + h / 2, enabled) - h / 2 }
}

export function portDirection(side: PortSide): Point {
  switch (side) {
    case 'top':
      return { x: 0, y: -1 }
    case 'right':
      return { x: 1, y: 0 }
    case 'bottom':
      return { x: 0, y: 1 }
    case 'left':
      return { x: -1, y: 0 }
  }
}

export function portPosition(node: FlowNode, side: PortSide): Point {
  const inset = node.kind === 'data' ? DATA_SKEW / 2 : 0
  switch (side) {
    case 'top':
      return { x: node.x + node.w / 2, y: node.y }
    case 'right':
      return { x: node.x + node.w - inset, y: node.y + node.h / 2 }
    case 'bottom':
      return { x: node.x + node.w / 2, y: node.y + node.h }
    case 'left':
      return { x: node.x + inset, y: node.y + node.h / 2 }
  }
}

export function nearestPort(node: FlowNode, p: Point): PortSide {
  let best: PortSide = 'top'
  let bestDist = Infinity
  for (const side of PORT_SIDES) {
    const pos = portPosition(node, side)
    const d = (pos.x - p.x) ** 2 + (pos.y - p.y) ** 2
    if (d < bestDist) {
      bestDist = d
      best = side
    }
  }
  return best
}

export function shapePath(node: FlowNode): string {
  const { x, y, w, h } = node
  switch (node.kind) {
    case 'start':
    case 'end': {
      const r = h / 2
      return `M${x + r} ${y} H${x + w - r} A${r} ${r} 0 0 1 ${x + w - r} ${y + h} H${x + r} A${r} ${r} 0 0 1 ${x + r} ${y} Z`
    }
    case 'process': {
      const r = 10
      return `M${x + r} ${y} H${x + w - r} Q${x + w} ${y} ${x + w} ${y + r} V${y + h - r} Q${x + w} ${y + h} ${x + w - r} ${y + h} H${x + r} Q${x} ${y + h} ${x} ${y + h - r} V${y + r} Q${x} ${y} ${x + r} ${y} Z`
    }
    case 'decision':
      return `M${x + w / 2} ${y} L${x + w} ${y + h / 2} L${x + w / 2} ${y + h} L${x} ${y + h / 2} Z`
    case 'data':
      return `M${x + DATA_SKEW} ${y} H${x + w} L${x + w - DATA_SKEW} ${y + h} H${x} Z`
  }
}

export function pointInNode(node: FlowNode, p: Point, pad = 0): boolean {
  return p.x >= node.x - pad && p.x <= node.x + node.w + pad && p.y >= node.y - pad && p.y <= node.y + node.h + pad
}

export function rectsIntersect(a: Rect, b: Rect): boolean {
  return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y
}

export function normalizeRect(a: Point, b: Point): Rect {
  return {
    x: Math.min(a.x, b.x),
    y: Math.min(a.y, b.y),
    w: Math.abs(a.x - b.x),
    h: Math.abs(a.y - b.y),
  }
}

export function diagramBounds(diagram: Diagram, pad = 0): Rect | null {
  if (diagram.nodes.length === 0) return null
  let minX = Infinity
  let minY = Infinity
  let maxX = -Infinity
  let maxY = -Infinity
  for (const n of diagram.nodes) {
    minX = Math.min(minX, n.x)
    minY = Math.min(minY, n.y)
    maxX = Math.max(maxX, n.x + n.w)
    maxY = Math.max(maxY, n.y + n.h)
  }
  return { x: minX - pad, y: minY - pad, w: maxX - minX + pad * 2, h: maxY - minY + pad * 2 }
}

export function screenToWorld(p: Point, vp: Viewport): Point {
  return { x: (p.x - vp.x) / vp.zoom, y: (p.y - vp.y) / vp.zoom }
}

export function worldToScreen(p: Point, vp: Viewport): Point {
  return { x: p.x * vp.zoom + vp.x, y: p.y * vp.zoom + vp.y }
}

export function routeEdge(
  source: FlowNode,
  sourcePort: PortSide,
  target: FlowNode,
  targetPort: PortSide,
  style: EdgeStyle,
): Point[] {
  const s = portPosition(source, sourcePort)
  const e = portPosition(target, targetPort)
  return routePoints(s, sourcePort, e, targetPort, style)
}

export function routePoints(s: Point, sourcePort: PortSide, e: Point, targetPort: PortSide, style: EdgeStyle): Point[] {
  if (style === 'straight') return [s, e]
  const ds = portDirection(sourcePort)
  const de = portDirection(targetPort)
  const p1 = { x: s.x + ds.x * PORT_OFFSET, y: s.y + ds.y * PORT_OFFSET }
  const p2 = { x: e.x + de.x * PORT_OFFSET, y: e.y + de.y * PORT_OFFSET }
  const sHorizontal = ds.x !== 0
  const eHorizontal = de.x !== 0
  const mid: Point[] = []
  if (sHorizontal && eHorizontal) {
    // Same-facing ports (e.g. right→right loop-backs) route around the outside instead of between the nodes.
    const midX = ds.x === de.x ? (ds.x > 0 ? Math.max(p1.x, p2.x) : Math.min(p1.x, p2.x)) : (p1.x + p2.x) / 2
    mid.push({ x: midX, y: p1.y }, { x: midX, y: p2.y })
  } else if (!sHorizontal && !eHorizontal) {
    const midY = ds.y === de.y ? (ds.y > 0 ? Math.max(p1.y, p2.y) : Math.min(p1.y, p2.y)) : (p1.y + p2.y) / 2
    mid.push({ x: p1.x, y: midY }, { x: p2.x, y: midY })
  } else if (sHorizontal) {
    mid.push({ x: p2.x, y: p1.y })
  } else {
    mid.push({ x: p1.x, y: p2.y })
  }
  return dedupe([s, p1, ...mid, p2, e])
}

function dedupe(points: Point[]): Point[] {
  const out: Point[] = []
  for (const p of points) {
    const last = out[out.length - 1]
    if (!last || Math.abs(last.x - p.x) > 0.01 || Math.abs(last.y - p.y) > 0.01) out.push(p)
  }
  return out
}

/** Shortens the last segment so the stroke stops just inside the arrowhead. */
export function trimForArrow(points: Point[]): Point[] {
  if (points.length < 2) return points
  const out = points.slice()
  const end = out[out.length - 1]
  const prev = out[out.length - 2]
  const dx = end.x - prev.x
  const dy = end.y - prev.y
  const len = Math.hypot(dx, dy) || 1
  const cut = Math.min(ARROW_LENGTH - 2, len)
  out[out.length - 1] = { x: end.x - (dx / len) * cut, y: end.y - (dy / len) * cut }
  return out
}

export function arrowHead(points: Point[]): string {
  if (points.length < 2) return ''
  const end = points[points.length - 1]
  const prev = points[points.length - 2]
  const dx = end.x - prev.x
  const dy = end.y - prev.y
  const len = Math.hypot(dx, dy) || 1
  const ux = dx / len
  const uy = dy / len
  const bx = end.x - ux * ARROW_LENGTH
  const by = end.y - uy * ARROW_LENGTH
  const px = -uy * (ARROW_WIDTH / 2)
  const py = ux * (ARROW_WIDTH / 2)
  return `${end.x},${end.y} ${bx + px},${by + py} ${bx - px},${by - py}`
}

export function polylinePath(points: Point[], radius = 8): string {
  if (points.length === 0) return ''
  if (points.length <= 2) return points.map((p, i) => `${i === 0 ? 'M' : 'L'}${p.x} ${p.y}`).join(' ')
  let d = `M${points[0].x} ${points[0].y}`
  for (let i = 1; i < points.length - 1; i++) {
    const prev = points[i - 1]
    const cur = points[i]
    const next = points[i + 1]
    const inLen = Math.hypot(cur.x - prev.x, cur.y - prev.y)
    const outLen = Math.hypot(next.x - cur.x, next.y - cur.y)
    const r = Math.min(radius, inLen / 2, outLen / 2)
    if (r <= 0.5) {
      d += ` L${cur.x} ${cur.y}`
      continue
    }
    const a = { x: cur.x + ((prev.x - cur.x) / inLen) * r, y: cur.y + ((prev.y - cur.y) / inLen) * r }
    const b = { x: cur.x + ((next.x - cur.x) / outLen) * r, y: cur.y + ((next.y - cur.y) / outLen) * r }
    d += ` L${a.x} ${a.y} Q${cur.x} ${cur.y} ${b.x} ${b.y}`
  }
  const last = points[points.length - 1]
  d += ` L${last.x} ${last.y}`
  return d
}

export function polylineMidpoint(points: Point[]): Point {
  if (points.length === 0) return { x: 0, y: 0 }
  if (points.length === 1) return points[0]
  let total = 0
  const lens: number[] = []
  for (let i = 1; i < points.length; i++) {
    const l = Math.hypot(points[i].x - points[i - 1].x, points[i].y - points[i - 1].y)
    lens.push(l)
    total += l
  }
  let remaining = total / 2
  for (let i = 1; i < points.length; i++) {
    const l = lens[i - 1]
    if (remaining <= l) {
      const t = l === 0 ? 0 : remaining / l
      return {
        x: points[i - 1].x + (points[i].x - points[i - 1].x) * t,
        y: points[i - 1].y + (points[i].y - points[i - 1].y) * t,
      }
    }
    remaining -= l
  }
  return points[points.length - 1]
}

export function wrapLabel(label: string, maxChars: number): string[] {
  const lines: string[] = []
  for (const paragraph of label.split('\n')) {
    const words = paragraph.split(/\s+/).filter(Boolean)
    if (words.length === 0) {
      lines.push('')
      continue
    }
    let current = ''
    for (const word of words) {
      if (current && (current + ' ' + word).length > maxChars) {
        lines.push(current)
        current = word
      } else {
        current = current ? current + ' ' + word : word
      }
    }
    lines.push(current)
  }
  return lines
}

export function edgeEndpoints(diagram: Diagram, edge: FlowEdge): [FlowNode, FlowNode] | null {
  const s = diagram.nodes.find((n) => n.id === edge.source)
  const t = diagram.nodes.find((n) => n.id === edge.target)
  return s && t ? [s, t] : null
}
