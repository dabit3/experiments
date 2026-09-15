import { describe, expect, it } from 'vitest'
import { area, commit, createHistory, deleteElement, doorOnWall, exportPlan, initialProject, parseProject, redo, slabFromPoints, snap, undo, updateElement, visibleElements, wallFromPoints } from './model'

describe('architectural geometry', () => {
  it('creates a rich deterministic campus with three hosted doors', () => {
    const p = initialProject()
    expect(p.elements.length).toBe(25)
    expect(parseProject(JSON.stringify(p))).toEqual(p)
    expect(p.elements.filter(e => e.kind === 'door')).toHaveLength(3)
  })
  it('computes diagonal walls and rejects accidental short clicks', () => {
    const e = wallFromPoints('w', { x: 0, z: 0 }, { x: 3, z: 4 }, 1, 'concrete')
    expect(e.width).toBe(5)
    expect(e.rotation).toBeCloseTo(53.1301)
    expect(e.elevation).toBe(3)
    expect(() => wallFromPoints('w', { x: 0, z: 0 }, { x: .1, z: 0 }, 0, 'timber')).toThrow()
    expect(snap(1.14)).toBe(1.25)
  })
  it('creates a positive slab from reverse corner order', () => {
    const e = slabFromPoints('s', { x: 10, z: 10 }, { x: 4, z: 2 }, 0, 'limestone')
    expect([e.x, e.z, e.width, e.depth, area(e)]).toEqual([7, 6, 6, 8, 48])
  })
  it('hosts a new door, follows wall movement, and cascades deletion', () => {
    let p = initialProject()
    const host = p.elements.find(e => e.id === 'north-0')!
    const d = doorOnWall('new-door', host, { x: host.x + 1, z: host.z }, p)
    p = { ...p, elements: [...p.elements, d] }
    p = updateElement(p, host.id, { x: host.x + 4, rotation: 90 })
    const moved = p.elements.find(e => e.id === d.id)!
    expect(moved.x).toBeCloseTo(host.x + 4)
    expect(moved.z).toBeCloseTo(host.z + 1)
    expect(moved.rotation).toBe(90)
    expect(() => doorOnWall('duplicate', host, host, p)).toThrow()
    expect(deleteElement(p, host.id).elements.some(e => e.id === d.id)).toBe(false)
  })
  it('filters stories, structural layers and roofs consistently', () => {
    const p = initialProject()
    expect(visibleElements(p, 'All elements', 2)).toHaveLength(3)
    expect(visibleElements(p, 'All elements', 1)).toHaveLength(1)
    expect(visibleElements(p, 'All elements', undefined, true).some(e => e.layer === 'Roofs')).toBe(false)
    expect(visibleElements(p, 'Structure only').every(e => e.layer === 'Structure')).toBe(true)
  })
})
describe('transactions and files', () => {
  it('undoes and redoes edits exactly, clearing redo on new edits', () => {
    const p = initialProject(), next = updateElement(p, 'north-0', { material: 'terracotta' })
    const h = commit(createHistory(p), next)
    expect(undo(h).present).toEqual(p)
    expect(redo(undo(h)).present).toEqual(next)
    expect(commit(undo(h), { ...p, name: 'Alternative' }).future).toEqual([])
    expect(commit(h, next)).toBe(h)
  })
  it('roundtrips saved projects without losing geometry or Unicode names', () => {
    const p = { ...initialProject(), name: 'Oak & Light — Édition' }
    expect(parseProject(JSON.stringify(p))).toEqual(p)
  })
  it('rejects malformed, hostile and inconsistent imported state', () => {
    expect(() => parseProject('not-json')).toThrow()
    expect(() => parseProject('{"version":2}')).toThrow()
    const p = initialProject()
    expect(() => parseProject(JSON.stringify({ ...p, elements: [p.elements[0], p.elements[0]] }))).toThrow()
    expect(() => parseProject(JSON.stringify({ ...p, elements: [{ ...p.elements[0], width: -1 }] }))).toThrow()
    expect(() => parseProject(JSON.stringify({ ...p, elements: [{ ...p.elements[0], material: '__proto__' }] }))).toThrow()
    expect(() => updateElement(p, 'south-0', { width: .8 })).toThrow()
    expect(() => updateElement(p, 'door-0', { hostId: 'missing' })).toThrow()
  })
  it('exports actual geometry, metric dimensions, active story and escaped text', () => {
    const p = { ...initialProject(), name: '<script>alert("x")</script>' }
    const svg = exportPlan(p, 0, 'All elements')
    expect(svg).toContain('15.00 m')
    expect(svg).toContain('0. Ground Floor')
    expect(svg).toContain('&lt;script&gt;')
    expect(svg).toContain('width="440mm"')
    expect(exportPlan(p, 0, 'All elements', 100)).toContain('width="880mm"')
    expect(exportPlan(p, 0, 'All elements', 500)).toContain('1:500')
    expect(svg).not.toContain('<script>')
    expect(exportPlan(p, 1, 'All elements')).toContain('mezzanine deck')
    expect(exportPlan(p, 1, 'All elements')).not.toContain('north wall')
  })
})
