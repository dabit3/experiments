import * as THREE from 'three'
import { RoundedBoxGeometry } from 'three/examples/jsm/geometries/RoundedBoxGeometry.js'
import { PART_IDS, type PartId } from '../config'

/**
 * A low-top court sneaker (Air Force 1 silhouette) modelled procedurally from a lofted
 * "last" surface. Every overlay panel — toe cap, mudguard, eyestay, heel counter and the
 * swoosh — is a thin shell offset from that same surface, so the panels always sit flush
 * on the upper no matter how the profile curves are tuned.
 */
export interface SneakerModel {
  root: THREE.Group
  /** Every mesh that belongs to a configurable part, grouped by part. */
  partMeshes: Record<PartId, THREE.Mesh[]>
  /** One shared material per part. */
  materials: Record<PartId, THREE.MeshStandardMaterial>
  /** The plane on the heel tab that carries the engraving texture. */
  engravingMaterial: THREE.MeshStandardMaterial
}

// ---------------------------------------------------------------------------
// 1D profile curves (monotone cubic Hermite through x-sorted control points)
// ---------------------------------------------------------------------------

type Curve1D = (x: number) => number

function profile(points: [number, number][]): Curve1D {
  const xs = points.map((p) => p[0])
  const ys = points.map((p) => p[1])
  const n = points.length
  const h = xs.slice(1).map((x, i) => x - xs[i])
  const d = ys.slice(1).map((y, i) => (y - ys[i]) / h[i])
  // Fritsch–Carlson tangents: no overshoot between control points.
  const m = ys.map((_, i) => {
    if (i === 0) return d[0]
    if (i === n - 1) return d[n - 2]
    if (d[i - 1] * d[i] <= 0) return 0
    const w1 = 2 * h[i] + h[i - 1]
    const w2 = h[i] + 2 * h[i - 1]
    return (w1 + w2) / (w1 / d[i - 1] + w2 / d[i])
  })
  return (x) => {
    if (x <= xs[0]) return ys[0]
    if (x >= xs[n - 1]) return ys[n - 1]
    let i = 0
    while (x > xs[i + 1]) i++
    const t = (x - xs[i]) / h[i]
    const t2 = t * t
    const t3 = t2 * t
    return (
      (2 * t3 - 3 * t2 + 1) * ys[i] +
      (t3 - 2 * t2 + t) * h[i] * m[i] +
      (-2 * t3 + 3 * t2) * ys[i + 1] +
      (t3 - t2) * h[i] * m[i + 1]
    )
  }
}

/** Smoothstep that also accepts reversed edges (a > b). */
function sstep(a: number, b: number, x: number): number {
  const t = THREE.MathUtils.clamp((x - a) / (b - a), 0, 1)
  return t * t * (3 - 2 * t)
}

// ---------------------------------------------------------------------------
// The last: a superelliptic tube swept along x
// ---------------------------------------------------------------------------

const X0 = -1.3
const X1 = 1.45
const BASE_Y = 0.27
/** How far the upper is tucked below its base line into the midsole. */
const DIP = 0.08

/** Height of the upper above its base line: tall padded collar, sloping down the throat. */
const HEIGHT = profile([
  [-1.3, 0.7],
  [-1.27, 0.74],
  [-1.2, 0.76],
  [-1.1, 0.77],
  [-0.95, 0.78],
  [-0.7, 0.78],
  [-0.5, 0.75],
  [-0.3, 0.7],
  [0.0, 0.61],
  [0.3, 0.53],
  [0.6, 0.45],
  [0.9, 0.37],
  [1.15, 0.28],
  [1.35, 0.15],
  [1.45, 0.03],
])

/** Half-width of the upper: a round heel cup, widest over the ball of the foot. */
const WIDTH = profile([
  [-1.3, 0.0],
  [-1.295, 0.1],
  [-1.28, 0.17],
  [-1.25, 0.24],
  [-1.2, 0.3],
  [-1.1, 0.36],
  [-0.95, 0.4],
  [-0.7, 0.43],
  [-0.3, 0.45],
  [0.2, 0.49],
  [0.6, 0.53],
  [0.95, 0.5],
  [1.2, 0.4],
  [1.38, 0.2],
  [1.45, 0.03],
])

