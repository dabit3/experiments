import * as THREE from 'three'
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js'
import type { Entity, Project } from './model.ts'
import { materials } from './model.ts'

const palette = {
  ink: '#3e403a', timber: '#b98452', dark: '#493b2d', plaster: '#ece6d5', roof: '#526165',
  gravel: '#d2cec1', concrete: '#adae9e', leaf: '#6e8355', glass: '#b9dadd',
}
function seeded(seed: number) {
  let n = seed
  return () => { n = (n * 1664525 + 1013904223) >>> 0; return n / 4294967296 }
}
function material(color: string, opacity = 1) {
  return new THREE.MeshStandardMaterial({ color, roughness: .9, transparent: opacity < 1, opacity, depthWrite: opacity === 1, side: opacity < 1 ? THREE.DoubleSide : THREE.FrontSide })
}
function outline(mesh: THREE.Mesh, color = palette.ink) {
  const line = new THREE.LineSegments(new THREE.EdgesGeometry(mesh.geometry, 24), new THREE.LineBasicMaterial({ color, transparent: true, opacity: .72 }))
  line.userData.edge = true
  mesh.add(line)
}
function box(parent: THREE.Object3D, size: number[], pos: number[], color: string, edges = true, opacity = 1) {
  const mesh = new THREE.Mesh(new THREE.BoxGeometry(...size as [number, number, number]), material(color, opacity))
  mesh.position.set(...pos as [number, number, number])
  mesh.castShadow = opacity === 1
  mesh.receiveShadow = true
  if (edges) outline(mesh)
  parent.add(mesh)
  return mesh
}
function sphere(parent: THREE.Object3D, pos: number[], scale: number[], color: string, detail = 1) {
  const mesh = new THREE.Mesh(new THREE.IcosahedronGeometry(1, detail), material(color))
  mesh.position.set(...pos as [number, number, number])
  mesh.scale.set(...scale as [number, number, number])
  mesh.castShadow = true
  mesh.receiveShadow = true
  parent.add(mesh)
  return mesh
}
function line(parent: THREE.Object3D, points: number[][], color: string, opacity = .7) {
  const geometry = new THREE.BufferGeometry().setFromPoints(points.map(p => new THREE.Vector3(...p as [number, number, number])))
  const object = new THREE.Line(geometry, new THREE.LineBasicMaterial({ color, transparent: true, opacity }))
  parent.add(object)
  return object
}
function branch(parent: THREE.Object3D, from: number[], to: number[], radius: number, color: string) {
  const a = new THREE.Vector3(...from as [number, number, number])
  const b = new THREE.Vector3(...to as [number, number, number])
  const mesh = new THREE.Mesh(new THREE.CylinderGeometry(radius * .55, radius, a.distanceTo(b), 7), material(color))
  mesh.position.copy(a).add(b).multiplyScalar(.5)
  mesh.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), b.sub(a).normalize())
  mesh.castShadow = true
  parent.add(mesh)
}
function pavilion(entity: Entity, root: THREE.Group, wood: string) {
  const [w, h, d] = entity.size
  box(root, [w, .18, d], [0, .09, 0], '#cdb58c')
  for (let x = -w / 2; x < w / 2; x += .24) line(root, [[x, .19, -d / 2], [x, .19, d / 2]], '#988570', .5)
  box(root, [w, h, .17], [0, h / 2, -d / 2], palette.plaster)
  box(root, [.18, h, d], [-w / 2, h / 2, 0], palette.plaster)
  box(root, [.18, h, d], [w / 2, h / 2, 0], wood)
  for (let z = -d / 2; z <= d / 2; z += .19) box(root, [.075, h, .08], [w / 2 + .11, h / 2, z], wood, false)
  const bays = Math.max(2, Math.floor(w / 1.3))
  for (let i = 0; i <= bays; i++) {
    const x = -w / 2 + i * w / bays
    box(root, [.065, h, .12], [x, h / 2, d / 2], palette.dark)
    if (i < bays) box(root, [w / bays - .065, h - .2, .028], [x + w / bays / 2, h / 2, d / 2], palette.glass, false, .22)
  }
  for (const y of [.14, h - .12]) box(root, [w, .085, .12], [0, y, d / 2], palette.dark)
  for (const x of [-w / 2 - .25, w / 2 + .25]) {
    for (const z of [-d / 2, d / 2 + .6]) box(root, [.15, h + .12, .15], [x, (h + .12) / 2, z], wood)
  }
  box(root, [w + 1, .22, .23], [0, h, d / 2 + .6], wood)
  for (let x = -w / 2; x <= w / 2; x += .8) box(root, [.09, .15, d + 1.4], [x, h + .05, 0], palette.dark)
  const roofHalf = d / 2 + .85
  const rise = Math.min(1.3, h * .31)
  const slope = Math.atan2(rise, roofHalf)
  for (const side of [-1, 1]) {
    const roof = box(root, [w + 1.65, .12, Math.hypot(roofHalf, rise)], [0, h + rise / 2 + .2, side * roofHalf / 2], palette.roof)
    roof.rotation.x = side * slope
    for (let x = -w / 2 - .7; x < w / 2 + .8; x += .48) {
      line(root, [[x, h + rise + .265, 0], [x, h + .265, side * roofHalf]], '#354448', .6)
    }
  }
  box(root, [w + 1.75, .14, .16], [0, h + rise + .25, 0], '#3c494c')
  // Furnished interiors remain visible through the sliding glazing.
  box(root, [w * .46, .025, d * .55], [0, .205, .15], '#ded6c1')
  if (w > 5) {
    box(root, [3.5, .4, 1.1], [-2, .52, -.8], '#c8c5b2')
    box(root, [3.5, .55, .25], [-2, .83, -1.24], '#a4aea0')
    for (const x of [-3.65, -.35]) box(root, [.2, .55, 1.1], [x, .79, -.8], '#a4aea0')
    for (let x = -3.15; x <= -1; x += 1.04) box(root, [.97, .14, .87], [x, .77, -.7], '#d6d2bc')
    box(root, [2, .12, .95], [-2, .6, 1.1], palette.dark)
    for (const x of [-2.75, -1.25]) for (const z of [.8, 1.4]) box(root, [.06, .4, .06], [x, .39, z], palette.dark)
    box(root, [.45, .05, .3], [-1.6, .7, 1.1], '#efead8')
    box(root, [2.1, .12, 1.1], [3.4, .98, 0], wood)
    for (const x of [2.6, 4.2]) for (const z of [-.4, .4]) box(root, [.08, .7, .08], [x, .58, z], palette.dark)
    for (const x of [2.7, 4.1]) for (const z of [-.9, .9]) {
      box(root, [.5, .12, .45], [x, .6, z], wood)
      box(root, [.5, .6, .07], [x, .9, z + Math.sign(z) * .2], wood)
      for (const dx of [-.19, .19]) box(root, [.06, .45, .06], [x + dx, .37, z], palette.dark, false)
    }
    box(root, [2, 1.1, .48], [3.3, .73, -d / 2 + .34], wood)
    for (let y = .55; y < 1.4; y += .35) box(root, [1.86, .045, .5], [3.3, y, -d / 2 + .34], palette.dark)
  } else {
    box(root, [w * .65, .15, d * .48], [0, .32, 0], '#bdc3a7')
    box(root, [1.2, .12, .9], [0, .65, .4], palette.dark)
    for (const x of [-.8, .8]) box(root, [.55, .12, .6], [x, .39, .5], '#a09e85')
  }
  for (let x = -w / 2 + .5; x < -w / 2 + Math.min(1.7, w * .35); x += .16) {
    box(root, [.065, h - .1, .09], [x, h / 2, d / 2 + .18], wood, false)
  }
  branch(root, [0, h, 0], [0, h - .65, 0], .015, '#3c3a33')
  sphere(root, [0, h - .85, 0], [.32, .23, .32], '#f1d9a4', 2)
}
function garden(entity: Entity, root: THREE.Group) {
  const [w, , d] = entity.size
  box(root, [w, .14, d], [0, .07, 0], entity.material === 'concrete' ? palette.gravel : materials.find(m => m.id === entity.material)!.color)
  for (const x of [-w / 2, w / 2]) box(root, [.12, .22, d + .15], [x, .06, 0], '#646e5e')
  for (const z of [-d / 2, d / 2]) box(root, [w, .22, .12], [0, .06, z], '#646e5e')
  const rand = seeded(42)
  const gravel = new THREE.InstancedMesh(new THREE.IcosahedronGeometry(.026, 0), material('#9e9f91'), 650)
  const dummy = new THREE.Object3D()
  for (let i = 0; i < 650; i++) {
    dummy.position.set((rand() - .5) * w, .152, (rand() - .5) * d)
    dummy.scale.setScalar(.6 + rand())
    dummy.updateMatrix()
    gravel.setMatrixAt(i, dummy.matrix)
  }
  root.add(gravel)
  for (let z = -d / 2 + .25; z < d / 2; z += .18) {
    line(root, [[-w / 2 + .15, .146, z], [w / 2 - .15, .146, z]], '#acae9e', .4)
  }
  for (const [x, z, scale] of [[-1.7, -.9, .8], [-.7, -1.3, .55], [-2.1, -.1, .4]]) {
    sphere(root, [x, scale * .42 + .15, z], [scale, scale * .8, scale * .73], '#858c7a')
    for (let r = scale + .12; r < scale + .65; r += .14) {
      line(root, Array.from({ length: 65 }, (_, i) => [x + Math.cos(i / 64 * Math.PI * 2) * r, .16, z + Math.sin(i / 64 * Math.PI * 2) * r * .8]), '#939b86', .55)
    }
  }
  for (let i = 0; i < 5; i++) {
    const step = box(root, [.75, .11, .65], [1.2 + Math.sin(i) * .18, .21, -d / 2 + .65 + i * 1.15], '#a5a99b')
    step.rotation.y = Math.sin(i * 2) * .12
  }
  sphere(root, [2.7, .4, -2.1], [.45, .5, .45], '#6c7f52', 2)
}
function tree(entity: Entity, root: THREE.Group) {
  const [w, h] = entity.size
  const rand = seeded(entity.id.length * 136 + entity.rotation * 50)
  branch(root, [0, 0, 0], [.1, h * .66, 0], .16, '#716652')
  for (let i = 0; i < 16; i++) {
    const angle = i * 2.4
    const radius = (.28 + rand() * .28) * w
    const y = h * (.55 + rand() * .34)
    const x = Math.cos(angle) * radius
    const z = Math.sin(angle) * radius
    branch(root, [0, y * .65, 0], [x, y, z], .045 + rand() * .035, '#786a52')
    const colors = entity.material === 'sage' ? ['#7b915c', '#8b9b66', '#9aa774', '#687f55', '#a4b27d'] : Array.from({ length: 5 }, (_, j) => `#${new THREE.Color(materials.find(m => m.id === entity.material)!.color).multiplyScalar(.8 + j * .06).getHexString()}`)
    sphere(root, [x, y, z], [w * .27, w * (.12 + rand() * .05), w * .24], colors[i % colors.length], 2)
  }
  sphere(root, [0, h * .94, 0], [w * .26, w * .16, w * .23], entity.material === 'sage' ? '#92a46d' : materials.find(m => m.id === entity.material)!.color, 2)
}

