import { useEffect, useRef, useState } from 'react'
import * as THREE from 'three'
import { OrbitControls } from 'three/addons/controls/OrbitControls.js'
import { buildModel, disposeObject } from './geometry'
import { exportObj } from './export'
import type { Project, Vec3 } from './model'
import { standardViews } from './model'

export type Tool = 'select' | 'rectangle' | 'pull' | 'paint' | 'orbit' | 'pan' | 'zoom'
export interface ViewportApi {
  setView: (position: Vec3, target: Vec3) => void
  camera: () => { position: Vec3; target: Vec3 }
  exportObj: () => string
  zoom: (factor: number) => void
}
interface Props {
  project: Project
  selected: string[]
  tool: Tool
  api: React.RefObject<ViewportApi | null>
  onSelect: (id: string | null, additive: boolean) => void
  onRectangle: (a: Vec3, b: Vec3) => void
  onPull: (id: string, height: number) => void
  onPaint: (id: string) => void
  onHint: (hint: string) => void
}

export function Viewport(props: Props) {
  const host = useRef<HTMLDivElement>(null)
  const current = useRef(props)
  current.current = props
  const [error, setError] = useState('')
  const world = useRef<{ scene: THREE.Scene; model: THREE.Group; selection: THREE.Group; sun: THREE.DirectionalLight; axes: THREE.Group; controls: OrbitControls } | null>(null)

  useEffect(() => {
    if (!host.current) return
    const parent = host.current
    let renderer: THREE.WebGLRenderer
    try { renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false, preserveDrawingBuffer: true }) } catch {
      setError('WebGL is unavailable. Enable hardware acceleration and reload to model in 3D.')
      return
    }
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.5))
    renderer.shadowMap.enabled = true
    renderer.shadowMap.type = THREE.PCFSoftShadowMap
    renderer.outputColorSpace = THREE.SRGBColorSpace
    renderer.setClearColor('#dce9e7')
    renderer.domElement.setAttribute('aria-label', '3D modeling viewport')
    renderer.domElement.setAttribute('role', 'img')
    parent.appendChild(renderer.domElement)
    const scene = new THREE.Scene()
    scene.fog = new THREE.Fog('#dce9e7', 75, 180)
    const camera = new THREE.PerspectiveCamera(38, 1, .1, 300)
    camera.position.fromArray(standardViews.Perspective.position)
    const controls = new OrbitControls(camera, renderer.domElement)
    controls.target.fromArray(standardViews.Perspective.target)
    controls.enableDamping = true
    controls.dampingFactor = .15
    controls.minDistance = 3
    controls.maxDistance = 110
    controls.maxPolarAngle = Math.PI * .49
    controls.mouseButtons = { LEFT: null, MIDDLE: THREE.MOUSE.ROTATE, RIGHT: THREE.MOUSE.PAN }
    scene.add(new THREE.HemisphereLight('#f3f6ed', '#b4b9a6', 2.7))
    const sun = new THREE.DirectionalLight('#fff5df', 2.5)
    sun.position.set(-15, 24, 15)
    sun.castShadow = true
    sun.shadow.mapSize.set(2048, 2048)
    Object.assign(sun.shadow.camera, { left: -24, right: 24, top: 24, bottom: -24, near: 1, far: 85 })
    sun.shadow.bias = -.001
    sun.shadow.normalBias = .03
    sun.shadow.radius = 3
    scene.add(sun)
    const ground = new THREE.Mesh(new THREE.PlaneGeometry(500, 500), new THREE.MeshStandardMaterial({ color: '#d4d9c4', roughness: 1 }))
    ground.rotation.x = -Math.PI / 2
    ground.position.y = -1.21
    ground.receiveShadow = true
    scene.add(ground)
    const axes = new THREE.Group()
    const origin = new THREE.Vector3(-14.2, -1.18, 11.7)
    for (const [end, color] of [[new THREE.Vector3(70, -1.18, 11.7), '#c57c78'], [new THREE.Vector3(-14.2, -1.18, -70), '#769577'], [new THREE.Vector3(-14.2, 12, 11.7), '#7493bf']] as const) {
      axes.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints([origin, end]), new THREE.LineBasicMaterial({ color, transparent: true, opacity: .58 })))
    }
    scene.add(axes)
    const model = buildModel(current.current.project)
    scene.add(model)
    const selection = new THREE.Group()
    scene.add(selection)
    world.current = { scene, model, selection, sun, axes, controls }
    props.api.current = {
      setView(position, target) { camera.position.fromArray(position); controls.target.fromArray(target); controls.update() },
      camera() { return { position: camera.position.toArray(), target: controls.target.toArray() } },
      exportObj() { return exportObj(current.current.project) },
      zoom(factor) { camera.position.sub(controls.target).multiplyScalar(factor).add(controls.target); controls.update() },
    }
    const raycaster = new THREE.Raycaster()
    const pointer = new THREE.Vector2()
    const plane = new THREE.Plane(new THREE.Vector3(0, 1, 0), -.7)
    const drawPreview = new THREE.Line(new THREE.BufferGeometry(), new THREE.LineBasicMaterial({ color: '#267fce', depthTest: false }))
    drawPreview.renderOrder = 20
    scene.add(drawPreview)
    let first: Vec3 | null = null
    let down: { x: number; y: number; id: string | null; height: number } | null = null
    function ray(event: PointerEvent) {
      const rect = renderer.domElement.getBoundingClientRect()
      pointer.set((event.clientX - rect.left) / rect.width * 2 - 1, -((event.clientY - rect.top) / rect.height) * 2 + 1)
      raycaster.setFromCamera(pointer, camera)
    }
    function pick() {
      const intersection = raycaster.intersectObjects(world.current!.model.children, true).find(hit => hit.object instanceof THREE.Mesh && typeof hit.object.userData.entityId === 'string')
      return intersection ? String(intersection.object.userData.entityId) : null
    }
    function groundPoint(): Vec3 | null {
      const point = new THREE.Vector3()
      return raycaster.ray.intersectPlane(plane, point) ? [Math.round(point.x * 20) / 20, .7, Math.round(point.z * 20) / 20] : null
    }
    function pointerDown(event: PointerEvent) {
      if (event.button !== 0) return
      ray(event)
      const id = pick()
      down = { x: event.clientX, y: event.clientY, id, height: current.current.project.entities.find(e => e.id === id)?.size[1] ?? 1 }
      if (current.current.tool === 'pull' && id) current.current.onSelect(id, false)
    }
    function pointerMove(event: PointerEvent) {
      ray(event)
      if (first && current.current.tool === 'rectangle') {
        const p = groundPoint()
        if (p) {
          drawPreview.geometry.dispose()
          drawPreview.geometry = new THREE.BufferGeometry().setFromPoints([first, [p[0], .72, first[2]], p, [first[0], .72, p[2]], first].map(p => new THREE.Vector3(...p as Vec3)))
          current.current.onHint(`Rectangle · ${Math.abs(p[0] - first[0]).toFixed(2)} × ${Math.abs(p[2] - first[2]).toFixed(2)} m · Click opposite corner`)
        }
      }
      if (down?.id && current.current.tool === 'pull') {
        const height = Math.max(.05, Math.min(50, down.height + (down.y - event.clientY) * .025))
        current.current.onHint(`Push/Pull · ${height.toFixed(2)} m · Release to apply`)
      }
    }
    function pointerUp(event: PointerEvent) {
      if (event.button !== 0 || !down) return
      ray(event)
      const tool = current.current.tool
      const distance = Math.hypot(down.x - event.clientX, down.y - event.clientY)
      if (tool === 'pull' && down.id && distance > 4) current.current.onPull(down.id, Math.round(Math.max(.05, Math.min(50, down.height + (down.y - event.clientY) * .025)) * 100) / 100)
      else if (distance < 5) {
        const id = pick()
        if (tool === 'select' || tool === 'pull') current.current.onSelect(id, event.shiftKey)
        if (tool === 'paint' && id) current.current.onPaint(id)
        if (tool === 'zoom') props.api.current?.zoom(event.shiftKey ? 1.2 : .8)
        if (tool === 'rectangle') {
          const p = groundPoint()
          if (p) {
            if (first) {
              current.current.onRectangle(first, p)
              first = null
              drawPreview.geometry.dispose()
              drawPreview.geometry = new THREE.BufferGeometry()
            } else {
              first = p
              current.current.onHint('Rectangle · Click the opposite corner. Esc cancels.')
            }
          }
        }
      }
      down = null
    }
    const cancelDrawing = () => {
      if (current.current.tool !== 'rectangle' || first) {
        first = null
        drawPreview.geometry.dispose()
        drawPreview.geometry = new THREE.BufferGeometry()
      }
    }
    const keyDown = (event: KeyboardEvent) => { if (event.key === 'Escape') cancelDrawing() }
    parent.addEventListener('pointerdown', pointerDown)
    parent.addEventListener('pointermove', pointerMove)
    parent.addEventListener('pointerup', pointerUp)
    window.addEventListener('keydown', keyDown)
    const resize = new ResizeObserver(() => {
      const { width, height } = parent.getBoundingClientRect()
      renderer.setSize(width, height)
      camera.aspect = width / height
      camera.updateProjectionMatrix()
    })
    resize.observe(parent)
    let frame = 0
    const animate = () => {
      frame = requestAnimationFrame(animate)
      const tool = current.current.tool
      controls.mouseButtons.LEFT = tool === 'orbit' ? THREE.MOUSE.ROTATE : tool === 'pan' ? THREE.MOUSE.PAN : null
      if (tool !== 'rectangle' && first) cancelDrawing()
      controls.update()
      renderer.render(scene, camera)
    }
    animate()
    return () => {
      cancelAnimationFrame(frame)
      resize.disconnect()
      parent.removeEventListener('pointerdown', pointerDown)
      parent.removeEventListener('pointermove', pointerMove)
      parent.removeEventListener('pointerup', pointerUp)
      window.removeEventListener('keydown', keyDown)
      controls.dispose()
      disposeObject(scene)
      renderer.dispose()
      renderer.domElement.remove()
      world.current = null
      props.api.current = null
    }
  }, [props.api])

  useEffect(() => {
    const state = world.current
    if (!state) return
    state.scene.remove(state.model)
    disposeObject(state.model)
    state.model = buildModel(props.project)
    state.scene.add(state.model)
    state.sun.castShadow = props.project.shadows
    const angle = (props.project.time - 6) / 12 * Math.PI
    state.sun.position.set(Math.cos(angle) * 26, Math.sin(angle) * 25 + 6, 15)
    state.axes.visible = props.project.axes
  }, [props.project])

  useEffect(() => {
    const state = world.current
    if (!state) return
    disposeObject(state.selection)
    state.selection.clear()
    for (const child of state.model.children) {
      if (props.selected.includes(String(child.userData.entityId))) {
        const helper = new THREE.BoxHelper(child, '#2080db')
        helper.material.depthTest = false
        helper.material.transparent = true
        helper.material.opacity = .8
        helper.renderOrder = 10
        state.selection.add(helper)
      }
    }
  }, [props.selected, props.project])

  return <div ref={host} className={`viewport tool-${props.tool}`} data-testid="viewport">{error && <div className="webgl-error">{error}</div>}</div>
}
