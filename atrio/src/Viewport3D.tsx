import { useEffect, useRef, useState } from 'react'
import * as THREE from 'three'
import { OrbitControls } from 'three/addons/controls/OrbitControls.js'
import type { Combination, Project } from './model'
import { buildCampus, disposeScene } from './scene'

export type CameraPreset = 'Axonometry' | 'Courtyard' | 'Top'
type Props = {
  project: Project
  selected: string | null
  onSelect: (id: string | null) => void
  combination: Combination
  cutaway: boolean
  appearance: string
  camera: CameraPreset
  sun: string
  fit: number
}
type Engine = {
  scene: THREE.Scene
  camera: THREE.OrthographicCamera
  controls: OrbitControls
  renderer: THREE.WebGLRenderer
  campus: THREE.Group | null
  elements: Map<string, THREE.Group>
  highlight: THREE.Box3Helper
  sun: THREE.DirectionalLight
}

export default function Viewport3D(props: Props) {
  const mount = useRef<HTMLDivElement>(null)
  const engine = useRef<Engine | null>(null)
  const onSelect = useRef(props.onSelect)
  const [failed, setFailed] = useState(false)
  onSelect.current = props.onSelect
  useEffect(() => {
    if (!mount.current) return
    const host = mount.current
    const scene = new THREE.Scene()
    scene.background = new THREE.Color('#edf0ec')
    const camera = new THREE.OrthographicCamera(-50, 50, 40, -40, .1, 500)
    camera.position.set(66, 60, 75)
    let renderer: THREE.WebGLRenderer
    try {
      renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false })
    } catch { setFailed(true); return }
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.5))
    renderer.shadowMap.enabled = true
    renderer.shadowMap.type = THREE.PCFSoftShadowMap
    renderer.outputColorSpace = THREE.SRGBColorSpace
    renderer.toneMapping = THREE.ACESFilmicToneMapping
    renderer.toneMappingExposure = 1.3
    host.appendChild(renderer.domElement)
    renderer.domElement.setAttribute('aria-label', 'Interactive 3D campus. Drag to orbit, scroll to zoom, click geometry to select.')
    const controls = new OrbitControls(camera, renderer.domElement)
    controls.target.set(0, 0, 0)
    controls.enableDamping = true
    controls.dampingFactor = .12
    controls.maxPolarAngle = Math.PI * .47
    controls.minZoom = .45
    controls.maxZoom = 5
    controls.update()
    scene.add(new THREE.HemisphereLight('#fff8e7', '#a4aaa1', 2.3))
    const sun = new THREE.DirectionalLight('#fff4d8', 3.4)
    sun.position.set(-30, 55, 25)
    sun.castShadow = true
    sun.shadow.mapSize.set(2048, 2048)
    Object.assign(sun.shadow.camera, { left: -65, right: 65, top: 60, bottom: -60, near: 1, far: 170 })
    sun.shadow.camera.updateProjectionMatrix()
    sun.shadow.normalBias = .12
    sun.shadow.bias = -.0002
    sun.shadow.radius = 3
    scene.add(sun)
    const ground = new THREE.Mesh(new THREE.PlaneGeometry(2000, 2000), new THREE.MeshStandardMaterial({ color: '#edf0e9', roughness: 1 }))
    ground.rotation.x = -Math.PI / 2
    ground.position.y = -1.17
    ground.receiveShadow = true
    scene.add(ground)
    const highlight = new THREE.Box3Helper(new THREE.Box3(), new THREE.Color('#228aff'))
    highlight.visible = false
    scene.add(highlight)
    engine.current = { scene, camera, controls, renderer, campus: null, elements: new Map(), highlight, sun }
    const resize = () => {
      const { width, height } = host.getBoundingClientRect()
      const aspect = width / height
      const span = Math.max(37, 49 / aspect)
      camera.left = -span * aspect
      camera.right = span * aspect
      camera.top = span
      camera.bottom = -span
      camera.updateProjectionMatrix()
      renderer.setSize(width, height)
    }
    const observer = new ResizeObserver(resize)
    observer.observe(host)
    resize()
    let frame = 0
    const animate = () => { controls.update(); renderer.render(scene, camera); frame = requestAnimationFrame(animate) }
    animate()
    let down = { x: 0, y: 0 }
    const start = (event: PointerEvent) => { down = { x: event.clientX, y: event.clientY } }
    const select = (event: PointerEvent) => {
      if (Math.hypot(event.clientX - down.x, event.clientY - down.y) > 5 || event.button !== 0) return
      const rect = host.getBoundingClientRect()
      const pointer = new THREE.Vector2((event.clientX - rect.left) / rect.width * 2 - 1, -(event.clientY - rect.top) / rect.height * 2 + 1)
      const raycaster = new THREE.Raycaster()
      raycaster.setFromCamera(pointer, camera)
      const roots = engine.current ? [...engine.current.elements.values()] : []
      const hit = raycaster.intersectObjects(roots, true)[0]
      let obj: THREE.Object3D | null = hit?.object ?? null
      while (obj && !obj.userData.elementId) obj = obj.parent
      onSelect.current(typeof obj?.userData.elementId === 'string' ? obj.userData.elementId : null)
    }
    renderer.domElement.addEventListener('pointerdown', start)
    renderer.domElement.addEventListener('pointerup', select)
    return () => {
      cancelAnimationFrame(frame)
      observer.disconnect()
      controls.dispose()
      disposeScene(scene)
      renderer.dispose()
      host.removeChild(renderer.domElement)
      engine.current = null
    }
  }, [])
  useEffect(() => {
    const e = engine.current
    if (!e) return
    if (e.campus) { e.scene.remove(e.campus); disposeScene(e.campus) }
    const { root, elements } = buildCampus(props.project, props.combination, props.cutaway, props.appearance)
    e.scene.add(root)
    e.campus = root
    e.elements = elements
  }, [props.project, props.combination, props.cutaway, props.appearance])
  useEffect(() => {
    const e = engine.current
    if (!e) return
    const selected = props.selected ? e.elements.get(props.selected) : undefined
    e.highlight.visible = Boolean(selected)
    if (selected) e.highlight.box.setFromObject(selected)
  }, [props.project, props.combination, props.cutaway, props.appearance, props.selected])
  useEffect(() => {
    const e = engine.current
    if (!e) return
    const positions: Record<CameraPreset, [number, number, number]> = { Axonometry: [66, 60, 75], Courtyard: [44, 25, 60], Top: [0, 95, .01] }
    e.camera.position.set(...positions[props.camera])
    e.controls.target.set(0, 0, 0)
    e.camera.zoom = 1
    e.camera.updateProjectionMatrix()
    e.controls.update()
  }, [props.camera, props.fit])
  useEffect(() => {
    const e = engine.current
    if (!e) return
    e.sun.position.set(props.sun === 'Morning' ? 40 : -30, props.sun === 'Evening' ? 20 : 55, 25)
    e.sun.color.set(props.sun === 'Evening' ? '#ffd5a0' : '#fff4d8')
  }, [props.sun])
  return <div className="canvas-3d" ref={mount}>{failed && <div className="webgl-error">WebGL is unavailable in this browser. The Floor Plan remains fully editable.</div>}</div>
}
