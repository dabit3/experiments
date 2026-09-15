import * as THREE from 'three'
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js'
import type { ObjectKind } from './state'

export const materials = {
  stone: new THREE.MeshStandardMaterial({ color: '#c8bb9f', roughness: 0.6 }),
  concrete: new THREE.MeshStandardMaterial({ color: '#d6cbb4', roughness: 0.88 }),
  wood: new THREE.MeshStandardMaterial({ color: '#785138', roughness: 0.75 }),
  dark: new THREE.MeshStandardMaterial({ color: '#262e2c', roughness: 0.45 }),
  fabric: new THREE.MeshStandardMaterial({ color: '#e5d9bf', roughness: 0.97 }),
  glass: new THREE.MeshStandardMaterial({ color: '#7daba5', metalness: 0.42, roughness: 0.12, transparent: true, opacity: 0.2, side: THREE.DoubleSide }),
  glow: new THREE.MeshStandardMaterial({ color: '#fff2c1', emissive: '#ffb456', emissiveIntensity: 3.2 }),
  trunk: new THREE.MeshStandardMaterial({ color: '#74614a', roughness: 1 }),
  leaf: new THREE.MeshStandardMaterial({ color: '#3b5833', roughness: 0.9, side: THREE.DoubleSide }),
  olive: new THREE.MeshStandardMaterial({ color: '#6b7a52', roughness: 0.9, side: THREE.DoubleSide }),
  grass: new THREE.MeshStandardMaterial({ color: '#434e2d', roughness: 1 }),
  flower: new THREE.MeshStandardMaterial({ color: '#9f6677', roughness: 1 }),
}
export function rng(seed: number) {
  return () => {
    seed = (seed * 1664525 + 1013904223) >>> 0
    return seed / 4294967296
  }
}
export function box(parent: THREE.Group, dimensions: [number, number, number], position: [number, number, number], material = materials.stone) {
  const mesh = new THREE.Mesh(new THREE.BoxGeometry(...dimensions), material)
  mesh.position.set(...position)
  mesh.castShadow = !material.transparent
  mesh.receiveShadow = true
  parent.add(mesh)
  return mesh
}
export function sphere(parent: THREE.Group, position: THREE.Vector3, scale: THREE.Vector3, material: THREE.MeshStandardMaterial) {
  const mesh = new THREE.Mesh(new THREE.IcosahedronGeometry(1, 1), material)
  mesh.position.copy(position)
  mesh.scale.copy(scale)
  mesh.castShadow = true
  parent.add(mesh)
  return mesh
}
export function rod(parent: THREE.Group, a: THREE.Vector3, b: THREE.Vector3, radius: number, material = materials.trunk) {
  const mesh = new THREE.Mesh(new THREE.CylinderGeometry(radius * 0.7, radius, a.distanceTo(b), 7), material)
  mesh.position.copy(a).add(b).multiplyScalar(0.5)
  mesh.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), b.clone().sub(a).normalize())
  mesh.castShadow = true
  parent.add(mesh)
}
export function batch(group: THREE.Group) {
  group.updateMatrixWorld(true)
  const buckets = new Map<THREE.Material, THREE.BufferGeometry[]>()
  group.traverse(object => {
    if (!(object instanceof THREE.Mesh) || Array.isArray(object.material)) return
    const geometry = object.geometry.clone().applyMatrix4(object.matrixWorld)
    const list = buckets.get(object.material) ?? []
    list.push(geometry)
    buckets.set(object.material, list)
    object.geometry.dispose()
  })
  group.clear()
  for (const [material, geometries] of buckets) {
    const geometry = mergeGeometries(geometries)
    if (geometry) {
      const mesh = new THREE.Mesh(geometry, material)
      mesh.castShadow = !material.transparent
      mesh.receiveShadow = true
      group.add(mesh)
    }
    geometries.forEach(g => g.dispose())
  }
  return group
}
function sofa(parent: THREE.Group, x: number, y: number, z: number, rotation = 0) {
  const group = new THREE.Group()
  box(group, [3.6, 0.38, 1.25], [0, 0.5, 0], materials.fabric)
  box(group, [3.6, 0.65, 0.25], [0, 0.92, -0.52], materials.fabric)
  for (const side of [-1, 1]) {
    box(group, [0.26, 0.4, 1.2], [side * 1.72, 0.83, 0], materials.fabric)
    box(group, [0.12, 0.3, 0.9], [side * 1.4, 0.15, 0], materials.dark)
  }
  for (let i = -1; i <= 1; i++) {
    box(group, [1.03, 0.13, 0.88], [i * 1.08, 0.73, 0.1], materials.fabric)
  }
  group.rotation.y = rotation
  group.position.set(x, y, z)
  parent.add(group)
}
export function architecture() {
  const group = new THREE.Group()
  box(group, [24, 0.48, 21], [0, 0.05, 1], materials.concrete)
  box(group, [20, 0.32, 11], [0, 0.47, -3])
  // Floating floor plates and deeply recessed glazing define the pavilion.
  box(group, [20.6, 0.42, 11.5], [0, 4.1, -3])
  box(group, [14.8, 0.4, 9.4], [-2.5, 7.55, -4])
  box(group, [0.85, 3.5, 10.8], [-9.3, 2.2, -3])
  box(group, [0.7, 3.4, 8.7], [-9.25, 5.8, -4])
  box(group, [19, 3.3, 0.4], [0, 2.15, -7.9], materials.wood)
  box(group, [13.7, 3.2, 0.4], [-2.4, 5.8, -8.1], materials.wood)
  box(group, [0.4, 3.3, 8.8], [4.4, 5.8, -4], materials.wood)
  box(group, [0.55, 3.45, 10.6], [9.4, 2.2, -3])
  box(group, [4.1, 7.15, 3.2], [-6.4, 4.1, -4.8])
  for (let i = 0; i < 55; i++) {
    box(group, [0.045, 7, 0.1], [-8.35 + i * 0.073, 4.1, -3.16], materials.concrete)
  }
  for (let level = 0; level < 2; level++) {
    const y = 0.66 + level * 3.62
    const left = level === 0 ? -8.8 : -8.75
    const right = level === 0 ? 8.9 : 4.0
    const front = level === 0 ? 1.9 : 0.22
    for (let x = left; x <= right; x += 2.14) {
      box(group, [0.055, 3.12, 0.1], [x, y + 1.55, front], materials.dark)
      box(group, [2.08, 3.08, 0.035], [x + 1.06, y + 1.55, front], materials.glass)
    }
    box(group, [right - left + 2, 0.055, 0.1], [(left + right + 2) / 2, y, front], materials.dark)
    box(group, [right - left + 2, 0.035, 0.055], [(left + right + 2) / 2, y + 3.09, front - 0.2], materials.glow)
    for (let x = -4; x < right; x += 3.8) {
      const pendant = new THREE.Mesh(new THREE.ConeGeometry(0.42, 0.34, 16, 1, true), materials.dark)
      pendant.position.set(x, y + 2.6, -2)
      group.add(pendant)
      rod(group, new THREE.Vector3(x, y + 2.65, -2), new THREE.Vector3(x, y + 3.1, -2), 0.012, materials.dark)
      box(group, [0.42, 0.04, 0.42], [x, y + 2.43, -2], materials.glow)
    }
    for (let i = 0; i < 7; i++) {
      box(group, [0.06, 2.9, 0.24], [-0.8 + i * 0.11, y + 1.45, -6.7], materials.wood)
    }
  }
  // Timber ceiling battens and exterior pergola.
  for (let i = 0; i < 34; i++) {
    box(group, [0.10, 0.10, 10.8], [-9.5 + i * 0.57, 3.83, -3], materials.wood)
  }
  for (let i = 0; i < 19; i++) {
    box(group, [0.12, 0.18, 5.5], [4.4 + i * 0.28, 6.65, -3.0], materials.wood)
  }
  for (const x of [4.4, 9.5]) box(group, [0.14, 2.4, 0.14], [x, 5.45, -0.3], materials.dark)
  box(group, [5.5, 0.16, 0.18], [7, 6.65, -0.3], materials.wood)
  box(group, [5.4, 0.95, 0.035], [7, 4.8, 2], materials.glass)
  box(group, [5.4, 0.06, 0.06], [7, 5.28, 2], materials.dark)
  for (const x of [4.35, 7, 9.65]) box(group, [0.035, 1, 0.035], [x, 4.8, 2], materials.dark)
  sofa(group, -2.5, 0.7, -1.2)
  sofa(group, 3.3, 0.7, -3.9, Math.PI / 2)
  sofa(group, -2.8, 4.3, -2.3)
  sofa(group, 6.5, 4.3, -4.4)
  box(group, [2.2, 0.15, 1.2], [-2.3, 1.1, 0.4], materials.wood)
  box(group, [1.6, 0.46, 0.75], [-2.3, 0.81, 0.4], materials.dark)
  box(group, [3.8, 0.1, 1.6], [5.4, 1.6, -2.1], materials.wood)
  for (const x of [4.2, 6.6]) {
    for (const z of [-2.65, -1.55]) {
      box(group, [0.12, 0.93, 0.12], [x, 1.1, z], materials.dark)
      box(group, [0.62, 0.15, 0.6], [x, 1.1, z + (z < -2 ? -0.55 : 0.55)], materials.fabric)
      box(group, [0.62, 0.65, 0.12], [x, 1.43, z + (z < -2 ? -0.82 : 0.82)], materials.wood)
    }
  }
  box(group, [4, 1.3, 0.6], [3, 1.25, -7.2], materials.wood)
  box(group, [4.1, 0.08, 0.65], [3, 1.96, -7.2], materials.concrete)
  for (let i = 0; i < 4; i++) {
    box(group, [3.1 + i * 0.4, 0.12, 0.64], [8.3, 0.4 - i * 0.1, 3.0 + i * 0.6], materials.concrete)
  }
  // Pool coping and submerged mosaic basin.
  const pool = new THREE.MeshStandardMaterial({ color: '#427d79', roughness: 0.28 })
  box(group, [10.8, 0.28, 7.2], [2.7, -0.11, 8.1], pool)
  box(group, [11.6, 0.24, 0.4], [2.7, 0.34, 4.4], materials.concrete)
  box(group, [11.6, 0.24, 0.4], [2.7, 0.34, 11.8], materials.concrete)
  box(group, [0.4, 0.24, 7.8], [-3.1, 0.34, 8.1], materials.concrete)
  box(group, [0.4, 0.24, 7.8], [8.5, 0.34, 8.1], materials.concrete)
  box(group, [11, 0.06, 0.045], [2.7, 0.27, 11.52], materials.glow)
  for (let i = 0; i < 3; i++) box(group, [2.4, 0.12, 0.5], [6.6, 0.14 - i * 0.11, 4.9 + i * 0.5], pool)
  for (let x = -10; x < 11; x += 1.8) {
    for (let z = -7; z < 12; z += 1.8) {
      if (x > -3.3 && x < 8.5 && z > 4.2) continue
      box(group, [1.78, 0.02, 1.78], [x, 0.302, z], materials.concrete)
    }
  }
  for (let i = 0; i < 8; i++) {
    box(group, [1.7, 0.12, 0.8], [-9.8, 0.08, 12.5 + i * 1.2], materials.concrete)
  }
  return batch(group)
}
export function makePlant(kind: ObjectKind, seed = 12) {
  const group = new THREE.Group()
  const random = rng(seed)
  if (kind === 'lounger') {
    box(group, [1.1, 0.17, 2.25], [0, 0.48, 0], materials.wood)
    box(group, [0.97, 0.2, 1.55], [0, 0.63, 0.35], materials.fabric)
    const back = box(group, [0.97, 0.18, 0.85], [0, 0.89, -0.71], materials.fabric)
    back.rotation.x = -0.53
    for (const x of [-0.4, 0.4]) for (const z of [-0.8, 0.8]) box(group, [0.1, 0.45, 0.1], [x, 0.24, z], materials.wood)
  } else if (kind === 'palm') {
    const height = 7.7
    for (let i = 0; i < 18; i++) {
      const y = i * height / 18
      rod(group, new THREE.Vector3(Math.sin(i / 22) * 0.5, y, 0), new THREE.Vector3(Math.sin((i + 1) / 22) * 0.5, y + height / 18, 0), 0.22 - i * 0.004)
    }
    for (let f = 0; f < 14; f++) {
      const angle = f / 14 * Math.PI * 2
      const length = 3.3 + random() * 1.1
      const points = []
      for (let i = 0; i <= 12; i++) {
        const t = i / 12
        points.push(new THREE.Vector3(0.35 + Math.cos(angle) * length * t, height + Math.sin(t * Math.PI) * 1.45 - t * 1.4, Math.sin(angle) * length * t))
      }
      for (let i = 0; i < 12; i++) {
        rod(group, points[i], points[i + 1], 0.022, materials.leaf)
        if (i < 2) continue
        for (const side of [-1, 1]) {
          const p = points[i]
          const width = Math.sin(i / 13 * Math.PI) * 0.8
          const tip = p.clone().add(new THREE.Vector3(Math.cos(angle + side * 1.05) * width, -0.4, Math.sin(angle + side * 1.05) * width))
          const a = points[i - 1]
          const geometry = new THREE.BufferGeometry().setFromPoints([
            p, tip, a.clone().lerp(p, 0.68),
          ])
          geometry.computeVertexNormals()
          const leaf = new THREE.Mesh(geometry, materials.leaf)
          leaf.castShadow = true
          group.add(leaf)
        }
      }
    }
  } else if (kind === 'olive') {
    rod(group, new THREE.Vector3(), new THREE.Vector3(0.2, 2.8, 0), 0.21)
    for (let i = 0; i < 9; i++) {
      const a = i * 2.4
      const tip = new THREE.Vector3(Math.cos(a) * 1.8, 3.3 + random() * 1.6, Math.sin(a) * 1.8)
      rod(group, new THREE.Vector3(0.2, 1.9, 0), tip, 0.085)
      for (let j = 0; j < 36; j++) {
        const p = tip.clone().add(new THREE.Vector3((random() - 0.5) * 2.2, (random() - 0.5) * 1.6, (random() - 0.5) * 2.2))
        sphere(group, p, new THREE.Vector3(0.16 + random() * 0.21, 0.13, 0.14 + random() * 0.2), materials.olive)
      }
    }
  } else {
    for (let i = 0; i < 23; i++) {
      const angle = i * 2.4
      const len = 0.6 + random() * 0.75
      const leaf = new THREE.Mesh(new THREE.ConeGeometry(0.12, len, 4), materials.olive)
      leaf.position.set(Math.cos(angle) * 0.35, 0.4, Math.sin(angle) * 0.35)
      leaf.rotation.set(Math.cos(angle) * 0.9, 0, Math.sin(angle) * 0.9)
      group.add(leaf)
    }
  }
  return batch(group)
}
export function landscape() {
  const group = new THREE.Group()
  const random = rng(42)
  const terrain = new THREE.Mesh(new THREE.CylinderGeometry(24, 28, 3, 64), materials.grass)
  terrain.position.set(0, -1.65, 0)
  terrain.scale.z = 0.84
  terrain.receiveShadow = true
  group.add(terrain)
  const rockMaterial = new THREE.MeshStandardMaterial({ color: '#81796a', roughness: 1 })
  for (let i = 0; i < 60; i++) {
    const angle = i / 60 * Math.PI * 2
    const rock = sphere(group, new THREE.Vector3(Math.cos(angle) * (24 + random()), -1.2, Math.sin(angle) * (20 + random())),
      new THREE.Vector3(1.4 + random(), 1.2 + random(), 1.2 + random()), rockMaterial)
    rock.rotation.set(random(), random(), random())
  }
  for (let i = 0; i < 210; i++) {
    const x = (random() - 0.5) * 42
    const z = (random() - 0.5) * 33
    if (Math.abs(x) < 12.5 && z < 12 && z > -10) continue
    if (x * x / 420 + z * z / 250 > 1) continue
    const size = 0.28 + random() * 0.7
    sphere(group, new THREE.Vector3(x, size * 0.7, z), new THREE.Vector3(size, size * 0.8, size), materials.leaf)
    for (let j = 0; j < 5; j++) {
      sphere(group, new THREE.Vector3(x + (random() - 0.5) * size, size + random() * 0.2, z + (random() - 0.5) * size),
        new THREE.Vector3(0.07, 0.06, 0.07), materials.flower)
    }
  }
  for (let i = 0; i < 18; i++) {
    const x = i % 2 ? -13 : 12.3
    const z = -8 + Math.floor(i / 2) * 2.5
    box(group, [0.16, 0.52, 0.16], [x, 0.26, z], materials.dark)
    box(group, [0.18, 0.09, 0.18], [x, 0.48, z], materials.glow)
  }
  return batch(group)
}
