import { test } from 'node:test'
import assert from 'node:assert/strict'
import { commit, createProject, exportPlan, exportSchedule, localPoint, parseProject, placeDoor, redo, removeElement, serializeProject, undo, updateElement, wallFromPoints, wallSegments, worldPoint } from './model.ts'
import type { History, Project } from './model.ts'

const fixture = () => {
  const wall = wallFromPoints({ x: -5, z: 0 }, { x: 5, z: 0 }, 'test-wall')
  const project: Project = { version: 1, name: 'Test Pavilion', elements: [wall], hidden: [] }
  return { wall, project }
}
test('built-in pavilion is a valid round-trip with multiple levels and hosted doors', () => {
  const project = createProject()
  assert.deepEqual(parseProject(serializeProject(project)), project)
  assert.ok(project.elements.length > 30)
  assert.ok(project.elements.some(e => e.y === 4.42))
  assert.equal(project.elements.filter(e => e.category === 'Door').length, 2)
})
test('plan wall snaps both points and computes diagonal coordinates and rotation', () => {
  const wall = wallFromPoints({ x: .13, z: .2 }, { x: 3.12, z: 4.19 }, 'new')
  assert.equal(wall.x, 1.5)
  assert.equal(wall.z, 2)
  assert.equal(wall.w, 5)
  assert.equal(wall.rotation, Math.atan2(4, 3))
  const end = worldPoint(wall, { x: 2.5, z: 0 })
  assert.ok(Math.abs(end.x - 3) < 1e-10)
  assert.ok(Math.abs(end.z - 4) < 1e-10)
})
test('zero and sub-grid walls are rejected', () => {
  assert.throws(() => wallFromPoints({ x: 0, z: 0 }, { x: .1, z: 0 }, 'short'), /at least/)
})
test('door placement projects onto rotated wall and preserves host', () => {
  const wall = wallFromPoints({ x: 0, z: -5 }, { x: 0, z: 5 }, 'rotated')
  const p: Project = { version: 1, name: 'test', elements: [wall], hidden: [] }
  const door = placeDoor(p, { x: .6, z: 1.2 }, 'door')
  assert.equal(door.hostId, wall.id)
  assert.ok(Math.abs(door.x) < 1e-10)
  assert.equal(door.z, 1)
  assert.equal(door.rotation, Math.PI / 2)
})
test('door snaps away from wall edge and openings cannot overlap', () => {
  const { project, wall } = fixture()
  const door = placeDoor(project, { x: 4.9, z: .2 }, 'd1')
  assert.ok(localPoint(wall, door).x + door.w / 2 <= wall.w / 2)
  const next = { ...project, elements: [...project.elements, door] }
  assert.throws(() => placeDoor(next, { x: 4, z: .2 }, 'd2'), /overlaps/)
})
test('door rejects no host, too short wall and hidden host', () => {
  const { project, wall } = fixture()
  assert.throws(() => placeDoor(project, { x: 0, z: 2 }, 'd'), /within 1 m/)
  assert.throws(() => placeDoor({ ...project, hidden: ['Wall'] }, { x: 0, z: 0 }, 'd'), /within 1 m/)
  assert.throws(() => placeDoor({ ...project, elements: [{ ...wall, w: 1 }] }, { x: 0, z: 0 }, 'd'), /within 1 m/)
})
test('3D wall segments subtract actual door opening area', () => {
  const { project, wall } = fixture()
  const d1 = placeDoor(project, { x: -2, z: 0 }, 'd1')
  const next = { ...project, elements: [...project.elements, d1] }
  const d2 = placeDoor(next, { x: 2, z: 0 }, 'd2')
  const segments = wallSegments(wall, { ...project, elements: [wall, d1, d2] })
  const solidArea = segments.reduce((area, s) => area + s.width * s.height, 0)
  assert.ok(Math.abs(solidArea - (wall.w * wall.h - d1.w * d1.h - d2.w * d2.h)) < 1e-10)
  assert.equal(segments.length, 5)
  assert.ok(segments.every(s => s.width > 0 && s.height > 0))
})
test('moving and rotating wall moves its hosted door in local coordinates', () => {
  const { project, wall } = fixture()
  const door = placeDoor(project, { x: 2, z: 0 }, 'door')
  const nextWall = { ...wall, x: 10, z: 5, rotation: Math.PI / 2, y: 4.42 }
  const updated = updateElement({ ...project, elements: [wall, door] }, nextWall)
  const nextDoor = updated.elements[1]
  assert.equal(nextDoor.x, 10)
  assert.equal(nextDoor.z, 7)
  assert.equal(nextDoor.y, 4.42)
  assert.deepEqual(parseProject(serializeProject(updated)), updated)
})
test('wall cannot shrink through a hosted door', () => {
  const { project, wall } = fixture()
  const door = placeDoor(project, { x: 3, z: 0 }, 'door')
  assert.throws(() => updateElement({ ...project, elements: [wall, door] }, { ...wall, w: 2 }), /contain all/)
})
test('invalid property edits leave source project immutable', () => {
  const { project, wall } = fixture()
  assert.throws(() => updateElement(project, { ...wall, h: NaN }), /numeric/)
  assert.throws(() => updateElement(project, { ...wall, w: -1 }), /bounds/)
  assert.throws(() => updateElement(project, { ...wall, name: '' }), /Name/)
  assert.equal(project.elements[0].w, 10)
})
test('deleting wall cascades to doors, deleting door preserves wall', () => {
  const { project, wall } = fixture()
  const door = placeDoor(project, { x: 0, z: 0 }, 'door')
  const next = { ...project, elements: [wall, door] }
  assert.equal(removeElement(next, wall.id).elements.length, 0)
  assert.deepEqual(removeElement(next, door.id).elements, [wall])
})
test('undo/redo restores geometry, properties and visibility; new edit invalidates redo', () => {
  const original = createProject()
  let h: History = { past: [], present: original, future: [] }
  const changed = { ...original, name: 'Edited pavilion', hidden: ['Roof'] as Project['hidden'] }
  h = commit(h, changed)
  h = undo(h)
  assert.deepEqual(h.present, original)
  h = redo(h)
  assert.deepEqual(h.present, changed)
  h = commit(undo(h), { ...original, name: 'Another edit' })
  assert.equal(h.future.length, 0)
  assert.equal(redo(h), h)
})
test('history ignores no-op commits and retains 50 undo steps', () => {
  const original = createProject()
  let h: History = { past: [], present: original, future: [] }
  assert.equal(commit(h, structuredClone(original)), h)
  assert.equal(undo(h), h)
  for (let i = 0; i < 65; i++) h = commit(h, { ...original, name: `Edit ${i}` })
  assert.equal(h.past.length, 50)
  assert.equal(h.past[0].name, 'Edit 14')
})
test('saved project parser rejects malformed data, duplicate IDs and missing hosts', () => {
  const { project, wall } = fixture()
  for (const value of [null, {}, { ...project, version: 2 }, { ...project, hidden: ['Unknown'] }, { ...project, elements: [{ ...wall, x: '5' }] }, { ...project, elements: [{ ...wall, h: null }] }, { ...project, elements: [wall, wall] }]) assert.throws(() => parseProject(JSON.stringify(value)))
  const door = placeDoor(project, { x: 0, z: 0 }, 'd')
  assert.throws(() => parseProject(serializeProject({ ...project, elements: [door] })), /valid wall/)
  assert.throws(() => parseProject(' '.repeat(2_000_001)), /exceeds/)
})
test('saved parser rejects misaligned and overlapping hosted doors', () => {
  const { project, wall } = fixture()
  const door = placeDoor(project, { x: 0, z: 0 }, 'd1')
  assert.throws(() => parseProject(serializeProject({ ...project, elements: [wall, { ...door, z: 5 }] })), /fit within/)
  assert.throws(() => parseProject(serializeProject({ ...project, elements: [wall, door, { ...door, id: 'd2' }] })), /overlap/)
})
test('CSV exports edited quantities, quotes names and neutralizes spreadsheet formulas', () => {
  const { project, wall } = fixture()
  const csv = exportSchedule({ ...project, elements: [{ ...wall, name: '=HYPERLINK("bad")', w: 4, h: 3, d: .25 }] })
  assert.ok(csv.includes(`"'=HYPERLINK(""bad"")"`))
  assert.ok(csv.endsWith('"4","0.25","3","3"'))
  assert.equal(csv.split('\r\n').length, 2)
})
test('SVG exports visible Level 1 geometry with real coordinates and safe text', () => {
  const { project, wall } = fixture()
  const svg = exportPlan({ ...project, name: 'Gallery <&>', elements: [wall, { ...wall, id: 'upper', y: 4.42 }] })
  assert.ok(svg.includes('data-id="test-wall"'))
  assert.ok(svg.includes('width="10"'))
  assert.ok(!svg.includes('data-id="upper"'))
  assert.ok(svg.includes('Gallery &lt;&amp;&gt;'))
  const hidden = exportPlan({ ...project, hidden: ['Wall'] })
  assert.ok(!hidden.includes('data-id="test-wall"'))
})
