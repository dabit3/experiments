import * as THREE from 'three'
import { OrbitControls } from 'three/addons/controls/OrbitControls.js'
import { Reflector } from 'three/addons/objects/Reflector.js'
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js'
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js'
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js'
import { ShaderPass } from 'three/addons/postprocessing/ShaderPass.js'
import { OutputPass } from 'three/addons/postprocessing/OutputPass.js'
import { architecture, landscape, makePlant, materials, rng } from './geometry'
import { daylight, materialColors, sunPosition, presets } from './state'
import type { CameraShot, Project, Vector } from './state'

const skyVertex = `
varying vec3 vWorld;
void main() {
  vWorld = (modelMatrix * vec4(position, 1.0)).xyz;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}`
const skyFragment = `
uniform vec3 topColor;
uniform vec3 horizonColor;
uniform float cloud;
varying vec3 vWorld;
float noise(vec2 p) {
 return sin(p.x*1.3+sin(p.y*1.7))*sin(p.y*0.7+cos(p.x*1.1))*.5+.5;
}
void main() {
 vec3 dir = normalize(vWorld);
 float h = max(0.0, dir.y);
 vec3 color = mix(horizonColor, topColor, pow(h, .43));
 vec2 uv = dir.xz / max(.06, dir.y + .12);
 float c = noise(uv*1.6)*.5 + noise(uv*3.3)*.3 + noise(uv*6.7)*.2;
 float band = smoothstep(.52, .8, c) * smoothstep(.02, .20, h);
 color = mix(color, color * .76 + vec3(.13), band * cloud);
 gl_FragColor = vec4(color, 1.);
}`
const waterFragment = `
uniform float time;
uniform float light;
varying vec3 vWorld;
void main() {
 vec3 direction = normalize(cameraPosition-vWorld);
 float wave = sin(vWorld.x*1.8 + time*.6 + sin(vWorld.z*.3))*sin(vWorld.z*2.6+time*.5);
 float ripples = sin(vWorld.x*6.+vWorld.z*8.+wave*2.)*.5+.5;
 float fresnel = pow(1.-abs(direction.y), 3.);
 vec3 deep = mix(vec3(.018,.06,.085),vec3(.12,.27,.30), light);
 vec3 reflected = mix(vec3(.22,.27,.38),vec3(.60,.53,.45), light);
 vec3 color = mix(deep, reflected, fresnel*.85);
 color += vec3(.07,.07,.055)*pow(ripples, 9.)*fresnel;
 gl_FragColor = vec4(color, 1.);
}`
const gradeShader = {
  uniforms: { tDiffuse: { value: null }, saturation: { value: 1 }, vignette: { value: 0.2 } },
  vertexShader: 'varying vec2 vUv; void main(){vUv=uv; gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.);}',
  fragmentShader: `uniform sampler2D tDiffuse; uniform float saturation; uniform float vignette;
    varying vec2 vUv; void main(){ vec4 c=texture2D(tDiffuse,vUv);
    float l=dot(c.rgb,vec3(.2126,.7152,.0722)); c.rgb=mix(vec3(l),c.rgb,saturation);
    float edge=smoothstep(.2,.78,length(vUv-.5)); c.rgb*=1.-edge*vignette;
    gl_FragColor=c;}`,
}
export class VillaScene {
  readonly renderer: THREE.WebGLRenderer
  readonly scene = new THREE.Scene()
  readonly camera = new THREE.PerspectiveCamera(43, 1, 0.2, 800)
  readonly controls: OrbitControls
  private readonly composer: EffectComposer
  private readonly bloom: UnrealBloomPass
  private readonly grade = new ShaderPass(gradeShader)
  private readonly sun = new THREE.DirectionalLight('#ffc58b', 2)
  private readonly ambient = new THREE.HemisphereLight('#b5c7dc', '#6b6351', 1.3)
  private readonly sky: THREE.Mesh<THREE.SphereGeometry, THREE.ShaderMaterial>
  private readonly water: THREE.Mesh<THREE.PlaneGeometry, THREE.ShaderMaterial>
  private readonly pool: Reflector
  private readonly poolMaterial: THREE.ShaderMaterial
  private readonly objects = new THREE.Group()
  private readonly building: THREE.Group
  private readonly outline = new THREE.Box3Helper(new THREE.Box3(), new THREE.Color('#37b8e3'))
  private readonly interiorLights: THREE.PointLight[] = []
  private readonly resizeObserver: ResizeObserver
  private readonly raycaster = new THREE.Raycaster()
  private readonly mouse = new THREE.Vector2()
  private readonly oceanPlane = new THREE.Plane(new THREE.Vector3(0, 1, 0), -0.4)
  private objectSignature = ''
  private selected: string | null = null
  private frame = 0
  private lastRender = 0
  private startPoint = { x: 0, y: 0 }
  onSelect: (id: string | null) => void = () => {}
  onPlace: ((position: Vector) => void) | null = null

