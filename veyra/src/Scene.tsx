import { useEffect, useRef, useState } from 'react'
import * as THREE from 'three'
import { OrbitControls } from 'three/addons/controls/OrbitControls.js'
import { isWall, localPoint, wallSegments } from './model'
import type { Element, Material, Project } from './model'

const palette: Record<Material, string> = { Concrete: '#d6d5cc', Limestone: '#e7dfca', Timber: '#a77443', Glass: '#abc9cc', Plaster: '#ede9dd', Metal: '#54646b' }
export type CameraAction = { type: 'home' | 'top' | 'front' | 'right' | 'in' | 'out'; tick: number }
type Runtime = { scene: THREE.Scene; model: THREE.Group; camera: THREE.OrthographicCamera; controls: OrbitControls; renderer: THREE.WebGLRenderer }

function material(color: string, glass = false) {
  return new THREE.MeshStandardMaterial({ color, roughness: glass ? .18 : .83, metalness: glass ? .23 : .02, transparent: glass, opacity: glass ? .38 : 1, side: THREE.DoubleSide, depthWrite: !glass })
}
function box(group: THREE.Group, size: number[], pos: number[], mat: THREE.Material, id?: string) {
  const mesh = new THREE.Mesh(new THREE.BoxGeometry(size[0], size[1], size[2]), mat)
  mesh.position.set(pos[0], pos[1], pos[2])
  mesh.castShadow = true
  mesh.receiveShadow = true
  mesh.userData.elementId = id || group.userData.elementId
  group.add(mesh)
  return mesh
}
function sphere(group: THREE.Group, radius: number, pos: number[], mat: THREE.Material, detail = 2) {
  const mesh = new THREE.Mesh(new THREE.IcosahedronGeometry(radius, detail), mat)
  mesh.position.set(pos[0], pos[1], pos[2])
  mesh.castShadow = true
  mesh.receiveShadow = true
  mesh.userData.elementId = group.userData.elementId
  group.add(mesh)
  return mesh
}
function tree(group: THREE.Group, x: number, z: number, scale = 1, hue = 0) {
  const trunkMat = material('#77715a')
  const leaf = material(['#728269', '#879271', '#98a17d'][hue % 3])
  const trunk = new THREE.Mesh(new THREE.CylinderGeometry(.11 * scale, .17 * scale, 2.5 * scale, 7), trunkMat)
  trunk.position.set(x, 1.15 * scale, z)
  trunk.castShadow = true
  trunk.userData.elementId = group.userData.elementId
  group.add(trunk)
  for (let i = 0; i < 7; i++) {
    const angle = i * 2.4
    const mesh = sphere(group, (i ? .87 : 1.2) * scale, [x + Math.cos(angle) * (i ? .78 : 0) * scale, (2.9 + (i % 3) * .35) * scale, z + Math.sin(angle) * (i ? .75 : 0) * scale], leaf)
    mesh.scale.y = 1.25
  }
}
function person(group: THREE.Group, x: number, z: number, base = 0, color = '#52636b') {
  const clothing = material(color)
  const skin = material('#bf9e82')
  const head = sphere(group, .12, [x, base + 1.62, z], skin)
  head.castShadow = true
  box(group, [.31, .58, .22], [x, base + 1.17, z], clothing)
  const left = box(group, [.12, .69, .13], [x - .10, base + .49, z + .08], clothing)
  left.rotation.x = .15
  const right = box(group, [.12, .69, .13], [x + .10, base + .49, z - .08], clothing)
  right.rotation.x = -.15
  box(group, [.11, .52, .12], [x - .24, base + 1.12, z], clothing).rotation.z = -.18
  box(group, [.11, .52, .12], [x + .24, base + 1.12, z], clothing).rotation.z = .18
}
function buildElement(e: Element, project: Project) {
  const group = new THREE.Group()
  group.name = e.id
  group.userData.elementId = e.id
  group.position.set(e.x, e.y, e.z)
  group.rotation.y = -e.rotation
  const mat = material(palette[e.material], e.material === 'Glass')
  const steel = material('#667779')
  const wood = material('#ae8252')
  if (isWall(e)) {
    const openings = project.elements.filter(d => d.hostId === e.id).map(d => ({ door: d, start: localPoint(e, d).x - d.w / 2, end: localPoint(e, d).x + d.w / 2 })).sort((a, b) => a.start - b.start)
    for (const segment of wallSegments(e, project)) box(group, [segment.width, segment.height, e.d], [segment.x, segment.y, 0], mat)
    if (e.category === 'Curtain Wall') {
      const count = Math.ceil(e.w / 1.5)
      for (let i = 0; i <= count; i++) {
        const x = -e.w / 2 + e.w * i / count
        const opening = openings.find(o => x > o.start && x < o.end)
        const base = opening?.door.h ?? 0
        box(group, [.055, e.h - base, .09], [x, (e.h + base) / 2, .04], steel)
      }
      box(group, [e.w, .055, .09], [0, e.h - .03, .04], steel)
      if (e.h > 4.5) box(group, [e.w, .09, .09], [0, 4.2, .04], steel)
    }
  } else if (e.category === 'Timber Fins') {
    for (let i = 0; i <= Math.floor(e.w / .46); i++) box(group, [.11, e.h, e.d], [-e.w / 2 + i * .46, e.h / 2, 0], mat)
  } else if (e.category === 'Door') {
    box(group, [e.w - .08, e.h - .06, .055], [0, e.h / 2, .06], mat)
    for (const x of [-e.w / 2, e.w / 2]) box(group, [.07, e.h, .18], [x, e.h / 2, .03], steel)
    box(group, [e.w, .07, .18], [0, e.h, .03], steel)
    box(group, [.055, .35, .07], [e.w / 2 - .16, 1, .15], steel)
    if (e.w > 2) box(group, [.055, e.h, .1], [0, e.h / 2, .08], steel)
  } else if (e.category === 'Furniture') {
    if (e.id.startsWith('table')) {
      box(group, [e.w, .09, e.d], [0, e.h - .045, 0], mat)
      for (const x of [-e.w / 2 + .12, e.w / 2 - .12]) for (const z of [-e.d / 2 + .12, e.d / 2 - .12]) box(group, [.06, e.h, .06], [x, e.h / 2, z], steel)
      for (const x of [-.6, .6]) for (const z of [-1, 1]) {
        box(group, [.45, .06, .45], [x, .42, z], wood)
        box(group, [.45, .45, .06], [x, .66, z + Math.sign(z) * .2], wood)
      }
    } else {
      box(group, [e.w, e.h, e.d], [0, e.h / 2, 0], mat)
      if (e.id.startsWith('art')) {
        const sculpture = sphere(group, .46, [0, e.h + .47, 0], material('#767a73'), 0)
        sculpture.scale.set(.55, 1.5, .7)
      }
    }
  } else if (e.category !== 'Landscape') {
    box(group, [e.w, e.h, e.d], [0, e.h / 2, 0], mat)
    if (e.category === 'Floor' && e.y > 3) {
      for (const x of [-e.w / 2 + .45, e.w / 2 - .45]) {
        box(group, [.14, e.y, .14], [x, -e.y / 2, e.d / 2 - .45], steel)
      }
    }
    if (e.id === 'roof-02') {
      box(group, [e.w - .8, .12, e.d - .8], [0, e.h + .06, 0], material('#92997c'))
      for (let i = 0; i < 4; i++) box(group, [e.w - 2, .05, .72], [0, e.h + .14, -5 + i * 3], material('#d0c4a6'))
      for (const x of [-e.w / 2 + .13, e.w / 2 - .13]) box(group, [.15, .4, e.d], [x, e.h + .2, 0], mat)
      for (const z of [-e.d / 2 + .13, e.d / 2 - .13]) box(group, [e.w, .4, .15], [0, e.h + .2, z], mat)
      for (let i = 0; i < 12; i++) sphere(group, .32, [-e.w / 2 + .8, e.h + .3, -8 + i * 1.4], material('#707e5b'), 1).scale.y = .6
    }
    if (e.id === 'roof-01') {
      for (let i = 0; i < 3; i++) {
        box(group, [3.3, .18, 2.3], [-5 + i * 5, e.h + .08, -2], steel)
        box(group, [3.16, .06, 2.16], [-5 + i * 5, e.h + .20, -2], material('#a5bdbe'))
        box(group, [.06, .09, 2.16], [-5 + i * 5, e.h + .23, -2], steel)
      }
      for (let i = 0; i < 5; i++) box(group, [.016, .012, e.d], [-8 + i * 4, e.h + .01, 0], material('#babbb4'))
    }
  }
  return group
}
function buildLandscape() {
  const group = new THREE.Group()
  group.name = 'landscape-01'
  group.userData.elementId = 'landscape-01'
  const ground = material('#bcc3a6')
  const stone = material('#dedbcd')
  const darkStone = material('#b1b5a4')
  box(group, [55, .35, 41], [0, -.74, 0], ground)
  box(group, [41, .08, 29], [0, -.51, 0], stone)
  for (let i = -9; i <= 9; i++) box(group, [.018, .015, 29], [i * 2.1, -.462, 0], darkStone)
  for (let i = -6; i <= 6; i++) box(group, [41, .015, .018], [0, -.462, i * 2.1], darkStone)
  box(group, [9, .08, 10], [9, -.45, 17], stone)
  box(group, [13, .12, 4.1], [-8, -.34, 15], material('#829797'))
  box(group, [12.6, .04, 3.7], [-8, -.25, 15], new THREE.MeshStandardMaterial({ color: '#769c9f', metalness: .58, roughness: .22 }))
  for (const z of [12.9, 17.1]) box(group, [13.4, .26, .25], [-8, -.22, z], stone)
  for (let i = 0; i < 5; i++) box(group, [7.2, .1, .55], [9, -.4 + i * .09, 12.4 - i * .5], stone)
  for (const [i, [x, z, scale]] of [[-21, -11, 1.5], [-23, 0, 1.3], [-22, 12, 1.7], [21, -12, 1.6], [23, 0, 1.3], [22, 12, 1.5], [-12, -17, 1.1], [1, -17, 1.6], [13, -17, 1.2], [-21, -18, 1.3], [20, -19, 1.35]].entries()) {
    box(group, [3.6, .18, 3.6], [x, -.48, z], material('#a3b18d'))
    tree(group, x, z, scale, i)
  }
  for (let i = 0; i < 7; i++) {
    sphere(group, .65, [-18, -.08, -8 + i * 2.5], material('#8c9b75'), 1).scale.y = .75
    sphere(group, .55, [18, -.12, -9 + i * 2.8], material('#96a080'), 1).scale.y = .65
  }
  for (const [x, z] of [[-19, 7], [18.8, 5], [-17, -12]]) {
    box(group, [2.7, .16, .65], [x, .07, z], material('#aa8154'))
    box(group, [.12, .5, .5], [x - 1, -.13, z], material('#657174'))
    box(group, [.12, .5, .5], [x + 1, -.13, z], material('#657174'))
  }
  person(group, 8, 13.5, -.4)
  person(group, 9.3, 14, -.4, '#b99a75')
  person(group, -1, 10, 0, '#68745d')
  person(group, -18, 2, -.4, '#a6907f')
  person(group, 12, 5, 0, '#a79471')
  return group
}
function disposeGroup(group: THREE.Group) {
  const materials = new Set<THREE.Material>()
  group.traverse(obj => {
    if (obj instanceof THREE.Mesh || obj instanceof THREE.LineSegments) {
      obj.geometry.dispose()
      if (Array.isArray(obj.material)) obj.material.forEach(m => materials.add(m))
      else materials.add(obj.material)
    }
  })
  materials.forEach(m => m.dispose())
}

