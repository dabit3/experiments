import * as THREE from 'three'
import { OBJExporter } from 'three/examples/jsm/exporters/OBJExporter.js'
import { canopyProfile, sampleCurve, stripGeometry, surfaceGeometry } from './geometry'
import type { Entity, Point, Project } from './model'

export type DisplayMode = 'Shaded' | 'Wireframe' | 'Rendered'

function material(color: string, opacity = 1, metalness = 0): THREE.MeshStandardMaterial {
  return new THREE.MeshStandardMaterial({ color, roughness: 0.64, metalness, transparent: opacity < 1, opacity, side: THREE.DoubleSide })
}
function line(group: THREE.Group, points: Point[], color: string, opacity = 1) {
  const geometry = new THREE.BufferGeometry().setFromPoints(points.map(point => new THREE.Vector3(...point)))
  const object = new THREE.Line(geometry, new THREE.LineBasicMaterial({ color, transparent: opacity < 1, opacity }))
  group.add(object)
  return object
}
function solid(group: THREE.Group, geometry: THREE.BufferGeometry, color: string, wire: boolean, opacity = 1, edge = true) {
  if (wire) {
    const lines = new THREE.LineSegments(new THREE.EdgesGeometry(geometry, 24), new THREE.LineBasicMaterial({ color, transparent: true, opacity: 0.67 }))
    group.add(lines)
    geometry.dispose()
    return lines
  }
  const mesh = new THREE.Mesh(geometry, material(color, opacity))
  mesh.castShadow = opacity === 1
  mesh.receiveShadow = true
  group.add(mesh)
  if (edge) mesh.add(new THREE.LineSegments(new THREE.EdgesGeometry(geometry, 35), new THREE.LineBasicMaterial({ color: '#6c655b', transparent: true, opacity: 0.16 })))
  return mesh
}
function box(group: THREE.Group, size: Point, position: Point, color: string, wire: boolean, opacity = 1) {
  const object = solid(group, new THREE.BoxGeometry(...size), color, wire, opacity)
  object.position.set(...position)
  return object
}
function post(group: THREE.Group, a: Point, b: Point, radius: number, color: string, wire: boolean) {
  const from = new THREE.Vector3(...a), to = new THREE.Vector3(...b)
  const object = solid(group, new THREE.CylinderGeometry(radius, radius, from.distanceTo(to), 8), color, wire, 1, false)
  object.position.copy(from.clone().add(to).multiplyScalar(0.5))
  object.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), to.sub(from).normalize())
}

function buildCanopy(group: THREE.Group, object: Entity, color: string, wire: boolean) {
  for (let i = 0; i < object.ribs; i++) {
    const y = -11.7 + i * 23.4 / (object.ribs - 1)
    const width = 23.4 / object.ribs * 0.76
    const a = Array.from({ length: 65 }, (_, j) => canopyProfile(j / 64, y - width / 2, object.height))
    const b = Array.from({ length: 65 }, (_, j) => canopyProfile(j / 64, y + width / 2, object.height))
    if (wire) {
      line(group, a, color, 0.85)
      line(group, b, color, 0.55)
      line(group, [a[0], b[0]], color)
      line(group, [a[64], b[64]], color)
    } else {
      solid(group, stripGeometry(a, b), '#e5d7b5', false, 1, false)
      const lower = a.map(([x, y, z]): Point => [x, y, z - 0.23])
      solid(group, stripGeometry(a, lower), color, false, 1, false)
      const lowerB = b.map(([x, y, z]): Point => [x, y, z - 0.23])
      solid(group, stripGeometry(b, lowerB), color, false, 1, false)
      solid(group, stripGeometry(lower, lowerB), '#d4c8ad', false, 1, false)
    }
  }
  for (const t of [0.12, 0.28, 0.5, 0.72, 0.88]) {
    const path = Array.from({ length: 33 }, (_, j): Point => {
      const p = canopyProfile(t, -11.9 + j * 23.8 / 32, object.height)
      return [p[0], p[1], p[2] - 0.32]
    })
    if (wire) line(group, path, color, 0.65)
    else solid(group, new THREE.TubeGeometry(new THREE.CatmullRomCurve3(path.map(p => new THREE.Vector3(...p))), 32, 0.085, 6, false), '#b8a17a', false, 1, false)
  }
  for (const y of [-9, -2.5, 4, 10]) {
    for (const t of [0.105, 0.895]) {
      const p = canopyProfile(t, y, object.height)
      post(group, [p[0] * 0.89, p[1], 0.3], [p[0], p[1], p[2] - 0.2], 0.12, wire ? color : '#d4cbbc', wire)
    }
  }
}

