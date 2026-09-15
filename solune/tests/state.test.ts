import { describe, expect, it } from 'vitest'
import { commit, createProject, daylight, exportProject, formatTime, parseProject, placeObject, redo, sunPosition, undo } from '../src/state'
import type { History } from '../src/state'

describe('persistent scene document', () => {
  it('roundtrips every editable field and camera without losing precision', () => {
    const project = createProject()
    project.material = 'terracotta'
    project.time = 19.7
    project.weather = 'mist'
    project.objects[0].rotation = 55
    project.shots[0].position[0] = 27.34567
    expect(parseProject(exportProject(project))).toEqual(project)
  })
  it('isolates reset fixtures rather than sharing mutable arrays', () => {
    const first = createProject()
    first.objects.splice(0, 1)
    first.shots[0].position[0] = 900
    expect(createProject().objects).toHaveLength(8)
    expect(createProject().shots[0].position[0]).toBe(29)
  })
  it.each([
    ['version', 2], ['time', 25], ['weather', 'hurricane'], ['material', 'constructor'],
    ['exposure', null], ['bloom', 40], ['cloud', -1], ['roughness', '0.5'], ['shots', []],
  ])('rejects malformed %s instead of silently loading a partial document', (key, value) => {
    expect(() => parseProject(JSON.stringify({ ...createProject(), [key]: value }))).toThrow()
  })
  it('rejects malicious or broken object and camera arrays', () => {
    const project = createProject()
    project.objects[0].position[0] = Infinity
    expect(() => parseProject(JSON.stringify(project))).toThrow()
    const duplicate = createProject()
    duplicate.objects.push(duplicate.objects[0])
    expect(() => parseProject(JSON.stringify(duplicate))).toThrow('Duplicate')
    const badCamera = createProject()
    badCamera.shots[0].target = [...badCamera.shots[0].position]
    expect(() => parseProject(JSON.stringify(badCamera))).toThrow()
  })
  it('rejects non-JSON, null, and oversize scene object arrays', () => {
    expect(() => parseProject('not json')).toThrow()
    expect(() => parseProject('null')).toThrow()
    const p = createProject()
    p.objects = Array.from({ length: 101 }, (_, i) => ({ ...p.objects[0], id: `p-${i}` }))
    expect(() => parseProject(JSON.stringify(p))).toThrow()
  })
})
describe('editing and history', () => {
  it('places a real scene object on bounded terrain without mutating its source', () => {
    const p = createProject()
    const next = placeObject(p, 'olive', [40, 9, -30], 'new')
    expect(next.objects.at(-1)).toEqual({ id: 'new', kind: 'olive', position: [19, 0.42, -12], rotation: 0, scale: 1 })
    expect(p.objects).toHaveLength(8)
    expect(() => placeObject(p, 'palm', [NaN, 0, 1], 'invalid')).toThrow()
    expect(() => placeObject(p, 'palm', [0, 0, 0], 'palm-1')).toThrow()
  })
  it('undoes and redoes a complete material/placement/export workflow', () => {
    const original = createProject()
    let h: History = { past: [], present: original, future: [] }
    h = commit(h, { ...h.present, material: 'charcoal' })
    h = commit(h, placeObject(h.present, 'agave', [12, 0, 13], 'added'))
    expect(parseProject(exportProject(h.present)).objects).toHaveLength(9)
    h = undo(h)
    expect(h.present.objects).toHaveLength(8)
    expect(h.present.material).toBe('charcoal')
    h = undo(h)
    expect(h.present).toEqual(original)
    h = redo(redo(h))
    expect(h.present.objects.at(-1)?.id).toBe('added')
  })
  it('clears future history after branching and ignores no-op edits', () => {
    let h: History = { past: [], present: createProject(), future: [] }
    expect(commit(h, structuredClone(h.present))).toBe(h)
    h = commit(h, { ...h.present, time: 12 })
    h = undo(h)
    h = commit(h, { ...h.present, weather: 'mist' })
    expect(h.future).toEqual([])
    expect(redo(h)).toBe(h)
    for (let i = 0; i < 100; i++) h = commit(h, { ...h.present, name: `${i}` })
    expect(h.past).toHaveLength(50)
  })
})
describe('sun geometry', () => {
  it('makes noon brighter than dusk and rotates heading on a fixed horizontal radius', () => {
    expect(daylight(12)).toBeGreaterThan(daylight(18.4))
    expect(daylight(18.4)).toBeGreaterThan(daylight(22))
    expect(sunPosition(12, 0)).toEqual([60, 65, 0])
    expect(sunPosition(12, 90)[2]).toBeCloseTo(60)
    expect(sunPosition(22, 0)[1]).toBe(1.5)
    expect(formatTime(18.4)).toBe('18:24')
  })
})