export function buildEntity(entity: Entity): THREE.Group {
  const root = new THREE.Group()
  root.name = entity.name
  root.userData.entityId = entity.id
  const wood = materials.find(m => m.id === entity.material)!.color
  const [w, h, d] = entity.size
  if (entity.kind === 'pavilion') pavilion(entity, root, wood)
  if (entity.kind === 'garden') garden(entity, root)
  if (entity.kind === 'tree') tree(entity, root)
  if (entity.kind === 'deck') {
    box(root, [w, h, d], [0, h / 2, 0], wood)
    for (let z = -d / 2; z <= d / 2; z += .2) line(root, [[-w / 2, h + .007, z], [w / 2, h + .007, z]], '#6d583f', .56)
    for (let x = -w / 2 + 3; x < w / 2; x += 3.2) line(root, [[x, h + .008, -d / 2], [x, h + .008, d / 2]], '#6d583f', .35)
  }
  if (entity.kind === 'furniture') {
    box(root, [w, .12, d], [0, h * .57, 0], wood)
    box(root, [w, h * .4, .08], [0, h * .83, -d / 2], wood)
    for (const x of [-w / 2 + .15, w / 2 - .15]) for (const z of [-d / 2 + .15, d / 2 - .15]) box(root, [.09, h * .5, .09], [x, h * .25, z], palette.dark)
  }
  if (entity.kind === 'volume') box(root, [w, h, d], [0, h / 2, 0], wood, true, entity.material === 'glass' ? .42 : 1)
  root.position.fromArray(entity.position)
  root.rotation.y = entity.rotation
  root.traverse(child => { child.userData.entityId = entity.id })
  return optimizeGroup(root)
}

