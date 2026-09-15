import { describe, expect, it } from 'vitest'
import * as THREE from 'three'
import { architecture, landscape, makePlant, materials } from '../src/geometry'
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
  it('retains both indexed frond spines and leaf triangles after material batching', () => {
    const palm = makePlant('palm')
    const crown = palm.children.find(child => child instanceof THREE.Mesh && child.material === materials.leaf)
    expect(crown).toBeInstanceOf(THREE.Mesh)
    const bounds = new THREE.Box3().setFromObject(crown!)
    expect(bounds.max.x - bounds.min.x).toBeGreaterThan(6)
    expect(bounds.min.y).toBeGreaterThan(5)
  })
  it('keeps the reflecting pool clear of terrace geometry', () => {
    const villa = architecture()
    villa.updateMatrixWorld(true)
    const ray = new THREE.Raycaster(new THREE.Vector3(2.7, 0.6, 8.1), new THREE.Vector3(0, -1, 0))
    const hit = ray.intersectObject(villa, true)[0]
    expect(hit).toBeDefined()
    expect(hit.point.y).toBeLessThan(0.1)
  })
})
