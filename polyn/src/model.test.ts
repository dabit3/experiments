import { describe, expect, it } from 'vitest'
import { Box3, Group, Mesh, Vector3 } from 'three'
import { addObject, createProject, duplicateObject, historyReducer, parseProject, removeObject, sampleObject, serializeProject, setKeyframe, updateObject, type History, type Vec3 } from './model'
import { applyTransform, buildObject, disposeGroup, readTransform, selectionEdges } from './geometry'

describe('project editing and history', () => {
  it('starts with a complete architectural fixture and independent mutable values', () => {
    const a = createProject()
    const b = createProject()
    expect(a.objects).toHaveLength(15)
    expect(new Set(a.objects.map(o => o.id)).size).toBe(15)
    expect(a.objects.map(o => o.kind)).toContain('stair')
    a.objects[0].position[0] = 100
    expect(b.objects[0].position[0]).toBe(0)
  })
  it('edits the selected object without mutating earlier snapshots', () => {
    const initial = createProject()
    const edited = updateObject(initial, 'sofa', { position: [2, -1, 0], color: '#6e7964' })
    expect(initial.objects.find(o => o.id === 'sofa')?.position).toEqual([0.55, -0.4, 0])
    expect(edited.objects.find(o => o.id === 'sofa')?.color).toBe('#6e7964')
    expect(edited.objects.find(o => o.id === 'chair')).toBe(initial.objects.find(o => o.id === 'chair'))
  })
  it('duplicates composite geometry with isolated transforms and keyframes', () => {
    const initial = setKeyframe(createProject(), 'sofa', 1)
    const next = duplicateObject(initial, 'sofa', 'copy')
    const copy = next.objects.at(-1)!
    expect(copy.name).toBe('Sofa · Sienna.001')
    expect(copy.kind).toBe('sofa')
    expect(copy.position).toEqual([1.35, -1, 0])
    copy.keyframes[0].position[0] = 20
    expect(initial.objects.find(o => o.id === 'sofa')?.keyframes[0].position[0]).toBe(0.55)
  })
  it('adds and deletes a mesh with valid portable state', () => {
    const p = addObject(createProject(), 'sphere', 'new-mesh')
    expect(p.objects.at(-1)?.kind).toBe('sphere')
    expect(parseProject(serializeProject(p))).toEqual(p)
    expect(removeObject(p, 'new-mesh').objects).toHaveLength(15)
  })
  it('undoes and redoes a multi-step workflow and branches after undo', () => {
    const initial = createProject()
    let state: History = { past: [], present: initial, future: [] }
    state = historyReducer(state, { type: 'edit', project: addObject(state.present, 'cube', 'cube-a') })
    state = historyReducer(state, { type: 'edit', project: updateObject(state.present, 'cube-a', { color: '#123456' }) })
    state = historyReducer(state, { type: 'undo' })
    expect(state.present.objects.at(-1)?.color).toBe('#b99c79')
    state = historyReducer(state, { type: 'redo' })
    expect(state.present.objects.at(-1)?.color).toBe('#123456')
    state = historyReducer(state, { type: 'undo' })
    state = historyReducer(state, { type: 'edit', project: removeObject(state.present, 'cube-a') })
    expect(state.future).toHaveLength(0)
    expect(state.present.objects).toHaveLength(15)
  })
  it('bounds history and ignores no-op transactions', () => {
    let state: History = { past: [], present: createProject(), future: [] }
    expect(historyReducer(state, { type: 'undo' })).toBe(state)
    expect(historyReducer(state, { type: 'redo' })).toBe(state)
    expect(historyReducer(state, { type: 'edit', project: state.present })).toBe(state)
    for (let i = 0; i < 80; i++) state = historyReducer(state, { type: 'edit', project: { ...state.present, name: `Edit ${i}` } })
    expect(state.past).toHaveLength(60)
  })
})