/** Superellipse exponent: boxy (flat deck, vertical walls) through the ankle, round at both ends. */
const BOXINESS = profile([
  [-1.3, 2.2],
  [-1.15, 2.8],
  [-0.9, 3.2],
  [-0.5, 3.1],
  [0.0, 2.9],
  [0.6, 2.6],
  [1.1, 2.2],
  [1.45, 2.0],
])

/** Toe spring + a touch of heel lift, applied to the upper and to the sole. */
function lift(x: number): number {
  const toe = Math.max(0, x - 0.55) / 0.9
  const heel = Math.max(0, -x - 1.0) / 0.3
  return 0.24 * toe * toe + 0.06 * heel * heel
}

function baseY(x: number): number {
  return BASE_Y + lift(x)
}

/** Cosine spacing along x clusters rows at the heel and toe where the last curves fastest. */
const xAt = (u: number): number => X0 + ((X1 - X0) * (1 - Math.cos(Math.PI * u))) / 2
const uAt = (x: number): number => Math.acos(1 - 2 * THREE.MathUtils.clamp((x - X0) / (X1 - X0), 0, 1)) / Math.PI

// Foot opening carved into the deck at the ankle, and the throat channel the tongue lies in.
const OPEN_X = -0.8
const OPEN_RX = 0.34
const OPEN_RZ = 0.6
const OPEN_DEPTH = 0.15
const THROAT_X0 = -0.62
const THROAT_X1 = 0.75
const THROAT_DEPTH = 0.06

/** Depth to sink the deck at (x, z / width); `ss` is the height fraction so walls are untouched. */
function carve(x: number, zf: number, ss: number): number {
  const r = Math.hypot((x - OPEN_X) / OPEN_RX, zf / OPEN_RZ)
  const bowl = OPEN_DEPTH * sstep(1, 0.45, r)
  const along = sstep(THROAT_X0 - 0.15, THROAT_X0 + 0.1, x) * (1 - sstep(THROAT_X1 - 0.35, THROAT_X1, x))
  const across = 1 - sstep(0.28, 0.46, Math.abs(zf))
  return Math.max(bowl, THROAT_DEPTH * along * across) * ss * ss * ss
}

/** θ ∈ [0, π] runs from +z over the top to −z. */
function surface(u: number, theta: number, out: THREE.Vector3): THREE.Vector3 {
  const x = xAt(u)
  const p = 2 / BOXINESS(x)
  const c = Math.cos(theta)
  const s = Math.sin(theta)
  const cc = Math.sign(c) * Math.abs(c) ** p
  const ss = Math.abs(s) ** p
  const y = baseY(x) - DIP + (HEIGHT(x) + DIP) * ss - carve(x, cc, ss)
  return out.set(x, y, WIDTH(x) * cc)
}

const _a = new THREE.Vector3()
const _b = new THREE.Vector3()
const _c = new THREE.Vector3()
const _d = new THREE.Vector3()

function normalAt(u: number, theta: number, out: THREE.Vector3): THREE.Vector3 {
  const eu = 0.002
  const et = 0.004
  surface(Math.min(1, u + eu), theta, _a)
  surface(Math.max(0, u - eu), theta, _b)
  surface(u, Math.min(Math.PI, theta + et), _c)
  surface(u, Math.max(0, theta - et), _d)
  _a.sub(_b)
  _c.sub(_d)
  out.crossVectors(_a, _c)
  if (out.lengthSq() < 1e-10) return out.set(u > 0.5 ? 1 : -1, 0, 0)
  return out.normalize()
}

/**
 * θ for a given height fraction of the cross-section (0 = base line, 1 = top ridge).
 * `side` +1 is the +z (lateral) side, −1 the −z side.
 */
function thetaAtHeight(u: number, frac: number, side: 1 | -1): number {
  const p = BOXINESS(xAt(u))
  const f = THREE.MathUtils.clamp(frac, 0, 1)
  const t = Math.asin(f ** (p / 2))
  return side === 1 ? t : Math.PI - t
}

// ---------------------------------------------------------------------------
// Mesh builders
// ---------------------------------------------------------------------------

