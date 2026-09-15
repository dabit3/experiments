import { describe, expect, it } from 'vitest'
import * as THREE from 'three'
import { commit, createMuseum, extrudeCurve, inversePoint, loftCurves, parseProject, redo, serializeProject, transformPoint, undo, updateEntity } from './model'
import type { History, Point } from './model'
import { canopyProfile, sampleCurve, stripGeometry, surfaceGeometry } from './geometry'
import { buildModel, disposeObject, exportOBJ, pickModelHit } from './scene'

describe('local project lifecycle', () => {
  it('round trips the deterministic museum through the persistence parser', () => {
    const project = createMuseum()
    expect(parseProject(serializeProject(project))).toEqual(project)
    expect(project.objects).toHaveLength(6)
    expect(project.layers).toHaveLength(6)
  })
  it('rejects malformed, duplicate, oversized and unsafe geometry before opening', () => {
    expect(() => parseProject('{')).toThrow()
    expect(() => parseProject(' '.repeat(2_000_001))).toThrow('2 MB')
    for (const value of [
      { ...createMuseum(), version: 2 },
      { ...createMuseum(), layers: [] },
      { ...createMuseum(), objects: [...createMuseum().objects, createMuseum().objects[0]] },
      { ...createMuseum(), layers: createMuseum().layers.map(layer => ({ ...layer, color: 'red' })) },
      updateEntity(createMuseum(), 'roof', { scale: 0 }),
      updateEntity(createMuseum(), 'roof', { ribs: 100000 }),
      updateEntity(createMuseum(), 'roof', { layerId: 'missing' }),
      updateEntity(createMuseum(), 'profile-a', { points: [[0, 0, 0]] }),
    ]) expect(() => parseProject(JSON.stringify(value))).toThrow()
  })
  it('undoes and redoes edits without mutating snapshots and clears redo on branching', () => {
    const initial: History = { past: [], present: createMuseum(), future: [] }
    const moved = updateEntity(initial.present, 'roof', { position: [4, 2, 1] })
    const edited = commit(initial, moved)
    expect(initial.present.objects[0].position).toEqual([0, 0, 0])
    expect(undo(edited).present).toEqual(initial.present)
    expect(redo(undo(edited)).present).toEqual(moved)
    const branched = commit(undo(edited), updateEntity(initial.present, 'roof', { height: 12 }))
    expect(branched.future).toEqual([])
    expect(redo(branched)).toBe(branched)
  })
  it('limits undo history and ignores no-op commits', () => {
    let history: History = { past: [], present: createMuseum(), future: [] }
    expect(commit(history, createMuseum())).toBe(history)
    for (let i = 0; i < 80; i++) history = commit(history, { ...history.present, name: `Study ${i}` })
    expect(history.past).toHaveLength(50)
  })
})

describe('geometry operations', () => {
  it('transforms in Rhino-style Z-up coordinates and accurately inverts points', () => {
    const entity = { ...createMuseum().objects[4], position: [10, 4, 2] as Point, rotation: 90, scale: 2 }
    const result = transformPoint([2, 3, 5], entity)
    expect(result[0]).toBeCloseTo(4)
    expect(result[1]).toBeCloseTo(8)
    expect(result[2]).toBeCloseTo(12)
    const original = inversePoint(result, entity)
    original.forEach((value, index) => expect(value).toBeCloseTo([2, 3, 5][index]))
  })
  it('interpolates the original endpoints and produces finite curve coordinates', () => {
    const points = createMuseum().objects[4].points
    const sampled = sampleCurve(points)
    expect(sampled).toHaveLength(65)
    expect(sampled[0]).toEqual(points[0])
    sampled.at(-1)?.forEach((value, i) => expect(value).toBeCloseTo(points.at(-1)![i]))
    expect(sampled.flat().every(Number.isFinite)).toBe(true)
    expect(Math.max(...sampled.map(point => point[2]))).toBeGreaterThanOrEqual(15)
  })
  it('changes the canopy crest with rise while preserving its span', () => {
    expect(canopyProfile(0.5, 0, 15)[2] - canopyProfile(0.5, 0, 9)[2]).toBeCloseTo(6)
    expect(canopyProfile(1, 0, 9)[0] - canopyProfile(0, 0, 9)[0]).toBeCloseTo(39)
    expect(canopyProfile(0, 0, 9)[2]).toBeCloseTo(canopyProfile(0, 0, 15)[2])
  })
  it('extrudes transformed curves into a real connected surface of the right height', () => {
    const curve = { ...createMuseum().objects[4], position: [2, 0, 1] as Point }
    const extrusion = extrudeCurve(curve, 5, 'test-extrusion')
    expect(extrusion.points[0]).toEqual([-14, -8, 6])
    const geometry = surfaceGeometry(extrusion)
    expect(geometry.getAttribute('position').count).toBe(130)
    expect(geometry.index?.count).toBe(384)
    const position = geometry.getAttribute('position')
    expect(position.getZ(1) - position.getZ(0)).toBe(5)
    geometry.dispose()
    expect(() => extrudeCurve(curve, -2, 'bad')).toThrow()
    expect(() => extrudeCurve(createMuseum().objects[0], 5, 'bad')).toThrow()
  })
  it('lofts different point counts with aligned sampling and independent copied sections', () => {
    const a = createMuseum().objects[4], b = createMuseum().objects[5]
    b.points = [b.points[0], b.points[2], b.points[4]]
    const loft = loftCurves([a, b], 'test-loft')
    expect(loft.sections[0]).toEqual(a.points)
    expect(loft.sections[0]).not.toBe(a.points)
    const geometry = surfaceGeometry(loft)
    expect(geometry.getAttribute('position').count).toBe(130)
    expect(Array.from(geometry.getAttribute('normal').array).every(Number.isFinite)).toBe(true)
    geometry.dispose()
    expect(() => loftCurves([a], 'bad')).toThrow()
    expect(() => stripGeometry([[0, 0, 0]], [[1, 0, 0], [2, 0, 0]])).toThrow()
  })
})

