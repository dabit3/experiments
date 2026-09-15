import * as THREE from 'three'
import { type SceneObject, type Project, type Transform, sample } from './model'

export function twistGeometry(geometry: THREE.BufferGeometry, degrees: number): THREE.BufferGeometry {
  geometry.computeBoundingBox()
  const bounds = geometry.boundingBox!
  const height = Math.max(bounds.max.y - bounds.min.y, 0.0001)
  const positions = geometry.getAttribute('position')
  for (let i = 0; i < positions.count; i++) {
    const angle = (positions.getY(i) - bounds.min.y) / height * THREE.MathUtils.degToRad(degrees)
    const x = positions.getX(i), z = positions.getZ(i)
    positions.setXYZ(i, x * Math.cos(angle) - z * Math.sin(angle), positions.getY(i), x * Math.sin(angle) + z * Math.cos(angle))
  }
  positions.needsUpdate = true
  geometry.computeVertexNormals()
  geometry.computeBoundingBox()
  geometry.computeBoundingSphere()
  return geometry
}

export function applyTransform(group: THREE.Object3D, t: Transform) {
  group.position.fromArray(t.position)
  group.rotation.set(...t.rotation.map(THREE.MathUtils.degToRad) as [number, number, number])
  group.scale.fromArray(t.scale)
}

export function buildObject(object: SceneObject): THREE.Group {
  const group = new THREE.Group()
  group.name = object.name
  group.userData.objectId = object.id
  const base = new THREE.MeshStandardMaterial({ color: object.color, roughness: object.roughness, metalness: object.metalness })
  const material = (color: string, roughness = 0.65, metalness = 0) => new THREE.MeshStandardMaterial({ color, roughness, metalness })
  const mesh = (geometry: THREE.BufferGeometry, mat = base, position: [number, number, number] = [0, 0, 0]) => {
    if (object.twist) twistGeometry(geometry, object.twist)
    const m = new THREE.Mesh(geometry, mat)
    m.position.fromArray(position)
    m.castShadow = true
    m.receiveShadow = true
    m.userData.objectId = object.id
    group.add(m)
    return m
  }
  const box = (size: [number, number, number], pos: [number, number, number], mat = base) => mesh(new THREE.BoxGeometry(...size, 1, object.twist ? 40 : 1, 1), mat, pos)
  switch (object.kind) {
    case 'box': box([1, 1, 1], [0, 0, 0]); break
    case 'sphere': mesh(new THREE.SphereGeometry(0.65, 32, 24)); break
    case 'cylinder': mesh(new THREE.CylinderGeometry(0.65, 0.65, 1.8, 32, 24)); break
    case 'torus': mesh(new THREE.TorusGeometry(0.85, 0.2, 16, 56)); break
    case 'plinth':
      box([1, 0.95, 1], [0, 0.525, 0])
      box([0.92, 0.05, 0.92], [0, 0.025, 0], material('#39352c'))
      break
    case 'sculpture': {
      const curve = new THREE.CatmullRomCurve3(Array.from({ length: 121 }, (_, i) => {
        const a = i / 120 * Math.PI * 2
        return new THREE.Vector3(Math.sin(a) * (1.0 + 0.18 * Math.cos(a * 3)), 1.35 + Math.cos(a) * 1.2, Math.sin(a * 2) * 0.43)
      }), true)
      mesh(new THREE.TubeGeometry(curve, 120, 0.24, 14, true))
      const inner = mesh(new THREE.TorusGeometry(0.64, 0.09, 12, 48), base, [0, 1.35, 0])
      inner.rotation.y = 0.7
      break
    }
    case 'rib': {
      const shape = new THREE.Shape()
      const outer = (a: number) => [6.75 * Math.cos(a), 2.25 + 4.3 * Math.sin(a)]
      shape.moveTo(6.75, 0)
      shape.lineTo(6.75, 2.25)
      for (let i = 0; i <= 60; i++) { const p = outer(i / 60 * Math.PI); shape.lineTo(p[0], p[1]) }
      shape.lineTo(-6.75, 0)
      shape.lineTo(-6.38, 0)
      shape.lineTo(-6.38, 2.25)
      for (let i = 60; i >= 0; i--) { const a = i / 60 * Math.PI; shape.lineTo(6.38 * Math.cos(a), 2.25 + 3.95 * Math.sin(a)) }
      shape.lineTo(6.38, 0)
      shape.closePath()
      mesh(new THREE.ExtrudeGeometry(shape, { depth: 0.24, bevelEnabled: true, bevelThickness: 0.035, bevelSize: 0.035, bevelSegments: 2, steps: 1 }), base, [0, 0, -0.12])
      break
    }
    case 'shell': {
      box([14, 0.28, 20.5], [0, -0.14, 0])
      box([0.3, 2.25, 20.5], [6.95, 1.125, 0])
      box([14, 5.7, 0.25], [0, 2.85, -10.2])
      const seam = material('#b8ad98')
      for (let x = -6; x <= 6; x += 2) box([0.016, 0.003, 20], [x, 0.005, 0], seam)
      for (let z = -9; z <= 9; z += 2) box([14, 0.003, 0.016], [0, 0.005, z], seam)
      const dark = material('#45443a')
      box([3.2, 3.7, 0.04], [-3.6, 2.3, -10.03], dark)
      box([3.05, 3.55, 0.05], [-3.6, 2.3, -9.99], material('#d1c3a9'))
      const art = material('#a35e40')
      const disc = mesh(new THREE.CircleGeometry(0.94, 48), art, [-3.6, 2.4, -9.94])
      disc.scale.y = 1.3
      box([2, 0.022, 0.024], [-3.6, 1.35, -9.90], dark)
      const emissive = new THREE.MeshStandardMaterial({ color: '#fff6d9', emissive: '#ffcc88', emissiveIntensity: 2 })
      for (const x of [-5.9, 5.9]) {
        box([0.035, 0.025, 19.5], [x, 0.035, 0], emissive)
        box([0.07, 0.07, 19.5], [x * 0.58, 5.65, 0], dark)
        for (let z = -8; z <= 8; z += 4) {
          mesh(new THREE.CylinderGeometry(0.11, 0.11, 0.2, 12), dark, [x * 0.58, 5.49, z])
          mesh(new THREE.CircleGeometry(0.08, 12), emissive, [x * 0.58, 5.38, z]).rotation.x = Math.PI / 2
        }
      }
      break
    }
    case 'window': {
      const glass = new THREE.MeshStandardMaterial({ color: '#bdcecb', transparent: true, opacity: 0.12, roughness: 0.1, metalness: 0.1, side: THREE.DoubleSide, depthWrite: false })
      box([0.035, 4.8, 20], [0, 2.4, 0], glass)
      for (let z = -10; z <= 10; z += 2) box([0.065, 4.8, 0.065], [0, 2.4, z])
      for (const y of [0.1, 2.8, 4.8]) box([0.07, 0.065, 20], [0, y, 0])
      break
    }
    case 'bench': {
      box([1.25, 0.18, 3.2], [0, 0.61, 0])
      box([1.2, 0.16, 3.13], [0, 0.78, 0], material('#d7cbb5'))
      for (const x of [-0.43, 0.43]) for (const z of [-1.15, 1.15]) box([0.08, 0.57, 0.08], [x, 0.29, z], material('#35332e'))
      for (let z = -1; z <= 1; z++) box([1.18, 0.006, 0.016], [0, 0.864, z], material('#b8a88e'))
      break
    }
    case 'plant': {
      mesh(new THREE.CylinderGeometry(0.47, 0.32, 0.85, 24), material('#aaa28d'), [0, 0.425, 0])
      mesh(new THREE.CylinderGeometry(0.43, 0.43, 0.03, 24), material('#3e3c30'), [0, 0.83, 0])
      mesh(new THREE.CylinderGeometry(0.045, 0.065, 1.6, 10), material('#75634c'), [0, 1.55, 0])
      for (let i = 0; i < 36; i++) {
        const a = i * 2.39996, radius = 0.3 + (i % 5) * 0.12
        const leaf = mesh(new THREE.SphereGeometry(1, 8, 6), i % 3 === 0 ? material('#68784c') : base, [Math.cos(a) * radius, 1.65 + (i % 7) * 0.15, Math.sin(a) * radius])
        leaf.scale.set(0.16, 0.035, 0.4)
        leaf.rotation.set(i * 0.21, a, 0.4)
      }
      break
    }
  }
  applyTransform(group, object)
  group.visible = object.visible
  return group
}