type PointFn = (i: number, j: number, out: THREE.Vector3) => THREE.Vector3

interface GridBuild {
  positions: number[]
  index: number[]
}

function quad(index: number[], a: number, b: number, c: number, d: number): void {
  index.push(a, b, d, a, d, c)
}

/** A single-sided (i × j) grid; triangles wind so that di × dj is the front normal. */
function skin(build: GridBuild, n: number, m: number, at: PointFn, flip = false): number {
  const base = build.positions.length / 3
  const v = new THREE.Vector3()
  for (let i = 0; i <= n; i++) {
    for (let j = 0; j <= m; j++) {
      at(i, j, v)
      build.positions.push(v.x, v.y, v.z)
    }
  }
  const id = (i: number, j: number): number => base + i * (m + 1) + j
  for (let i = 0; i < n; i++) {
    for (let j = 0; j < m; j++) {
      if (flip) quad(build.index, id(i, j), id(i, j + 1), id(i + 1, j), id(i + 1, j + 1))
      else quad(build.index, id(i, j), id(i + 1, j), id(i, j + 1), id(i + 1, j + 1))
    }
  }
  return base
}

function finishGeometry(build: GridBuild): THREE.BufferGeometry {
  const geom = new THREE.BufferGeometry()
  geom.setAttribute('position', new THREE.Float32BufferAttribute(build.positions, 3))
  geom.setIndex(build.index)
  geom.computeVertexNormals()
  return geom
}

/** Surface on the last over the full (u, θ) domain, capped at the heel and toe ends. */
function lastSurface(n: number, m: number): THREE.BufferGeometry {
  const build: GridBuild = { positions: [], index: [] }
  skin(build, n, m, (i, j, out) => surface(i / n, (j / m) * Math.PI, out))
  const v = new THREE.Vector3()
  for (const [u, flip] of [
    [0, false],
    [1, true],
  ] as const) {
    const ring = build.positions.length / 3
    for (let j = 0; j <= m; j++) {
      surface(u, (j / m) * Math.PI, v)
      build.positions.push(v.x, v.y, v.z)
    }
    const centre = build.positions.length / 3
    surface(u, 0, v)
    build.positions.push(v.x, baseY(xAt(u)) - DIP, 0)
    for (let j = 0; j < m; j++) {
      if (flip) build.index.push(centre, ring + j + 1, ring + j)
      else build.index.push(centre, ring + j, ring + j + 1)
    }
  }
  return finishGeometry(build)
}

interface PatchSpec {
  /** Maps patch coordinates (s, t) ∈ [0,1]² to a (u, θ) position on the last. */
  domain: (s: number, t: number) => [number, number]
  n: number
  m: number
  /** Outward offset of the visible face. */
  raise: number
  /** How deep the shell sinks below the surface (hides the seam). */
  sink?: number
}

/** A closed shell that hugs the last: raised front skin, sunken back skin and four edge walls. */
function patch({ domain, n, m, raise, sink = 0.02 }: PatchSpec): THREE.BufferGeometry {
  const build: GridBuild = { positions: [], index: [] }
  const nrm = new THREE.Vector3()
  const pointAt =
    (offset: number): PointFn =>
    (i, j, out) => {
      const [u, theta] = domain(i / n, j / m)
      surface(u, theta, out)
      normalAt(u, theta, nrm)
      return out.addScaledVector(nrm, offset)
    }
  const front = skin(build, n, m, pointAt(raise))
  const back = skin(build, n, m, pointAt(-sink), true)
  const f = (i: number, j: number): number => front + i * (m + 1) + j
  const b = (i: number, j: number): number => back + i * (m + 1) + j
  for (let i = 0; i < n; i++) {
    quad(build.index, f(i, 0), b(i, 0), f(i + 1, 0), b(i + 1, 0))
    quad(build.index, f(i, m), f(i + 1, m), b(i, m), b(i + 1, m))
  }
  for (let j = 0; j < m; j++) {
    quad(build.index, f(0, j), f(0, j + 1), b(0, j), b(0, j + 1))
    quad(build.index, f(n, j), b(n, j), f(n, j + 1), b(n, j + 1))
  }
  // Mirrored domains (θ decreasing with t) turn the shell inside out; flip the winding
  // so the front skin always faces along the surface normal.
  const [u0, t0] = domain(0.5, 0.5)
  const [u1, t1] = domain(0.5 + 0.5 / n, 0.5)
  const [u2, t2] = domain(0.5, 0.5 + 0.5 / m)
  normalAt(u0, t0, nrm)
  surface(u0, t0, _a)
  surface(u1, t1, _b).sub(_a)
  surface(u2, t2, _c).sub(_a)
  if (_b.cross(_c).dot(nrm) < 0) {
    for (let k = 0; k < build.index.length; k += 3) {
      const tmp = build.index[k + 1]
      build.index[k + 1] = build.index[k + 2]
      build.index[k + 2] = tmp
    }
  }
  return finishGeometry(build)
}

