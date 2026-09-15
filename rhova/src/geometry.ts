import * as THREE from 'three'
import type { Entity, Point } from './model'

export function sampleCurve(points: Point[], count = 64): Point[] {
  if (points.length < 2) return points
  return new THREE.CatmullRomCurve3(points.map(point => new THREE.Vector3(...point)), false, 'centripetal').getPoints(count).map(point => [point.x, point.y, point.z])
}
export function canopyProfile(t: number, y: number, rise: number): Point {
  const x = (t - 0.5) * 39
  const envelope = Math.pow(Math.sin(Math.PI * t), 0.8)
  const wave = Math.sin(y / 9 + t * 3.2) * 1.3
  return [x + Math.sin(y / 8) * 1.4, y + Math.cos(t * Math.PI) * 2.2, 3.8 + envelope * (rise + wave) + (y + 12) * 0.035]
}
export function stripGeometry(a: Point[], b: Point[]): THREE.BufferGeometry {
  if (a.length !== b.length || a.length < 2) throw new Error('Surface sections must have equal sample counts.')
  const vertices: number[] = []
  const indices: number[] = []
  for (let i = 0; i < a.length; i++) {
    vertices.push(...a[i], ...b[i])
    if (i < a.length - 1) {
      const n = i * 2
      indices.push(n, n + 1, n + 2, n + 1, n + 3, n + 2)
    }
  }
  const geometry = new THREE.BufferGeometry()
  geometry.setAttribute('position', new THREE.Float32BufferAttribute(vertices, 3))
  geometry.setIndex(indices)
  geometry.computeVertexNormals()
  return geometry
}
export function surfaceGeometry(object: Entity): THREE.BufferGeometry {
  if (object.kind === 'extrusion') {
    const a = sampleCurve(object.points)
    return stripGeometry(a, a.map(([x, y, z]) => [x, y, z + object.height]))
  }
  if (object.kind === 'loft') return stripGeometry(sampleCurve(object.sections[0]), sampleCurve(object.sections[1]))
  throw new Error('Unsupported surface type')
}
