import { useEffect, useRef, useState } from 'react'
import * as THREE from 'three'
import { OrbitControls } from 'three/addons/controls/OrbitControls.js'
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js'
import { Maximize2, Minimize2 } from 'lucide-react'
import { type Project, sample } from './model'
import { applyTransform, buildObject, disposeGroup } from './geometry'

export type ViewName = 'Top' | 'Front' | 'Left' | 'Perspective'
const views: ViewName[] = ['Top', 'Front', 'Left', 'Perspective']
interface Props {
  project: Project
  selected: string | null
  frame: number
  active: ViewName
  maximized: boolean
  grid: boolean
  lighting: 'Studio' | 'Daylight'
  cameraReset: number
  onSelect: (id: string | null) => void
  onActive: (view: ViewName) => void
  onMaximize: () => void
}

export function Viewport(props: Props) {
  const host = useRef<HTMLDivElement>(null)
  const current = useRef(props)
  current.current = props
  const sceneRef = useRef<THREE.Group | null>(null)
  const wiresRef = useRef<THREE.Group | null>(null)
  const [error, setError] = useState('')

  useEffect(() => {
    const el = host.current!
    let renderer: THREE.WebGLRenderer
    try {
      renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false, powerPreference: 'high-performance' })
    } catch {
      setError('WebGL is unavailable. Enable hardware acceleration and reload.')
      return
    }
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.5))
    renderer.shadowMap.enabled = true
    renderer.shadowMap.type = THREE.PCFSoftShadowMap
    renderer.toneMapping = THREE.ACESFilmicToneMapping
    renderer.toneMappingExposure = 0.92
    el.prepend(renderer.domElement)
    renderer.domElement.setAttribute(
      'aria-label',
      'Four synchronized 3D viewports. Click objects to select; drag Perspective to orbit; scroll to zoom.',
    )
    const scene = new THREE.Scene()
    const wireScene = new THREE.Scene()
    const models = new THREE.Group()
    const wireModels = new THREE.Group()
    scene.add(models)
    wireScene.add(wireModels)
    sceneRef.current = models
    wiresRef.current = wireModels
    const pmrem = new THREE.PMREMGenerator(renderer)
    const room = new RoomEnvironment()
    const environment = pmrem.fromScene(room, 0.04)
    scene.environment = environment.texture
    scene.environmentIntensity = 0.5
    room.dispose()
    pmrem.dispose()
    const ambient = new THREE.HemisphereLight('#d8e5e4', '#8e7761', 1.25)
    scene.add(ambient)
    const sun = new THREE.DirectionalLight('#fff0d1', 2.4)
    sun.position.set(-11, 14, 5)
    sun.castShadow = true
    sun.shadow.mapSize.set(2048, 2048)
    sun.shadow.camera.left = -17
    sun.shadow.camera.right = 17
    sun.shadow.camera.top = 17
    sun.shadow.camera.bottom = -17
    sun.shadow.camera.far = 55
    sun.shadow.normalBias = 0.025
    sun.shadow.bias = -0.0002
    scene.add(sun)
    const fill = new THREE.DirectionalLight('#e9f1ff', 0.65)
    fill.position.set(8, 8, -5)
    scene.add(fill)
    for (const z of [-6, 1, 7]) {
      const lamp = new THREE.PointLight('#ffe0ab', 30, 12, 2)
      lamp.position.set(0, 5.1, z)
      scene.add(lamp)
    }
    const ground = new THREE.Mesh(
      new THREE.PlaneGeometry(200, 200),
      new THREE.MeshStandardMaterial({ color: '#797f76', roughness: 1 }),
    )
    ground.rotation.x = -Math.PI / 2
    ground.position.y = -0.31
    ground.receiveShadow = true
    scene.add(ground)
    const shadedGrid = new THREE.GridHelper(60, 60, '#929990', '#878d82')
    for (const material of Array.isArray(shadedGrid.material) ? shadedGrid.material : [shadedGrid.material]) {
      material.transparent = true
      material.opacity = 0.18
    }
    shadedGrid.position.y = -0.29
    scene.add(shadedGrid)
    const wireGrid = new THREE.GridHelper(100, 100, '#555958', '#3c4141')
    wireScene.add(wireGrid)
    const perspective = new THREE.PerspectiveCamera(42, 1, 0.1, 250)
    const ortho = () => new THREE.OrthographicCamera(-14, 14, 10, -10, 0.1, 150)
    const top = ortho(),
      front = ortho(),
      left = ortho()
    top.position.set(0, 50, 0)
    top.up.set(0, 0, -1)
    top.lookAt(0, 0, 0)
    front.position.set(0, 2.7, 50)
    front.lookAt(0, 2.7, 0)
    left.position.set(50, 2.7, 0)
    left.lookAt(0, 2.7, 0)
    const cameras = [top, front, left, perspective]
    const controls = new OrbitControls(perspective, renderer.domElement)
    controls.enableDamping = true
    controls.dampingFactor = 0.13
    controls.minDistance = 3
    controls.maxDistance = 65
    controls.maxPolarAngle = Math.PI * 0.49
    const resetCamera = () => {
      perspective.position.set(5.8, 4.4, 13.8)
      controls.target.set(0, 2.5, -2.3)
      controls.update()
    }
    resetCamera()
    let resetVersion = current.current.cameraReset
    const box = new THREE.Box3()
    const selection = new THREE.Box3Helper(box, '#fbd761')
    const wireSelection = new THREE.Box3Helper(box, '#fbd761')
    for (const helper of [selection, wireSelection]) {
      for (const material of Array.isArray(helper.material) ? helper.material : [helper.material])
        material.depthTest = false
    }
    scene.add(selection)
    wireScene.add(wireSelection)
    const axes = new THREE.AxesHelper(1.6)
    const wireAxes = new THREE.AxesHelper(1.6)
    scene.add(axes)
    wireScene.add(wireAxes)
    const raycaster = new THREE.Raycaster()
    const mouse = new THREE.Vector2()
    let dirty = true
    let lastState: Props | null = null
    let pointerStart = [0, 0]
    const getRect = (index: number) => {
      const width = el.clientWidth,
        height = el.clientHeight
      if (current.current.maximized) return { x: 0, y: 0, width, height }
      return {
        x: ((index % 2) * width) / 2,
        y: (Math.floor(index / 2) * height) / 2,
        width: width / 2,
        height: height / 2,
      }
    }
    const indexAt = (event: PointerEvent | WheelEvent) => {
      if (current.current.maximized) return views.indexOf(current.current.active)
      const r = el.getBoundingClientRect()
      return (event.clientX - r.left >= r.width / 2 ? 1 : 0) + (event.clientY - r.top >= r.height / 2 ? 2 : 0)
    }
    const down = (event: PointerEvent) => {
      const index = indexAt(event)
      controls.enabled = index === 3
      current.current.onActive(views[index])
      pointerStart = [event.clientX, event.clientY]
    }
    const up = (event: PointerEvent) => {
      if (event.button !== 0 || Math.hypot(event.clientX - pointerStart[0], event.clientY - pointerStart[1]) > 5) return
      const index = indexAt(event)
      const rect = getRect(index),
        bounds = el.getBoundingClientRect()
      mouse.set(
        ((event.clientX - bounds.left - rect.x) / rect.width) * 2 - 1,
        (-(event.clientY - bounds.top - rect.y) / rect.height) * 2 + 1,
      )
      raycaster.setFromCamera(mouse, cameras[index])
      const hits = raycaster.intersectObjects(models.children, true).filter((hit) => {
        let o: THREE.Object3D | null = hit.object
        while (o) {
          if (!o.visible) return false
          o = o.parent
        }
        return true
      })
      current.current.onSelect(hits[0]?.object.userData.objectId ?? null)
    }
    const wheel = (event: WheelEvent) => {
      dirty = true
      const index = indexAt(event)
      controls.enabled = index === 3
      if (index < 3) {
        event.preventDefault()
        const camera = cameras[index] as THREE.OrthographicCamera
        camera.zoom = Math.max(0.3, Math.min(8, camera.zoom * (event.deltaY < 0 ? 1.1 : 0.9)))
        camera.updateProjectionMatrix()
      }
    }
    renderer.domElement.addEventListener('pointerdown', down, { capture: true })
    renderer.domElement.addEventListener('pointerup', up)
    renderer.domElement.addEventListener('wheel', wheel, { passive: false, capture: true })
    const resize = new ResizeObserver(() => {
      renderer.setSize(el.clientWidth, el.clientHeight)
      dirty = true
    })
    resize.observe(el)
    let animation = 0,
      lastTime = 0
    function render(time: number) {
      animation = requestAnimationFrame(render)
      if (time - lastTime < 30) return
      lastTime = time
      const state = current.current
      if (resetVersion !== state.cameraReset) {
        resetVersion = state.cameraReset
        resetCamera()
        for (const c of [top, front, left]) {
          c.zoom = 1
          c.updateProjectionMatrix()
        }
      }
      const cameraMoved = controls.update()
      if (!dirty && !cameraMoved && state === lastState) return
      dirty = false
      lastState = state
      for (let i = 0; i < state.project.objects.length; i++) {
        const object = state.project.objects[i],
          solid = models.children[i],
          wire = wireModels.children[i]
        if (solid && wire) {
          const t = sample(object, state.frame)
          applyTransform(solid, t)
          applyTransform(wire, t)
        }
      }
      const selected = models.children.find((o) => o.userData.objectId === state.selected && o.visible)
      selection.visible = wireSelection.visible = axes.visible = wireAxes.visible = !!selected
      if (selected) {
        box.setFromObject(selected)
        axes.position.copy(selected.position)
        wireAxes.position.copy(selected.position)
      }
      sun.intensity = state.lighting === 'Studio' ? 2.4 : 3.5
      scene.environmentIntensity = state.lighting === 'Studio' ? 0.5 : 0.8
      shadedGrid.visible = state.grid
      wireGrid.visible = state.grid
      renderer.setScissorTest(true)
      for (let i = 0; i < 4; i++) {
        if (state.maximized && views[i] !== state.active) continue
        const r = getRect(i),
          camera = cameras[i]
        renderer.setViewport(r.x, el.clientHeight - r.y - r.height, r.width, r.height)
        renderer.setScissor(r.x, el.clientHeight - r.y - r.height, r.width, r.height)
        if (camera instanceof THREE.PerspectiveCamera) camera.aspect = r.width / r.height
        else {
          const vertical = i === 0 ? 12.4 : 9.4
          camera.left = (-vertical * r.width) / r.height
          camera.right = (vertical * r.width) / r.height
          camera.top = vertical
          camera.bottom = -vertical
        }
        camera.updateProjectionMatrix()
        if (i === 3) {
          renderer.setClearColor('#a3aaa1')
          renderer.render(scene, camera)
        } else {
          wireGrid.rotation.set(i === 1 ? Math.PI / 2 : 0, 0, i === 2 ? Math.PI / 2 : 0)
          renderer.setClearColor('#303636')
          renderer.render(wireScene, camera)
        }
      }
    }
    animation = requestAnimationFrame(render)
    return () => {
      cancelAnimationFrame(animation)
      resize.disconnect()
      controls.dispose()
      renderer.domElement.removeEventListener('pointerdown', down, { capture: true })
      renderer.domElement.removeEventListener('pointerup', up)
      renderer.domElement.removeEventListener('wheel', wheel, { capture: true })
      disposeGroup(scene)
      disposeGroup(wireScene)
      environment.dispose()
      renderer.dispose()
      renderer.domElement.remove()
      sceneRef.current = null
      wiresRef.current = null
    }
  }, [])

  useEffect(() => {
    const models = sceneRef.current,
      wires = wiresRef.current
    if (!models || !wires) return
    disposeGroup(models)
    disposeGroup(wires)
    models.clear()
    wires.clear()
    for (const object of props.project.objects) {
      const model = buildObject(object)
      models.add(model)
      const wire = new THREE.Group()
      model.updateMatrixWorld(true)
      const inverse = model.matrixWorld.clone().invert()
      model.traverse((child) => {
        if (!(child instanceof THREE.Mesh)) return
        const geometry =
          child.geometry.type === 'TorusGeometry' ||
          child.geometry.type === 'TubeGeometry' ||
          child.geometry.type === 'SphereGeometry'
            ? new THREE.WireframeGeometry(child.geometry)
            : new THREE.EdgesGeometry(child.geometry, 12)
        const color =
          object.category === 'Sculptures' ? '#bcab80' : object.category === 'Landscape' ? '#7d9a68' : '#819b99'
        const line = new THREE.LineSegments(
          geometry,
          new THREE.LineBasicMaterial({ color, transparent: true, opacity: object.id === props.selected ? 1 : 0.67 }),
        )
        line.applyMatrix4(inverse.clone().multiply(child.matrixWorld))
        wire.add(line)
      })
      wire.visible = object.visible
      applyTransform(wire, object)
      wires.add(wire)
    }
  }, [props.project, props.selected])

  return (
    <div className={`viewport-host ${props.maximized ? 'maximized' : ''}`} ref={host}>
      {error && (
        <div className="webgl-error" role="alert">
          {error}
        </div>
      )}
      {views.map((view, i) => (
        <div
          key={view}
          className={`view-overlay view-${i} ${view === props.active ? 'active' : ''} ${props.maximized && view !== props.active ? 'hidden' : ''}`}
        >
          <div className="view-label">
            <span>[+]</span>
            <b>{view}</b>
            <span>[Standard]</span>
            <span>[{i === 3 ? 'Default Shading' : 'Wireframe'}]</span>
          </div>
          <button
            className="view-max"
            title={`${props.maximized ? 'Restore four viewports' : `Maximize ${view}`} (Alt+W)`}
            aria-label={`${props.maximized ? 'Restore four viewports' : `Maximize ${view}`}`}
            onClick={() => {
              props.onActive(view)
              props.onMaximize()
            }}
          >
            {props.maximized ? <Minimize2 size={12} /> : <Maximize2 size={12} />}
          </button>
          <div className="view-cube">
            <span>{i === 3 ? 'FRONT' : view.toUpperCase()}</span>
            <i>N</i>
          </div>
          <div className="axis-indicator">
            <span className="axis-y">Y</span>
            <span className="axis-z">Z</span>
            <span className="axis-x">X</span>
          </div>
          {i === 3 && (
            <div className="scene-caption">
              <b>FORMA</b>
              <span>GALLERY / STUDY 01</span>
            </div>
          )}
          {i === 3 && <div className="view-hint">Drag to orbit · Scroll to zoom</div>}
        </div>
      ))}
    </div>
  )
}