/** A flat lace: a rectangular section swept along `curve`, kept level with `up`. */
function ribbon(curve: THREE.Curve<THREE.Vector3>, up: THREE.Vector3, width: number, thick: number): THREE.BufferGeometry {
  const build: GridBuild = { positions: [], index: [] }
  const p = new THREE.Vector3()
  const tan = new THREE.Vector3()
  const side = new THREE.Vector3()
  const nrm = new THREE.Vector3()
  const corners: [number, number][] = [
    [1, 1],
    [-1, 1],
    [-1, -1],
    [1, -1],
  ]
  const segments = 18
  skin(build, segments, 4, (i, j, out) => {
    const s = i / segments
    curve.getPoint(s, p)
    curve.getTangent(s, tan)
    side.crossVectors(tan, up).normalize()
    nrm.crossVectors(side, tan).normalize()
    const [a, b] = corners[j % 4]
    return out
      .copy(p)
      .addScaledVector(side, (a * width) / 2)
      .addScaledVector(nrm, (b * thick) / 2)
  })
  return finishGeometry(build)
}

/** Footprint of the sole: the last's width plus a lip, as a closed spline. */
function soleShape(margin: number): THREE.Shape {
  const pts: THREE.Vector2[] = []
  const N = 30
  for (let i = 0; i <= N; i++) {
    const x = THREE.MathUtils.lerp(X0 - margin * 0.4, X1 + margin * 0.4, i / N)
    const xi = THREE.MathUtils.clamp(x, X0, X1)
    const w = WIDTH(xi) + margin
    pts.push(new THREE.Vector2(x, w))
  }
  const back = pts.map((p) => new THREE.Vector2(p.x, -p.y)).reverse()
  const shape = new THREE.Shape()
  shape.moveTo(pts[0].x, pts[0].y)
  shape.splineThru(pts.slice(1))
  shape.splineThru(back)
  shape.closePath()
  return shape
}

/** Extrudes a flat sole slab (y from `y0` upwards) and bends it with the toe spring. */
function soleSlab(margin: number, y0: number, depth: number, bevel: number): THREE.BufferGeometry {
  const geom = new THREE.ExtrudeGeometry(soleShape(margin), {
    depth,
    bevelEnabled: bevel > 0,
    bevelThickness: bevel,
    bevelSize: bevel * 0.8,
    bevelSegments: 3,
    curveSegments: 12,
  })
  // Extrude runs along +z; lay it flat so the bevelled cap faces up.
  geom.rotateX(-Math.PI / 2)
  geom.translate(0, y0 + bevel, 0)
  const pos = geom.attributes.position
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i)
    pos.setY(i, pos.getY(i) + lift(THREE.MathUtils.clamp(x, X0, X1)))
  }
  pos.needsUpdate = true
  geom.computeVertexNormals()
  return geom
}

/** Places an object on the last at (u, θ), facing outward. */
function placeOnLast(obj: THREE.Object3D, u: number, theta: number, offset: number): void {
  const p = new THREE.Vector3()
  const nrm = new THREE.Vector3()
  surface(u, theta, p)
  normalAt(u, theta, nrm)
  obj.position.copy(p).addScaledVector(nrm, offset)
  obj.quaternion.setFromUnitVectors(new THREE.Vector3(0, 0, 1), nrm)
}

// ---------------------------------------------------------------------------
// Panel layouts (in x × height-fraction space)
// ---------------------------------------------------------------------------

