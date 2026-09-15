export type Point = { x: number; y: number }
type Base = { id: string; layer: string }
export type Entity =
  | (Base & { type: 'line'; x1: number; y1: number; x2: number; y2: number })
  | (Base & { type: 'rect'; x: number; y: number; width: number; height: number; hatch?: boolean })
  | (Base & { type: 'circle'; cx: number; cy: number; radius: number })
  | (Base & { type: 'arc'; cx: number; cy: number; radius: number; start: number; end: number })
  | (Base & { type: 'text'; x: number; y: number; text: string; size: number; angle: number })
  | (Base & { type: 'polyline'; points: Point[]; closed: boolean })
export type Layer = { id: string; name: string; color: string; visible: boolean; locked: boolean; weight: number }
export type Drawing = { version: 1; title: string; entities: Entity[]; layers: Layer[]; currentLayer: string }
export type View = { x: number; y: number; width: number; height: number }
export type History = { past: Drawing[]; present: Drawing; future: Drawing[] }
export type Draft = { tool: 'line' | 'rect' | 'circle'; first?: Point }
export const STORAGE_KEY = 'draev.drawing.v1'
export const round = (value: number) => Math.round(value * 1000) / 1000
export const snapPoint = (p: Point, step = 100): Point => ({ x: Math.round(p.x / step) * step, y: Math.round(p.y / step) * step })
export const distance = (a: Point, b: Point) => Math.hypot(a.x - b.x, a.y - b.y)

export function anchor(entity: Entity): Point {
  switch (entity.type) {
    case 'line': return { x: entity.x1, y: entity.y1 }
    case 'circle': case 'arc': return { x: entity.cx, y: entity.cy }
    case 'polyline': return entity.points[0]
    default: return { x: entity.x, y: entity.y }
  }
}

export function moveEntity(entity: Entity, dx: number, dy: number): Entity {
  switch (entity.type) {
    case 'line': return { ...entity, x1: round(entity.x1 + dx), y1: round(entity.y1 + dy), x2: round(entity.x2 + dx), y2: round(entity.y2 + dy) }
    case 'circle': case 'arc': return { ...entity, cx: round(entity.cx + dx), cy: round(entity.cy + dy) }
    case 'polyline': return { ...entity, points: entity.points.map(p => ({ x: round(p.x + dx), y: round(p.y + dy) })) }
    default: return { ...entity, x: round(entity.x + dx), y: round(entity.y + dy) }
  }
}

export function controlPoints(e: Entity): Point[] {
  switch (e.type) {
    case 'line': return [{ x: e.x1, y: e.y1 }, { x: e.x2, y: e.y2 }]
    case 'rect': return [{ x: e.x, y: e.y }, { x: e.x + e.width, y: e.y + e.height }]
    case 'circle': case 'arc': return [{ x: e.cx, y: e.cy }, { x: e.cx + e.radius, y: e.cy }]
    case 'polyline': return e.points
    default: return [{ x: e.x, y: e.y }]
  }
}

export function bounds(entities: Entity[]): View {
  const points = entities.flatMap(e => e.type === 'circle' || e.type === 'arc'
    ? [{ x: e.cx - e.radius, y: e.cy - e.radius }, { x: e.cx + e.radius, y: e.cy + e.radius }]
    : controlPoints(e))
  if (!points.length) return { x: 0, y: -10000, width: 10000, height: 10000 }
  const xs = points.map(p => p.x), ys = points.map(p => p.y)
  const minX = Math.min(...xs), maxX = Math.max(...xs), minY = Math.min(...ys), maxY = Math.max(...ys)
  return { x: minX - 800, y: -maxY - 800, width: maxX - minX + 1600, height: maxY - minY + 1600 }
}

export function fitView(entities: Entity[], aspect: number): View {
  const b = bounds(entities)
  const width = Math.max(b.width, b.height * aspect)
  const height = width / aspect
  return { x: b.x - (width - b.width) / 2, y: b.y - (height - b.height) / 2, width, height }
}

export function zoomView(view: View, factor: number, position: Point): View {
  const width = Math.min(250000, Math.max(1000, view.width * factor))
  const ratio = width / view.width
  return { x: position.x - (position.x - view.x) * ratio, y: position.y - (position.y - view.y) * ratio, width, height: view.height * ratio }
}

export function parsePoint(text: string, origin?: Point): Point | null {
  const relative = text.startsWith('@')
  const parts = text.replace(/^@/, '').split(',')
  if (parts.length !== 2 || parts.some(s => !s.trim() || !Number.isFinite(Number(s)))) return null
  if (relative && !origin) return null
  const x = Number(parts[0]) + (relative ? origin!.x : 0), y = Number(parts[1]) + (relative ? origin!.y : 0)
  return Math.max(Math.abs(x), Math.abs(y)) <= 1e7 ? { x, y } : null
}

