import { useEffect, useRef, useImperativeHandle, forwardRef } from 'react'
import * as THREE from 'three'
import { OrbitControls } from 'three/addons/controls/OrbitControls.js'
import { TransformControls } from 'three/addons/controls/TransformControls.js'
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js'
import { buildObject, applyTransform, readTransform, disposeGroup } from './geometry'
import { defaultCameras, sampleObject, type CameraBookmark, type Project, type SceneObject } from './model'

export type Shading = 'material' | 'solid' | 'wireframe'
export type Tool = 'select' | 'translate' | 'rotate' | 'scale'
export interface ViewportHandle {
  capture: () => Promise<Blob>
  bookmark: () => CameraBookmark
  home: () => void
}
interface Props {
  project: Project
  selected: string | null
  shading: Shading
  tool: Tool
  grid: boolean
  camera: CameraBookmark
  frame: number
  animate: boolean
  exposure: number
  onSelect: (id: string | null) => void
  onTransform: (id: string, transform: Pick<SceneObject, 'position' | 'rotation' | 'scale'>) => void
  onReady: () => void
  onError: (message: string) => void
}
interface Engine {
  scene: THREE.Scene
  renderer: THREE.WebGLRenderer
  camera: THREE.PerspectiveCamera
  controls: OrbitControls
  transform: TransformControls
  groups: Map<string, THREE.Group>
  selection: THREE.Group
  grid: THREE.GridHelper
  axes: THREE.AxesHelper
}
export default forwardRef<ViewportHandle, Props>(function Viewport(props, ref) {
  const container = useRef<HTMLDivElement>(null)
  const engine = useRef<Engine | null>(null)
  const latest = useRef(props)
  latest.current = props
  useImperativeHandle(ref, () => ({
    capture: () => new Promise((resolve, reject) => {
      const e = engine.current
      if (!e) return reject(new Error('The viewport is not ready.'))
      const grid = e.grid.visible
      const axes = e.axes.visible
      e.grid.visible = false
      e.axes.visible = false
      e.selection.visible = false
      e.transform.getHelper().visible = false
      e.renderer.render(e.scene, e.camera)
      e.renderer.domElement.toBlob(blob => {
        e.grid.visible = grid
        e.axes.visible = axes
        e.selection.visible = true
        e.transform.getHelper().visible = latest.current.tool !== 'select'
        if (blob) resolve(blob)
        else reject(new Error('Image export failed.'))
      }, 'image/png')
    }),
    bookmark: () => {
      const e = engine.current
      return e ? { name: 'Saved view', position: e.camera.position.toArray(), target: e.controls.target.toArray() } : defaultCameras[0]
    },
    home: () => {
      const e = engine.current
      if (e) {
        e.camera.position.set(...defaultCameras[0].position)
        e.controls.target.set(...defaultCameras[0].target)
        e.controls.update()
      }
    },
  }), [])
  useEffect(() => {
    if (!container.current) return
    const host = container.current
    let renderer: THREE.WebGLRenderer
    try {
      renderer = new THREE.WebGLRenderer({ antialias: true, preserveDrawingBuffer: true })
    } catch {
      latest.current.onError('WebGL is unavailable. Enable browser hardware acceleration to use the 3D viewport.')
      return
    }
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.7))
    renderer.shadowMap.enabled = true
    renderer.shadowMap.type = THREE.PCFSoftShadowMap
    renderer.toneMapping = THREE.ACESFilmicToneMapping
    renderer.toneMappingExposure = 1.15
    renderer.setClearColor('#333330')
    host.appendChild(renderer.domElement)
    const scene = new THREE.Scene()
    const pmrem = new THREE.PMREMGenerator(renderer)
    const room = new RoomEnvironment()
    const env = pmrem.fromScene(room, 0.04)
    scene.environment = env.texture
    scene.environmentIntensity = 0.32
    room.dispose()
    pmrem.dispose()
    const hemi = new THREE.HemisphereLight('#dedacf', '#534334', 1.8)
    scene.add(hemi)
    const sun = new THREE.DirectionalLight('#ffdea3', 4.2)
    sun.position.set(-3, 10, 7)
    sun.castShadow = true
    sun.shadow.mapSize.set(2048, 2048)
    Object.assign(sun.shadow.camera, { left: -10, right: 10, top: 10, bottom: -10, near: 0.1, far: 40 })
    sun.shadow.bias = -0.0003
    sun.shadow.normalBias = 0.025
    sun.shadow.radius = 3
    scene.add(sun)
    const fill = new THREE.DirectionalLight('#d7e2ee', 1.15)
    fill.position.set(8, 5, -2)
    scene.add(fill)
    const interior = new THREE.PointLight('#ffc279', 13, 7, 2)
    interior.position.set(-2.8, 2.7, -2)
    scene.add(interior)
    const ground = new THREE.Mesh(new THREE.PlaneGeometry(200, 200), new THREE.ShadowMaterial({ opacity: 0.24 }))
    ground.rotation.x = -Math.PI / 2
    ground.position.y = -0.35
    ground.receiveShadow = true
    scene.add(ground)
    const grid = new THREE.GridHelper(60, 60, '#69665d', '#454640')
    grid.position.y = -0.34
    scene.add(grid)
    const axes = new THREE.AxesHelper(10)
    axes.position.set(0, -0.32, 0)
    scene.add(axes)
    const camera = new THREE.PerspectiveCamera(36, 1, 0.1, 200)
    camera.position.set(...defaultCameras[0].position)
    const controls = new OrbitControls(camera, renderer.domElement)
    controls.target.set(...defaultCameras[0].target)
    controls.enableDamping = true
    controls.dampingFactor = 0.1
    controls.minDistance = 3
    controls.maxDistance = 55
    controls.maxPolarAngle = Math.PI * 0.49
    controls.mouseButtons = { LEFT: THREE.MOUSE.ROTATE, MIDDLE: THREE.MOUSE.DOLLY, RIGHT: THREE.MOUSE.PAN }
    controls.update()
    const transform = new TransformControls(camera, renderer.domElement)
    transform.setSize(0.78)
    transform.setSpace('world')
    const helper = transform.getHelper()
    scene.add(helper)
    transform.addEventListener('dragging-changed', event => { controls.enabled = !event.value })
    transform.addEventListener('mouseUp', () => {
      if (transform.object) latest.current.onTransform(transform.object.userData.objectId as string, readTransform(transform.object))
    })
    const selection = new THREE.Group()
    scene.add(selection)
    const e: Engine = { renderer, scene, camera, controls, transform, groups: new Map(), selection, grid, axes }
    engine.current = e
    const resize = new ResizeObserver(() => {
      const { width, height } = host.getBoundingClientRect()
      renderer.setSize(width, height)
      camera.aspect = width / Math.max(height, 1)
      camera.updateProjectionMatrix()
    })
    resize.observe(host)
    const raycaster = new THREE.Raycaster()
    let down = [0, 0]
    const onDown = (event: PointerEvent) => { down = [event.clientX, event.clientY] }
    const onUp = (event: PointerEvent) => {
      if (event.button !== 0 || Math.hypot(event.clientX - down[0], event.clientY - down[1]) > 5 || transform.axis) return
      const bounds = renderer.domElement.getBoundingClientRect()
      const pointer = new THREE.Vector2((event.clientX - bounds.left) / bounds.width * 2 - 1, -(event.clientY - bounds.top) / bounds.height * 2 + 1)
      raycaster.setFromCamera(pointer, camera)
      const hits = raycaster.intersectObjects([...e.groups.values()].filter(g => g.visible), true)
      if (hits[0]) {
        let target = hits[0].object
        while (target.parent && !target.userData.objectId) target = target.parent
        latest.current.onSelect(target.userData.objectId as string)
      } else latest.current.onSelect(null)
    }
    renderer.domElement.addEventListener('pointerdown', onDown)
    renderer.domElement.addEventListener('pointerup', onUp)
    renderer.domElement.addEventListener('webglcontextlost', () => latest.current.onError('The graphics context was lost. Reload to recover the saved project.'))
    let raf = 0
    const loop = () => {
      controls.update()
      if (latest.current.animate) {
        for (const o of latest.current.project.objects) {
          const group = e.groups.get(o.id)
          if (group && o.keyframes.length) applyTransform(group, sampleObject(o, latest.current.frame))
        }
      }
      const selected = e.groups.get(latest.current.selected ?? '')
      if (selected) {
        selection.position.copy(selected.position)
        selection.rotation.copy(selected.rotation)
        selection.scale.copy(selected.scale)
      }
      renderer.render(scene, camera)
      raf = requestAnimationFrame(loop)
    }
    loop()
    latest.current.onReady()
    return () => {
      cancelAnimationFrame(raf)
      resize.disconnect()
      renderer.domElement.removeEventListener('pointerdown', onDown)
      renderer.domElement.removeEventListener('pointerup', onUp)
      controls.dispose()
      transform.dispose()
      disposeGroup(scene)
      env.dispose()
      renderer.dispose()
      renderer.domElement.remove()
      engine.current = null
    }
  }, [])
  useEffect(() => {
    const e = engine.current
    if (!e) return
    e.transform.detach()
    for (const group of e.groups.values()) { e.scene.remove(group); disposeGroup(group) }
    e.groups.clear()
    for (const object of props.project.objects) {
      const group = buildObject(object)
      applyTransform(group, object)
      group.visible = object.visible
      if (props.shading !== 'material') group.traverse(child => {
        if (child instanceof THREE.Mesh) {
          const previous = child.material
          child.material = new THREE.MeshStandardMaterial({ color: '#c2c4c5', roughness: 0.75, wireframe: props.shading === 'wireframe' })
          if (Array.isArray(previous)) previous.forEach(m => m.dispose())
          else previous.dispose()
        }
      })
      e.groups.set(object.id, group)
      e.scene.add(group)
    }
  }, [props.project.objects, props.shading])
  useEffect(() => {
    const e = engine.current
    if (!e) return
    disposeGroup(e.selection)
    e.selection.clear()
    const group = e.groups.get(props.selected ?? '')
    e.transform.detach()
    if (group?.visible) {
      group.traverse(child => {
        if (child instanceof THREE.Mesh) {
          const edge = new THREE.LineSegments(new THREE.EdgesGeometry(child.geometry, 32), new THREE.LineBasicMaterial({ color: '#f58b31', transparent: true, opacity: 0.85 }))
          edge.position.copy(child.position)
          edge.rotation.copy(child.rotation)
          edge.scale.copy(child.scale)
          e.selection.add(edge)
        }
      })
      if (props.tool !== 'select') {
        e.transform.setMode(props.tool)
        e.transform.attach(group)
      }
    }
  }, [props.selected, props.tool, props.project.objects, props.shading])
  useEffect(() => {
    const e = engine.current
    if (e) {
      e.camera.position.set(...props.camera.position)
      e.controls.target.set(...props.camera.target)
      e.controls.update()
    }
  }, [props.camera])
  useEffect(() => {
    const e = engine.current
    if (e) {
      e.grid.visible = props.grid
      e.axes.visible = props.grid
      e.renderer.toneMappingExposure = props.exposure
    }
  }, [props.grid, props.exposure])
  useEffect(() => {
    const e = engine.current
    if (!e) return
    for (const o of props.project.objects) {
      const group = e.groups.get(o.id)
      if (group) applyTransform(group, props.animate ? sampleObject(o, props.frame) : o)
    }
  }, [props.animate, props.frame, props.project.objects])
  return <div className="webgl" ref={container} aria-label="Interactive 3D architectural loft" data-testid="viewport" />
})
