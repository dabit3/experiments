import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { Reflector } from 'three/addons/objects/Reflector.js';
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js';
import { MATERIALS, seededRandom, sunPosition, terrainHeight } from './model';
import type { Ambience, AssetKind, CameraShot, MaterialId, Project, SceneObject, Vec3 } from './model';

const UP = new THREE.Vector3(0, 1, 0);
const boxGeometry = new THREE.BoxGeometry(1, 1, 1);
const leafGeometry = new THREE.PlaneGeometry(1, 1);
const trunkGeometry = new THREE.CylinderGeometry(0.6, 1, 1, 12);
const standard = (color: string | number, roughness = 0.85) => new THREE.MeshStandardMaterial({ color, roughness });
const dark = standard('#272d2c');
const fabric = standard('#c9c8b5');
const stone = standard('#555d52');
const metal = standard('#292c29', 0.4);
const bark = standard('#5e5b46');
const whiteBark = standard('#b5b5a0');
let foliageMap: THREE.CanvasTexture | null = null;

function leafMaterial() {
  if (!foliageMap) {
    const canvas = document.createElement('canvas');
    canvas.width = 128; canvas.height = 128;
    const ctx = canvas.getContext('2d')!;
    ctx.strokeStyle = '#79866a'; ctx.lineWidth = 2;
    ctx.beginPath(); ctx.moveTo(64, 125); ctx.quadraticCurveTo(76, 64, 58, 8); ctx.stroke();
    const random = seededRandom(718);
    for (let i = 0; i < 14; i++) {
      const y = 17 + i * 6.5, side = i % 2 ? 1 : -1;
      const x = 65 + side * (17 + random() * 9);
      ctx.beginPath(); ctx.moveTo(65, y + 12); ctx.lineTo(x, y); ctx.stroke();
      ctx.save(); ctx.translate(x, y); ctx.rotate(side * 0.5);
      const fill = ctx.createLinearGradient(-12, 0, 12, 0);
      fill.addColorStop(0, '#78876a'); fill.addColorStop(0.48, '#e3e9cd'); fill.addColorStop(1, '#99aa7b');
      ctx.fillStyle = fill; ctx.beginPath(); ctx.ellipse(0, 0, 13 + random() * 3, 6 + random() * 2, 0, 0, Math.PI * 2); ctx.fill();
      ctx.strokeStyle = '#9ba884'; ctx.lineWidth = 0.6;
      ctx.beginPath(); ctx.moveTo(-12, 0); ctx.lineTo(12, 0); ctx.stroke();
      ctx.restore();
    }
    foliageMap = new THREE.CanvasTexture(canvas);
    foliageMap.colorSpace = THREE.SRGBColorSpace;
  }
  return new THREE.MeshStandardMaterial({ color: '#ffffff', map: foliageMap, alphaTest: 0.4, side: THREE.DoubleSide, roughness: 0.85 });
}
function texture(kind: 'wood' | 'stone' | 'soil') {
  const canvas = document.createElement('canvas');
  canvas.width = 256; canvas.height = 256;
  const ctx = canvas.getContext('2d')!;
  const random = seededRandom(42);
  ctx.fillStyle = kind === 'wood' ? '#c2aa88' : kind === 'soil' ? '#414c31' : '#bbbbaf';
  ctx.fillRect(0, 0, 256, 256);
  for (let i = 0; i < (kind === 'soil' ? 18000 : 2500); i++) {
    const value = Math.floor(100 + random() * 100);
    ctx.strokeStyle = kind === 'soil' ? `rgba(${65 + random() * 70},${69 + random() * 70},${35 + random() * 50},0.35)` : `rgba(${value},${value},${value},${kind === 'wood' ? 0.19 : 0.2})`;
    ctx.beginPath();
    const x = random() * 256, y = random() * 256;
    ctx.moveTo(x, y);
    ctx.lineTo(kind === 'wood' ? x + random() * 1.5 : x + 2, y + (kind === 'wood' ? random() * 110 : 2));
    ctx.stroke();
  }
  const map = new THREE.CanvasTexture(canvas);
  map.wrapS = map.wrapT = THREE.RepeatWrapping;
  map.colorSpace = THREE.SRGBColorSpace;
  return map;
}