export function Scene({ project, selected, onSelect, action, shadows, wireframe }: { project: Project; selected: string | null; onSelect: (id: string | null) => void; action: CameraAction; shadows: boolean; wireframe: boolean }) {
  const host = useRef<HTMLDivElement>(null)
  const runtime = useRef<Runtime | null>(null)
  const selectRef = useRef(onSelect)
  const [error, setError] = useState('')
  useEffect(() => { selectRef.current = onSelect }, [onSelect])
  useEffect(() => {
    const node = host.current
    if (!node) return
    let renderer: THREE.WebGLRenderer
    try {
      renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true })
    } catch {
      setError('WebGL is unavailable. Level 1 and South drawings remain available.')
      return
    }
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.5))
    renderer.shadowMap.enabled = true
    renderer.shadowMap.type = THREE.PCFSoftShadowMap
    renderer.toneMapping = THREE.ACESFilmicToneMapping
    renderer.toneMappingExposure = 1.12
    node.appendChild(renderer.domElement)
    const scene = new THREE.Scene()
    const camera = new THREE.OrthographicCamera(-34, 34, 25, -25, .1, 300)
    camera.position.set(38, 29, 42)
    const controls = new OrbitControls(camera, renderer.domElement)
    controls.target.set(0, 1, 0)
    controls.enableDamping = true
    controls.dampingFactor = .12
    controls.minZoom = .4
    controls.maxZoom = 5
    controls.maxPolarAngle = Math.PI / 2.02
    controls.update()
    scene.add(new THREE.HemisphereLight('#f1f7ff', '#a1a287', 2.5))
    const sun = new THREE.DirectionalLight('#fff3dd', 3.3)
    sun.position.set(-20, 40, 25)
    sun.castShadow = true
    sun.shadow.mapSize.set(2048, 2048)
    sun.shadow.camera.left = -40
    sun.shadow.camera.right = 40
    sun.shadow.camera.top = 40
    sun.shadow.camera.bottom = -40
    sun.shadow.normalBias = .035
    sun.shadow.bias = -.0004
    sun.shadow.radius = 3
    scene.add(sun)
    const model = new THREE.Group()
    scene.add(model)
    const floor = new THREE.Mesh(new THREE.PlaneGeometry(500, 500), material('#e2e5df'))
    floor.rotation.x = -Math.PI / 2
    floor.position.y = -.95
    floor.receiveShadow = true
    scene.add(floor)
    runtime.current = { scene, model, camera, controls, renderer }
    const observer = new ResizeObserver(() => {
      const { width, height } = node.getBoundingClientRect()
      renderer.setSize(width, height)
      const aspect = width / height
      camera.left = -26 * aspect
      camera.right = 26 * aspect
      camera.top = 26
      camera.bottom = -26
      camera.updateProjectionMatrix()
    })
    observer.observe(node)
    let start = { x: 0, y: 0 }
    const down = (e: PointerEvent) => { start = { x: e.clientX, y: e.clientY } }
    const up = (e: PointerEvent) => {
      if (e.button !== 0 || Math.hypot(start.x - e.clientX, start.y - e.clientY) > 5) return
      const rect = renderer.domElement.getBoundingClientRect()
      const ray = new THREE.Raycaster()
      ray.setFromCamera(new THREE.Vector2((e.clientX - rect.left) / rect.width * 2 - 1, -(e.clientY - rect.top) / rect.height * 2 + 1), camera)
      const hit = ray.intersectObject(model, true).find(h => typeof h.object.userData.elementId === 'string')
      selectRef.current(hit ? hit.object.userData.elementId as string : null)
    }
    renderer.domElement.addEventListener('pointerdown', down)
    renderer.domElement.addEventListener('pointerup', up)
    renderer.setAnimationLoop(() => { controls.update(); renderer.render(scene, camera) })
    return () => {
      observer.disconnect()
      controls.dispose()
      renderer.setAnimationLoop(null)
      renderer.dispose()
      disposeGroup(model)
      floor.geometry.dispose()
      floor.material.dispose()
      sun.dispose()
      node.removeChild(renderer.domElement)
      runtime.current = null
    }
  }, [])
  useEffect(() => {
    const r = runtime.current
    if (!r) return
    disposeGroup(r.model)
    r.model.clear()
    project.elements.filter(e => !project.hidden.includes(e.category)).forEach(e => {
      if (e.category === 'Landscape') r.model.add(buildLandscape())
      else r.model.add(buildElement(e, project))
    })
  }, [project])
  useEffect(() => {
    runtime.current?.model.traverse(obj => {
      if (obj instanceof THREE.Mesh && obj.material instanceof THREE.MeshStandardMaterial) {
        obj.material.emissive.set(obj.userData.elementId === selected ? '#1680db' : '#000000')
        obj.material.emissiveIntensity = obj.userData.elementId === selected ? .48 : 0
        obj.material.wireframe = wireframe
      }
    })
  }, [selected, project, wireframe])
  useEffect(() => {
    const r = runtime.current
    if (r) r.renderer.shadowMap.enabled = shadows
  }, [shadows])
  useEffect(() => {
    const r = runtime.current
    if (!r) return
    if (action.type === 'in') r.camera.zoom = Math.min(5, r.camera.zoom * 1.2)
    else if (action.type === 'out') r.camera.zoom = Math.max(.4, r.camera.zoom / 1.2)
    else {
      r.controls.target.set(0, 1, 0)
      r.camera.zoom = 1
      const pos: Record<string, number[]> = { home: [38, 29, 42], top: [0, 65, .01], front: [0, 2, 65], right: [65, 2, 0] }
      const p = pos[action.type]
      r.camera.position.set(p[0], p[1], p[2])
    }
    r.camera.updateProjectionMatrix()
    r.controls.update()
  }, [action])
  return <div className="three-viewport" ref={host} aria-label="Interactive 3D pavilion">{error && <div className="webgl-error">{error}</div>}</div>
}
