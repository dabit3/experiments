import { describe, expect, it } from 'vitest'
import * as THREE from 'three'
import { addKey, commit, createPrimitive, initialProject, parseProject, patchObject, redo, sample, serializeProject, transform, undo, updateWithKeys, type History } from './model'
import { applyTransform, buildObject, disposeGroup, exportOBJ, twistGeometry } from './geometry'

describe('deterministic gallery and editing', () => {
  it('creates a detailed, independent gallery fixture with architectural ribs', () => {
    const first = initialProject(), second = initialProject()
    expect(first).toEqual(second)
    expect(first.objects).toHaveLength(25)
    expect(first.objects.filter(o => o.kind === 'rib')).toHaveLength(11)
    expect(new Set(first.objects.map(o => o.id)).size).toBe(25)
    first.objects[0].name = 'Edited'
    expect(second.objects[0].name).not.toBe('Edited')
  })
  it('allocates unique primitive names without depending on wall-clock time', () => {
    const project = initialProject()
    const a = createPrimitive(project, 'box')
    const b = createPrimitive({ ...project, objects: [...project.objects, a] }, 'box')
    expect(a.id).toBe('user-box-1')
    expect(b.id).toBe('user-box-2')
    expect(a.position).toEqual([2.8, 1, 2.8])
  })
  it('changes only the targeted object without mutating previous history', () => {
    const original = initialProject()
    const changed = patchObject(original, 'hero', { twist: 135, color: '#ff00aa' })
    expect(original.objects.find(o => o.id === 'hero')!.twist).toBe(0)
    expect(changed.objects.find(o => o.id === 'hero')!.twist).toBe(135)
    expect(changed.objects[0]).toBe(original.objects[0])
  })
  it('undoes and redoes scene edits, and truncates redo after a divergent edit', () => {
    const initial: History = { past: [], present: initialProject(), future: [] }
    const first = commit(initial, patchObject(initial.present, 'hero', { twist: 90 }))
    const restored = undo(first)
    expect(restored.present).toEqual(initial.present)
    expect(redo(restored).present).toEqual(first.present)
    expect(commit(restored, patchObject(restored.present, 'hero', { twist: 180 })).future).toEqual([])
    expect(undo(initial)).toBe(initial)
    expect(redo(initial)).toBe(initial)
    expect(commit(initial, initial.present)).toBe(initial)
  })
  it('caps history at 60 snapshots', () => {
    let history: History = { past: [], present: initialProject(), future: [] }
    for (let n = 1; n <= 70; n++) history = commit(history, patchObject(history.present, 'hero', { twist: n }))
    expect(history.past).toHaveLength(60)
  })
})

describe('animation editing and sampling', () => {
  it('interpolates synchronized position/rotation/scale and clamps outside key range', () => {
    const hero = initialProject().objects.find(o => o.id === 'hero')!
    expect(sample(hero, 50).rotation).toEqual([0, 90, 0])
    expect(sample(hero, -10).rotation).toEqual([0, 0, 0])
    expect(sample(hero, 110).rotation).toEqual([0, 180, 0])
  })
  it('adds ordered keys and replaces an existing frame without duplicates', () => {
    const object = initialProject().objects.find(o => o.id === 'hero')!
    object.keys = addKey({ ...object, rotation: [0, 120, 0] }, 50)
    object.keys = addKey({ ...object, rotation: [0, 125, 0] }, 50)
    expect(object.keys.map(k => k.frame)).toEqual([0, 50, 100])
    expect(sample(object, 50).rotation[1]).toBe(125)
    expect(sample(object, 25).rotation[1]).toBe(62.5)
  })
  it('edits keyed objects at the current pose rather than losing edits to sampling', () => {
    const hero = initialProject().objects.find(o => o.id === 'hero')!
    const edited = updateWithKeys(hero, { position: [4, 2, 0] }, 50, false)
    expect(sample(edited, 50).position).toEqual([4, 2, 0])
    expect(sample(edited, 50).rotation).toEqual([0, 90, 0])
    expect(edited.keys).toHaveLength(3)
    expect(hero.keys).toHaveLength(2)
  })
  it('preserves a frame-zero pose when Auto Key starts later in the timeline', () => {
    const primitive = createPrimitive(initialProject(), 'box')
    const edited = updateWithKeys(primitive, { position: [7, 2, 3] }, 60, true)
    expect(edited.keys.map(k => k.frame)).toEqual([0, 60])
    expect(sample(edited, 0)).toEqual(transform(primitive))
    expect(sample(edited, 60).position).toEqual([7, 2, 3])
    expect(updateWithKeys(primitive, { position: [7, 2, 3] }, 60, false).keys).toEqual([])
  })
})