function box(parent: THREE.Object3D, size: Vec3, position: Vec3, material: THREE.Material) {
  const mesh = new THREE.Mesh(boxGeometry, material);
  mesh.scale.set(...size); mesh.position.set(...position);
  mesh.castShadow = true; mesh.receiveShadow = true;
  parent.add(mesh);
  return mesh;
}
function cylinder(parent: THREE.Object3D, start: Vec3, end: Vec3, radius: number, material: THREE.Material) {
  const a = new THREE.Vector3(...start), b = new THREE.Vector3(...end);
  const mesh = new THREE.Mesh(trunkGeometry, material);
  mesh.position.copy(a).lerp(b, 0.5);
  mesh.scale.set(radius, a.distanceTo(b), radius);
  mesh.quaternion.setFromUnitVectors(UP, b.sub(a).normalize());
  mesh.castShadow = true;
  parent.add(mesh);
}
function foliage(parent: THREE.Object3D, centers: Vec3[], radius: number, color: string, seed: number, count = 60) {
  const random = seededRandom(seed);
  const mesh = new THREE.InstancedMesh(leafGeometry, leafMaterial(), centers.length * count);
  const dummy = new THREE.Object3D();
  const shade = new THREE.Color();
  let index = 0;
  centers.forEach(center => {
    for (let i = 0; i < count; i++) {
      const theta = random() * Math.PI * 2;
      const z = random() * 2 - 1;
      const r = Math.cbrt(random()) * radius;
      dummy.position.set(center[0] + Math.sqrt(1 - z * z) * Math.cos(theta) * r,
        center[1] + z * r * 0.75, center[2] + Math.sqrt(1 - z * z) * Math.sin(theta) * r);
      const size = 0.5 + random() * 0.48;
      dummy.scale.set(size * 1.1, size, size);
      dummy.rotation.set(random() * 3, random() * 6, random() * 3);
      dummy.updateMatrix();
      mesh.setMatrixAt(index, dummy.matrix);
      shade.set(color).multiplyScalar(0.65 + random() * 0.6);
      mesh.setColorAt(index++, shade);
    }
  });
  mesh.castShadow = true; mesh.receiveShadow = true;
  mesh.userData.foliage = true;
  mesh.userData.baseColor = color;
  parent.add(mesh);
}
function tree(parent: THREE.Object3D, kind: 'pine' | 'maple' | 'birch', seed: number) {
  const random = seededRandom(seed);
  const height = kind === 'maple' ? 4.6 : kind === 'pine' ? 9 : 7;
  const spread = kind === 'maple' ? 2.8 : 2;
  cylinder(parent, [0, 0, 0], [0.15, height, 0], kind === 'maple' ? 0.18 : 0.23, kind === 'birch' ? whiteBark : bark);
  const centers: Vec3[] = [];
  for (let i = 0; i < 13; i++) {
    const angle = i * 2.399;
    const y = height * (0.46 + i / 25);
    const r = spread * (1 - i / 22) * (0.8 + random() * 0.4);
    const end: Vec3 = [Math.cos(angle) * r, y + 0.55, Math.sin(angle) * r];
    cylinder(parent, [0, y - 0.7, 0], end, 0.055, kind === 'birch' ? whiteBark : bark);
    centers.push(end);
  }
  foliage(parent, centers, kind === 'maple' ? 1.2 : 1.25, kind === 'maple' ? '#8caa52' : kind === 'birch' ? '#abc273' : '#668565', seed, 85);
}
function chair(parent: THREE.Object3D, wood: THREE.Material) {
  [-0.43, 0.43].forEach(x => {
    cylinder(parent, [x, 0, -0.4], [x, 0.85, 0.4], 0.055, wood);
    cylinder(parent, [x, 0, 0.5], [x, 0.7, -0.4], 0.055, wood);
    box(parent, [0.09, 0.08, 1.12], [x, 0.65, 0], wood);
  });
  box(parent, [0.81, 0.13, 0.85], [0, 0.49, 0.08], fabric);
  const back = box(parent, [0.81, 0.85, 0.11], [0, 0.93, -0.35], fabric);
  back.rotation.x = -0.2;
}
function makeObject(object: SceneObject, wood: THREE.Material) {
  const group = new THREE.Group();
  switch (object.kind) {
    case 'pavilion': {
      const concrete = standard('#c8c7b7');
      box(group, [12, 0.35, 6.8], [0, 1.22, 0], concrete);
      box(group, [14.5, 0.22, 8.5], [0.5, 4.85, 0.25], dark);
      box(group, [14.1, 0.13, 8.15], [0.5, 4.69, 0.25], wood);
      box(group, [0.5, 3.4, 6.2], [-5.6, 3, -0.2], concrete);
      box(group, [11.2, 3.35, 0.22], [0, 3, -2.9], wood);
      for (let i = 0; i < 82; i++) box(group, [0.06, 3.25, 0.07], [-5.5 + i * 0.135, 3, -2.72], dark);
      [-5.6, -2, 1.9, 5.6].forEach(x => {
        box(group, [0.09, 3.45, 0.12], [x, 3, 3], dark);
        box(group, [0.09, 3.45, 0.12], [x, 3, -2.5], dark);
      });
      box(group, [11.4, 0.07, 0.1], [0, 1.49, 3], dark);
      const glass = new THREE.MeshPhysicalMaterial({ color: '#a3b7b0', roughness: 0.08, metalness: 0.15, transparent: true, opacity: 0.16, side: THREE.DoubleSide, depthWrite: false });
      box(group, [11.15, 3.16, 0.025], [0, 3.02, 3], glass).castShadow = false;
      box(group, [0.025, 3.16, 5.8], [5.65, 3.02, 0], glass).castShadow = false;
      for (let i = 0; i < 30; i++) box(group, [0.3, 0.06, 6.3], [-5.5 + i * 0.38, 1.43, 0], wood);
      const rug = standard('#c8c4b1');
      box(group, [4, 0.04, 3], [-1.7, 1.51, 0.5], rug);
      box(group, [3.4, 0.42, 1], [-1.8, 1.8, -0.5], fabric);
      box(group, [3.6, 0.6, 0.25], [-1.8, 2.15, -0.95], fabric);
      [-3.45, -0.16].forEach(x => box(group, [0.25, 0.5, 1.1], [x, 2.05, -0.5], fabric));
      [-2.9, -1.8, -0.7].forEach(x => box(group, [1, 0.12, 0.8], [x, 2.08, -0.42], standard('#e0dbca')));
      box(group, [1.7, 0.12, 0.85], [-1.8, 1.94, 1.15], wood);
      [-2.4, -1.2].forEach(x => box(group, [0.09, 0.45, 0.6], [x, 1.7, 1.15], dark));
      box(group, [1.9, 0.8, 0.5], [3.2, 1.9, -2.28], wood);
      box(group, [1.95, 0.05, 0.6], [3.2, 2.33, -2.28], concrete);
      box(group, [0.07, 1.4, 1.6], [-5.26, 3.1, -0.7], dark);
      box(group, [0.09, 1.13, 1.28], [-5.21, 3.1, -0.7], standard('#b89c65'));
      const glow = new THREE.MeshStandardMaterial({ color: '#ffe0a2', emissive: '#ffb957', emissiveIntensity: 0.8 });
      [-3.8, 0, 3.8].forEach(x => {
        cylinder(group, [x, 4.65, 0], [x, 4.05, 0], 0.018, metal);
        const shade = new THREE.Mesh(new THREE.ConeGeometry(0.36, 0.17, 24), metal);
        shade.position.set(x, 4.01, 0); group.add(shade);
        box(group, [0.42, 0.025, 0.42], [x, 3.94, 0], glow);
      });
      box(group, [10.5, 0.025, 0.04], [0, 4.6, -2.45], glow);
      const warm = new THREE.PointLight('#ffcc89', 28, 10, 2);
      warm.position.set(0, 3.7, 0); group.add(warm);
      break;
    }
    case 'deck':
      box(group, [14, 0.15, 9], [0.3, 0.92, 0.7], dark);
      for (let i = 0; i < 95; i++) box(group, [0.136, 0.12, 9], [-6.5 + i * 0.145, 1.01, 0.7], wood);
      for (let i = 0; i < 4; i++) box(group, [3.4, 0.18, 0.5], [-4.8, 0.18 + i * 0.21, 6.95 - i * 0.5], wood);
      [-5, 0, 5].forEach(x => box(group, [0.25, 0.95, 0.25], [x, 0.5, 4.5], dark));
      break;
    case 'pine': case 'maple': case 'birch':
      tree(group, object.kind, object.id.split('').reduce((sum, char) => sum + char.charCodeAt(0), 0));
      group.traverse(child => {
        if (child.userData.foliage) child.userData.materialTint = object.material === 'sage' ? '#ffffff' : MATERIALS.find(m => m.id === object.material)?.color;
      });
      break;
    case 'chair': chair(group, wood); break;
    case 'bench':
      for (let i = 0; i < 5; i++) box(group, [1.8, 0.075, 0.09], [0, 0.52, -0.24 + i * 0.12], wood);
      [-0.65, 0.65].forEach(x => box(group, [0.1, 0.5, 0.52], [x, 0.25, 0], metal));
      break;
    case 'rock': {
      const rock = new THREE.Mesh(new THREE.IcosahedronGeometry(0.85, 1), stone);
      rock.scale.set(1.3, 0.6, 0.9); rock.position.y = 0.3;
      rock.castShadow = true; rock.receiveShadow = true; group.add(rock);
      break;
    }
    case 'fern':
      foliage(group, [[0, 0.5, 0], [-0.3, 0.3, 0.1], [0.3, 0.3, -0.2]], 0.55, '#5f7943', 91, 35);
      break;
    case 'lamp':
      box(group, [0.12, 0.82, 0.12], [0, 0.41, 0], metal);
      box(group, [0.17, 0.13, 0.17], [0, 0.74, 0], new THREE.MeshStandardMaterial({ color: '#ffdeb1', emissive: '#ffba60', emissiveIntensity: 1.4 }));
      box(group, [0.19, 0.03, 0.19], [0, 0.82, 0], metal);
      break;
  }
  group.position.set(...object.position);
  group.rotation.y = THREE.MathUtils.degToRad(object.rotation);
  group.scale.setScalar(object.scale);
  group.visible = object.visible;
  group.userData.objectId = object.id;
  return group;
}

