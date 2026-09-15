import * as THREE from 'three'
import { MATERIALS, PAVILIONS, TREES, visibleElements } from './model'
import type { Combination, Element, Project } from './model'

type Paint = THREE.MeshStandardMaterial
const palette = (color: string, roughness = .8) => new THREE.MeshStandardMaterial({ color, roughness })

export function buildCampus(project: Project, combination: Combination, cutaway: boolean, appearance: string) {
  const root = new THREE.Group()
  const elements = new Map<string, THREE.Group>()
  const paints = {
    concrete: palette('#e6e5df'), limestone: palette('#ded6c4'), timber: palette('#a67a4d'),
    terracotta: palette('#b77859'),
    glass: new THREE.MeshStandardMaterial({ color: '#9cbab8', transparent: true, opacity: .46, roughness: .16, metalness: .25, depthWrite: false }),
    steel: palette('#333f3d', .5), paving: palette('#d6d3c8'), ground: palette('#d1d4bd'),
    pool: palette('#79a4a1', .16), bark: palette('#756449'), white: palette('#eeede5'),
    earth: palette('#888775'), gravel: palette('#b3b6a9'), foliage: palette('#74876c'),
  }
  const cube = new THREE.BoxGeometry(1, 1, 1)
  function box(parent: THREE.Group, x: number, y: number, z: number, w: number, h: number, d: number, material: THREE.Material, shadow = true) {
    const mesh = new THREE.Mesh(cube, material)
    mesh.position.set(x, y, z)
    mesh.scale.set(w, h, d)
    mesh.castShadow = shadow
    mesh.receiveShadow = true
    parent.add(mesh)
    return mesh
  }
  function cylinder(parent: THREE.Group, x: number, y: number, z: number, radius: number, h: number, material: THREE.Material) {
    const mesh = new THREE.Mesh(new THREE.CylinderGeometry(radius, radius, h, 10), material)
    mesh.position.set(x, y, z)
    mesh.castShadow = true
    mesh.receiveShadow = true
    parent.add(mesh)
    return mesh
  }
  box(root, 0, -.65, 0, 79, 1, 65, paints.ground)
  box(root, 0, -.16, 0, 62, .14, 48, paints.gravel, false)
  box(root, 0, -.02, 6, 59, .16, 36, paints.paving, false)
  for (let x = -29; x <= 29; x += 3) box(root, x, .065, 7, .018, .006, 34, paints.gravel, false)
  for (let z = -10; z <= 23; z += 3) box(root, 0, .067, z, 59, .006, .018, paints.gravel, false)
  box(root, -2, .09, 7, 16, .22, 15, paints.earth, false)
  box(root, -2, .23, 7, 15.5, .15, 14.5, paints.ground, false)
  box(root, 8, .11, 13, 5.8, .28, 12, paints.white)
  box(root, 8, .28, 13, 5.2, .025, 11.4, paints.pool, false)
  for (let k = 0; k < 5; k++) box(root, 8, .29, 9 + k * 1.5, 4.3, .009, .012, paints.glass, false)
  for (let k = 0; k < 4; k++) box(root, 0, -.02 - k * .1, 24.1 + k * .5, 14, .16, 1, paints.concrete)
  box(root, 0, -.21, 29, 14, .12, 6, paints.paving, false)

  function addElement(e: Element) {
    const group = new THREE.Group()
    group.position.set(e.x, e.elevation + .23, e.z)
    group.rotation.y = -e.rotation * Math.PI / 180
    group.userData.elementId = e.id
    const mat: Paint = appearance === 'White model' ? paints.white : paints[e.material]
    if (e.kind === 'wall') {
      const door = project.elements.find(d => d.hostId === e.id)
      if (door) {
        const offset = door.offset ?? 0
        const left = offset - door.width / 2 + e.width / 2, right = e.width / 2 - offset - door.width / 2
        if (left > .001) box(group, -e.width / 2 + left / 2, e.height / 2, 0, left, e.height, e.depth, mat)
        if (right > .001) box(group, e.width / 2 - right / 2, e.height / 2, 0, right, e.height, e.depth, mat)
        if (e.height > door.height) box(group, offset, door.height + (e.height - door.height) / 2, 0, door.width, e.height - door.height, e.depth, mat)
      } else box(group, 0, e.height / 2, 0, e.width, e.height, e.depth, mat)
      if (e.material === 'glass' && appearance !== 'White model') {
        const n = Math.ceil(e.width / 1.5)
        for (let j = 0; j <= n; j++) {
          const x = -e.width / 2 + j * e.width / n
          if (door && Math.abs(x - (door.offset ?? 0)) < door.width / 2) continue
          box(group, x, e.height / 2, 0, .055, e.height, e.depth + .055, paints.steel)
        }
        for (const y of [.06, e.height * .64, e.height - .06]) {
          if (door && y - .03 < door.height) {
            const left = (door.offset ?? 0) - door.width / 2 + e.width / 2
            const right = e.width - left - door.width
            if (left > .001) box(group, -e.width / 2 + left / 2, y, 0, left, .06, e.depth + .06, paints.steel)
            if (right > .001) box(group, e.width / 2 - right / 2, y, 0, right, .06, e.depth + .06, paints.steel)
          } else box(group, 0, y, 0, e.width, .06, e.depth + .06, paints.steel)
        }
      } else if (e.material === 'timber' && appearance !== 'White model') {
        const n = Math.floor(e.width / .25)
        const slats = new THREE.InstancedMesh(cube, paints.timber, n * 2)
        const dummy = new THREE.Object3D()
        for (let i = 0; i < n; i++) {
          for (let side = 0; side < 2; side++) {
            const x = -e.width / 2 + .12 + i * .25
            const aboveDoor = door && Math.abs(x - (door.offset ?? 0)) < door.width / 2 + .055
            const base = aboveDoor ? door.height : 0
            dummy.position.set(x, base + (e.height - base) / 2, (side ? -1 : 1) * (e.depth / 2 + .06))
            dummy.scale.set(.11, e.height - base, .14)
            dummy.updateMatrix()
            slats.setMatrixAt(i * 2 + side, dummy.matrix)
          }
        }
        slats.castShadow = true
        slats.receiveShadow = true
        group.add(slats)
      }
    } else if (e.kind === 'slab') {
      box(group, 0, e.height / 2, 0, e.width, e.height, e.depth, mat)
      if (e.layer === 'Roofs') {
        box(group, 0, e.height + .02, 0, e.width - .6, .055, e.depth - .6, appearance === 'White model' ? paints.white : paints.gravel, false)
        for (const side of [-1, 1]) {
          box(group, side * (e.width / 2 - .12), e.height + .13, 0, .18, .27, e.depth, mat)
          box(group, 0, e.height + .13, side * (e.depth / 2 - .12), e.width, .27, .18, mat)
        }
        for (const side of [-1, 1]) {
          box(group, side * e.width * .22, e.height + .25, -e.depth * .18, e.width * .23, .23, e.depth * .28, paints.steel)
          box(group, side * e.width * .22, e.height + .38, -e.depth * .18, e.width * .23 - .18, .08, e.depth * .28 - .18, paints.glass)
        }
      }
    } else {
      for (const side of [-1, 1]) box(group, side * (e.width / 2 - .035), e.height / 2, 0, .07, e.height, e.depth, paints.steel)
      box(group, 0, e.height - .035, 0, e.width, .07, e.depth, paints.steel)
      const leaf = new THREE.Group()
      leaf.position.set(-e.width / 2, 0, 0)
      leaf.rotation.y = -.55
      box(leaf, e.width / 2, e.height / 2, 0, e.width - .08, e.height - .1, .065, mat)
      box(leaf, e.width - .2, 1.05, .06, .04, .4, .04, paints.steel)
      group.add(leaf)
    }
    elements.set(e.id, group)
    root.add(group)
  }
  visibleElements(project, combination, undefined, cutaway).forEach(addElement)

  if (combination !== 'Structure only') {
    PAVILIONS.forEach(p => {
      for (const dx of [-p.w / 2 + .3, p.w / 2 - .3]) {
        for (const dz of [-p.d / 2 + .3, p.d / 2 - .3]) box(root, p.x + dx, p.h / 2 + .23, p.z + dz, .2, p.h, .2, paints.steel)
      }
      for (let j = 0; j < 3; j++) {
        const x = p.x - p.w / 3 + j * p.w / 3
        box(root, x, 1.1, p.z + 2, 2.5, .12, 1.5, paints.timber)
        for (const dx of [-1, 1]) for (const dz of [-.5, .5]) box(root, x + dx, .65, p.z + 2 + dz, .06, .8, .06, paints.steel)
        for (const dz of [-1.3, 1.3]) {
          box(root, x, .73, p.z + 2 + dz, .65, .15, .65, paints.timber)
          box(root, x, 1.07, p.z + 2 + dz + Math.sign(dz) * .3, .65, .7, .06, paints.timber)
        }
      }
      for (let i = 0; i < 3; i++) {
        box(root, p.x - p.w / 3 + i * p.w / 3, 1.35, p.z - p.d / 2 + .3, p.w / 4, 1.6, .09, i % 2 ? paints.terracotta : paints.white)
      }
    })
    for (const x of [-10, 0, 10]) {
      for (const z of [18.5, 21.5]) box(root, x, 1.75, z, .13, 3.2, .13, paints.steel)
    }
    for (const z of [18.5, 21.5]) box(root, 0, 3.35, z, 23, .19, .16, paints.timber)
    for (let x = -11.5; x <= 11.5; x += .42) box(root, x, 3.55, 20, .12, .2, 4.6, paints.timber)
    for (const x of [-8.5, 1.5]) {
      box(root, x, .6, 14, 5, .3, 1.1, paints.timber)
      for (const dx of [-1.8, 1.8]) box(root, x + dx, .25, 14, .25, .5, 1, paints.steel)
    }
    box(root, 1, .6, -3, 2.7, 1, 2.7, paints.concrete)
    const sculpture = new THREE.Mesh(new THREE.TorusGeometry(1.45, .19, 12, 48, Math.PI * 1.7), paints.terracotta)
    sculpture.position.set(1, 2.8, -3)
    sculpture.rotation.set(.14, -.5, -.2)
    sculpture.castShadow = true
    root.add(sculpture)
  }
  if (combination === 'All elements') {
    const leafCount = TREES.length * 23 + 140
    const leaves = new THREE.InstancedMesh(new THREE.IcosahedronGeometry(1, 1), paints.foliage, leafCount)
    leaves.castShadow = true
    leaves.receiveShadow = true
    const dummy = new THREE.Object3D()
    const color = new THREE.Color()
    let index = 0
    const rand = (n: number) => { const f = Math.sin(n * 127.1 + 311.7) * 43758.5453; return f - Math.floor(f) }
    TREES.forEach(([x, z, size], i) => {
      cylinder(root, x, 2.15 * size, z, .16 * size, 4.3 * size, paints.bark)
      for (let j = 0; j < 23; j++) {
        const angle = j * 2.3999
        const radius = 2.5 * Math.sqrt(j / 23) * size
        dummy.position.set(x + Math.cos(angle) * radius, (4.4 + rand(i * 70 + j) * 2) * size, z + Math.sin(angle) * radius)
        dummy.scale.setScalar((.95 + rand(j * 13 + i) * .8) * size)
        dummy.scale.y *= .8
        dummy.rotation.set(j, i, j / 4)
        dummy.updateMatrix()
        leaves.setMatrixAt(index, dummy.matrix)
        color.setHSL(.21 + rand(i + j) * .05, .13 + rand(j + i) * .12, .29 + rand(i * 20 + j) * .18)
        leaves.setColorAt(index++, color)
      }
    })
    for (let j = 0; j < 140; j++) {
      const edge = j % 2 === 0
      const x = edge ? -8.7 + rand(j + 2) * 13.2 : -29 + rand(j + 13) * 58
      const z = edge ? 1 + rand(j + 17) * 11 : (j % 3 ? -25 : 25)
      dummy.position.set(x, .55, z)
      dummy.scale.set(.4 + rand(j) * .3, .42, .4 + rand(j + 4) * .25)
      dummy.updateMatrix()
      leaves.setMatrixAt(index, dummy.matrix)
      color.setHSL(.22, .19, .36 + rand(j) * .2)
      leaves.setColorAt(index++, color)
    }
    root.add(leaves)
  }
  if (appearance === 'Technical') {
    for (const [id, group] of elements) {
      const e = project.elements.find(item => item.id === id)!
      const edges = new THREE.LineSegments(new THREE.EdgesGeometry(new THREE.BoxGeometry(e.width, e.height, e.depth)), new THREE.LineBasicMaterial({ color: '#364746' }))
      edges.position.y = e.height / 2
      group.add(edges)
    }
  }
  return { root, elements }
}

export function disposeScene(root: THREE.Object3D) {
  const geometries = new Set<THREE.BufferGeometry>()
  const materials = new Set<THREE.Material>()
  root.traverse(obj => {
    if (obj instanceof THREE.Mesh || obj instanceof THREE.LineSegments) {
      geometries.add(obj.geometry)
      for (const m of Array.isArray(obj.material) ? obj.material : [obj.material]) materials.add(m)
    }
  })
  geometries.forEach(g => g.dispose())
  materials.forEach(m => m.dispose())
}

export const surfaceColor = (e: Element) => MATERIALS[e.material].color