describe('persistence validation', () => {
  it('round trips geometry, materials and keyframes', () => {
    const project = initialProject()
    expect(parseProject(serializeProject(project))).toEqual(project)
  })
  it('rejects corrupt documents and unbounded values', () => {
    expect(() => parseProject('{')).toThrow()
    for (const patch of [{ scale: [0, 1, 1] }, { position: [1e9, 1, 1] }, { color: 'url(evil)' }, { kind: 'unknown' }, { name: '' }, { twist: 999 }, { keys: [{ frame: 20 }] }]) {
      const project = initialProject()
      Object.assign(project.objects[0], patch)
      expect(() => parseProject(serializeProject(project))).toThrow()
    }
  })
  it('rejects duplicate object IDs and unordered animation keys', () => {
    const project = initialProject()
    project.objects.push(project.objects[0])
    expect(() => parseProject(serializeProject(project))).toThrow()
    const second = initialProject()
    second.objects.find(o => o.id === 'hero')!.keys.reverse()
    expect(() => parseProject(serializeProject(second))).toThrow()
    expect(() => parseProject(' '.repeat(2_000_001))).toThrow('2 MB')
  })
})

describe('real geometry and OBJ export', () => {
  it('constructs every fixture with finite world geometry', () => {
    for (const object of initialProject().objects) {
      const group = buildObject(object)
      const bounds = new THREE.Box3().setFromObject(group)
      expect(bounds.isEmpty()).toBe(false)
      expect([...bounds.min.toArray(), ...bounds.max.toArray()].every(Number.isFinite)).toBe(true)
      disposeGroup(group)
    }
  })
  it('twists vertices around Y with unchanged height and radial distances', () => {
    const geometry = new THREE.BoxGeometry(1, 4, 0.5, 1, 20, 1)
    const before = geometry.getAttribute('position').clone()
    twistGeometry(geometry, 135)
    const after = geometry.getAttribute('position')
    let changed = 0
    for (let i = 0; i < after.count; i++) {
      expect(after.getY(i)).toBeCloseTo(before.getY(i))
      expect(Math.hypot(after.getX(i), after.getZ(i))).toBeCloseTo(Math.hypot(before.getX(i), before.getZ(i)), 5)
      if (Math.abs(after.getX(i) - before.getX(i)) > 0.01) changed++
    }
    expect(changed).toBeGreaterThan(40)
    geometry.dispose()
  })
  it('applies degree rotations and numeric world transforms accurately', () => {
    const group = new THREE.Group()
    applyTransform(group, { position: [2, 3, 4], rotation: [0, 90, 0], scale: [2, 1, 1] })
    group.updateMatrixWorld()
    expect(new THREE.Vector3(1, 0, 0).applyMatrix4(group.matrixWorld).toArray()).toEqual([2.0000000000000004, 3, 2])
  })
  it('exports transformed triangles and excludes hidden geometry', () => {
    const project = initialProject()
    const box = createPrimitive(project, 'box')
    box.position = [10, 0, 0]
    box.name = 'Export\ninjection'
    const hidden = { ...box, id: 'hidden-box', name: 'Hidden', visible: false }
    const output = exportOBJ({ version: 1, name: 'Test', objects: [box, hidden] }, 0)
    expect(output).toContain('o Export_injection')
    expect(output).not.toContain('o Hidden')
    expect(output).toContain('v 10.50000')
    expect(output.split('\n').filter(s => s.startsWith('f '))).toHaveLength(12)
    expect(output).not.toMatch(/NaN|Infinity/)
  })
  it('exports baked modifiers and samples the requested animation frame', () => {
    const project = initialProject()
    const object = createPrimitive(project, 'box')
    object.twist = 90
    object.keys = [{ ...transform(object), frame: 0 }, { ...transform(object), position: [12, 1, 2.8], frame: 100 }]
    const fixture = { ...project, objects: [object] }
    expect(exportOBJ(fixture, 0)).not.toEqual(exportOBJ(fixture, 100))
    expect(exportOBJ(fixture, 0).split('\n').filter(s => s.startsWith('f ')).length).toBeGreaterThan(100)
  })
})