export class SceneEngine {
  readonly renderer: THREE.WebGLRenderer;
  readonly scene = new THREE.Scene();
  readonly camera = new THREE.PerspectiveCamera(42, 1, 0.1, 220);
  readonly controls: OrbitControls;
  private objects = new Map<string, THREE.Group>();
  private objectData = new Map<string, string>();
  private background = new THREE.Group();
  private selection = new THREE.BoxHelper(new THREE.Object3D(), '#31a9ec');
  private sun = new THREE.DirectionalLight('#ffe0ab', 3);
  private sky = new THREE.HemisphereLight('#d4e4ec', '#5b6047', 2.1);
  private materials = new Map<MaterialId, THREE.MeshStandardMaterial>();
  private frame = 0;
  private observer: ResizeObserver;
  private currentAmbience = '';
  private selected: string | null = null;
  private water: Reflector;
  private onSelect: (id: string | null) => void;
  private pointerStart: [number, number] = [0, 0];
  private rendered = false;
  private disposed = false;
  private pmrem: THREE.PMREMGenerator;
  private environment: THREE.WebGLRenderTarget;

  constructor(private container: HTMLElement, onSelect: (id: string | null) => void) {
    this.onSelect = onSelect;
    this.renderer = new THREE.WebGLRenderer({ antialias: true, preserveDrawingBuffer: true, powerPreference: 'high-performance' });
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.5));
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.renderer.shadowMap.autoUpdate = false;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 0.95;
    this.renderer.domElement.setAttribute('aria-label', 'Interactive 3D forest retreat. Drag to orbit, scroll to zoom, click an object to select.');
    this.renderer.domElement.setAttribute('role', 'img');
    container.appendChild(this.renderer.domElement);
    this.pmrem = new THREE.PMREMGenerator(this.renderer);
    const room = new RoomEnvironment();
    this.environment = this.pmrem.fromScene(room, 0.04);
    room.dispose();
    this.scene.environment = this.environment.texture;
    this.scene.environmentIntensity = 0.25;
    const wood = texture('wood');
    const concrete = texture('stone');
    MATERIALS.forEach(material => {
      const map = material.id === 'limestone' ? concrete : wood;
      this.materials.set(material.id, new THREE.MeshStandardMaterial({ color: material.color, roughness: material.roughness, map, bumpMap: map, bumpScale: 0.08 }));
    });
    this.scene.add(this.background, this.sky, this.sun);
    this.sun.castShadow = true;
    this.sun.shadow.mapSize.set(2048, 2048);
    Object.assign(this.sun.shadow.camera, { left: -29, right: 29, top: 28, bottom: -28, near: 0.5, far: 100 });
    this.sun.shadow.bias = -0.0005;
    this.sun.shadow.normalBias = 0.035;
    this.scene.add(this.sun.target);
    this.buildLandscape();
    this.batchLandscape();
    this.water = new Reflector(new THREE.CircleGeometry(1, 96), { color: 0x7d9486, textureWidth: 768, textureHeight: 768, clipBias: 0.003 });
    this.water.rotation.x = -Math.PI / 2;
    this.water.position.set(1, 0.075, 8);
    this.water.scale.set(12, 8, 1);
    if (this.water.material instanceof THREE.ShaderMaterial) {
      this.water.material.fragmentShader = this.water.material.fragmentShader.replace('vec4 base = texture2DProj( tDiffuse, vUv );', 'vec4 rippleUv = vUv; rippleUv.x += sin(vUv.y * 280.0) * 0.0007 * vUv.w; vec4 base = texture2DProj( tDiffuse, rippleUv );');
    }
    this.scene.add(this.water);
    const waterTint = new THREE.Mesh(new THREE.CircleGeometry(1, 96), new THREE.MeshStandardMaterial({ color: '#527a70', transparent: true, opacity: 0.18, roughness: 0.18, metalness: 0.4, depthWrite: false }));
    waterTint.rotation.x = -Math.PI / 2; waterTint.scale.set(12, 8, 1);
    waterTint.position.copy(this.water.position).y += 0.003;
    this.scene.add(waterTint);
    this.selection.visible = false;
    this.scene.add(this.selection);
    this.camera.position.set(19, 8.8, 23);
    this.controls = new OrbitControls(this.camera, this.renderer.domElement);
    this.controls.target.set(0, 2.2, -1);
    this.controls.minDistance = 4; this.controls.maxDistance = 80;
    this.controls.maxPolarAngle = Math.PI / 2 - 0.025;
    this.controls.enableDamping = false;
    this.controls.addEventListener('change', this.render);
    this.controls.update();
    this.renderer.domElement.addEventListener('pointerdown', this.pointerDown);
    this.renderer.domElement.addEventListener('pointerup', this.pointerUp);
    this.observer = new ResizeObserver(this.resize);
    this.observer.observe(container);
    this.resize();
  }
  private buildLandscape() {
    const random = seededRandom(311);
    const groundMap = texture('soil'); groundMap.repeat.set(35, 35);
    const terrain = new THREE.PlaneGeometry(240, 240, 100, 100);
    const vertices = terrain.attributes.position;
    for (let i = 0; i < vertices.count; i++) vertices.setZ(i, terrainHeight(vertices.getX(i), -vertices.getY(i)));
    terrain.computeVertexNormals();
    const ground = new THREE.Mesh(terrain, new THREE.MeshStandardMaterial({ map: groundMap, roughness: 1, bumpMap: groundMap, bumpScale: 0.1 }));
    ground.rotation.x = -Math.PI / 2; ground.receiveShadow = true;
    this.background.add(ground);
    for (let i = 0; i < 120; i++) {
      const group = new THREE.Group();
      const side = i % 3;
      group.position.set(side === 0 ? -19 - random() * 22 : side === 1 ? 18 + random() * 26 : -25 + random() * 60,
        0, side === 2 ? -20 - random() * 25 : -12 - random() * 30);
      if (i >= 56) {
        const angle = i * 2.399, distance = 40 + random() * 40;
        group.position.set(Math.cos(angle) * distance, 0, Math.sin(angle) * distance);
      }
      group.position.y = terrainHeight(group.position.x, group.position.z);
      const scale = 0.85 + random() * 1.4;
      group.scale.setScalar(scale);
      tree(group, i % 4 === 0 ? 'birch' : 'pine', i + 101);
      this.background.add(group);
    }
    for (let i = 0; i < 42; i++) {
      const angle = random() * Math.PI * 2;
      const x = 1 + Math.cos(angle) * (12.2 + random() * 2);
      const z = 8 + Math.sin(angle) * (8.3 + random());
      if (z < 3 && x > -6 && x < 7) continue;
      const rock = new THREE.Mesh(new THREE.IcosahedronGeometry(0.6, 2), stone);
      rock.position.set(x, 0.06, z);
      rock.scale.set(0.5 + random(), 0.3 + random() * 0.4, 0.5 + random());
      rock.rotation.set(random(), random(), random());
      rock.castShadow = true; rock.receiveShadow = true;
      this.background.add(rock);
    }
    const grassGeometry = new THREE.BufferGeometry();
    grassGeometry.setAttribute('position', new THREE.Float32BufferAttribute([-0.014, 0, 0, 0.014, 0, 0, 0.055, 0.27, 0, 0, 0, -0.012, 0, 0, 0.012, -0.04, 0.24, 0.01], 3));
    grassGeometry.computeVertexNormals();
    const grassMaterial = new THREE.MeshStandardMaterial({ color: '#ffffff', side: THREE.DoubleSide, roughness: 1 });
    const grass = new THREE.InstancedMesh(grassGeometry, grassMaterial, 18000);
    const dummy = new THREE.Object3D();
    const shade = new THREE.Color();
    for (let i = 0; i < 18000; i++) {
      let x = -29 + random() * 58, z = -19 + random() * 47;
      const pond = ((x - 1) / 13) ** 2 + ((z - 8) / 9) ** 2 < 1;
      const house = x > -7.4 && x < 7.7 && z > -8 && z < 4;
      const path = x > -8 && x < -4.1 && z > 3;
      if (pond || house || path) { x = -27 + random() * 54; z = -14 - random() * 8; }
      dummy.position.set(x, terrainHeight(x, z) + 0.03, z);
      dummy.rotation.y = random() * Math.PI;
      dummy.scale.setScalar(0.35 + random() * 0.55);
      dummy.updateMatrix(); grass.setMatrixAt(i, dummy.matrix);
      shade.set('#657543').multiplyScalar(0.65 + random() * 0.65);
      grass.setColorAt(i, shade);
    }
    grass.receiveShadow = true; this.background.add(grass);
    const boardwalk = new THREE.Group();
    for (let i = 0; i < 61; i++) box(boardwalk, [2.6, 0.1, 0.19], [0, 0.2, i * 0.21], this.materials.get('cedar')!);
    boardwalk.position.set(-6, 0, 6.6);
    boardwalk.rotation.y = -0.22;
    this.background.add(boardwalk);
    for (let i = 0; i < 17; i++) {
      const group = new THREE.Group();
      foliage(group, [[0, 0.3, 0]], 0.9, i % 2 ? '#657944' : '#85905c', 91 + i, 40);
      const angle = i * 2.399;
      group.position.set(1 + Math.cos(angle) * 14, 0, 8 + Math.sin(angle) * 9.4);
      if (group.position.z > 3) this.background.add(group);
    }
  }
  private batchLandscape() {
    this.background.updateMatrixWorld(true);
    const trunks: THREE.Mesh[] = [];
    const leaves: THREE.InstancedMesh[] = [];
    this.background.traverse(object => {
      if (object instanceof THREE.InstancedMesh && object.userData.foliage) leaves.push(object);
      else if (object instanceof THREE.Mesh && object.geometry === trunkGeometry) trunks.push(object);
    });
    const matrix = new THREE.Matrix4();
    const color = new THREE.Color();
    [bark, whiteBark].forEach(material => {
      const sources = trunks.filter(mesh => mesh.material === material);
      const merged = new THREE.InstancedMesh(trunkGeometry, material, sources.length);
      sources.forEach((source, i) => { merged.setMatrixAt(i, source.matrixWorld); source.removeFromParent(); });
      merged.castShadow = true; this.background.add(merged);
    });
    const mergedLeaves = new THREE.InstancedMesh(leafGeometry, leafMaterial(), leaves.reduce((sum, mesh) => sum + mesh.count, 0));
    let index = 0;
    leaves.forEach(source => {
      for (let i = 0; i < source.count; i++) {
        source.getMatrixAt(i, matrix);
        matrix.premultiply(source.matrixWorld);
        mergedLeaves.setMatrixAt(index, matrix);
        source.getColorAt(i, color);
        mergedLeaves.setColorAt(index++, color);
      }
      source.removeFromParent();
      (source.material as THREE.MeshStandardMaterial).dispose();
      source.dispose();
    });
    mergedLeaves.castShadow = true; mergedLeaves.receiveShadow = true;
    mergedLeaves.userData.foliage = true;
    this.background.add(mergedLeaves);
  }
  update(project: Project, selected: string | null) {
    project.objects.forEach(object => {
      const serialized = JSON.stringify(object);
      if (this.objectData.get(object.id) !== serialized) {
        const previous = this.objects.get(object.id);
        if (previous) { this.scene.remove(previous); this.disposeGroup(previous); }
        const group = makeObject(object, this.materials.get(object.material)!);
        this.scene.add(group); this.objects.set(object.id, group);
        this.objectData.set(object.id, serialized);
        this.currentAmbience = '';
      }
    });
    this.objects.forEach((group, id) => {
      if (!project.objects.some(object => object.id === id)) {
        this.scene.remove(group); this.disposeGroup(group);
        this.objects.delete(id); this.objectData.delete(id);
      }
    });
    if (this.currentAmbience !== JSON.stringify(project.ambience)) this.ambience(project.ambience);
    this.selected = selected;
    const chosen = selected && this.objects.get(selected);
    this.selection.visible = !!chosen && chosen.visible;
    if (chosen) this.selection.setFromObject(chosen);
    this.renderer.shadowMap.needsUpdate = true;
    this.render();
  }
  private ambience(a: Ambience) {
    this.currentAmbience = JSON.stringify(a);
    const evening = Math.max(0, (a.time - 15) / 6);
    const sky = new THREE.Color(a.weather === 'Clear' ? '#b6c7c6' : '#a5b3b0');
    if (a.time > 19) sky.lerp(new THREE.Color('#66778d'), (a.time - 19) / 2);
    this.scene.background = sky;
    this.scene.fog = new THREE.FogExp2(sky, 0.004 + a.fog * 0.00013 + (a.weather === 'Mist' ? 0.009 : 0));
    this.sun.position.set(...sunPosition(a.time));
    this.sun.color.set('#fff4d9').lerp(new THREE.Color('#ffc47b'), evening);
    this.sun.intensity = a.weather === 'Clear' ? Math.max(0.4, 3.8 - evening * 1.6) : 0.8;
    this.sky.intensity = a.time > 19 ? 0.4 : 0.95;
    this.scene.traverse(object => {
      if (object instanceof THREE.InstancedMesh && object.userData.foliage) {
        const material = object.material;
        if (material instanceof THREE.MeshStandardMaterial) {
          material.color.set(a.season === 'Winter' ? '#c8c4ab' : a.season === 'Autumn' ? '#e9af58' : '#ffffff');
          material.color.multiply(new THREE.Color(object.userData.materialTint ?? '#ffffff'));
        }
      }
    });
  }
  private disposeGroup(group: THREE.Group) {
    const sharedMaterials = new Set<THREE.Material>([...this.materials.values(), dark, fabric, stone, metal, bark, whiteBark]);
    group.traverse(object => {
      if (object instanceof THREE.Mesh) {
        if (![boxGeometry, leafGeometry, trunkGeometry].includes(object.geometry)) object.geometry.dispose();
        const materials = Array.isArray(object.material) ? object.material : [object.material];
        materials.forEach(material => { if (!sharedMaterials.has(material)) material.dispose(); });
        if (object instanceof THREE.InstancedMesh) object.dispose();
      }
    });
  }
  setCamera(shot: Pick<CameraShot, 'position' | 'target'>) {
    this.camera.position.set(...shot.position);
    this.controls.target.set(...shot.target);
    this.controls.update(); this.render();
  }
  getCamera(): { position: Vec3; target: Vec3 } {
    return { position: this.camera.position.toArray() as Vec3, target: this.controls.target.toArray() as Vec3 };
  }
  focus() {
    const group = this.selected && this.objects.get(this.selected);
    if (group) {
      const bounds = new THREE.Box3().setFromObject(group);
      const center = bounds.getCenter(new THREE.Vector3());
      const distance = Math.max(5, bounds.getSize(new THREE.Vector3()).length() * 1.2);
      this.controls.target.copy(center);
      this.camera.position.copy(center).add(new THREE.Vector3(1, 0.6, 1).normalize().multiplyScalar(distance));
      this.controls.update();
    }
  }
  capture(): Promise<Blob> {
    const visible = this.selection.visible;
    this.selection.visible = false;
    this.renderer.render(this.scene, this.camera);
    const data = new Promise<Blob>((resolve, reject) => {
      this.renderer.domElement.toBlob(blob => blob ? resolve(blob) : reject(new Error('PNG encoding failed')), 'image/png');
    });
    this.selection.visible = visible;
    this.render();
    return data;
  }
  thumbnail(shot: CameraShot) {
    const camera = this.getCamera();
    const previousAmbience = this.currentAmbience;
    this.ambience(shot.ambience);
    this.renderer.shadowMap.needsUpdate = true;
    this.setCamera(shot);
    const selected = this.selection.visible;
    this.selection.visible = false;
    this.renderer.render(this.scene, this.camera);
    const canvas = document.createElement('canvas');
    canvas.width = 260; canvas.height = 144;
    canvas.getContext('2d')!.drawImage(this.renderer.domElement, 0, 0, 260, 144);
    this.selection.visible = selected;
    if (previousAmbience) this.ambience(JSON.parse(previousAmbience) as Ambience);
    this.renderer.shadowMap.needsUpdate = true;
    this.setCamera(camera);
    return canvas;
  }
  private pointerDown = (event: PointerEvent) => { this.pointerStart = [event.clientX, event.clientY]; };
  private pointerUp = (event: PointerEvent) => {
    if (event.button !== 0 || Math.hypot(event.clientX - this.pointerStart[0], event.clientY - this.pointerStart[1]) > 5) return;
    const rect = this.renderer.domElement.getBoundingClientRect();
    const pointer = new THREE.Vector2((event.clientX - rect.left) / rect.width * 2 - 1, -(event.clientY - rect.top) / rect.height * 2 + 1);
    const raycaster = new THREE.Raycaster();
    raycaster.setFromCamera(pointer, this.camera);
    const hit = raycaster.intersectObjects([...this.objects.values()].filter(group => group.visible), true)[0];
    let object: THREE.Object3D | null = hit?.object ?? null;
    while (object && !object.userData.objectId) object = object.parent;
    this.onSelect(object ? String(object.userData.objectId) : null);
  };
  private resize = () => {
    const { width, height } = this.container.getBoundingClientRect();
    this.renderer.setSize(width, height);
    this.camera.aspect = width / height;
    this.camera.updateProjectionMatrix();
    this.render();
  };
  render = () => {
    if (this.disposed) return;
    cancelAnimationFrame(this.frame);
    this.frame = requestAnimationFrame(() => {
      this.renderer.render(this.scene, this.camera);
      if (!this.rendered) { this.container.dataset.ready = 'true'; this.rendered = true; }
    });
  };
  dispose() {
    this.disposed = true;
    cancelAnimationFrame(this.frame); this.observer.disconnect();
    this.controls.dispose(); this.water.dispose(); this.pmrem.dispose(); this.environment.dispose();
    this.renderer.domElement.removeEventListener('pointerdown', this.pointerDown);
    this.renderer.domElement.removeEventListener('pointerup', this.pointerUp);
    this.scene.traverse(object => {
      if (object instanceof THREE.Mesh) {
        object.geometry.dispose();
        const materials = Array.isArray(object.material) ? object.material : [object.material];
        materials.forEach(material => material.dispose());
      }
    });
    this.renderer.dispose(); this.renderer.domElement.remove();
  }
}

