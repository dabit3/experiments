import { useEffect, useRef, type RefObject } from 'react'
import * as THREE from 'three'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'
import { RoomEnvironment } from 'three/examples/jsm/environments/RoomEnvironment.js'
import { mergeVertices } from 'three/examples/jsm/utils/BufferGeometryUtils.js'
import { PART_IDS, type Finish, type PartId, type SneakerConfig, type ViewId } from '../config'
import { makeEngravingTexture } from './engraving'
import { buildSneaker, type SneakerModel } from './sneaker'

export interface ViewerApi {
  /** Fly the camera to one of the preset views. */
  setView: (view: ViewId, animate?: boolean) => void
  /** Render a clean full-resolution frame (no outlines) and return it as a PNG data URL. */
  snapshot: () => string
}

interface Props {
  config: SneakerConfig
  selected: PartId | null
  onSelect: (part: PartId | null) => void
  onHover: (part: PartId | null) => void
  /** Fired when the user orbits manually, so the app can mark the view as "custom". */
  onOrbit: () => void
  /** Fired once the first frame has been drawn (shader compilation can take a moment). */
  onReady: () => void
  apiRef: RefObject<ViewerApi | null>
}

const TARGET = new THREE.Vector3(0.05, 0.02, 0)

const VIEW_POSITIONS: Record<ViewId, THREE.Vector3> = {
  hero: new THREE.Vector3(3.0, 1.5, 3.4),
  side: new THREE.Vector3(0.05, 0.5, 4.8),
  heel: new THREE.Vector3(-4.6, 1.1, 0.7),
  top: new THREE.Vector3(0.05, 4.8, 0.5),
}

// Software/low-end GPUs: draw at reduced resolution while the camera moves,
// then settle on a crisp full-resolution frame once everything is still.
const MOTION_SCALE = 0.5
const IDLE_SCALE = 1

const SELECT_COLOR = new THREE.Color('#ff5a1f')
const HOVER_COLOR = new THREE.Color('#111111')

interface Rig {
  renderer: THREE.WebGLRenderer
  scene: THREE.Scene
  camera: THREE.PerspectiveCamera
  controls: OrbitControls
  model: SneakerModel
  environment: THREE.Texture
  raycaster: THREE.Raycaster
  hull: Record<PartId, THREE.Mesh[]>
  hullMaterial: THREE.MeshBasicMaterial
  hovered: PartId | null
  selected: PartId | null
  tween: { from: THREE.Vector3; to: THREE.Vector3; start: number; duration: number } | null
  /** Set when something changed and a frame must be drawn. */
  dirty: boolean
  /** Current render scale (pixel ratio); dropped while the camera moves. */
  scale: number
  dispose: () => void
}

/**
 * Matte reads as full-grain leather: a broad, dim environment sheen. Gloss is patent leather;
 * metallic is a brushed foil with the environment doing most of the work.
 */
function applyFinish(mat: THREE.MeshStandardMaterial, color: string, finish: Finish, env: THREE.Texture): void {
  mat.color.set(color)
  mat.envMap = env
  switch (finish) {
    case 'matte':
      mat.roughness = 0.58
      mat.metalness = 0
      mat.envMapIntensity = 0.35
      break
    case 'gloss':
      mat.roughness = 0.2
      mat.metalness = 0
      mat.envMapIntensity = 0.55
      break
    case 'metallic':
      mat.roughness = 0.34
      mat.metalness = 0.9
      mat.envMapIntensity = 1.1
      break
  }
  mat.needsUpdate = true
}

function easeInOutCubic(t: number): number {
  return t < 0.5 ? 4 * t * t * t : 1 - (-2 * t + 2) ** 3 / 2
}

function pickPart(hits: THREE.Intersection[]): PartId | null {
  for (const hit of hits) {
    const id = hit.object.userData.partId
    if (typeof id === 'string' && (PART_IDS as readonly string[]).includes(id)) return id as PartId
  }
  return null
}