export function buildSite(): THREE.Group {
  const root = new THREE.Group()
  box(root, [28, .8, 23], [0, -.75, 0], '#9b9b7b')
  box(root, [27.9, .08, 22.9], [0, -.31, 0], '#a5b28a', false)
  box(root, [24, .25, 19], [0, -.21, -1], '#bdc4a1')
  box(root, [21, .28, 15], [-.5, -.07, -1.5], '#c4c7ac')
  const rand = seeded(331)
  for (let x = -13.8; x < 14; x += .8) {
    for (let y = -.99; y <= -.4; y += .23) box(root, [.78, .21, .27], [x + (y === -.99 ? .15 : 0), y, 11.45], ['#a6a594', '#aaa998', '#b5b3a2'][Math.floor(rand() * 3)], false)
  }
  for (let i = 0; i < 5; i++) box(root, [4.1, .18, .62], [5, -.15 + i * .17, 8.4 - i * .58], '#d0cdbb')
  for (let i = 0; i < 5; i++) {
    box(root, [1.6, .08, .7], [4.6 - i * .5, -.255, 10.8 + i * .7], '#c8c8b7')
  }
  for (const [x, z] of [[-11, 7], [-10, 6], [10, 4.8], [11, 3.7], [10.5, -9], [-11, -8], [-7.5, 7.5]]) {
    for (let i = 0; i < 5; i++) {
      sphere(root, [x + (rand() - .5) * 2, .1 + rand() * .2, z + (rand() - .5) * 1.5], [.5 + rand() * .3, .3 + rand() * .25, .6], ['#768956', '#829260', '#8a9b6a'][i % 3], 1)
    }
    sphere(root, [x + .9, -.05, z + .2], [.5, .4, .55], '#9b9e8b')
  }
  // A stone lantern and timber approach fence define the garden boundary.
  box(root, [.5, .1, .5], [-4.8, .1, 6], '#909885')
  box(root, [.24, .72, .24], [-4.8, .48, 6], '#959d8c')
  box(root, [.48, .38, .48], [-4.8, .99, 6], '#b3b8a8')
  box(root, [.23, .22, .5], [-4.8, .98, 6], '#525b4a')
  const lantern = new THREE.Mesh(new THREE.ConeGeometry(.51, .28, 4), material('#818b77'))
  lantern.position.set(-4.8, 1.3, 6)
  lantern.rotation.y = Math.PI / 4
  root.add(lantern)
  for (let z = -7; z <= 3; z += 1.1) {
    box(root, [.14, 1.2, .14], [-12.3, .35, z], '#8d7955')
    for (const y of [.2, .7]) box(root, [.09, .08, 1.12], [-12.3, y, z + .5], '#8d7955')
  }
  return optimizeGroup(root)
}