function buildPavilion(group: THREE.Group, color: string, wire: boolean) {
  box(group, [26, 15.2, 0.35], [0, 0, 0.42], wire ? color : '#cec8ba', wire)
  box(group, [25.4, 14.5, 0.22], [0, 0, 4.85], wire ? color : '#d9d7ca', wire)
  box(group, [24.8, 0.12, 4.2], [0, -7, 2.6], color, wire, 0.34)
  box(group, [24.8, 0.12, 4.2], [0, 7, 2.6], color, wire, 0.34)
  box(group, [0.12, 14, 4.2], [-12.4, 0, 2.6], color, wire, 0.35)
  box(group, [0.12, 14, 4.2], [12.4, 0, 2.6], color, wire, 0.35)
  for (let i = -12; i <= 12; i += 1.5) {
    for (const y of [-7.07, 7.07]) {
      post(group, [i, y, 0.6], [i, y, 4.7], 0.037, wire ? color : '#496064', wire)
      if (i < 12) {
        line(group, [[i, y, 0.7], [i + 1.5, y, 2.6], [i, y, 4.65]], wire ? color : '#bdd0c9', 0.7)
        line(group, [[i + 1.5, y, 0.7], [i, y, 2.6], [i + 1.5, y, 4.65]], wire ? color : '#bdd0c9', 0.7)
      }
    }
  }
  for (let y = -6; y <= 6; y += 1.5) for (const x of [-12.45, 12.45]) post(group, [x, y, 0.6], [x, y, 4.7], 0.037, wire ? color : '#496064', wire)
  box(group, [8, 9, 4], [-5, 1, 2.6], wire ? color : '#e4dfd1', wire)
  box(group, [5, 4, 3.7], [7, 3, 2.5], wire ? color : '#bbb09a', wire)
  for (let i = 0; i < 5; i++) {
    box(group, [1.3, 0.5, 1.15], [1.5 + i * 1.7, -3.3, 1.1], wire ? color : '#9c8260', wire)
    box(group, [0.7, 0.7, 0.85], [-7 + i * 3, -4, 1], wire ? color : '#e8e4d7', wire)
  }
  box(group, [3.5, 0.15, 3.5], [3.5, -7.14, 2.3], wire ? color : '#6a9399', wire, 0.25)
}

function buildSite(group: THREE.Group, color: string, wire: boolean) {
  box(group, [61, 43, 0.45], [0, 0, -0.8], wire ? color : '#d4d3c5', wire)
  box(group, [46, 32, 0.3], [0, 0, -0.4], wire ? color : '#deddd2', wire)
  for (let i = 0; i < 4; i++) box(group, [31 - i * 0.45, 2.8 - i * 0.25, 0.12], [0, -15 + i * 0.25, -0.2 + i * 0.12], wire ? color : '#c9c9bd', wire)
  box(group, [13.5, 8, 0.15], [17, -12, -0.12], wire ? color : '#456e72', wire)
  box(group, [13.2, 7.7, 0.07], [17, -12, -0.02], wire ? color : '#82a9a6', wire)
  for (let x = -22; x < 23; x += 3) line(group, [[x, -16, -0.22], [x, 16, -0.22]], color, wire ? 0.25 : 0.3)
  for (let y = -15; y <= 15; y += 3) line(group, [[-23, y, -0.22], [23, y, -0.22]], color, wire ? 0.25 : 0.3)
  for (const [x, y] of [[-17, -13], [-21, -2], [18, 12]]) {
    box(group, [4, 1.1, 0.42], [x, y, 0.1], wire ? color : '#9c8667', wire)
    box(group, [0.18, 0.7, 0.5], [x - 1.5, y, -0.1], wire ? color : '#525b58', wire)
    box(group, [0.18, 0.7, 0.5], [x + 1.5, y, -0.1], wire ? color : '#525b58', wire)
  }
  const sculpture = solid(group, new THREE.TorusKnotGeometry(1, 0.19, 72, 8, 2, 3), wire ? color : '#ad7548', wire)
  sculpture.position.set(-18.5, -9, 1.65)
  box(group, [2.1, 2.1, 0.4], [-18.5, -9, 0.2], wire ? color : '#eee9da', wire)
}