export function createGeometry(draft: Draft, next: Point | number, layer: string, id: string): Entity | null {
  const a = draft.first
  if (!a) return null
  const base = { id, layer }
  if (draft.tool === 'circle') {
    const radius = typeof next === 'number' ? next : distance(a, next)
    return radius > 0 && radius <= 1e7 && Number.isFinite(radius) ? { ...base, type: 'circle', cx: a.x, cy: a.y, radius: round(radius) } : null
  }
  if (typeof next === 'number') return null
  if (draft.tool === 'line') return distance(a, next) > 0 ? { ...base, type: 'line', x1: a.x, y1: a.y, x2: next.x, y2: next.y } : null
  const width = Math.abs(next.x - a.x), height = Math.abs(next.y - a.y)
  return width > 0 && height > 0 ? { ...base, type: 'rect', x: Math.min(a.x, next.x), y: Math.min(a.y, next.y), width, height } : null
}

export function commit(history: History, drawing: Drawing): History {
  if (history.present === drawing) return history
  return { past: [...history.past, history.present].slice(-40), present: drawing, future: [] }
}
export function undo(history: History): History {
  const previous = history.past.at(-1)
  return previous ? { past: history.past.slice(0, -1), present: previous, future: [history.present, ...history.future] } : history
}
export function redo(history: History): History {
  const next = history.future[0]
  return next ? { past: [...history.past, history.present], present: next, future: history.future.slice(1) } : history
}

function record(value: unknown): value is Record<string, unknown> { return typeof value === 'object' && value !== null && !Array.isArray(value) }
function finite(value: unknown): value is number { return typeof value === 'number' && Number.isFinite(value) && Math.abs(value) <= 1e7 }
function validPoint(value: unknown): value is Point { return record(value) && finite(value.x) && finite(value.y) }
function validEntity(e: unknown, layers: Set<string>): e is Entity {
  if (!record(e) || typeof e.id !== 'string' || !e.id || typeof e.layer !== 'string' || !layers.has(e.layer)) return false
  switch (e.type) {
    case 'line': return [e.x1, e.y1, e.x2, e.y2].every(finite)
    case 'rect': return finite(e.x) && finite(e.y) && finite(e.width) && e.width > 0 && finite(e.height) && e.height > 0 && (e.hatch === undefined || typeof e.hatch === 'boolean')
    case 'circle': case 'arc': return finite(e.cx) && finite(e.cy) && finite(e.radius) && e.radius > 0 && (e.type === 'circle' || (finite(e.start) && finite(e.end)))
    case 'text': return finite(e.x) && finite(e.y) && typeof e.text === 'string' && e.text.length <= 2000 && finite(e.size) && e.size > 0 && finite(e.angle)
    case 'polyline': return Array.isArray(e.points) && e.points.length >= 2 && e.points.length <= 1000 && e.points.every(validPoint) && typeof e.closed === 'boolean'
    default: return false
  }
}

