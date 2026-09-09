import * as THREE from 'three'
import { RoundedBoxGeometry } from 'three/examples/jsm/geometries/RoundedBoxGeometry.js'
import type { PartId } from '../config'

export interface SneakerModel {
  root: THREE.Group
  /** Every mesh that belongs to a configurable part, grouped by part. */
  partMeshes: Record<PartId, THREE.Mesh[]>
  /** One shared material per part. */
  materials: Record<PartId, THREE.MeshStandardMaterial>
  /** The plane on the heel tab that carries the engraving texture. */
  engravingMaterial: THREE.MeshBasicMaterial
}

// The upper is built around this capsule plus a heel cup; the stripe is wrapped onto their surface.
const CAP = { cx: 0.05, cy: 0.42, r: 0.45, halfLen: 0.75, sy: 0.95, sz: 1.15 }
const CUP = { cx: -0.7, rx: 0.37 * 1.05, rz: 0.39 * 1.15, y0: 0.25, y1: 0.85 }

function capsuleSurfaceZ(x: number, y: number): number {
  const lx = x - CAP.cx
  const ly = (y - CAP.cy) / CAP.sy
  const over = Math.max(0, Math.abs(lx) - CAP.halfLen)
  const rEff = Math.sqrt(Math.max(0, CAP.r * CAP.r - over * over))
  return Math.sqrt(Math.max(0, rEff * rEff - ly * ly)) * CAP.sz
}

function cupSurfaceZ(x: number, y: number): number {
  if (y < CUP.y0 || y > CUP.y1) return 0
  const nx = (x - CUP.cx) / CUP.rx
  return CUP.rz * Math.sqrt(Math.max(0, 1 - nx * nx))
}

function upperSurfaceZ(x: number, y: number): number {
  return Math.max(capsuleSurfaceZ(x, y), cupSurfaceZ(x, y))
}

function soleShape(): THREE.Shape {
  const pts: [number, number][] = [
    [-1.35, 0],
    [-1.3, 0.42],
    [-1.0, 0.5],
    [-0.4, 0.46],
    [0.3, 0.55],
    [0.9, 0.58],
    [1.3, 0.4],
    [1.45, 0.05],
    [1.4, -0.3],
    [1.0, -0.55],
    [0.3, -0.55],
    [-0.4, -0.45],
    [-1.0, -0.5],
    [-1.3, -0.42],
  ]
  const shape = new THREE.Shape()
  shape.moveTo(pts[0][0], pts[0][1])
  shape.splineThru(pts.slice(1).map(([x, y]) => new THREE.Vector2(x, y)))
  shape.lineTo(pts[0][0], pts[0][1])
  return shape
}

/**
 * A swoosh-like ribbon between two 2D curves, tessellated finely enough to hug
 * the upper's curved surface. It has a front skin, a back skin sunk into the
 * upper and closed edges so the inverted-hull outline reads as a solid part.
 */
function stripeGeometry(): THREE.BufferGeometry {
  const lower = new THREE.QuadraticBezierCurve(
    new THREE.Vector2(-0.8, 0.56),
    new THREE.Vector2(-0.05, 0.22),
    new THREE.Vector2(0.98, 0.6),
  )
  const upperEdge = new THREE.QuadraticBezierCurve(
    new THREE.Vector2(-0.68, 0.76),
    new THREE.Vector2(0.0, 0.36),
    new THREE.Vector2(0.98, 0.6),
  )
  const N = 48
  const M = 3
  const FRONT = 0.03
  const BACK = -0.03
  const rows = M + 1
  const positions: number[] = []
  const index: number[] = []

  const skin = (offset: number): number => {
    const base = positions.length / 3
    for (let i = 0; i <= N; i++) {
      const a = lower.getPoint(i / N)
      const b = upperEdge.getPoint(i / N)
      for (let j = 0; j <= M; j++) {
        const x = THREE.MathUtils.lerp(a.x, b.x, j / M)
        const y = THREE.MathUtils.lerp(a.y, b.y, j / M)
        positions.push(x, y, upperSurfaceZ(x, y) + offset)
      }
    }
    return base
  }
  const at = (base: number, i: number, j: number): number => base + i * rows + j
  const quad = (a: number, b: number, c: number, d: number): void => {
    index.push(a, b, d, a, d, c)
  }

  const front = skin(FRONT)
  const back = skin(BACK)
  for (let i = 0; i < N; i++) {
    for (let j = 0; j < M; j++) {
      quad(at(front, i, j), at(front, i + 1, j), at(front, i, j + 1), at(front, i + 1, j + 1))
      quad(at(back, i, j), at(back, i, j + 1), at(back, i + 1, j), at(back, i + 1, j + 1))
    }
    quad(at(front, i, 0), at(back, i, 0), at(front, i + 1, 0), at(back, i + 1, 0))
    quad(at(front, i, M), at(front, i + 1, M), at(back, i, M), at(back, i + 1, M))
  }
  for (let j = 0; j < M; j++) {
    quad(at(front, 0, j), at(front, 0, j + 1), at(back, 0, j), at(back, 0, j + 1))
  }

  const geom = new THREE.BufferGeometry()
  geom.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3))
  geom.setIndex(index)
  geom.computeVertexNormals()
  return geom
}

