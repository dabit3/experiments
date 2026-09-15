export type Vec3 = [number, number, number]
export const kinds = ['box', 'sphere', 'cylinder', 'torus', 'sculpture', 'rib', 'shell', 'window', 'bench', 'plant', 'plinth'] as const
export type Kind = typeof kinds[number]
export type Category = 'Architecture' | 'Sculptures' | 'Furniture' | 'Landscape'
export interface Transform { position: Vec3; rotation: Vec3; scale: Vec3 }
export interface Keyframe extends Transform { frame: number }
export interface SceneObject extends Transform {
  id: string
  name: string
  kind: Kind
  category: Category
  color: string
  roughness: number
  metalness: number
  twist: number
  visible: boolean
  keys: Keyframe[]
}
export interface Project { version: 1; name: string; objects: SceneObject[] }
export interface History { past: Project[]; present: Project; future: Project[] }
export const STORAGE_KEY = 'vexel.project.v1'
export const transform = (o: Transform): Transform => ({
  position: [...o.position], rotation: [...o.rotation], scale: [...o.scale],
})

function object(id: string, name: string, kind: Kind, category: Category, position: Vec3, color: string, scale: Vec3 = [1, 1, 1]): SceneObject {
  return { id, name, kind, category, position, rotation: [0, 0, 0], scale, color, roughness: 0.65, metalness: 0, twist: 0, visible: true, keys: [] }
}

export function initialProject(): Project {
  const objects: SceneObject[] = [
    object('gallery', 'Gallery · limestone shell', 'shell', 'Architecture', [0, 0, 0], '#d6ccba'),
    ...Array.from({ length: 11 }, (_, i) => object(`rib-${i}`, `Arch rib ${String(i + 1).padStart(2, '0')}`, 'rib', 'Architecture', [0, 0, -9 + i * 1.8], '#e7dfcf')),
    object('glazing', 'West glazing · bronze mullions', 'window', 'Architecture', [-6.8, 0, 0], '#5b5548'),
    object('plinth-1', 'Plinth 01 · travertine', 'plinth', 'Sculptures', [0, 0, 1.3], '#cfc0a6', [2.5, 0.65, 2.5]),
    object('hero', 'Continuum · bronze study', 'sculpture', 'Sculptures', [0, 0.68, 1.3], '#b7894f', [1.35, 1.35, 1.35]),
    object('plinth-2', 'Plinth 02 · ivory', 'plinth', 'Sculptures', [-3.5, 0, -3.1], '#e4dfd1', [1.9, 1.5, 1.9]),
    object('orb', 'Orbital · polished stone', 'sphere', 'Sculptures', [-3.5, 2.3, -3.1], '#688078', [1.45, 1.45, 1.45]),
    object('plinth-3', 'Plinth 03 · graphite', 'plinth', 'Sculptures', [3.4, 0, -5.1], '#625d52', [1.75, 1.1, 1.75]),
    object('ribbon', 'Helix · folded brass', 'box', 'Sculptures', [3.4, 2.75, -5.1], '#b08a58', [1.3, 3.1, 0.32]),
    object('plinth-4', 'Plinth 04 · sandstone', 'plinth', 'Sculptures', [0.5, 0, -7.8], '#cec1a5', [1.55, 0.8, 1.55]),
    object('ring', 'Aperture · oxidized copper', 'torus', 'Sculptures', [0.5, 2.25, -7.8], '#546e65', [1.2, 1.2, 1.2]),
    object('bench-1', 'Bench 01 · oak & linen', 'bench', 'Furniture', [3.7, 0, 4.8], '#ad9270'),
    object('bench-2', 'Bench 02 · oak & linen', 'bench', 'Furniture', [-3.8, 0, 5.8], '#ad9270'),
    object('plant-1', 'Ficus 01 · entrance', 'plant', 'Landscape', [-5.6, 0, 8.1], '#4b6345'),
    object('plant-2', 'Ficus 02 · rear gallery', 'plant', 'Landscape', [5.3, 0, -8.3], '#4b6345'),
  ]
  const hero = objects.find(o => o.id === 'hero')!
  hero.metalness = 0.72
  hero.roughness = 0.29
  hero.keys = [{ ...transform(hero), frame: 0 }, { ...transform(hero), rotation: [0, 180, 0], frame: 100 }]
  const ribbon = objects.find(o => o.id === 'ribbon')!
  ribbon.twist = 155
  ribbon.metalness = 0.65
  objects.find(o => o.id === 'orb')!.roughness = 0.2
  return { version: 1, name: 'Forma Gallery', objects }
}