export function disposeGroup(group: THREE.Object3D) {
  const geometries = new Set<THREE.BufferGeometry>()
  const materials = new Set<THREE.Material>()
  group.traverse(o => {
    if (o instanceof THREE.Mesh || o instanceof THREE.LineSegments) {
      geometries.add(o.geometry)
      for (const m of Array.isArray(o.material) ? o.material : [o.material]) materials.add(m)
    }
  })
  geometries.forEach(g => g.dispose())
  materials.forEach(m => m.dispose())
}

export function exportOBJ(project: Project, frame: number): string {
  const lines = ['# Vexel geometry export', `# ${project.name.replace(/[\r\n]/g, ' ')} — frame ${frame}`]
  let offset = 1
  for (const object of project.objects.filter(o => o.visible)) {
    const group = buildObject(object)
    applyTransform(group, sample(object, frame))
    group.updateMatrixWorld(true)
    lines.push(`o ${object.name.replace(/[^\w-]/g, '_')}`)
    group.traverse(child => {
      if (!(child instanceof THREE.Mesh)) return
      const geometry = child.geometry.index ? child.geometry.toNonIndexed() : child.geometry.clone()
      geometry.applyMatrix4(child.matrixWorld)
      const p = geometry.getAttribute('position')
      for (let i = 0; i < p.count; i++) lines.push(`v ${p.getX(i).toFixed(5)} ${p.getY(i).toFixed(5)} ${p.getZ(i).toFixed(5)}`)
      for (let i = 0; i < p.count; i += 3) lines.push(`f ${offset + i} ${offset + i + 1} ${offset + i + 2}`)
      offset += p.count
      geometry.dispose()
    })
    disposeGroup(group)
  }
  return lines.join('\n')
}