export function buildSneaker(): SneakerModel {
  const root = new THREE.Group()
  const partMeshes: Record<PartId, THREE.Mesh[]> = {
    sole: [],
    upper: [],
    laces: [],
    tongue: [],
    heel: [],
    stripe: [],
  }
  const materials = {} as Record<PartId, THREE.MeshStandardMaterial>
  for (const id of Object.keys(partMeshes) as PartId[]) {
    materials[id] = new THREE.MeshStandardMaterial({ color: 0xffffff, roughness: 0.8 })
  }

  const add = (part: PartId, geom: THREE.BufferGeometry, parent: THREE.Object3D = root) => {
    const mesh = new THREE.Mesh(geom, materials[part])
    mesh.castShadow = true
    mesh.receiveShadow = true
    mesh.userData.partId = part
    partMeshes[part].push(mesh)
    parent.add(mesh)
    return mesh
  }

  // --- Sole ---------------------------------------------------------------
  const soleGeom = new THREE.ExtrudeGeometry(soleShape(), {
    depth: 0.2,
    bevelEnabled: true,
    bevelThickness: 0.05,
    bevelSize: 0.04,
    bevelSegments: 3,
    curveSegments: 16,
  })
  soleGeom.rotateX(-Math.PI / 2)
  soleGeom.translate(0, 0.05, 0)
  add('sole', soleGeom)

  // A thin darker midsole line adds visual depth (not configurable).
  const trim = new THREE.Mesh(
    new THREE.ExtrudeGeometry(soleShape(), { depth: 0.035, bevelEnabled: false, curveSegments: 16 }),
    new THREE.MeshStandardMaterial({ color: 0x2a2a2e, roughness: 0.9 }),
  )
  trim.geometry.rotateX(-Math.PI / 2)
  trim.geometry.scale(0.985, 1, 0.985)
  trim.position.y = 0.3
  trim.receiveShadow = true
  root.add(trim)

  // --- Upper --------------------------------------------------------------
  const body = new THREE.CapsuleGeometry(CAP.r, CAP.halfLen * 2, 8, 32)
  body.rotateZ(Math.PI / 2)
  body.scale(1, CAP.sy, CAP.sz)
  body.translate(CAP.cx, CAP.cy, 0)
  add('upper', body)

  const heelCup = new THREE.CylinderGeometry(0.37, 0.39, CUP.y1 - CUP.y0, 32, 1, false)
  heelCup.scale(1.05, 1, 1.15)
  heelCup.translate(CUP.cx, (CUP.y0 + CUP.y1) / 2, 0)
  add('upper', heelCup)

  const collar = new THREE.TorusGeometry(0.37, 0.07, 12, 32)
  collar.rotateX(Math.PI / 2)
  collar.scale(1.05, 1, 1.15)
  collar.translate(CUP.cx, CUP.y1, 0)
  add('upper', collar)

  // Dark foot opening inside the collar.
  const opening = new THREE.Mesh(
    new THREE.CircleGeometry(0.36, 32),
    new THREE.MeshStandardMaterial({ color: 0x15161a, roughness: 1 }),
  )
  opening.geometry.rotateX(-Math.PI / 2)
  opening.geometry.scale(1.05, 1, 1.15)
  opening.position.set(CUP.cx, CUP.y1 - 0.01, 0)
  root.add(opening)

  // --- Tongue + laces (share a tilted frame) --------------------------------
  const tilt = new THREE.Group()
  tilt.position.set(0.1, 0.83, 0)
  tilt.rotation.z = -0.2
  root.add(tilt)

  const tongueGeom = new RoundedBoxGeometry(0.95, 0.11, 0.44, 3, 0.05)
  add('tongue', tongueGeom, tilt)

  const laceRadius = 0.032
  const laceGeom = new THREE.CapsuleGeometry(laceRadius, 0.42, 4, 12)
  laceGeom.rotateX(Math.PI / 2)
  for (let i = 0; i < 5; i++) {
    const x = -0.36 + i * 0.17
    for (const sign of [1, -1]) {
      const lace = add('laces', laceGeom, tilt)
      lace.position.set(x, 0.055 + laceRadius, 0)
      lace.rotation.y = sign * 0.55
    }
  }
  // Two bow loops at the ankle end.
  const loopGeom = new THREE.TorusGeometry(0.09, laceRadius, 8, 20)
  for (const sign of [1, -1]) {
    const loop = add('laces', loopGeom, tilt)
    loop.position.set(-0.5, 0.06 + laceRadius, sign * 0.12)
    loop.rotation.set(Math.PI / 2 + sign * 0.35, 0, sign * 0.6)
  }

  // --- Heel tab -------------------------------------------------------------
  const tabGeom = new RoundedBoxGeometry(0.12, 0.34, 0.46, 3, 0.03)
  const tab = add('heel', tabGeom)
  tab.position.set(-1.12, 0.7, 0)

  const engravingMaterial = new THREE.MeshBasicMaterial({
    transparent: true,
    depthWrite: false,
    toneMapped: false,
  })
  const label = new THREE.Mesh(new THREE.PlaneGeometry(0.4, 0.29), engravingMaterial)
  label.rotation.y = -Math.PI / 2
  label.position.set(-1.12 - 0.064, 0.7, 0)
  label.userData.partId = 'heel'
  partMeshes.heel.push(label)
  root.add(label)

  // --- Stripe (both sides) ---------------------------------------------------
  const stripeGeom = stripeGeometry()
  add('stripe', stripeGeom)
  const mirrored = add('stripe', stripeGeom)
  mirrored.scale.z = -1

  root.position.y = -0.45
  return { root, partMeshes, materials, engravingMaterial }
}