export function createLibraryPreview(kind: AssetKind, element: HTMLElement) {
  const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setSize(160, 126);
  renderer.setPixelRatio(1);
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.5;
  const scene = new THREE.Scene();
  scene.add(new THREE.HemisphereLight('#ffffff', '#707a6e', 3));
  const light = new THREE.DirectionalLight('#ffe4bf', 4); light.position.set(4, 8, 5); scene.add(light);
  const object = makeObject({ id: kind, name: kind, kind, position: [0, 0, 0], rotation: 0, scale: 1, material: 'oak', visible: true }, standard('#ab906a'));
  scene.add(object);
  const bounds = new THREE.Box3().setFromObject(object);
  const center = bounds.getCenter(new THREE.Vector3());
  const size = bounds.getSize(new THREE.Vector3()).length();
  const camera = new THREE.PerspectiveCamera(38, 160 / 126, 0.01, 100);
  camera.position.copy(center).add(new THREE.Vector3(size * 0.7, size * 0.4, size * 1.3));
  camera.lookAt(center);
  renderer.render(scene, camera);
  const canvas = document.createElement('canvas'); canvas.width = 160; canvas.height = 126;
  canvas.getContext('2d')!.drawImage(renderer.domElement, 0, 0);
  element.replaceChildren(canvas);
  renderer.dispose(); renderer.forceContextLoss();
  scene.traverse(item => {
    if (item instanceof THREE.Mesh) {
      if (![boxGeometry, leafGeometry, trunkGeometry].includes(item.geometry)) item.geometry.dispose();
      const materials = Array.isArray(item.material) ? item.material : [item.material];
      materials.forEach(material => { if (![dark, fabric, stone, metal, bark, whiteBark].includes(material as THREE.MeshStandardMaterial)) material.dispose(); });
    }
  });
}
