import * as THREE from 'three'
import { RoundedBoxGeometry } from 'three/addons/geometries/RoundedBoxGeometry.js'
import type { SceneObject, Vec3 } from './model'

const charcoal = '#282a27'
const oak = '#9c7650'
const cream = '#d9cfb9'

export function selectionEdges(geometry: THREE.BufferGeometry): THREE.EdgesGeometry {
  const edges = new THREE.EdgesGeometry(geometry, 15)
  if (edges.getAttribute('position').count > 0) return edges
  edges.dispose()
  return new THREE.EdgesGeometry(geometry, 1)
}

export function buildObject(data: SceneObject): THREE.Group {
  const group = new THREE.Group()
  const materials = new Map<string, THREE.MeshStandardMaterial>()
  const material = (color: string, metal = 0) => {
    const key = `${color}:${metal}`
    if (!materials.has(key)) materials.set(key, new THREE.MeshStandardMaterial({
      color, roughness: color === data.color ? data.roughness : 0.78,
      metalness: color === data.color ? data.metallic : metal,
    }))
    return materials.get(key)!
  }
  const mesh = (geometry: THREE.BufferGeometry, color: string, position: Vec3, rotation: Vec3 = [0, 0, 0], metal = 0) => {
    const m = new THREE.Mesh(geometry, material(color, metal))
    m.position.set(...position)
    m.rotation.set(...rotation)
    m.castShadow = true
    m.receiveShadow = true
    group.add(m)
    return m
  }
  const box = (size: Vec3, position: Vec3, color = data.color, radius = 0, rotation: Vec3 = [0, 0, 0]) => mesh(radius ? new RoundedBoxGeometry(...size, 2, radius) : new THREE.BoxGeometry(...size), color, position, rotation)
  const cylinder = (top: number, bottom: number, height: number, position: Vec3, color = data.color, rotation: Vec3 = [0, 0, 0]) => mesh(new THREE.CylinderGeometry(top, bottom, height, 32), color, position, rotation)
  const sphere = (radius: number, position: Vec3, color = data.color, scale: Vec3 = [1, 1, 1]) => {
    const m = mesh(new THREE.SphereGeometry(radius, 24, 16), color, position)
    m.scale.set(...scale)
    return m
  }
  const rod = (start: Vec3, end: Vec3, radius: number, color: string) => {
    const a = new THREE.Vector3(...start)
    const b = new THREE.Vector3(...end)
    const mid = a.clone().add(b).multiplyScalar(0.5)
    const m = cylinder(radius, radius, a.distanceTo(b), mid.toArray(), color)
    m.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), b.sub(a).normalize())
  }
  const book = (position: Vec3, size: Vec3, color: string) => {
    box(size, position, color, 0.005)
    box([size[0] - 0.03, size[1] - 0.025, size[2] + 0.002], position, '#d9d3bd')
  }
  switch (data.kind) {
    case 'shell': {
      box([10.5, 0.26, 8.5], [0, -0.19, 0], '#686358')
      box([10.25, 0.08, 8.25], [0, -0.02, 0], '#a17b53')
      for (let i = 0; i < 43; i++) {
        const colors = ['#af916a', '#b39772', '#baa17d', '#b09671', '#a98b64']
        box([0.232, 0.05, 8.1], [-5.04 + i * 0.24, 0.04, 0], colors[i % 5])
        for (let j = 0; j < 3; j++) box([0.234, 0.003, 0.009], [-5.04 + i * 0.24, 0.067, -2.7 + j * 2.7 + (i % 3) * 0.22], '#927755')
      }
      box([10.4, 5.85, 0.23], [0, 2.88, -4.13])
      box([0.24, 0.6, 8.5], [-5.16, 0.26, 0])
      box([0.24, 0.43, 8.5], [-5.16, 5.62, 0])
      for (const z of [-4, -1.35, 1.35, 4]) box([0.28, 5.3, 0.25], [-5.15, 2.85, z])
      for (const z of [-2.7, 0, 2.7]) {
        box([0.18, 4.9, 0.08], [-5.14, 2.96, z], charcoal)
        for (const y of [0.6, 2.5, 4.2, 5.42]) box([0.17, 0.07, 2.48], [-5.14, y, z], charcoal)
        const glass = box([0.025, 4.78, 2.5], [-5.19, 3, z], '#cfddda')
        glass.material = new THREE.MeshPhysicalMaterial({ color: '#c5d2cf', transparent: true, opacity: 0.13, roughness: 0.15, metalness: 0.1, side: THREE.DoubleSide })
        glass.castShadow = false
      }
      box([0.25, 5.9, 0.25], [5.12, 2.9, -4.13])
      box([10.4, 0.16, 0.42], [0, 5.83, -4], '#dad1bc')
      for (const x of [-3.5, -1, 1.5, 4]) {
        box([0.055, 5.3, 0.02], [x, 2.72, -3.998], '#b2ac9f')
      }
      for (const y of [1.45, 3, 4.55]) box([10.2, 0.018, 0.02], [0, y, -3.998], '#aaa698')
      box([10.1, 0.09, 0.07], [0, 0.1, -3.96], '#a8a295')
      break
    }
    case 'mezzanine':
      box([4.55, 0.23, 3.2], [-2.88, 3.09, -2.45])
      for (let i = 0; i < 23; i++) box([0.188, 0.04, 3.18], [-5.06 + i * 0.2, 3.225, -2.45], i % 3 ? '#b99569' : '#b18d60')
      box([4.5, 0.1, 0.12], [-2.85, 3, -0.84], charcoal)
      for (const x of [-4.85, -0.85]) box([0.09, 3, 0.09], [x, 1.5, -0.87], charcoal)
      for (let i = 0; i <= 19; i++) box([0.023, 0.95, 0.023], [-5.05 + i * 0.232, 3.71, -0.82], charcoal)
      box([4.52, 0.05, 0.06], [-2.85, 4.2, -0.82], charcoal)
      for (let i = 0; i < 14; i++) box([0.023, 0.95, 0.023], [-0.6, 3.71, -0.95 - i * 0.234], charcoal)
      box([0.06, 0.05, 3.12], [-0.6, 4.2, -2.45], charcoal)
      box([4.25, 0.025, 0.035], [-2.85, 2.95, -0.92], '#ffcf7d')
      break
    case 'stair': {
      const height = 3.22
      cylinder(0.072, 0.072, height + 0.95, [0, (height + 0.95) / 2, 0], charcoal)
      const pts: THREE.Vector3[] = []
      for (let i = 0; i < 18; i++) {
        const a = -Math.PI * 0.36 + i * Math.PI * 1.56 / 17
        const y = (i + 1) * height / 18
        const x = Math.cos(a) * 0.63
        const z = Math.sin(a) * 0.63
        box([1.26, 0.105, 0.34], [x, y, z], data.color, 0.025, [0, -a, 0])
        const px = Math.cos(a) * 1.18
        const pz = Math.sin(a) * 1.18
        rod([px, y, pz], [px, y + 0.88, pz], 0.018, charcoal)
        pts.push(new THREE.Vector3(px, y + 0.91, pz))
      }
      mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts), 100, 0.026, 8, false), charcoal, [0, 0, 0])
      break
    }
    case 'sofa':
      box([3.4, 0.31, 1.16], [0, 0.28, 0], '#663d2a', 0.09)
      box([3.38, 0.7, 0.24], [0, 0.71, -0.55], data.color, 0.095)
      for (const x of [-1.58, 1.58]) box([0.23, 0.53, 1.17], [x, 0.58, 0], data.color, 0.09)
      for (const x of [-0.98, 0, 0.98]) {
        box([0.955, 0.23, 0.97], [x, 0.51, 0.05], data.color, 0.09)
        box([0.97, 0.53, 0.24], [x, 0.85, -0.37], data.color, 0.075, [-0.12, 0, 0])
      }
      box([0.5, 0.46, 0.18], [-1.04, 0.8, -0.11], '#ddc7a0', 0.065, [-0.15, 0.15, 0.18])
      box([0.49, 0.45, 0.17], [1, 0.81, -0.1], '#6a7460', 0.065, [-0.18, -0.1, -0.16])
      for (const x of [-1.4, 1.4]) for (const z of [-0.4, 0.4]) cylinder(0.035, 0.03, 0.22, [x, 0.13, z], charcoal)
      break
    case 'chair':
      box([0.95, 0.25, 0.9], [0, 0.46, 0], data.color, 0.1)
      box([0.98, 0.6, 0.25], [0, 0.78, -0.38], data.color, 0.11, [-0.12, 0, 0])
      for (const x of [-0.52, 0.52]) {
        box([0.085, 0.085, 1], [x, 0.67, 0], oak, 0.03)
        for (const z of [-0.35, 0.35]) box([0.075, 0.62, 0.075], [x, 0.34, z], oak, 0.015)
      }
      box([0.45, 0.34, 0.16], [0, 0.7, -0.15], '#a47148', 0.07, [-0.15, 0, 0.1])
      break
    case 'table':
      cylinder(0.9, 0.91, 0.15, [0, 0.48, 0])
      cylinder(0.48, 0.53, 0.39, [0, 0.23, 0])
      book([-0.18, 0.595, 0.03], [0.46, 0.06, 0.31], '#593b2a')
      book([-0.15, 0.646, 0.02], [0.38, 0.04, 0.28], '#c9b48f')
      cylinder(0.11, 0.16, 0.22, [0.39, 0.66, -0.16], '#5c5c43')
      cylinder(0.085, 0.085, 0.015, [0.39, 0.778, -0.16], '#2c3025')
      sphere(0.07, [0.16, 0.61, 0.4], '#977c4f', [1.5, 0.45, 1])
      break
    case 'rug':
      box([5.35, 0.025, 3.6], [0, 0.09, 0], data.color, 0.04)
      for (let i = 0; i < 50; i++) box([5.26, 0.003, 0.012], [0, 0.105, -1.72 + i * 0.07], '#b9ad92')
      for (let i = 0; i < 75; i++) {
        for (const z of [-1.83, 1.83]) box([0.012, 0.008, 0.12], [-2.62 + i * 0.071, 0.094, z], cream)
      }
      break
    case 'plant': {
      cylinder(0.32, 0.24, 0.48, [0, 0.25, 0], '#9d8061')
      cylinder(0.32, 0.32, 0.045, [0, 0.49, 0], '#b59974')
      cylinder(0.28, 0.28, 0.025, [0, 0.51, 0], '#353429')
      for (let i = 0; i < 11; i++) {
        const a = i * 2.4
        const height = 0.85 + ((i * 7) % 11) * 0.13
        const r = 0.3 + (i % 3) * 0.12
        const end: Vec3 = [Math.cos(a) * r, height, Math.sin(a) * r]
        rod([0, 0.48, 0], end, 0.012, '#5d6542')
        const leaf = sphere(0.32, end, i % 3 === 0 ? '#7d8a4d' : data.color, [0.48, 1.6, 0.1])
        leaf.rotation.set(0.55 * Math.sin(a), a, 0.6 * Math.cos(a))
        leaf.position.y += 0.2
      }
      break
    }
    case 'kitchen':
      box([4.25, 0.9, 0.68], [0, 0.5, -0.43], '#877454', 0.015)
      box([4.35, 0.11, 0.79], [0, 0.98, -0.43], data.color, 0.02)
      for (let i = 0; i < 7; i++) {
        box([0.58, 0.76, 0.035], [-1.82 + i * 0.61, 0.5, -0.07], '#a9916b')
        box([0.14, 0.015, 0.03], [-1.82 + i * 0.61, 0.81, -0.04], charcoal)
      }
      box([2.15, 1, 0.91], [0.25, 0.54, 1.15], data.color, 0.025)
      box([2.28, 0.1, 1.04], [0.25, 1.09, 1.15], '#ddd0b6', 0.015)
      box([0.65, 0.02, 0.41], [-0.6, 1.044, -0.41], '#292d29', 0.03)
      rod([-0.65, 1.05, -0.65], [-0.65, 1.41, -0.65], 0.026, '#b7b1a0')
      rod([-0.65, 1.41, -0.65], [-0.65, 1.41, -0.4], 0.026, '#b7b1a0')
      box([2, 0.065, 0.3], [0.1, 2.05, -0.73], oak)
      for (let i = 0; i < 5; i++) cylinder(0.055, 0.07, 0.17 + (i % 2) * 0.07, [-0.55 + i * 0.26, 2.16, -0.72], i % 2 ? '#b6a682' : '#646652')
      for (const x of [-0.35, 0.85]) {
        cylinder(0.25, 0.25, 0.075, [x, 0.71, 2], oak)
        for (const dx of [-0.16, 0.16]) for (const dz of [-0.16, 0.16]) rod([x + dx, 0.05, 2 + dz], [x + dx * 0.7, 0.7, 2 + dz * 0.7], 0.025, charcoal)
      }
      cylinder(0.15, 0.2, 0.12, [0.75, 1.2, 1.15], '#7c6d4e')
      sphere(0.07, [0.75, 1.29, 1.15], '#a08244')
      break
    case 'art':
      box([1.6, 2.03, 0.08], [0, 0, 0], '#493f31')
      box([1.49, 1.92, 0.035], [0, 0, 0.055], '#e0d3b7')
      const sun = cylinder(0.41, 0.41, 0.015, [0.12, 0.35, 0.083], data.color, [Math.PI / 2, 0, 0])
      sun.castShadow = false
      box([0.53, 0.82, 0.015], [-0.25, -0.39, 0.08], '#747962')
      box([0.38, 0.58, 0.017], [0.25, -0.51, 0.083], '#b88c57')
      break
    case 'pendant': {
      cylinder(0.015, 0.015, 1.2, [0, 0.6, 0], charcoal)
      const torus = mesh(new THREE.TorusGeometry(0.57, 0.022, 12, 80), data.color, [0, 0, 0], [Math.PI / 2, 0, 0], 0.6)
      torus.material = new THREE.MeshStandardMaterial({ color: '#dcb47a', emissive: '#ffb856', emissiveIntensity: 1.8 })
      sphere(0.07, [0, -0.11, 0], '#ead9b2')
      break
    }
    case 'shelf':
      for (const z of [-0.65, 0.65]) box([0.05, 1.8, 0.05], [0, 0.92, z], charcoal)
      for (let level = 0; level < 4; level++) {
        box([0.42, 0.06, 1.48], [0, 0.18 + level * 0.48, 0], data.color)
        for (let i = 0; i < 5; i++) box([0.27, 0.21 + ((i + level) % 3) * 0.06, 0.07], [0, 0.36 + level * 0.48, -0.45 + i * 0.11], ['#ccc2a9', '#a57f53', '#556152', '#b85e3b'][i % 4])
      }
      break
    case 'bed':
      box([1.62, 0.25, 2.35], [0, 0.22, 0], oak, 0.04)
      box([1.58, 0.19, 2.2], [0, 0.44, 0], data.color, 0.085)
      box([1.64, 0.065, 0.88], [0, 0.57, 0.56], '#92927b', 0.015)
      for (const x of [-0.39, 0.39]) box([0.64, 0.15, 0.42], [x, 0.59, -0.7], '#e2d5bb', 0.08)
      break
    case 'cube': box([1, 1, 1], [0, 0, 0], data.color, 0.025); break
    case 'sphere': sphere(0.5, [0, 0, 0]); break
    case 'cylinder': cylinder(0.45, 0.45, 1, [0, 0, 0]); break
  }
  group.userData.objectId = data.id
  group.name = data.name
  return group
}

