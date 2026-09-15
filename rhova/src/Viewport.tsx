import { useEffect, useRef } from 'react'
import * as THREE from 'three'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'
import { buildModel, disposeObject } from './scene'
import type { DisplayMode } from './scene'
import { inversePoint, transformPoint } from './model'
import type { Point, Project } from './model'

export type ViewName = 'Top' | 'Perspective' | 'Front' | 'Right'
type Props = {
  view: ViewName; project: Project; selected: string[]; mode: DisplayMode; active: boolean
  showPoints: boolean; tool: 'select' | 'curve'; draft: Point[]; grid: boolean; snap: boolean
  fit: number; maximized: boolean; pointIndex: number | null
  onActive: () => void; onSelect: (id: string | null, shift: boolean) => void
  onPoint: (index: number) => void; onPointMove: (id: string, index: number, point: Point) => void
  onDraw: (point: Point) => void; onCursor: (point: Point) => void
  onMaximize: () => void; onMode: (mode: DisplayMode) => void
}
type Runtime = { scene: THREE.Scene; camera: THREE.PerspectiveCamera | THREE.OrthographicCamera; controls: OrbitControls; renderer: THREE.WebGLRenderer; model: THREE.Group | null; render: () => void; reset: () => void }

export function Viewport(props: Props) {
  const mount = useRef<HTMLDivElement>(null)
  const latest = useRef(props)
  latest.current = props
  const runtime = useRef<Runtime | null>(null)

  useEffect(() => {
    const element = mount.current
    if (!element) return
    const scene = new THREE.Scene()
    const perspective = props.view === 'Perspective'
    const camera = perspective ? new THREE.PerspectiveCamera(36, 1, 0.1, 500) : new THREE.OrthographicCamera(-40, 40, 30, -30, 0.1, 500)
    camera.up.set(0, 0, 1)
    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, preserveDrawingBuffer: true })
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.5))
    renderer.shadowMap.enabled = perspective
    renderer.shadowMap.type = THREE.PCFSoftShadowMap
    renderer.toneMapping = THREE.ACESFilmicToneMapping
    renderer.toneMappingExposure = 1.25
    element.appendChild(renderer.domElement)
    const controls = new OrbitControls(camera, renderer.domElement)
    controls.enableRotate = perspective
    controls.enableDamping = false
    controls.minDistance = 12
    controls.maxDistance = 180
    controls.maxPolarAngle = Math.PI * 0.49
    controls.zoomSpeed = 0.7
    if (!perspective) controls.mouseButtons.LEFT = THREE.MOUSE.PAN
    const render = () => renderer.render(scene, camera)
    const resize = () => {
      const width = element.clientWidth, height = element.clientHeight
      renderer.setSize(width, height)
      if (camera instanceof THREE.PerspectiveCamera) camera.aspect = width / height
      else {
        const aspect = width / height
        camera.left = -35
        camera.right = 35
        camera.top = 35 / aspect
        camera.bottom = -35 / aspect
      }
      camera.updateProjectionMatrix()
      render()
    }
    const reset = () => {
      if (perspective) { camera.position.set(64, -78, 61); controls.target.set(0, 0, 2) }
      else if (props.view === 'Top') { camera.position.set(0, 0, 120); camera.up.set(0, 1, 0); controls.target.set(0, 0, 0) }
      else if (props.view === 'Front') { camera.position.set(0, -120, 6); controls.target.set(0, 0, 6) }
      else { camera.position.set(120, 0, 6); controls.target.set(0, 0, 6) }
      camera.zoom = 1
      camera.updateProjectionMatrix()
      controls.update()
      render()
    }
    scene.add(new THREE.HemisphereLight('#ffffff', '#c3beb0', 2.3))
    const sun = new THREE.DirectionalLight('#fff5db', 3.8)
    sun.position.set(-25, -35, 65)
    sun.castShadow = true
    sun.shadow.mapSize.set(2048, 2048)
    Object.assign(sun.shadow.camera, { left: -55, right: 55, top: 55, bottom: -55, far: 180 })
    sun.shadow.bias = -0.0003
    sun.shadow.normalBias = 0.06
    scene.add(sun)
    const fill = new THREE.DirectionalLight('#d9eaff', 1.2)
    fill.position.set(40, 20, 40)
    scene.add(fill)
    runtime.current = { scene, camera, renderer, controls, model: null, render, reset }
    reset()
    const observer = new ResizeObserver(resize)
    observer.observe(element)
    controls.addEventListener('change', render)
    const raycaster = new THREE.Raycaster()
    raycaster.params.Line.threshold = 0.2
    const pointer = new THREE.Vector2()
    let start: [number, number] = [0, 0]
    let drag: { id: string; index: number; plane: THREE.Plane; point: Point | null } | null = null
    const ray = (event: PointerEvent) => {
      const bounds = renderer.domElement.getBoundingClientRect()
      pointer.set((event.clientX - bounds.left) / bounds.width * 2 - 1, -(event.clientY - bounds.top) / bounds.height * 2 + 1)
      raycaster.setFromCamera(pointer, camera)
    }
    const planePoint = (plane: THREE.Plane): Point | null => {
      const intersection = raycaster.ray.intersectPlane(plane, new THREE.Vector3())
      if (!intersection) return null
      const point: Point = [intersection.x, intersection.y, intersection.z]
      return latest.current.snap ? point.map(value => Math.round(value * 2) / 2) as Point : point.map(value => Math.round(value * 100) / 100) as Point
    }
    const drawingPlane = () => new THREE.Plane(new THREE.Vector3(...(props.view === 'Front' ? [0, 1, 0] as Point : props.view === 'Right' ? [1, 0, 0] as Point : [0, 0, 1] as Point)), 0)
    const hit = () => {
      const root = runtime.current?.model
      return root ? raycaster.intersectObject(root, true).find(intersection => {
        let node: THREE.Object3D | null = intersection.object
        while (node) {
          if (node.userData.decoration) return false
          node = node.parent
        }
        return true
      }) : undefined
    }
    const down = (event: PointerEvent) => {
      latest.current.onActive()
      start = [event.clientX, event.clientY]
      if (event.button !== 0) return
      ray(event)
      const intersection = hit()
      if (latest.current.showPoints && intersection && typeof intersection.object.userData.pointIndex === 'number') {
        const id = String(intersection.object.userData.entityId)
        const index = Number(intersection.object.userData.pointIndex)
        const entity = latest.current.project.objects.find(object => object.id === id)
        if (!entity) return
        latest.current.onPoint(index)
        const world = transformPoint(entity.points[index], entity)
        const plane = drawingPlane()
        plane.constant = -plane.normal.dot(new THREE.Vector3(...world))
        drag = { id, index, plane, point: null }
        controls.enabled = false
        event.stopImmediatePropagation()
        renderer.domElement.setPointerCapture(event.pointerId)
      }
    }
    const move = (event: PointerEvent) => {
      ray(event)
      const point = planePoint(drag?.plane ?? drawingPlane())
      if (point) latest.current.onCursor(point)
      if (drag && point) {
        drag.point = point
        const entity = latest.current.project.objects.find(object => object.id === drag?.id)
        if (entity) {
          const local = inversePoint(point, entity)
          runtime.current?.model?.traverse(child => {
            if (child.userData.entityId === drag?.id && child.userData.pointIndex === drag?.index) child.position.set(...local)
          })
          render()
        }
      }
    }
    const up = (event: PointerEvent) => {
      if (event.button !== 0) return
      const moved = Math.hypot(event.clientX - start[0], event.clientY - start[1]) > 4
      if (drag) {
        const entity = latest.current.project.objects.find(object => object.id === drag?.id)
        if (drag.point && entity && moved) latest.current.onPointMove(drag.id, drag.index, inversePoint(drag.point, entity))
        drag = null
        controls.enabled = latest.current.tool !== 'curve'
        return
      }
      if (moved) return
      ray(event)
      if (latest.current.tool === 'curve') {
        const point = planePoint(drawingPlane())
        if (point) latest.current.onDraw(point)
        return
      }
      let node: THREE.Object3D | null = hit()?.object ?? null
      while (node && !node.userData.entityId) node = node.parent
      if (node?.userData.entityId) {
        const entity = latest.current.project.objects.find(object => object.id === node?.userData.entityId)
        const layer = latest.current.project.layers.find(layer => layer.id === entity?.layerId)
        if (!layer?.locked) latest.current.onSelect(String(node.userData.entityId), event.shiftKey)
      } else latest.current.onSelect(null, event.shiftKey)
    }
    renderer.domElement.addEventListener('pointerdown', down, true)
    renderer.domElement.addEventListener('pointermove', move)
    renderer.domElement.addEventListener('pointerup', up)
    return () => {
      observer.disconnect()
      controls.dispose()
      renderer.domElement.removeEventListener('pointerdown', down, true)
      renderer.domElement.removeEventListener('pointermove', move)
      renderer.domElement.removeEventListener('pointerup', up)
      disposeObject(scene)
      renderer.dispose()
      element.removeChild(renderer.domElement)
      runtime.current = null
    }
  }, [props.view])

  useEffect(() => {
    const state = runtime.current
    if (!state) return
    if (state.model) { state.scene.remove(state.model); disposeObject(state.model) }
    const root = buildModel(props.project, props.mode, props.selected, props.showPoints)
    if (props.draft.length) {
      const geometry = new THREE.BufferGeometry().setFromPoints(props.draft.map(point => new THREE.Vector3(...point)))
      root.add(new THREE.Line(geometry, new THREE.LineBasicMaterial({ color: '#c68b14', depthTest: false })))
      for (const point of props.draft) {
        const dot = new THREE.Mesh(new THREE.SphereGeometry(0.2, 8, 6), new THREE.MeshBasicMaterial({ color: '#db9f20', depthTest: false }))
        dot.position.set(...point)
        root.add(dot)
      }
    }
    if (props.grid && props.mode === 'Wireframe') {
      const grid = new THREE.GridHelper(180, 90, '#b9bdbb', '#d6d9d6')
      if (props.view === 'Top') grid.rotation.x = Math.PI / 2
      if (props.view === 'Right') grid.rotation.z = Math.PI / 2
      grid.position.set(...(props.view === 'Top' ? [0, 0, -1.5] as Point : props.view === 'Front' ? [0, 2, 0] as Point : [-2, 0, 0] as Point))
      grid.userData.decoration = true
      root.add(grid)
    }
    state.scene.add(root)
    state.model = root
    state.controls.enabled = props.tool !== 'curve'
    state.renderer.toneMappingExposure = props.mode === 'Rendered' ? 1.4 : 1.17
    state.render()
  }, [props.project, props.selected, props.showPoints, props.draft, props.mode, props.grid, props.view, props.tool])
  useEffect(() => runtime.current?.reset(), [props.fit])

  return <section className={`viewport ${props.view.toLowerCase()} ${props.active ? 'active' : ''} ${props.tool === 'curve' ? 'drawing' : ''}`} aria-label={`${props.view} viewport`}>
    <div className="viewport-title">
      <button className="view-name" onClick={props.onActive} onDoubleClick={props.onMaximize}>{props.view}</button>
      <details className="view-dropdown"><summary aria-label={`${props.view} display options`}>⌄</summary><div className="view-menu">
        {(['Wireframe', 'Shaded', 'Rendered'] as DisplayMode[]).map(mode => <button key={mode} onClick={event => { props.onMode(mode); event.currentTarget.closest('details')?.removeAttribute('open') }}>{mode === props.mode ? '✓ ' : ''}{mode}</button>)}
        <button onClick={props.onMaximize}>{props.maximized ? 'Restore four views' : 'Maximize viewport'}</button>
      </div></details>
      <span className="view-mode">{props.mode}</span>
    </div>
    <button className="maximize" title={props.maximized ? 'Restore four views' : `Maximize ${props.view}`} aria-label={props.maximized ? 'Restore four views' : `Maximize ${props.view}`} onClick={props.onMaximize}>⌗</button>
    <div ref={mount} className="canvas-mount" />
    <div className="axis-gizmo"><span className="axis-z">{props.view === 'Top' ? 'Y' : 'Z'}</span><i /><span className="axis-x">{props.view === 'Right' ? 'Y' : 'X'}</span></div>
    <div className="viewport-scale">{props.view === 'Perspective' ? '35 mm  ·  Z up' : 'Meters  ·  1 : 200'}<i /></div>
    {props.view === 'Perspective' && <div className="project-caption"><span>AURELIAN</span><small>MUSEUM OF CONTEMPORARY ART</small></div>}
  </section>
}