const TOE_CAP_X = 0.86
const EYELET_XS = [-0.36, -0.2, -0.04, 0.12, 0.28, 0.44, 0.6]
const EYELET_HEIGHT = 0.9

function toeCap(): THREE.BufferGeometry {
  return patch({
    n: 14,
    m: 36,
    raise: 0.024,
    domain: (s, t) => {
      const theta = t * Math.PI
      // Rear edge bows back over the top of the foot.
      const x0 = TOE_CAP_X - 0.08 * Math.sin(theta)
      return [uAt(THREE.MathUtils.lerp(x0, X1, s)), theta]
    },
  })
}

function mudguard(side: 1 | -1): THREE.BufferGeometry {
  const xA = -0.5
  const xB = TOE_CAP_X - 0.03
  return patch({
    n: 22,
    m: 6,
    raise: 0.018,
    domain: (s, t) => {
      // Rounded rear end: the corners are pulled forward, the middle of the edge stays.
      const rear = xA + 0.14 * (1 - Math.sin(Math.PI * t)) ** 2
      const x = THREE.MathUtils.lerp(rear, xB, s)
      const u = uAt(x)
      const top = 0.22 + 0.38 * s ** 1.4
      return [u, thetaAtHeight(u, THREE.MathUtils.lerp(-0.02, top, t), side)]
    },
  })
}

function eyestay(side: 1 | -1): THREE.BufferGeometry {
  const xA = -0.42
  const xB = TOE_CAP_X - 0.03
  return patch({
    n: 20,
    m: 5,
    raise: 0.02,
    domain: (s, t) => {
      const x = THREE.MathUtils.lerp(xA, xB, s)
      const u = uAt(x)
      const bottom = THREE.MathUtils.lerp(0.66, 0.6, s)
      return [u, thetaAtHeight(u, THREE.MathUtils.lerp(bottom, 0.94, t), side)]
    },
  })
}

function heelCounter(side: 1 | -1): THREE.BufferGeometry {
  return patch({
    n: 16,
    m: 14,
    raise: 0.018,
    sink: 0.006,
    domain: (s, t) => {
      // Front edge sweeps back as it rises so the top-front corner is a soft curve.
      const x = THREE.MathUtils.lerp(X0, -0.7 - 0.2 * t * t, s)
      const u = uAt(x)
      // Top edge at an absolute height (tallest at the back) rather than a fraction of the profile.
      const top = Math.min(1, THREE.MathUtils.lerp(0.52, 0.3, s * s) / HEIGHT(x))
      return [u, thetaAtHeight(u, t * top, side)]
    },
  })
}

function swoosh(side: 1 | -1): THREE.BufferGeometry {
  // Centre line in (x, height-fraction): blunt nose low over the mudguard, sweeping back and up.
  const centre = new THREE.CubicBezierCurve(
    new THREE.Vector2(0.72, 0.4),
    new THREE.Vector2(0.42, 0.14),
    new THREE.Vector2(-0.15, 0.26),
    new THREE.Vector2(-0.98, 0.74),
  )
  const halfWidth = (s: number): number => {
    const cap = s < 0.16 ? Math.sqrt(1 - (1 - s / 0.16) ** 2) : 1
    return 0.15 * cap * (1 - s) ** 0.9
  }
  return patch({
    n: 56,
    m: 6,
    raise: 0.03,
    sink: 0.012,
    domain: (s0, t) => {
      const s = s0 ** 1.6
      const c = centre.getPoint(s)
      const f = Math.max(0.04, c.y + (2 * t - 1) * halfWidth(s))
      const u = uAt(c.x)
      return [u, thetaAtHeight(u, f, side)]
    },
  })
}

// ---------------------------------------------------------------------------
// Assembly
// ---------------------------------------------------------------------------