function optimizeGroup(root: THREE.Group): THREE.Group {
  root.updateMatrixWorld(true)
  const inverse = root.matrixWorld.clone().invert()
  const batches = new Map<string, { material: THREE.Material; geometries: THREE.BufferGeometry[]; shadow: boolean }>()
  const originals: THREE.Mesh[] = []
  root.traverse(child => {
    if (!(child instanceof THREE.Mesh) || child instanceof THREE.InstancedMesh || Array.isArray(child.material)) return
    const mat = child.material
    if (!(mat instanceof THREE.MeshStandardMaterial) || mat.transparent) return
    const key = mat.color.getHexString()
    if (!batches.has(key)) batches.set(key, { material: mat.clone(), geometries: [], shadow: child.castShadow })
    const geometry = child.geometry.clone().applyMatrix4(inverse.clone().multiply(child.matrixWorld))
    batches.get(key)!.geometries.push(geometry)
    originals.push(child)
  })
  for (const mesh of originals) {
    while (mesh.children.length) {
      const child = mesh.children[0]
      child.applyMatrix4(mesh.matrix)
      root.add(child)
    }
    mesh.removeFromParent()
    mesh.geometry.dispose()
    if (!Array.isArray(mesh.material)) mesh.material.dispose()
  }
  for (const batch of batches.values()) {
    const geometry = mergeGeometries(batch.geometries)
    batch.geometries.forEach(g => g.dispose())
    if (!geometry) continue
    const mesh = new THREE.Mesh(geometry, batch.material)
    mesh.castShadow = batch.shadow
    mesh.receiveShadow = true
    mesh.userData.entityId = root.userData.entityId
    root.add(mesh)
  }
  return root
}

export function buildModel(project: Project): THREE.Group {
  const root = new THREE.Group()
  root.add(buildSite())
  project.entities.filter(e => project.tags[e.tag]).forEach(e => root.add(buildEntity(e)))
  root.traverse(child => { if (child.userData.edge) child.visible = project.edges })
  return root
}
export function disposeObject(root: THREE.Object3D) {
  root.traverse(child => {
    if (child instanceof THREE.Mesh || child instanceof THREE.Line || child instanceof THREE.LineSegments) {
      child.geometry.dispose()
      const mats = Array.isArray(child.material) ? child.material : [child.material]
      mats.forEach(m => m.dispose())
    }
  })
}
