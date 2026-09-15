import test from 'node:test'
import assert from 'node:assert/strict'
import * as THREE from 'three'
import { buildEntity, buildModel, disposeObject } from './geometry.ts'
import { exportObj } from './export.ts'
import { fitCamera } from './camera.ts'
import { commit, createProject, createVolume, groupEntities, parseMeasurements, parseProject, redo, selectionFor, serializeProject, undo, ungroupEntities, updateEntity, volume } from './model.ts'
import type { History, Project } from './model.ts'

test('built-in fixture round-trips all architectural, material, scene and visibility data', () => {
  const project = createProject()
  assert.equal(project.entities.length, 9)
  assert.equal(project.entities.filter(e => e.kind === 'pavilion').length, 3)
  assert.deepEqual(parseProject(serializeProject(project)), project)
  assert.notEqual(createProject().tags, project.tags)
})
test('reversed rectangle corners generate correct positive dimensions and center', () => {
  const original = createProject()
  const project = createVolume(original, [4, .7, 6], [1, .7, 2], 2.5, 'rect')
  const entity = project.entities.at(-1)!
  assert.deepEqual(entity.position, [2.5, .7, 4])
  assert.deepEqual(entity.size, [3, 2.5, 4])
  assert.equal(volume(entity), 30)
  assert.equal(original.entities.length, 9)
})
test('rectangle limits reject degenerate, huge, non-finite and over-capacity geometry', () => {
  const p = createProject()
  assert.throws(() => createVolume(p, [0, 0, 0], [0, 0, 4]), /dimension/)
  assert.throws(() => createVolume(p, [0, 0, 0], [51, 0, 4]), /dimension/)
  assert.throws(() => createVolume(p, [0, 0, 0], [3, 0, 4], NaN), /dimension/)
  assert.throws(() => createVolume({ ...p, entities: Array.from({ length: 300 }, () => p.entities[0]) }, [0, 0, 0], [1, 0, 1]), /300/)
})
test('push-pull, paint and rename do not mutate the original or other entities', () => {
  const p = createProject()
  const changed = updateEntity(p, ['living'], { size: [14, 5, 5.5], material: 'sage', name: 'Studio' })
  assert.equal(changed.entities[0].size[1], 5)
  assert.equal(changed.entities[0].material, 'sage')
  assert.equal(p.entities[0].size[1], 3.6)
  assert.deepEqual(changed.entities[1], p.entities[1])
  assert.throws(() => updateEntity(p, ['living'], { size: [1, -2, 1] }), /Dimensions/)
  assert.throws(() => updateEntity(p, ['living'], { name: ' ' }), /name/)
})
test('group membership drives multi-selection and survives persistence; ungroup is reversible', () => {
  const grouped = groupEntities(createProject(), ['living', 'tea'], 'assembly')
  assert.deepEqual(selectionFor(grouped, 'living'), ['living', 'tea'])
  assert.deepEqual(selectionFor(parseProject(serializeProject(grouped)), 'tea'), ['living', 'tea'])
  assert.deepEqual(selectionFor(ungroupEntities(grouped, ['living', 'tea']), 'tea'), ['tea'])
  assert.throws(() => groupEntities(grouped, ['living']), /two/)
  assert.deepEqual(selectionFor(grouped, 'missing'), [])
})
test('history restores geometry, materials, deletion and scenes; a new edit clears redo', () => {
  const initial = createProject()
  let h: History = { past: [], present: initial, future: [] }
  h = commit(h, createVolume(initial, [0, 0, 0], [2, 0, 3], 2, 'study'))
  h = commit(h, updateEntity(h.present, ['study'], { material: 'terracotta' }))
  h = commit(h, { ...h.present, entities: h.present.entities.filter(e => e.id !== 'tea') })
  assert.equal(undo(h).present.entities.length, 10)
  assert.equal(undo(undo(h)).present.entities.at(-1)!.material, 'plaster')
  assert.deepEqual(undo(undo(undo(h))).present, initial)
  assert.deepEqual(redo(undo(h)).present, h.present)
  assert.equal(commit(undo(h), { ...undo(h).present, time: 12 }).future.length, 0)
  assert.equal(commit(h, h.present), h)
})
test('history is bounded to fifty edits', () => {
  let h: History = { past: [], present: createProject(), future: [] }
  for (let i = 0; i < 70; i++) h = commit(h, { ...h.present, name: `Project ${i}` })
  assert.equal(h.past.length, 50)
})
test('import rejects malformed, unknown versions, invalid tags, duplicate IDs and invalid cameras', () => {
  assert.throws(() => parseProject('not json'), /valid JSON/)
  assert.throws(() => parseProject(' '.repeat(2_000_001)), /2 MB/)
  const invalid: unknown[] = [
    { ...createProject(), version: 2 },
    { ...createProject(), tags: { Architecture: true } },
    { ...createProject(), entities: [createProject().entities[0], createProject().entities[0]] },
    { ...createProject(), scenes: [] },
    { ...createProject(), time: 23 },
    { ...createProject(), entities: [{ ...createProject().entities[0], material: 'remote-url' }] },
    { ...createProject(), entities: [{ ...createProject().entities[0], size: [2, 0, 2] }] },
    { ...createProject(), scenes: [{ ...createProject().scenes[0], position: [0, 0, 0], target: [0, 0, 0] }] },
  ]
  invalid.forEach(value => assert.throws(() => parseProject(JSON.stringify(value)), /invalid Skelo project/))
})
test('measurements parse meters and dimensions and reject invalid input', () => {
  assert.deepEqual(parseMeasurements('3, 2, 1.5', 'rectangle'), [3, 2, 1.5])
  assert.deepEqual(parseMeasurements('3m × 2m × 1.5m', 'rectangle'), [3, 2, 1.5])
  assert.deepEqual(parseMeasurements('4.25m', 'height'), [4.25])
  for (const text of ['', 'hello', '0', '51', '3,2']) assert.throws(() => parseMeasurements(text, 'height'))
})
test('parametric volume bounds match dimensions after push-pull', () => {
  const entity = createVolume(createProject(), [1, .7, 2], [4, .7, 6], 2.5).entities.at(-1)!
  const mesh = buildEntity(entity)
  const bounds = new THREE.Box3().setFromObject(mesh)
  const size = bounds.getSize(new THREE.Vector3())
  assert.ok(Math.abs(size.x - 3) < 1e-5)
  assert.ok(Math.abs(size.y - 2.5) < 1e-5)
  assert.ok(Math.abs(size.z - 4) < 1e-5)
  assert.ok(Math.abs(bounds.min.y - .7) < 1e-5)
  disposeObject(mesh)
})
test('full model has real finite geometry, outlined pavilions and obeys tag visibility', () => {
  const project = createProject()
  const model = buildModel(project)
  let vertices = 0
  let edges = 0
  model.traverse(child => {
    if (child instanceof THREE.Mesh) {
      const position = child.geometry.getAttribute('position')
      vertices += position.count
      for (const value of position.array) assert.ok(Number.isFinite(value))
    }
    if (child.userData.edge) edges++
  })
  assert.ok(vertices > 20_000)
  assert.ok(edges > 150)
  assert.equal(model.children.length, 10)
  const hidden = buildModel({ ...project, tags: { ...project.tags, Landscape: false } })
  assert.equal(hidden.children.length, 6)
  disposeObject(hidden)
  disposeObject(model)
})
test('OBJ export contains actual transformed triangles and respects hidden tags', () => {
  const project: Project = { ...createProject(), entities: [], tags: { Architecture: false, Landscape: false, Furniture: false, Study: true } }
  const p = createVolume(project, [1, .7, 2], [4, .7, 6], 2.5, 'study')
  const text = exportObj(p)
  assert.match(text, /# Units: meters/)
  assert.match(text, /^v 4 3\.2[0-9]* 6$/m)
  assert.match(text, /^f \d+\/\d+\/\d+ /m)
  assert.doesNotMatch(text, /NaN|Infinity/)
})

test('camera fit frames default and maximum volumes at every desktop aspect ratio', () => {
  for (const project of [createProject(), createVolume(createProject(), [8, .7, 6.5], [58, .7, 56.5], 50)]) {
    const model = buildModel(project)
    const bounds = new THREE.Box3().setFromObject(model)
    for (const aspect of [1090 / 730, 1540 / 910, 955 / 630]) {
      for (const direction of [new THREE.Vector3(26, 17, 30), new THREE.Vector3(0, 42, .01), new THREE.Vector3(37, 6, 0)]) {
        const view = fitCamera(bounds, direction, 38, aspect)
        const camera = new THREE.PerspectiveCamera(38, aspect, .1, Math.max(300, view.distance * 6))
        camera.position.copy(view.position)
        camera.lookAt(view.target)
        camera.updateMatrixWorld()
        assert.ok(!bounds.containsPoint(camera.position))
        assert.ok(camera.position.clone().sub(view.target).normalize().distanceTo(direction.clone().normalize()) < 1e-9)
        for (const x of [bounds.min.x, bounds.max.x]) for (const y of [bounds.min.y, bounds.max.y]) for (const z of [bounds.min.z, bounds.max.z]) {
          const projected = new THREE.Vector3(x, y, z).project(camera)
          assert.ok(Math.abs(projected.x) < .9 && Math.abs(projected.y) < .9)
          assert.ok(projected.z > -1 && projected.z < 1)
        }
      }
    }
    disposeObject(model)
  }
})