export function parseDrawing(raw: string): Drawing | null {
  try {
    if (raw.length > 6_000_000) return null
    const d: unknown = JSON.parse(raw)
    if (!record(d) || d.version !== 1 || typeof d.title !== 'string' || !d.title.trim() || d.title.length > 120 || !Array.isArray(d.layers) || d.layers.length < 1 || d.layers.length > 100 || !Array.isArray(d.entities) || d.entities.length > 10000) return null
    const layers: Layer[] = []
    for (const layer of d.layers) {
      if (!record(layer) || typeof layer.id !== 'string' || !/^[a-zA-Z0-9_-]+$/.test(layer.id) || typeof layer.name !== 'string' || layer.name.length > 100 || typeof layer.color !== 'string' || !/^#[0-9a-f]{6}$/i.test(layer.color) || typeof layer.visible !== 'boolean' || typeof layer.locked !== 'boolean' || !finite(layer.weight) || layer.weight <= 0) return null
      layers.push({ id: layer.id, name: layer.name, color: layer.color, visible: layer.visible, locked: layer.locked, weight: layer.weight })
    }
    const ids = new Set(layers.map(l => l.id))
    if (ids.size !== layers.length || typeof d.currentLayer !== 'string' || !ids.has(d.currentLayer) || !d.entities.every(e => validEntity(e, ids))) return null
    if (new Set(d.entities.map(e => e.id)).size !== d.entities.length) return null
    return { version: 1, title: d.title, layers, currentLayer: d.currentLayer, entities: d.entities }
  } catch { return null }
}

export const escapeXml = (text: string) => text.replace(/[<>&"']/g, c => ({ '<': '&lt;', '>': '&gt;', '&': '&amp;', '"': '&quot;', "'": '&apos;' })[c]!)
export function arcPath(e: Extract<Entity, { type: 'arc' }>): string {
  const radians = Math.PI / 180, a = e.start * radians, b = e.end * radians
  const sweep = ((e.end - e.start) % 360 + 360) % 360
  return `M ${e.cx + e.radius * Math.cos(a)} ${-e.cy - e.radius * Math.sin(a)} A ${e.radius} ${e.radius} 0 ${sweep > 180 ? 1 : 0} 0 ${e.cx + e.radius * Math.cos(b)} ${-e.cy - e.radius * Math.sin(b)}`
}
export function entitySvg(e: Entity): string {
  switch (e.type) {
    case 'line': return `<line x1="${e.x1}" y1="${-e.y1}" x2="${e.x2}" y2="${-e.y2}"/>`
    case 'rect': return `<rect x="${e.x}" y="${-e.y - e.height}" width="${e.width}" height="${e.height}"${e.hatch ? ' fill="url(#hatch)"' : ''}/>`
    case 'circle': return `<circle cx="${e.cx}" cy="${-e.cy}" r="${e.radius}"/>`
    case 'arc': return `<path d="${arcPath(e)}"/>`
    case 'polyline': return `<${e.closed ? 'polygon' : 'polyline'} points="${e.points.map(p => `${p.x},${-p.y}`).join(' ')}"/>`
    case 'text': return `<text x="${e.x}" y="${-e.y}" font-size="${e.size}" fill="currentColor" stroke="none" text-anchor="middle" font-family="Arial, sans-serif" transform="rotate(${-e.angle} ${e.x} ${-e.y})">${escapeXml(e.text)}</text>`
  }
}
export function exportSvg(d: Drawing): string {
  const visible = d.entities.filter(e => d.layers.find(l => l.id === e.layer)?.visible)
  const b = bounds(visible)
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${b.x} ${b.y} ${b.width} ${b.height}"><title>${escapeXml(d.title)}</title><defs><pattern id="hatch" width="130" height="130" patternUnits="userSpaceOnUse"><path d="M0 130L130 0" stroke="#74828c" stroke-width="12"/></pattern></defs><rect x="${b.x}" y="${b.y}" width="${b.width}" height="${b.height}" fill="#20282f"/>${d.layers.filter(l => l.visible).map(l => `<g id="${l.id}" fill="none" color="${l.color}" stroke="${l.color}" stroke-width="${l.weight * 22}">${visible.filter(e => e.layer === l.id).map(entitySvg).join('')}</g>`).join('')}</svg>`
}
export function exportDxf(d: Drawing): string {
  const pairs: (string | number)[] = [0, 'SECTION', 2, 'HEADER', 9, '$ACADVER', 1, 'AC1015', 9, '$INSUNITS', 70, 4, 0, 'ENDSEC', 0, 'SECTION', 2, 'TABLES', 0, 'TABLE', 2, 'LAYER', 70, d.layers.length]
  for (const l of d.layers) pairs.push(0, 'LAYER', 2, l.id, 70, l.locked ? 4 : 0, 62, l.visible ? 7 : -7, 420, parseInt(l.color.slice(1), 16), 6, 'CONTINUOUS')
  pairs.push(0, 'ENDTAB', 0, 'ENDSEC', 0, 'SECTION', 2, 'ENTITIES')
  for (const e of d.entities) {
    if (e.type === 'line') pairs.push(0, 'LINE', 8, e.layer, 10, e.x1, 20, e.y1, 11, e.x2, 21, e.y2)
    if (e.type === 'circle' || e.type === 'arc') {
      pairs.push(0, e.type.toUpperCase(), 8, e.layer, 10, e.cx, 20, e.cy, 40, e.radius)
      if (e.type === 'arc') pairs.push(50, e.start, 51, e.end)
    }
    if (e.type === 'text') pairs.push(0, 'TEXT', 8, e.layer, 10, e.x, 20, e.y, 40, e.size, 1, e.text.replace(/[\r\n]/g, ' '), 50, e.angle, 72, 1, 11, e.x, 21, e.y)
    if (e.type === 'rect' || e.type === 'polyline') {
      const points = e.type === 'polyline' ? e.points : [{ x: e.x, y: e.y }, { x: e.x + e.width, y: e.y }, { x: e.x + e.width, y: e.y + e.height }, { x: e.x, y: e.y + e.height }]
      pairs.push(0, 'LWPOLYLINE', 8, e.layer, 90, points.length, 70, e.type === 'rect' || e.closed ? 1 : 0)
      for (const p of points) pairs.push(10, p.x, 20, p.y)
    }
  }
  pairs.push(0, 'ENDSEC', 0, 'EOF')
  return pairs.join('\n') + '\n'
}