export function buildSneaker(): SneakerModel {
  const root = new THREE.Group()
  const partMeshes = {} as Record<PartId, THREE.Mesh[]>
  const materials = {} as Record<PartId, THREE.MeshStandardMaterial>
  for (const id of PART_IDS) {
    partMeshes[id] = []
    materials[id] = new THREE.MeshStandardMaterial({ roughness: 0.6, metalness: 0 })
  }

  const trim = new THREE.MeshStandardMaterial({ color: 0x15161a, roughness: 0.75, metalness: 0 })
  const lining = new THREE.MeshStandardMaterial({ color: 0x1b1b1f, roughness: 0.95, metalness: 0 })
  const hardware = new THREE.MeshStandardMaterial({ color: 0x2a2b30, roughness: 0.35, metalness: 0.6 })

  const add = (id: PartId, geometry: THREE.BufferGeometry, parent: THREE.Object3D = root): THREE.Mesh => {
    const mesh = new THREE.Mesh(geometry, materials[id])
    mesh.userData.partId = id
    partMeshes[id].push(mesh)
    parent.add(mesh)
    return mesh
  }
  const addMirrored = (id: PartId, build: (side: 1 | -1) => THREE.BufferGeometry): void => {
    add(id, build(1))
    add(id, build(-1))
  }

  // --- Sole unit -------------------------------------------------------------
  add('outsole', soleSlab(0.075, 0, 0.07, 0.01))
  add('sole', soleSlab(0.085, 0.05, 0.15, 0.035))
  // Stitch line where the upper meets the midsole.
  root.add(new THREE.Mesh(soleSlab(0.03, BASE_Y - 0.012, 0.01, 0), trim))
  // Grooves around the midsole wall give the cupsole its moulded look.
  for (const y of [0.12, 0.19]) {
    root.add(new THREE.Mesh(soleSlab(0.088, y, 0.008, 0), trim))
  }

  // --- Upper (base) -----------------------------------------------------------
  add('upper', lastSurface(96, 48))

  // Padded collar ringing the foot opening, and the dark lining inside it.
  const deckY = baseY(OPEN_X) + HEIGHT(OPEN_X)
  const openRz = OPEN_RZ * WIDTH(OPEN_X)
  const collar = new THREE.TorusGeometry(0.3, 0.04, 16, 56)
  collar.rotateX(Math.PI / 2)
  collar.scale((OPEN_RX + 0.005) / 0.3, 1, (openRz + 0.005) / 0.3)
  collar.translate(OPEN_X, deckY - 0.032, 0)
  add('upper', collar)

  const opening = new THREE.Mesh(new THREE.CircleGeometry(1, 48), lining)
  opening.geometry.rotateX(-Math.PI / 2)
  opening.geometry.scale(OPEN_RX * 0.62, 1, openRz * 0.62)
  opening.position.set(OPEN_X, deckY - 0.13, 0)
  root.add(opening)

  // --- Overlays ---------------------------------------------------------------
  add('overlays', toeCap())
  addMirrored('overlays', heelCounter)
  addMirrored('overlays', mudguard)
  addMirrored('overlays', eyestay)
  addMirrored('stripe', swoosh)

  // Perforations across the toe box.
  const holeGeom = new THREE.CircleGeometry(0.0085, 10)
  const holes: THREE.Matrix4[] = []
  const probe = new THREE.Object3D()
  for (const [row, x] of [0.98, 1.08, 1.18, 1.27].entries()) {
    const count = 12 - row * 2
    for (let k = 0; k < count; k++) {
      const theta = THREE.MathUtils.lerp(0.45, Math.PI - 0.45, (k + 0.5) / count)
      placeOnLast(probe, uAt(x), theta, 0.027)
      probe.updateMatrix()
      holes.push(probe.matrix.clone())
    }
  }
  const perforations = new THREE.InstancedMesh(holeGeom, trim, holes.length)
  holes.forEach((mtx, i) => perforations.setMatrixAt(i, mtx))
  root.add(perforations)

  // Eyelets punched into the eyestays.
  const eyeletGeom = new THREE.RingGeometry(0.018, 0.038, 18)
  const eyeletMesh = new THREE.InstancedMesh(eyeletGeom, hardware, EYELET_XS.length * 2)
  const eyelets: { pos: THREE.Vector3; nrm: THREE.Vector3 }[][] = [[], []]
  EYELET_XS.forEach((x, k) => {
    const u = uAt(x)
    for (const side of [1, -1] as const) {
      const theta = thetaAtHeight(u, EYELET_HEIGHT, side)
      placeOnLast(probe, u, theta, 0.026)
      probe.updateMatrix()
      eyeletMesh.setMatrixAt(k * 2 + (side === 1 ? 0 : 1), probe.matrix)
      const nrm = new THREE.Vector3()
      normalAt(u, theta, nrm)
      eyelets[side === 1 ? 0 : 1].push({ pos: probe.position.clone(), nrm })
    }
  })
  root.add(eyeletMesh)

  // --- Tongue -----------------------------------------------------------------
  const throatA = surface(uAt(-0.78), Math.PI / 2, new THREE.Vector3())
  const throatB = surface(uAt(0.7), Math.PI / 2, new THREE.Vector3())
  const throatDir = throatB.clone().sub(throatA)
  const tongueLen = throatDir.length() + 0.06
  const tongueTilt = Math.atan2(throatDir.y, throatDir.x) - 0.14
  const tongueThick = 0.13
  const tongue = new THREE.Group()
  tongue.position.copy(throatA).lerp(throatB, 0.5)
  tongue.position.y += 0.075
  tongue.rotation.z = tongueTilt
  root.add(tongue)
  add('tongue', new RoundedBoxGeometry(tongueLen, tongueThick, 0.44, 4, 0.05), tongue)
  const label = new THREE.Mesh(new RoundedBoxGeometry(0.22, 0.016, 0.24, 2, 0.008), trim)
  label.position.set(-tongueLen / 2 + 0.2, tongueThick / 2, 0)
  tongue.add(label)

  // --- Laces ------------------------------------------------------------------
  const laceWidth = 0.075
  const laceThick = 0.014
  const tongueTopAt = (x: number): number =>
    tongue.position.y + (x - tongue.position.x) * Math.tan(tongueTilt) + tongueThick / 2 / Math.cos(tongueTilt)
  const lace = (a: { pos: THREE.Vector3; nrm: THREE.Vector3 }, b: { pos: THREE.Vector3; nrm: THREE.Vector3 }, clearance: number) => {
    const from = a.pos.clone().addScaledVector(a.nrm, 0.004)
    const to = b.pos.clone().addScaledVector(b.nrm, 0.004)
    const mid = from.clone().lerp(to, 0.5)
    const midX = mid.x
    // Quadratic Bézier passes through (from + 2·ctrl + to) / 4 at its middle.
    const wantY = tongueTopAt(midX) + laceThick / 2 + clearance
    mid.y = 2 * wantY - (from.y + to.y) / 2
    const up = a.nrm.clone().add(b.nrm).add(new THREE.Vector3(0, 1.5, 0)).normalize()
    return ribbon(new THREE.QuadraticBezierCurve3(from, mid, to), up, laceWidth, laceThick)
  }
  for (let k = 0; k < EYELET_XS.length - 1; k++) {
    add('laces', lace(eyelets[0][k], eyelets[1][k + 1], 0.002))
    add('laces', lace(eyelets[1][k], eyelets[0][k + 1], laceThick + 0.004))
  }
  // Straight bar across the top pair of eyelets.
  add('laces', lace(eyelets[0][0], eyelets[1][0], 0.002))

  // --- Heel tab ---------------------------------------------------------------
  const heelTopY = baseY(X0) + HEIGHT(X0)
  const tab = add('heel', new RoundedBoxGeometry(0.05, 0.16, 0.24, 3, 0.02))
  tab.position.set(X0 - 0.028, heelTopY + 0.005, 0)
  tab.rotation.z = 0.12

  const engravingMaterial = new THREE.MeshStandardMaterial({
    transparent: true,
    depthWrite: false,
    polygonOffset: true,
    polygonOffsetFactor: -2,
    polygonOffsetUnits: -2,
    roughness: 0.7,
    metalness: 0,
  })
  const engraving = new THREE.Mesh(new THREE.PlaneGeometry(0.2, 0.12), engravingMaterial)
  engraving.rotation.y = -Math.PI / 2
  engraving.position.set(-0.0255, 0, 0)
  engraving.userData.partId = 'heel'
  partMeshes.heel.push(engraving)
  tab.add(engraving)

  root.position.y = -0.62
  return { root, partMeshes, materials, engravingMaterial }
}
