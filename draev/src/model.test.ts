import { describe, expect, it } from 'vitest'
import { createResidence } from './fixture'
import { anchor, arcPath, bounds, commit, createGeometry, exportDxf, exportSvg, fitView, moveEntity, parseDrawing, parsePoint, redo, snapPoint, undo, zoomView } from './model'
import type { Drawing, Entity, History } from './model'

const rectangle: Entity = { id: 'test', layer: 'draft', type: 'rect', x: 1000, y: 2000, width: 3000, height: 4000 }
const freshHistory = (): History => ({ past: [], present: createResidence(), future: [] })

describe('coordinate and geometry engine', () => {
  it('parses absolute, negative and relative points with finite bounds', () => {
    expect(parsePoint('-120.5,800')).toEqual({ x: -120.5, y: 800 })
    expect(parsePoint('@-500,250', { x: 1000, y: 2000 })).toEqual({ x: 500, y: 2250 })
    for (const invalid of ['', ',', 'NaN,3', 'Infinity,4', '1e8,0', '1,2,3', '@1,2']) expect(parsePoint(invalid)).toBeNull()
  })
  it('snaps positive and negative coordinates to a metric grid', () => {
    expect(snapPoint({ x: 1263, y: -1232 })).toEqual({ x: 1300, y: -1200 })
    expect(snapPoint({ x: 28, y: 43 }, 25)).toEqual({ x: 25, y: 50 })
  })
  it('creates ordered rectangles from reversed corners and rejects zero area', () => {
    const draft = { tool: 'rect' as const, first: { x: 5000, y: 7000 } }
    expect(createGeometry(draft, { x: 1000, y: 2000 }, 'draft', 'r')).toEqual({ id: 'r', layer: 'draft', type: 'rect', x: 1000, y: 2000, width: 4000, height: 5000 })
    expect(createGeometry(draft, { x: 5000, y: 9000 }, 'draft', 'r')).toBeNull()
  })
  it('creates lines and circle radii accurately from points or typed radius', () => {
    expect(createGeometry({ tool: 'line', first: { x: 0, y: 0 } }, { x: 0, y: 0 }, 'draft', 'l')).toBeNull()
    expect(createGeometry({ tool: 'line', first: { x: 0, y: 0 } }, { x: 1200, y: 4500 }, 'draft', 'l')).toMatchObject({ x2: 1200, y2: 4500 })
    const draft = { tool: 'circle' as const, first: { x: 100, y: 100 } }
    expect(createGeometry(draft, { x: 400, y: 500 }, 'draft', 'c')).toMatchObject({ radius: 500 })
    expect(createGeometry(draft, 750, 'draft', 'c')).toMatchObject({ radius: 750 })
    for (const radius of [0, -3, Infinity, NaN, 1e8]) expect(createGeometry(draft, radius, 'draft', 'c')).toBeNull()
  })
  it('moves every fixture entity without changing its type or dimensions', () => {
    for (const entity of createResidence().entities) {
      const original = anchor(entity)
      const moved = moveEntity(entity, 400, -900)
      expect(anchor(moved)).toEqual({ x: Math.round((original.x + 400) * 1000) / 1000, y: Math.round((original.y - 900) * 1000) / 1000 })
      expect(moved.type).toBe(entity.type)
      expect(entity).not.toBe(moved)
    }
  })
  it('fits geometry to the viewport aspect without cropping and anchors zoom', () => {
    const entities = createResidence().entities, b = bounds(entities), v = fitView(entities, 1.8)
    expect(v.width / v.height).toBeCloseTo(1.8)
    expect(v.x).toBeLessThanOrEqual(b.x)
    expect(v.y).toBeLessThanOrEqual(b.y)
    expect(v.x + v.width).toBeGreaterThanOrEqual(b.x + b.width)
    const p = { x: 3000, y: -7000 }, z = zoomView(v, .7, p)
    expect((p.x - v.x) / v.width).toBeCloseTo((p.x - z.x) / z.width)
    expect((p.y - v.y) / v.height).toBeCloseTo((p.y - z.y) / z.height)
  })
  it('renders door arcs with the correct inverted Y and sweep', () => {
    expect(arcPath({ id: 'a', layer: 'doors', type: 'arc', cx: 0, cy: 0, radius: 1000, start: 0, end: 90 })).toContain('A 1000 1000 0 0 0')
  })
})