function buildLandscape(group: THREE.Group, color: string, wire: boolean) {
  const treePoints = [[-25, -14], [-26, -6], [-26, 4], [-23, 14], [-16, 18], [-7, 19], [3, 18.5], [13, 19], [23, 15], [26, 6], [27, -2], [-28, 14], [25, -17]]
  treePoints.forEach(([x, y], i) => {
    const height = 3.5 + (i % 4) * 0.48
    post(group, [x, y, -0.5], [x, y, height], 0.12, wire ? color : '#807560', wire)
    if (wire) {
      const ring = Array.from({ length: 33 }, (_, j): Point => {
        const angle = j / 32 * Math.PI * 2
        const radius = 1.7 + Math.sin(j * 2.5) * 0.16
        return [x + Math.cos(angle) * radius, y + Math.sin(angle) * radius, height]
      })
      line(group, ring, color, 0.6)
      line(group, ring.map(([px, , pz], j): Point => [px, y, pz + Math.sin(j / 32 * Math.PI * 2) * 1.8]), color, 0.45)
    } else {
      for (let j = 0; j < 4; j++) {
        const foliage = solid(group, new THREE.IcosahedronGeometry(1.45 + j * 0.08, 1), ['#81917a', '#9baa89', '#899a7e', '#a3ac8d'][(i + j) % 4], false, 1, false)
        foliage.position.set(x + Math.sin(j * 2.4) * 0.7, y + Math.cos(j * 2.4) * 0.65, height + j * 0.3)
        foliage.scale.z = 1.1
      }
    }
  })
  for (const [x, y, w, d] of [[-26, 0, 6, 31], [0, 19, 45, 5], [26, 6, 5, 21]]) box(group, [w, d, 0.05], [x, y, -0.53], wire ? color : '#b4bda2', wire)
}

export function buildEntity(object: Entity, color: string, mode: DisplayMode): THREE.Group {
  const group = new THREE.Group()
  group.name = object.name.replaceAll(/[^a-z0-9]/gi, '_')
  group.userData.entityId = object.id
  const wire = mode === 'Wireframe'
  if (object.kind === 'canopy') buildCanopy(group, object, color, wire)
  if (object.kind === 'pavilion') buildPavilion(group, color, wire)
  if (object.kind === 'site') buildSite(group, color, wire)
  if (object.kind === 'landscape') buildLandscape(group, color, wire)
  if (object.kind === 'curve') {
    line(group, sampleCurve(object.points), color, 0.85)
  }
  if (object.kind === 'loft' || object.kind === 'extrusion') {
    if (wire) {
      const first = sampleCurve(object.kind === 'loft' ? object.sections[0] : object.points)
      const second = object.kind === 'loft' ? sampleCurve(object.sections[1]) : first.map(([x, y, z]): Point => [x, y, z + object.height])
      line(group, first, color)
      line(group, second, color)
      for (let i = 0; i < first.length; i += 4) line(group, [first[i], second[i]], color, 0.65)
    } else solid(group, surfaceGeometry(object), color, false, 1, false)
  }
  group.position.set(...object.position)
  group.rotation.z = object.rotation * Math.PI / 180
  group.scale.setScalar(object.scale)
  return group
}

export function buildModel(project: Project, mode: DisplayMode, selected: string[] = [], showPoints = false): THREE.Group {
  const root = new THREE.Group()
  for (const object of project.objects) {
    const layer = project.layers.find(layer => layer.id === object.layerId)
    if (!layer?.visible) continue
    const isSelected = selected.includes(object.id)
    const group = buildEntity(object, isSelected ? '#db9f20' : layer.color, mode)
    if (isSelected && mode !== 'Wireframe') {
      group.traverse(child => {
        if (child instanceof THREE.Mesh && child.material instanceof THREE.MeshStandardMaterial) {
          child.material.emissive.set('#805511')
          child.material.emissiveIntensity = 0.12
        }
      })
      const helper = new THREE.BoxHelper(group, '#daa634')
      helper.material.depthTest = false
      helper.material.transparent = true
      helper.material.opacity = 0.65
      helper.userData.decoration = true
      root.add(helper)
    }
    if (isSelected && object.kind === 'curve' && showPoints) {
      const polygon = line(group, object.points, '#db9f20', 0.7)
      polygon.userData.decoration = true
      object.points.forEach((point, index) => {
        const handle = new THREE.Mesh(new THREE.SphereGeometry(0.23, 10, 8), new THREE.MeshBasicMaterial({ color: '#f8ce4c', depthTest: false }))
        handle.position.set(...point)
        handle.renderOrder = 10
        handle.userData.pointIndex = index
        handle.userData.entityId = object.id
        group.add(handle)
      })
    }
    root.add(group)
  }
  root.updateMatrixWorld(true)
  return root
}

export function disposeObject(root: THREE.Object3D) {
  root.traverse(child => {
    if (child instanceof THREE.Mesh || child instanceof THREE.Line) {
      child.geometry.dispose()
      const materials = Array.isArray(child.material) ? child.material : [child.material]
      materials.forEach(material => material.dispose())
    }
  })
}

export function exportOBJ(project: Project): string {
  const root = buildModel(project, 'Shaded')
  const output = `# Rhova geometry export\n# Units: meters; Z up; visible layers only\n${new OBJExporter().parse(root)}`
  disposeObject(root)
  return output
}