export function applyTransform(group: THREE.Object3D, value: Pick<SceneObject, 'position' | 'rotation' | 'scale'>): void {
  const [x, y, z] = value.position
  const [rx, ry, rz] = value.rotation
  group.position.set(x, z, -y)
  group.rotation.set(THREE.MathUtils.degToRad(rx), THREE.MathUtils.degToRad(rz), -THREE.MathUtils.degToRad(ry))
  group.scale.set(value.scale[0], value.scale[2], value.scale[1])
}
export function readTransform(group: THREE.Object3D): Pick<SceneObject, 'position' | 'rotation' | 'scale'> {
  const round = (n: number) => Math.round(n * 1000) / 1000
  return {
    position: [round(group.position.x), round(-group.position.z), round(group.position.y)],
    rotation: [round(THREE.MathUtils.radToDeg(group.rotation.x)), round(-THREE.MathUtils.radToDeg(group.rotation.z)), round(THREE.MathUtils.radToDeg(group.rotation.y))],
    scale: [round(Math.max(0.01, group.scale.x)), round(Math.max(0.01, group.scale.z)), round(Math.max(0.01, group.scale.y))],
  }
}
export function disposeGroup(group: THREE.Object3D): void {
  const materials = new Set<THREE.Material>()
  group.traverse(child => {
    if (child instanceof THREE.Mesh || child instanceof THREE.LineSegments) {
      child.geometry.dispose()
      if (Array.isArray(child.material)) child.material.forEach(m => materials.add(m))
      else materials.add(child.material)
    }
  })
  materials.forEach(m => m.dispose())
}
