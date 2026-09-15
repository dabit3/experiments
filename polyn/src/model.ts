export type Vec3 = [number, number, number]
export const kinds = ['shell', 'mezzanine', 'stair', 'sofa', 'chair', 'table', 'rug', 'plant', 'kitchen', 'art', 'pendant', 'shelf', 'bed', 'cube', 'sphere', 'cylinder'] as const
export type Kind = typeof kinds[number]
export interface SceneObject {
  id: string
  name: string
  kind: Kind
  collection: string
  position: Vec3
  rotation: Vec3
  scale: Vec3
  color: string
  roughness: number
  metallic: number
  visible: boolean
  keyframes: { frame: number; position: Vec3; rotation: Vec3; scale: Vec3 }[]
}
export interface CameraBookmark { name: string; position: Vec3; target: Vec3 }
export interface Project { version: 1; name: string; objects: SceneObject[]; cameras: CameraBookmark[] }
export interface History { past: Project[]; present: Project; future: Project[] }
export type HistoryAction = { type: 'edit'; project: Project } | { type: 'undo' } | { type: 'redo' }
export const STORAGE_KEY = 'polyn.project.v1'
export const defaultCameras: CameraBookmark[] = [
  { name: '01 · Atelier overview', position: [13, 10.5, 15.5], target: [0, 2.1, 0] },
  { name: '02 · Living room', position: [9, 6, 12], target: [1, 1, 0.8] },
  { name: '03 · Mezzanine', position: [9, 9, 11], target: [-1.5, 3.2, -1.4] },
  { name: '04 · Front elevation', position: [0, 5, 20], target: [0, 2.6, 0] },
]
function object(id: string, name: string, kind: Kind, collection: string, position: Vec3, color: string, rotation: Vec3 = [0, 0, 0], scale: Vec3 = [1, 1, 1]): SceneObject {
  return { id, name, kind, collection, position, color, rotation, scale, roughness: 0.72, metallic: 0, visible: true, keyframes: [] }
}
export function createProject(): Project {
  return {
    version: 1,
    name: 'Atelier No. 04',
    cameras: structuredClone(defaultCameras),
    objects: [
      object('shell', 'Concrete shell', 'shell', 'Architecture', [0, 0, 0], '#c4beb1'),
      object('mezzanine', 'Oak mezzanine', 'mezzanine', 'Architecture', [0, 0, 0], '#ac8051'),
      object('stair', 'Sculptural stair', 'stair', 'Architecture', [-3.65, -1.05, 0], '#b59c76'),
      object('kitchen', 'Kitchen · limestone', 'kitchen', 'Architecture', [2.5, 2.9, 0], '#cfc5b1'),
      object('sofa', 'Sofa · Sienna', 'sofa', 'Furniture', [0.55, -0.4, 0], '#b96035'),
      object('chair', 'Lounge chair · Bouclé', 'chair', 'Furniture', [3.55, -1.45, 0], '#e1d6bf', [0, 0, -30]),
      object('table', 'Travertine coffee table', 'table', 'Furniture', [0.55, -2.4, 0], '#b9ae92'),
      object('rug', 'Woven wool rug', 'rug', 'Furniture', [0.9, -1.45, 0.015], '#c9bc9d'),
      object('shelf', 'Studio shelving', 'shelf', 'Furniture', [-4.55, 2.1, 3.22], '#8f6f4b'),
      object('bed', 'Daybed · Linen', 'bed', 'Furniture', [-2.4, 2.55, 3.22], '#e8deca'),
      object('art', 'Composition No. 04', 'art', 'Objects & greenery', [1.45, 3.81, 2.7], '#ae5638'),
      object('plant-1', 'Strelitzia · tall', 'plant', 'Objects & greenery', [4.25, 1.2, 0], '#537249', [0, 0, 10], [1.15, 1.15, 1.15]),
      object('plant-2', 'Ficus · mezzanine', 'plant', 'Objects & greenery', [-0.85, 2.95, 3.22], '#4f6742', [0, 0, 60], [0.62, 0.62, 0.62]),
      object('plant-3', 'Strelitzia · entry', 'plant', 'Objects & greenery', [-4.35, -3.05, 0], '#61764a', [0, 0, -30], [0.78, 0.78, 0.78]),
      object('pendant', 'Pendant · Orbit', 'pendant', 'Lighting', [1, 0.1, 4.55], '#d9b97b'),
    ],
  }
}
export function historyReducer(state: History, action: HistoryAction): History {
  if (action.type === 'undo') {
    const prev = state.past.at(-1)
    return prev ? { past: state.past.slice(0, -1), present: prev, future: [state.present, ...state.future] } : state
  }
  if (action.type === 'redo') {
    const next = state.future[0]
    return next ? { past: [...state.past, state.present], present: next, future: state.future.slice(1) } : state
  }
  if (JSON.stringify(state.present) === JSON.stringify(action.project)) return state
  return { past: [...state.past.slice(-59), state.present], present: action.project, future: [] }
}
export function updateObject(project: Project, id: string, patch: Partial<Omit<SceneObject, 'id' | 'kind'>>): Project {
  return { ...project, objects: project.objects.map(o => o.id === id ? { ...o, ...patch } : o) }
}
export function duplicateObject(project: Project, id: string, newId: string): Project {
  const original = project.objects.find(o => o.id === id)
  if (!original) return project
  const copy = structuredClone(original)
  copy.id = newId
  copy.name = `${original.name}.001`
  copy.position[0] += 0.8
  copy.position[1] -= 0.6
  return { ...project, objects: [...project.objects, copy] }
}
export function addObject(project: Project, kind: 'cube' | 'sphere' | 'cylinder' | 'plant', id: string): Project {
  return { ...project, objects: [...project.objects, object(id, kind[0].toUpperCase() + kind.slice(1), kind, 'Added objects', [1.5, -3, 0.5], kind === 'plant' ? '#637c49' : '#b99c79')] }
}
export function removeObject(project: Project, id: string): Project {
  return { ...project, objects: project.objects.filter(o => o.id !== id) }
}
const isRecord = (x: unknown): x is Record<string, unknown> => typeof x === 'object' && x !== null
const vec = (x: unknown): x is Vec3 => Array.isArray(x) && x.length === 3 && x.every(n => typeof n === 'number' && Number.isFinite(n) && Math.abs(n) <= 10000)
const numberIn = (x: unknown, min: number, max: number): x is number => typeof x === 'number' && Number.isFinite(x) && x >= min && x <= max
export function parseProject(text: string): Project {
  if (text.length > 2_000_000) throw new Error('Project is too large (2 MB limit).')
  const p: unknown = JSON.parse(text)
  if (!isRecord(p) || p.version !== 1 || typeof p.name !== 'string' || p.name.length > 100 || !Array.isArray(p.objects) || p.objects.length > 200 || !Array.isArray(p.cameras) || p.cameras.length > 30) throw new Error('This is not a supported Polyn project.')
  const ids = new Set<string>()
  for (const o of p.objects) {
    if (!isRecord(o) || typeof o.id !== 'string' || ids.has(o.id) || typeof o.name !== 'string' || o.name.length > 100 || typeof o.collection !== 'string' || !kinds.includes(o.kind as Kind) || !vec(o.position) || !vec(o.rotation) || !vec(o.scale) || o.scale.some(v => v <= 0 || v > 100) || typeof o.color !== 'string' || !/^#[\da-f]{6}$/i.test(o.color) || !numberIn(o.roughness, 0, 1) || !numberIn(o.metallic, 0, 1) || typeof o.visible !== 'boolean' || !Array.isArray(o.keyframes) || o.keyframes.length > 250) throw new Error('Invalid object data in project.')
    const frames = new Set<number>()
    for (const k of o.keyframes) {
      if (!isRecord(k) || !numberIn(k.frame, 1, 250) || !Number.isInteger(k.frame) || frames.has(k.frame) || !vec(k.position) || !vec(k.rotation) || !vec(k.scale) || k.scale.some(v => v <= 0 || v > 100)) throw new Error('Invalid animation keyframe.')
      frames.add(k.frame)
    }
    ids.add(o.id)
  }
  for (const c of p.cameras) {
    if (!isRecord(c) || typeof c.name !== 'string' || c.name.length > 100 || !vec(c.position) || !vec(c.target)) throw new Error('Invalid saved camera.')
  }
  return p as unknown as Project
}
export function serializeProject(project: Project): string {
  return JSON.stringify(project, null, 2)
}
export function setKeyframe(project: Project, id: string, frame: number): Project {
  const o = project.objects.find(item => item.id === id)
  if (!o) return project
  const keyframe = { frame, position: [...o.position] as Vec3, rotation: [...o.rotation] as Vec3, scale: [...o.scale] as Vec3 }
  return updateObject(project, id, { keyframes: [...o.keyframes.filter(k => k.frame !== frame), keyframe].sort((a, b) => a.frame - b.frame) })
}
export function sampleObject(o: SceneObject, frame: number): Pick<SceneObject, 'position' | 'rotation' | 'scale'> {
  if (!o.keyframes.length) return o
  const keys = [...o.keyframes].sort((a, b) => a.frame - b.frame)
  const a = [...keys].reverse().find(k => k.frame <= frame) ?? keys[0]
  const b = keys.find(k => k.frame >= frame) ?? keys[keys.length - 1]
  const t = a.frame === b.frame ? 0 : (frame - a.frame) / (b.frame - a.frame)
  const mix = (u: Vec3, v: Vec3): Vec3 => u.map((n, i) => n + (v[i] - n) * t) as Vec3
  return { position: mix(a.position, b.position), rotation: mix(a.rotation, b.rotation), scale: mix(a.scale, b.scale) }
}
export function downloadFile(blob: Blob, name: string): void {
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = name
  a.click()
  setTimeout(() => URL.revokeObjectURL(url), 1000)
}