describe('history and persistence', () => {
  it('undoes and redoes geometry and layer edits, then clears the redo branch', () => {
    const h = freshHistory()
    const withRect = commit(h, { ...h.present, entities: [...h.present.entities, rectangle] })
    const hidden = commit(withRect, { ...withRect.present, layers: withRect.present.layers.map(l => ({ ...l, visible: false })) })
    expect(undo(hidden).present).toEqual(withRect.present)
    expect(redo(undo(hidden)).present).toEqual(hidden.present)
    expect(commit(undo(hidden), { ...withRect.present, title: 'Edited' }).future).toHaveLength(0)
    expect(undo(h)).toBe(h)
  })
  it('limits history to forty complete edits', () => {
    let h = freshHistory()
    for (let i = 0; i < 50; i++) h = commit(h, { ...h.present, title: `Drawing ${i}` })
    expect(h.past).toHaveLength(40)
  })
  it('round-trips the complete deterministic architectural project', () => {
    const drawing = createResidence()
    expect(drawing.entities.length).toBeGreaterThan(900)
    expect(drawing).toEqual(createResidence())
    expect(new Set(drawing.entities.map(e => e.type)).size).toBe(6)
    expect(parseDrawing(JSON.stringify(drawing))).toEqual(drawing)
  })
  it('rejects malformed files, invalid layers, duplicates and non-finite geometry', () => {
    const d = createResidence()
    const cases: unknown[] = [
      null, {}, { ...d, version: 2 }, { ...d, currentLayer: 'missing' },
      { ...d, layers: [...d.layers, d.layers[0]] },
      { ...d, layers: [{ ...d.layers[0], color: 'url(https://invalid.test)' }] },
      { ...d, entities: [{ ...rectangle, width: -50 }] },
      { ...d, entities: [{ ...rectangle, y: null }] },
      { ...d, entities: [{ ...rectangle, layer: 'missing' }] },
      { ...d, entities: [rectangle, rectangle] },
      { ...d, entities: [{ type: 'polyline', id: 'p', layer: 'draft', points: [], closed: true }] },
    ]
    expect(parseDrawing('{malformed')).toBeNull()
    for (const value of cases) expect(parseDrawing(JSON.stringify(value))).toBeNull()
  })
})

describe('portable exports', () => {
  it('exports visible SVG geometry with correct coordinate inversion and escaped text', () => {
    const d: Drawing = { ...createResidence(), title: 'Courtyard <draft>', entities: [rectangle, { id: 'text', layer: 'text', type: 'text', x: 2, y: 3, text: '<script>&"quote"', size: 100, angle: 0 }] }
    const svg = exportSvg(d)
    expect(svg).toContain('x="1000" y="-6000" width="3000" height="4000"')
    expect(svg).toContain('Courtyard &lt;draft&gt;')
    expect(svg).toContain('&lt;script&gt;&amp;&quot;quote&quot;')
    const hidden = exportSvg({ ...d, layers: d.layers.map(l => l.id === 'draft' ? { ...l, visible: false } : l) })
    expect(hidden).not.toContain('width="3000"')
    expect(svg).not.toMatch(/NaN|Infinity/)
  })
  it('emits DXF header, metric units, layer flags and entity coordinate pairs', () => {
    const d = createResidence(), output = exportDxf(d), lines = output.trim().split('\n')
    expect(lines.length % 2).toBe(0)
    expect(output).toContain('$INSUNITS\n70\n4\n')
    expect(output).toContain('0\nLWPOLYLINE\n')
    expect(output).toContain('0\nARC\n')
    expect(output).toContain('0\nTEXT\n')
    expect(output.endsWith('0\nEOF\n')).toBe(true)
    const rectDxf = exportDxf({ ...d, entities: [rectangle] })
    expect(rectDxf).toContain('90\n4\n70\n1\n10\n1000\n20\n2000\n10\n4000\n20\n2000\n')
    expect(exportDxf({ ...d, layers: d.layers.map(l => ({ ...l, visible: false })) })).toContain('62\n-7\n')
  })
})