describe('scene/export integration', () => {
  it('picks displayed control handles ahead of occluding geometry and ignores decorations', () => {
    const project = createMuseum()
    const curve = project.objects[4]
    project.objects = [curve]
    const root = buildModel(project, 'Wireframe', [curve.id], true)
    const [x, y, z] = curve.points[2]
    const foreground = new THREE.Mesh(new THREE.BoxGeometry(2, 2, 2), new THREE.MeshBasicMaterial())
    foreground.position.set(x, y - 10, z)
    const decoration = foreground.clone()
    decoration.position.y -= 5
    decoration.userData.decoration = true
    root.add(foreground, decoration)
    root.updateMatrixWorld(true)
    const ray = new THREE.Raycaster(new THREE.Vector3(x, y - 30, z), new THREE.Vector3(0, 1, 0))
    expect(pickModelHit(root, ray, false)?.object).toBe(foreground)
    expect(pickModelHit(root, ray, true)?.object.userData.pointIndex).toBe(2)
    expect(pickModelHit(root, ray, true)?.object.userData.entityId).toBe(curve.id)
    disposeObject(root)
  })
  it('respects layer visibility when constructing display geometry', () => {
    const project = createMuseum()
    project.layers[0].visible = false
    const model = buildModel(project, 'Wireframe')
    expect(model.children).toHaveLength(5)
    expect(model.children.some(child => child.userData.entityId === 'roof')).toBe(false)
    disposeObject(model)
  })
  it('exports actual transformed vertices and faces; hidden geometry is omitted', () => {
    const project = createMuseum()
    const curve = project.objects[4]
    const extrusion = extrudeCurve(curve, 4, 'export-surface')
    extrusion.position = [10, 0, 0]
    project.objects = [extrusion]
    const text = exportOBJ(project)
    expect(text).toContain('# Units: meters; Z up')
    expect(text).toContain('v -6 -8 5')
    expect(text.split('\n').filter(line => line.startsWith('f '))).toHaveLength(128)
    expect(text).not.toContain('NaN')
    project.layers.find(layer => layer.id === 'design')!.visible = false
    expect(exportOBJ(project)).not.toContain('\nf ')
  })
  it('exports distinct named geometry parts for downstream object selection', () => {
    const project = createMuseum()
    project.objects = [project.objects[1], project.objects[4]]
    const names = exportOBJ(project).split('\n').filter(line => line.startsWith('o ')).map(line => line.slice(2))
    expect(names.length).toBeGreaterThan(1)
    expect(names.every(name => name.length > 0)).toBe(true)
    expect(new Set(names).size).toBe(names.length)
    expect(names.some(name => name.startsWith('Museum___glazed_pavilion_'))).toBe(true)
    expect(names.some(name => name.startsWith('Profile_A___west_'))).toBe(true)
  })
})