export function commit(history: History, project: Project): History {
  if (JSON.stringify(history.present) === JSON.stringify(project)) return history
  return { past: [...history.past, history.present].slice(-60), present: project, future: [] }
}
export function undo(history: History): History {
  const previous = history.past.at(-1)
  return previous ? { past: history.past.slice(0, -1), present: previous, future: [history.present, ...history.future] } : history
}
export function redo(history: History): History {
  const next = history.future[0]
  return next ? { past: [...history.past, history.present], present: next, future: history.future.slice(1) } : history
}
export function patchObject(project: Project, id: string, patch: Partial<SceneObject>): Project {
  return { ...project, objects: project.objects.map(o => o.id === id ? { ...o, ...patch } : o) }
}
export function createPrimitive(project: Project, kind: Kind): SceneObject {
  const label = kind[0].toUpperCase() + kind.slice(1)
  let number = 1
  while (project.objects.some(o => o.id === `user-${kind}-${number}`)) number++
  return object(`user-${kind}-${number}`, `${label} ${String(number).padStart(3, '0')}`, kind, 'Sculptures', [2.8, 1, 2.8], '#91b8c4')
}
export function addKey(object: SceneObject, frame: number): Keyframe[] {
  return [...object.keys.filter(k => k.frame !== frame), { ...transform(object), frame }].sort((a, b) => a.frame - b.frame)
}
export function updateWithKeys(object: SceneObject, patch: Partial<SceneObject>, frame: number, autoKey: boolean): SceneObject {
  const next = { ...object, ...patch }
  if ((patch.position || patch.rotation || patch.scale) && (autoKey || object.keys.length > 0)) {
    const posed = { ...next, ...sample(object, frame), ...patch }
    if (object.keys.length === 0 && frame > 0) posed.keys = [{ ...transform(object), frame: 0 }]
    next.keys = addKey(posed, frame)
  }
  return next
}
export function sample(object: SceneObject, frame: number): Transform {
  if (object.keys.length === 0) return transform(object)
  const before = [...object.keys].reverse().find(k => k.frame <= frame) ?? object.keys[0]
  const after = object.keys.find(k => k.frame >= frame) ?? object.keys.at(-1)!
  const t = after.frame === before.frame ? 0 : (frame - before.frame) / (after.frame - before.frame)
  const mix = (a: Vec3, b: Vec3): Vec3 => a.map((v, i) => v + (b[i] - v) * t) as Vec3
  return { position: mix(before.position, after.position), rotation: mix(before.rotation, after.rotation), scale: mix(before.scale, after.scale) }
}
const record = (v: unknown): v is Record<string, unknown> => typeof v === 'object' && v !== null && !Array.isArray(v)
const finite = (v: unknown, min: number, max: number): v is number => typeof v === 'number' && Number.isFinite(v) && v >= min && v <= max
const vector = (v: unknown, min: number, max: number): v is Vec3 => Array.isArray(v) && v.length === 3 && v.every(n => finite(n, min, max))
const validTransform = (v: Record<string, unknown>) => vector(v.position, -1000, 1000) && vector(v.rotation, -36000, 36000) && vector(v.scale, 0.01, 100)
export function parseProject(text: string): Project {
  if (text.length > 2_000_000) throw new Error('Project exceeds the 2 MB limit.')
  const data: unknown = JSON.parse(text)
  if (!record(data) || data.version !== 1 || typeof data.name !== 'string' || !data.name.trim() || data.name.length > 100 || !Array.isArray(data.objects) || data.objects.length > 200) throw new Error('Invalid Vexel project.')
  const ids = new Set<string>()
  for (const item of data.objects) {
    if (!record(item) || typeof item.id !== 'string' || !/^[\w-]{1,80}$/.test(item.id) || ids.has(item.id) ||
      typeof item.name !== 'string' || !item.name.trim() || item.name.length > 100 ||
      !kinds.includes(item.kind as Kind) || !['Architecture', 'Sculptures', 'Furniture', 'Landscape'].includes(String(item.category)) ||
      typeof item.color !== 'string' || !/^#[\da-f]{6}$/i.test(item.color) ||
      !finite(item.roughness, 0, 1) || !finite(item.metalness, 0, 1) || !finite(item.twist, -360, 360) ||
      typeof item.visible !== 'boolean' || !validTransform(item) || !Array.isArray(item.keys) || item.keys.length > 101) throw new Error('Invalid object data in project.')
    ids.add(item.id)
    let previousFrame = -1
    for (const key of item.keys) {
      if (!record(key) || !finite(key.frame, 0, 100) || !Number.isInteger(key.frame) || key.frame <= previousFrame || !validTransform(key)) throw new Error('Invalid animation keys.')
      previousFrame = key.frame
    }
  }
  return data as unknown as Project
}
export const serializeProject = (project: Project) => JSON.stringify(project, null, 2)