/** Soft radial shadow blob so the shoe sits on the stage without a shadow-map pass. */
function makeBlobShadow(): THREE.Mesh {
  const size = 256
  const canvas = document.createElement('canvas')
  canvas.width = canvas.height = size
  const ctx = canvas.getContext('2d')
  if (ctx) {
    const g = ctx.createRadialGradient(size / 2, size / 2, size * 0.1, size / 2, size / 2, size / 2)
    g.addColorStop(0, 'rgba(0,0,0,0.34)')
    g.addColorStop(0.55, 'rgba(0,0,0,0.12)')
    g.addColorStop(1, 'rgba(0,0,0,0)')
    ctx.fillStyle = g
    ctx.fillRect(0, 0, size, size)
  }
  const tex = new THREE.CanvasTexture(canvas)
  const mesh = new THREE.Mesh(
    new THREE.PlaneGeometry(4.6, 2.2),
    new THREE.MeshBasicMaterial({ map: tex, transparent: true, depthWrite: false }),
  )
  mesh.rotation.x = -Math.PI / 2
  mesh.position.set(0.05, -0.615, 0)
  mesh.renderOrder = -1
  return mesh
}

/**
 * Inverted-hull outline material: back faces pushed out along smooth vertex normals in a flat
 * colour. Far cheaper than a post-processing outline pass, which matters on software WebGL.
 */
function makeHullMaterial(): THREE.MeshBasicMaterial {
  const mat = new THREE.MeshBasicMaterial({ color: SELECT_COLOR, side: THREE.BackSide, toneMapped: false })
  mat.onBeforeCompile = (shader) => {
    shader.vertexShader = shader.vertexShader.replace(
      '#include <begin_vertex>',
      'vec3 transformed = position + normal * 0.018;',
    )
  }
  return mat
}

function buildHulls(model: SneakerModel, material: THREE.MeshBasicMaterial): Record<PartId, THREE.Mesh[]> {
  const smoothed = new Map<THREE.BufferGeometry, THREE.BufferGeometry>()
  const hull = {} as Record<PartId, THREE.Mesh[]>
  for (const id of PART_IDS) {
    hull[id] = model.partMeshes[id]
      .filter((m) => m.userData.decal !== true)
      .map((m) => {
        let geom = smoothed.get(m.geometry)
        if (!geom) {
          geom = mergeVertices(m.geometry, 1e-4)
          geom.computeVertexNormals()
          smoothed.set(m.geometry, geom)
        }
        const h = new THREE.Mesh(geom, material)
        h.visible = false
        h.raycast = () => {}
        h.position.copy(m.position)
        h.rotation.copy(m.rotation)
        h.scale.copy(m.scale)
        m.parent?.add(h)
        return h
      })
  }
  return hull
}

function refreshHulls(rig: Rig): void {
  rig.hullMaterial.color.copy(rig.selected ? SELECT_COLOR : HOVER_COLOR)
  for (const id of PART_IDS) {
    const show = id === rig.selected || (rig.selected === null && id === rig.hovered)
    for (const h of rig.hull[id]) h.visible = show
  }
  rig.dirty = true
}

function createRig(container: HTMLDivElement): Rig {
  const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'high-performance' })
  renderer.setClearColor(0x000000, 0)
  renderer.toneMapping = THREE.ACESFilmicToneMapping
  renderer.toneMappingExposure = 1.0
  container.appendChild(renderer.domElement)

  const scene = new THREE.Scene()
  const pmrem = new THREE.PMREMGenerator(renderer)
  const environment = pmrem.fromScene(new RoomEnvironment(), 0.04).texture
  pmrem.dispose()

  const camera = new THREE.PerspectiveCamera(38, 1, 0.1, 100)
  camera.position.copy(VIEW_POSITIONS.hero)
  camera.lookAt(TARGET)

  const controls = new OrbitControls(camera, renderer.domElement)
  controls.target.copy(TARGET)
  controls.enableDamping = true
  controls.dampingFactor = 0.1
  controls.minDistance = 2.4
  controls.maxDistance = 9
  controls.maxPolarAngle = Math.PI * 0.52
  controls.enablePan = false
  controls.autoRotateSpeed = 2.2

  // Studio setup: large soft key high front-right, cool fill from the back-left, a low rim
  // grazing the heel, and a bright hemisphere so shadows stay open like a product shoot.
  const key = new THREE.DirectionalLight(0xfff4e6, 1.7)
  key.position.set(3, 5.5, 3.5)
  scene.add(key)
  const fill = new THREE.DirectionalLight(0xdde6ff, 0.75)
  fill.position.set(-4, 2.5, -3)
  scene.add(fill)
  const rim = new THREE.DirectionalLight(0xffffff, 0.55)
  rim.position.set(-3, 1.2, 4)
  scene.add(rim)
  const top = new THREE.DirectionalLight(0xffffff, 0.45)
  top.position.set(0, 6, -1)
  scene.add(top)
  scene.add(new THREE.HemisphereLight(0xffffff, 0xcfc9c0, 1.05))

  scene.add(makeBlobShadow())

  const model = buildSneaker()
  scene.add(model.root)

  const hullMaterial = makeHullMaterial()
  const hull = buildHulls(model, hullMaterial)

  const dispose = () => {
    controls.dispose()
    renderer.dispose()
    scene.traverse((obj) => {
      if (obj instanceof THREE.Mesh) {
        obj.geometry.dispose()
        const mats = Array.isArray(obj.material) ? obj.material : [obj.material]
        mats.forEach((m) => m.dispose())
      }
    })
    renderer.domElement.remove()
  }

  return {
    renderer,
    scene,
    camera,
    controls,
    model,
    environment,
    raycaster: new THREE.Raycaster(),
    hull,
    hullMaterial,
    hovered: null,
    selected: null,
    tween: null,
    dirty: true,
    scale: IDLE_SCALE,
    dispose,
  }
}