  constructor(private container: HTMLElement) {
    this.renderer = new THREE.WebGLRenderer({ antialias: true, preserveDrawingBuffer: true, powerPreference: 'high-performance' })
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.5))
    this.renderer.shadowMap.enabled = true
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping
    this.renderer.toneMappingExposure = 1.05
    this.renderer.domElement.setAttribute('aria-label', 'Interactive 3D coastal villa. Drag to orbit, scroll to zoom, right-drag to pan.')
    this.renderer.domElement.setAttribute('tabindex', '0')
    container.appendChild(this.renderer.domElement)
    this.controls = new OrbitControls(this.camera, this.renderer.domElement)
    this.controls.enableDamping = true
    this.controls.dampingFactor = 0.09
    this.controls.maxPolarAngle = Math.PI * 0.485
    this.controls.minDistance = 7
    this.controls.maxDistance = 85
    this.controls.zoomSpeed = 0.7
    this.setCamera(presets[0])
    this.scene.add(this.ambient)
    this.sun.castShadow = true
    this.sun.shadow.mapSize.set(2048, 2048)
    Object.assign(this.sun.shadow.camera, { left: -28, right: 28, top: 28, bottom: -28, near: 1, far: 160 })
    this.sun.shadow.bias = -0.00025
    this.sun.shadow.normalBias = 0.025
    this.scene.add(this.sun)
    this.building = architecture()
    this.building.userData.objectId = 'villa'
    this.scene.add(this.building, landscape(), this.objects)
    this.sky = new THREE.Mesh(new THREE.SphereGeometry(390, 32, 24), new THREE.ShaderMaterial({
      side: THREE.BackSide, depthWrite: false, vertexShader: skyVertex, fragmentShader: skyFragment,
      uniforms: { topColor: { value: new THREE.Color('#546e94') }, horizonColor: { value: new THREE.Color('#e5b98e') }, cloud: { value: 0.24 } },
    }))
    this.sky.material.toneMapped = false
    this.scene.add(this.sky)
    this.water = new THREE.Mesh(new THREE.PlaneGeometry(760, 760), new THREE.ShaderMaterial({
      vertexShader: skyVertex, fragmentShader: waterFragment,
      uniforms: { time: { value: 0 }, light: { value: 0.3 } },
    }))
    this.water.rotation.x = -Math.PI / 2
    this.water.position.y = -1.5
    this.scene.add(this.water)
    this.pool = new Reflector(new THREE.PlaneGeometry(11.05, 7.05), {
      textureWidth: 1024, textureHeight: 1024, color: 0x679c9b, clipBias: 0.005,
    })
    this.pool.rotation.x = -Math.PI / 2
    this.pool.position.set(2.7, 0.3, 8.1)
    if (!(this.pool.material instanceof THREE.ShaderMaterial)) throw new Error('Reflection material is unavailable')
    this.poolMaterial = this.pool.material
    this.poolMaterial.uniforms.time = { value: 0 }
    this.poolMaterial.fragmentShader = this.poolMaterial.fragmentShader
      .replace('void main() {', 'uniform float time; void main() {')
      .replace('texture2DProj( tDiffuse, vUv )', 'texture2DProj( tDiffuse, vUv + vec4(sin(vUv.x*170.0+time*.5)*.00065, cos(vUv.y*180.0+time*.3)*.00065,0.,0.) )')
    this.scene.add(this.pool)
    for (const [x, y, z] of [[-3, 2.4, -2.5], [5, 2.4, -3], [-2, 5.8, -3]]) {
      const light = new THREE.PointLight('#ffb65e', 35, 10, 1.4)
      light.position.set(x, y, z)
      this.interiorLights.push(light)
      this.scene.add(light)
    }
    const poolLight = new THREE.PointLight('#52dad6', 15, 12, 1.6)
    poolLight.position.set(3, 1, 8)
    this.scene.add(poolLight)
    this.makeMountains()
    this.outline.visible = false
    if (!Array.isArray(this.outline.material)) this.outline.material.depthTest = false
    this.outline.renderOrder = 10
    this.scene.add(this.outline)
    this.composer = new EffectComposer(this.renderer)
    this.composer.addPass(new RenderPass(this.scene, this.camera))
    this.bloom = new UnrealBloomPass(new THREE.Vector2(1, 1), 0.28, 0.6, 1)
    this.composer.addPass(this.bloom)
    this.composer.addPass(this.grade)
    this.composer.addPass(new OutputPass())
    this.resizeObserver = new ResizeObserver(() => this.resize())
    this.resizeObserver.observe(container)
    this.resize()
    this.renderer.domElement.addEventListener('pointerdown', this.pointerDown)
    this.renderer.domElement.addEventListener('pointerup', this.pointerUp)
    this.frame = requestAnimationFrame(this.animate)
  }
  private makeMountains() {
    const random = rng(10)
    for (let layer = 0; layer < 3; layer++) {
      const shape = new THREE.Shape()
      shape.moveTo(-170, -6)
      for (let i = 0; i <= 40; i++) {
        shape.lineTo(-170 + i * 8.5, 2 + Math.sin(i * 0.47 + layer * 2) * 3.4 + random() * 4 + layer * 2)
      }
      shape.lineTo(170, -6)
      const mesh = new THREE.Mesh(new THREE.ShapeGeometry(shape), new THREE.MeshBasicMaterial({
        color: ['#758991', '#839098', '#9c9e9f'][layer], side: THREE.DoubleSide, fog: false,
      }))
      mesh.position.set(0, -1, -75 - layer * 33)
      mesh.renderOrder = -1
      this.scene.add(mesh)
    }
  }
  setCamera(shot: CameraShot) {
    this.camera.position.set(...shot.position)
    this.camera.fov = shot.fov
    this.controls.target.set(...shot.target)
    this.controls.update()
    this.camera.updateProjectionMatrix()
  }
  cameraShot(id: string, name: string): CameraShot {
    return { id, name, position: this.camera.position.toArray() as Vector, target: this.controls.target.toArray() as Vector, fov: this.camera.fov }
  }
  setFov(value: number) {
    this.camera.fov = value
    this.camera.updateProjectionMatrix()
  }
  update(project: Project) {
    const light = daylight(project.time)
    const mist = project.weather === 'mist'
    const overcast = project.weather === 'overcast'
    this.sun.position.set(...sunPosition(project.time, project.sunHeading))
    this.sun.intensity = (0.6 + light * 2.2) * (overcast ? 0.35 : 1)
    this.sun.color.set(light < 0.45 ? '#ffbd82' : '#ffefd5')
    this.ambient.intensity = 0.85 + light * 0.75
    this.sky.material.uniforms.topColor.value.set(overcast ? '#7d8a99' : (light > 0.7 ? '#589bd0' : '#4d6b98'))
    this.sky.material.uniforms.horizonColor.value.set(overcast ? '#c1c2bd' : (light > 0.7 ? '#bcd4d7' : (project.time > 20 ? '#7180a2' : '#e4b69b')))
    this.sky.material.uniforms.cloud.value = project.cloud / 100
    this.water.material.uniforms.light.value = light
    this.scene.fog = new THREE.FogExp2(mist ? '#bdc4c1' : '#b3b4af', mist ? 0.018 : 0.0015)
    materials.stone.color.set(materialColors[project.material])
    materials.stone.roughness = project.roughness
    materials.glow.emissiveIntensity = project.interior / 100 * 4
    this.interiorLights.forEach(l => { l.intensity = project.interior / 100 * 48 })
    this.renderer.toneMappingExposure = project.exposure
    this.bloom.strength = project.bloom
    this.grade.uniforms.saturation.value = project.saturation
    this.grade.uniforms.vignette.value = project.vignette
    const signature = JSON.stringify(project.objects)
    if (signature !== this.objectSignature) {
      this.objects.traverse(object => { if (object instanceof THREE.Mesh) object.geometry.dispose() })
      this.objects.clear()
      for (const object of project.objects) {
        const group = makePlant(object.kind)
        group.position.set(...object.position)
        group.scale.setScalar(object.scale)
        group.rotation.y = THREE.MathUtils.degToRad(object.rotation)
        group.userData.objectId = object.id
        this.objects.add(group)
      }
      this.objectSignature = signature
      this.select(this.selected)
    }
  }
  select(id: string | null) {
    this.selected = id
    const object = id === 'villa' ? this.building : this.objects.children.find(o => o.userData.objectId === id)
    this.outline.visible = Boolean(object)
    if (object) this.outline.box.setFromObject(object)
  }
  private pointerDown = (event: PointerEvent) => { this.startPoint = { x: event.clientX, y: event.clientY } }
  private pointerUp = (event: PointerEvent) => {
    if (event.button !== 0 || Math.hypot(event.clientX - this.startPoint.x, event.clientY - this.startPoint.y) > 5) return
    const rect = this.renderer.domElement.getBoundingClientRect()
    this.mouse.set((event.clientX - rect.left) / rect.width * 2 - 1, -(event.clientY - rect.top) / rect.height * 2 + 1)
    this.raycaster.setFromCamera(this.mouse, this.camera)
    if (this.onPlace) {
      const point = new THREE.Vector3()
      if (this.raycaster.ray.intersectPlane(this.oceanPlane, point)) this.onPlace(point.toArray() as Vector)
      return
    }
    const hit = this.raycaster.intersectObjects([this.objects, this.building], true)[0]
    let current: THREE.Object3D | null = hit?.object ?? null
    while (current && !current.userData.objectId) current = current.parent
    this.onSelect(current?.userData.objectId as string ?? null)
  }
  private resize() {
    const width = this.container.clientWidth
    const height = this.container.clientHeight
    if (!width || !height) return
    this.camera.aspect = width / height
    this.camera.updateProjectionMatrix()
    this.renderer.setSize(width, height)
    this.composer.setSize(width, height)
  }
  private animate = (time: number) => {
    this.frame = requestAnimationFrame(this.animate)
    this.controls.update()
    if (time - this.lastRender < 32) return
    this.lastRender = time
    this.water.material.uniforms.time.value = time * 0.001
    this.poolMaterial.uniforms.time.value = time * 0.001
    this.composer.render()
  }
  async image(width = 1920, height = 1080, shot?: CameraShot): Promise<Blob> {
    const previous = this.cameraShot('previous', 'previous')
    const ratio = this.renderer.getPixelRatio()
    const selectionVisible = this.outline.visible
    if (shot) this.setCamera(shot)
    this.outline.visible = false
    this.renderer.setPixelRatio(1)
    this.renderer.setSize(width, height, false)
    this.composer.setPixelRatio(1)
    this.composer.setSize(width, height)
    this.camera.aspect = width / height
    this.camera.updateProjectionMatrix()
    this.composer.render()
    const blob = new Promise<Blob>((resolve, reject) => this.renderer.domElement.toBlob(b => b ? resolve(b) : reject(new Error('Image export failed')), 'image/png'))
    this.renderer.setPixelRatio(ratio)
    this.composer.setPixelRatio(ratio)
    this.outline.visible = selectionVisible
    this.setCamera(previous)
    this.resize()
    return blob
  }
  dispose() {
    cancelAnimationFrame(this.frame)
    this.resizeObserver.disconnect()
    this.controls.dispose()
    this.renderer.domElement.removeEventListener('pointerdown', this.pointerDown)
    this.renderer.domElement.removeEventListener('pointerup', this.pointerUp)
    this.scene.traverse(object => {
      if (object instanceof THREE.Mesh) object.geometry.dispose()
    })
    this.pool.dispose()
    this.composer.dispose()
    this.renderer.dispose()
    this.renderer.domElement.remove()
  }
}