describe('persistence and export validation', () => {
  it('round trips edited materials, visibility, bookmarks and animation', () => {
    const p = setKeyframe(updateObject(createProject(), 'sofa', { roughness: 0.2, metallic: 0.8, visible: false }), 'sofa', 100)
    expect(parseProject(serializeProject(p))).toEqual(p)
    expect(JSON.parse(serializeProject(p)).version).toBe(1)
  })
  it.each([
    ['unsupported version', (p: ReturnType<typeof createProject>) => ({ ...p, version: 2 })],
    ['duplicate IDs', (p: ReturnType<typeof createProject>) => ({ ...p, objects: [...p.objects, p.objects[0]] })],
    ['unknown geometry', (p: ReturnType<typeof createProject>) => ({ ...p, objects: [{ ...p.objects[0], kind: 'script' }] })],
    ['negative scale', (p: ReturnType<typeof createProject>) => ({ ...p, objects: [{ ...p.objects[0], scale: [-1, 1, 1] }] })],
    ['non-finite coordinate', (p: ReturnType<typeof createProject>) => ({ ...p, objects: [{ ...p.objects[0], position: [Infinity, 0, 0] }] })],
    ['invalid material', (p: ReturnType<typeof createProject>) => ({ ...p, objects: [{ ...p.objects[0], color: 'url(evil)' }] })],
    ['excessive roughness', (p: ReturnType<typeof createProject>) => ({ ...p, objects: [{ ...p.objects[0], roughness: 5 }] })],
    ['invalid bookmark', (p: ReturnType<typeof createProject>) => ({ ...p, cameras: [{ name: 'Test', position: [0], target: [1, 2, 3] }] })],
    ['invalid frame', (p: ReturnType<typeof createProject>) => ({ ...p, objects: [{ ...p.objects[0], keyframes: [{ frame: 251, position: [0, 0, 0], rotation: [0, 0, 0], scale: [1, 1, 1] }] }] })],
  ])('rejects %s', (_name, mutate) => {
    expect(() => parseProject(JSON.stringify(mutate(createProject())))).toThrow()
  })
  it('rejects oversized or malformed files without partial data', () => {
    expect(() => parseProject('not json')).toThrow()
    expect(() => parseProject(' '.repeat(2_000_001))).toThrow('too large')
    expect(() => parseProject('null')).toThrow()
  })
})

describe('animation', () => {
  it('interpolates all transform axes and clamps outside the keyed range', () => {
    let p = setKeyframe(createProject(), 'chair', 10)
    const start = p.objects.find(o => o.id === 'chair')!
    p = updateObject(p, 'chair', { position: [5.55, 0.55, 2], rotation: [20, 40, 90], scale: [2, 3, 4] })
    p = setKeyframe(p, 'chair', 110)
    const chair = p.objects.find(o => o.id === 'chair')!
    expect(sampleObject(chair, 60).position).toEqual([4.55, -0.44999999999999996, 1])
    expect(sampleObject(chair, 60).rotation).toEqual([10, 20, 30])
    expect(sampleObject(chair, 60).scale).toEqual([1.5, 2, 2.5])
    expect(sampleObject(chair, 1).position).toEqual(start.position)
    expect(sampleObject(chair, 250).position).toEqual(chair.position)
  })
  it('replaces keyframes at the same frame and persists sorted keys', () => {
    let p = setKeyframe(createProject(), 'chair', 120)
    p = setKeyframe(p, 'chair', 1)
    p = setKeyframe(p, 'chair', 120)
    expect(p.objects.find(o => o.id === 'chair')!.keyframes.map(k => k.frame)).toEqual([1, 120])
  })
})

describe('real scene geometry', () => {
  it('produces visible selection segments for rounded furniture and smooth primitives', () => {
    const p = addObject(addObject(createProject(), 'cube', 'cube'), 'sphere', 'sphere')
    for (const object of p.objects.filter(o => ['sofa', 'chair', 'cube', 'sphere'].includes(o.kind))) {
      const group = buildObject(object)
      group.traverse(child => {
        if (child instanceof Mesh) {
          const edges = selectionEdges(child.geometry)
          expect(edges.getAttribute('position').count).toBeGreaterThan(0)
          edges.dispose()
        }
      })
      disposeGroup(group)
    }
  })
  it('builds every architectural component with finite bounds', () => {
    for (const object of createProject().objects) {
      const group = buildObject(object)
      applyTransform(group, object)
      const bounds = new Box3().setFromObject(group)
      const size = bounds.getSize(new Vector3())
      expect(size.toArray().every(n => Number.isFinite(n) && n > 0)).toBe(true)
      expect(group.userData.objectId).toBe(object.id)
      disposeGroup(group)
    }
  })
  it('generates a full-height spiral stair and a furnished multi-mesh loft', () => {
    const p = createProject()
    const stair = buildObject(p.objects.find(o => o.id === 'stair')!)
    const bounds = new Box3().setFromObject(stair)
    expect(bounds.max.y).toBeGreaterThan(4)
    expect(stair.children.length).toBeGreaterThan(35)
    let count = 0
    for (const o of p.objects) {
      const g = buildObject(o)
      g.traverse(m => { if (m instanceof Mesh) count++ })
      disposeGroup(g)
    }
    expect(count).toBeGreaterThan(600)
    disposeGroup(stair)
  })
  it('round trips Blender Z-up coordinates through Three.js Y-up transforms', () => {
    const group = new Group()
    const value = { position: [2, -4, 3] as Vec3, rotation: [15, 30, 45] as Vec3, scale: [1.5, 2, 0.7] as Vec3 }
    applyTransform(group, value)
    expect(group.position.toArray()).toEqual([2, 3, 4])
    expect(readTransform(group)).toEqual(value)
  })
})