export function SneakerViewer({ config, selected, onSelect, onHover, onOrbit, onReady, apiRef }: Props) {
  const containerRef = useRef<HTMLDivElement>(null)
  const rigRef = useRef<Rig | null>(null)
  const callbacks = useRef({ onSelect, onHover, onOrbit, onReady })
  useEffect(() => {
    callbacks.current = { onSelect, onHover, onOrbit, onReady }
  }, [onSelect, onHover, onOrbit, onReady])

  // Build the scene once.
  useEffect(() => {
    const container = containerRef.current
    if (!container) return
    const rig = createRig(container)
    rigRef.current = rig

    const setScale = (scale: number) => {
      if (rig.scale === scale) return
      rig.scale = scale
      const { clientWidth: w, clientHeight: h } = container
      rig.renderer.setPixelRatio(scale)
      rig.renderer.setSize(w, h, false)
    }
    const resize = () => {
      const { clientWidth: w, clientHeight: h } = container
      if (w === 0 || h === 0) return
      rig.camera.aspect = w / h
      rig.camera.updateProjectionMatrix()
      rig.renderer.setPixelRatio(rig.scale)
      rig.renderer.setSize(w, h, false)
      rig.dirty = true
    }
    resize()
    const ro = new ResizeObserver(resize)
    ro.observe(container)

    const allMeshes = (Object.values(rig.model.partMeshes) as THREE.Mesh[][]).flat()
    const pointer = new THREE.Vector2()
    const toNdc = (e: PointerEvent) => {
      const rect = rig.renderer.domElement.getBoundingClientRect()
      pointer.set(((e.clientX - rect.left) / rect.width) * 2 - 1, -((e.clientY - rect.top) / rect.height) * 2 + 1)
    }
    const castAt = (e: PointerEvent): PartId | null => {
      toNdc(e)
      rig.raycaster.setFromCamera(pointer, rig.camera)
      return pickPart(rig.raycaster.intersectObjects(allMeshes, false))
    }

    let down: { x: number; y: number; t: number } | null = null
    const setHovered = (part: PartId | null) => {
      if (part === rig.hovered) return
      rig.hovered = part
      rig.renderer.domElement.style.cursor = part ? 'pointer' : 'grab'
      refreshHulls(rig)
      callbacks.current.onHover(part)
    }

    const el = rig.renderer.domElement
    const onPointerDown = (e: PointerEvent) => {
      if (e.button !== 0) return
      down = { x: e.clientX, y: e.clientY, t: performance.now() }
      el.style.cursor = 'grabbing'
    }
    const onPointerMove = (e: PointerEvent) => {
      if (down) {
        if (Math.hypot(e.clientX - down.x, e.clientY - down.y) > 6) {
          rig.tween = null
          callbacks.current.onOrbit()
          setHovered(null)
        }
        return
      }
      setHovered(castAt(e))
    }
    const onPointerUp = (e: PointerEvent) => {
      if (!down) return
      const moved = Math.hypot(e.clientX - down.x, e.clientY - down.y)
      const elapsed = performance.now() - down.t
      down = null
      el.style.cursor = rig.hovered ? 'pointer' : 'grab'
      if (moved <= 6 && elapsed < 600) callbacks.current.onSelect(castAt(e))
    }
    const onPointerLeave = () => setHovered(null)
    el.addEventListener('pointerdown', onPointerDown)
    el.addEventListener('pointermove', onPointerMove)
    el.addEventListener('pointerup', onPointerUp)
    el.addEventListener('pointerleave', onPointerLeave)
    el.style.cursor = 'grab'

    let lastCameraMove = 0
    const onControlsChange = () => {
      rig.dirty = true
      lastCameraMove = performance.now()
    }
    rig.controls.addEventListener('change', onControlsChange)

    let frame = 0
    let ready = false
    const loop = (now: number) => {
      frame = requestAnimationFrame(loop)
      const t = rig.tween
      if (t) {
        const k = Math.min(1, (now - t.start) / t.duration)
        rig.camera.position.lerpVectors(t.from, t.to, easeInOutCubic(k))
        if (k >= 1) rig.tween = null
        rig.dirty = true
        lastCameraMove = now
      }
      rig.controls.update()
      const moving = rig.tween !== null || rig.controls.autoRotate || now - lastCameraMove < 160
      if (moving) {
        setScale(MOTION_SCALE)
        rig.dirty = true
      } else if (rig.scale !== IDLE_SCALE) {
        setScale(IDLE_SCALE)
        rig.dirty = true
      }
      if (!rig.dirty) return
      rig.dirty = false
      rig.renderer.render(rig.scene, rig.camera)
      if (!ready) {
        ready = true
        callbacks.current.onReady()
      }
    }
    frame = requestAnimationFrame(loop)

    apiRef.current = {
      setView: (view, animate = true) => {
        const to = VIEW_POSITIONS[view]
        if (!animate) {
          rig.camera.position.copy(to)
          rig.tween = null
          rig.dirty = true
          return
        }
        rig.tween = { from: rig.camera.position.clone(), to, start: performance.now(), duration: 750 }
      },
      snapshot: () => {
        const shown = (Object.values(rig.hull) as THREE.Mesh[][]).flat().filter((h) => h.visible)
        shown.forEach((h) => (h.visible = false))
        setScale(IDLE_SCALE)
        rig.renderer.render(rig.scene, rig.camera)
        const url = rig.renderer.domElement.toDataURL('image/png')
        shown.forEach((h) => (h.visible = true))
        rig.dirty = true
        return url
      },
    }

    return () => {
      cancelAnimationFrame(frame)
      ro.disconnect()
      rig.controls.removeEventListener('change', onControlsChange)
      el.removeEventListener('pointerdown', onPointerDown)
      el.removeEventListener('pointermove', onPointerMove)
      el.removeEventListener('pointerup', onPointerUp)
      el.removeEventListener('pointerleave', onPointerLeave)
      apiRef.current = null
      rig.dispose()
      rigRef.current = null
    }
  }, [apiRef])

  // Part colours + finishes.
  useEffect(() => {
    const rig = rigRef.current
    if (!rig) return
    for (const id of PART_IDS) {
      const { color, finish } = config.parts[id]
      applyFinish(rig.model.materials[id], color, finish, rig.environment)
    }
    rig.dirty = true
  }, [config.parts])

  // Engraving texture.
  useEffect(() => {
    const rig = rigRef.current
    if (!rig) return
    const tex = makeEngravingTexture(config.text, config.parts.heel.color)
    const old = rig.model.engravingMaterial.map
    rig.model.engravingMaterial.map = tex
    rig.model.engravingMaterial.needsUpdate = true
    old?.dispose()
    rig.dirty = true
  }, [config.text, config.parts.heel.color])

  // Autorotate.
  useEffect(() => {
    const rig = rigRef.current
    if (!rig) return
    rig.controls.autoRotate = config.spin
    rig.dirty = true
  }, [config.spin])

  // Selection outline.
  useEffect(() => {
    const rig = rigRef.current
    if (!rig) return
    rig.selected = selected
    refreshHulls(rig)
  }, [selected])

  return <div ref={containerRef} className="viewer-canvas" />
}
