import { describe, expect, it } from 'vitest'
import * as THREE from 'three'
import { architecture, landscape, makePlant } from '../src/geometry'
import type { ObjectKind } from '../src/state'

function inspect(group: THREE.Group) {
  let triangles = 0
  let invalid = 0
  group.traverse(object => {
    if (!(object instanceof THREE.Mesh)) return
    const positions = object.geometry.getAttribute('position')
    for (const value of positions.array) if (!Number.isFinite(value)) invalid++
    triangles += (object.geometry.index?.count ?? positions.count) / 3
  })
  return { triangles, invalid, bounds: new THREE.Box3().setFromObject(group) }
}
describe('deterministic procedural architecture', () => {
  it('constructs a detailed two-storey villa with finite merged geometry', () => {
    const group = architecture()
    const result = inspect(group)
    expect(result.invalid).toBe(0)
    expect(result.triangles).toBeGreaterThan(1000)
    expect(result.bounds.max.y).toBeCloseTo(7.75)
    expect(result.bounds.min.x).toBeCloseTo(-12)
    expect(group.children.length).toBeLessThan(20)
  })
  it.each<ObjectKind>(['palm', 'olive', 'agave', 'lounger'])('builds selectable %s with reproducible vertices', kind => {
    const first = makePlant(kind, 12)
    const second = makePlant(kind, 12)
    expect(inspect(first).invalid).toBe(0)
    expect(inspect(first).triangles).toBeGreaterThan(80)
    expect(inspect(first).bounds).toEqual(inspect(second).bounds)
    expect(first.children.length).toBeLessThan(8)
    const firstMesh = first.children[0] as THREE.Mesh
    const secondMesh = second.children[0] as THREE.Mesh
    expect(firstMesh.geometry.attributes.position.array).toEqual(secondMesh.geometry.attributes.position.array)
  })
  it('builds an island with surrounding rocks and finite landscaped planting', () => {
    const result = inspect(landscape())
    expect(result.invalid).toBe(0)
    expect(result.triangles).toBeGreaterThan(10000)
    expect(result.bounds.min.y).toBeLessThan(-2)
    expect(result.bounds.max.x).toBeGreaterThan(24)
  })
})
