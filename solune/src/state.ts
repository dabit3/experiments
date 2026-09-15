export type Vector = [number, number, number]
export type ObjectKind = 'palm' | 'olive' | 'agave' | 'lounger'
export type MaterialName = 'travertine' | 'limestone' | 'charcoal' | 'terracotta'
export type Weather = 'clear' | 'overcast' | 'mist'
export interface SceneObject {
  id: string
  kind: ObjectKind
  position: Vector
  rotation: number
  scale: number
}
export interface CameraShot {
  id: string
  name: string
  position: Vector
  target: Vector
  fov: number
}
export interface Project {
  version: 1
  name: string
  time: number
  sunHeading: number
  weather: Weather
  cloud: number
  material: MaterialName
  roughness: number
  interior: number
  exposure: number
  bloom: number
  saturation: number
  vignette: number
  objects: SceneObject[]
  shots: CameraShot[]
}
export const STORAGE_KEY = 'solune.project.v1'
export const presets: CameraShot[] = [
  { id: 'arrival', name: 'Coastal arrival', position: [29, 13, 32], target: [0, 3, 0], fov: 43 },
  { id: 'pool', name: 'Poolside evening', position: [18, 5, 22], target: [-1, 3, 0], fov: 47 },
  { id: 'garden', name: 'Garden retreat', position: [-24, 9, 24], target: [-1, 3, -1], fov: 46 },
  { id: 'aerial', name: 'Above the coast', position: [26, 32, 26], target: [0, 0, 0], fov: 48 },
]
export function createProject(): Project {
  return {
    version: 1, name: 'Casa del Mar', time: 18.4, sunHeading: 235,
    weather: 'clear', cloud: 24, material: 'travertine', roughness: 0.6,
    interior: 80, exposure: 1.05, bloom: 0.28, saturation: 1.06, vignette: 0.22,
    objects: [
      { id: 'palm-1', kind: 'palm', position: [-12, 0, 5], rotation: 20, scale: 1.1 },
      { id: 'palm-2', kind: 'palm', position: [13, 0, -5], rotation: 90, scale: 1.25 },
      { id: 'olive-1', kind: 'olive', position: [-12, 0, -7], rotation: 0, scale: 1.3 },
      { id: 'palm-3', kind: 'palm', position: [-16, 0, -4], rotation: 55, scale: 0.85 },
      { id: 'olive-2', kind: 'olive', position: [13, 0, 7], rotation: 20, scale: 0.85 },
      { id: 'lounger-1', kind: 'lounger', position: [-6, 0.42, 7], rotation: 0, scale: 1 },
      { id: 'lounger-2', kind: 'lounger', position: [-3.6, 0.42, 7], rotation: 0, scale: 1 },
      { id: 'agave-1', kind: 'agave', position: [10, 0, 10], rotation: 0, scale: 1 },
    ],
    shots: structuredClone(presets),
  }
}
export const materialColors: Record<MaterialName, string> = {
  travertine: '#c8bb9f', limestone: '#e7e2d5', charcoal: '#465052', terracotta: '#bb7c61',
}
export function clamp(value: number, min: number, max: number) {
  return Math.max(min, Math.min(max, value))
}
export function sunPosition(time: number, heading: number): Vector {
  const elevation = Math.sin((time - 6) / 12 * Math.PI)
  const angle = heading * Math.PI / 180
  return [Math.cos(angle) * 60, Math.max(1.5, elevation * 65), Math.sin(angle) * 60]
}
export function daylight(time: number) {
  return clamp(Math.sin((time - 6) / 12 * Math.PI) * 1.2 + 0.24, 0.06, 1)
}
export function formatTime(time: number) {
  const minutes = Math.round(time * 60)
  return `${Math.floor(minutes / 60).toString().padStart(2, '0')}:${(minutes % 60).toString().padStart(2, '0')}`
}
export function placeObject(project: Project, kind: ObjectKind, position: Vector, id: string): Project {
  if (project.objects.some(object => object.id === id)) throw new Error('Object ID already exists')
  if (!position.every(Number.isFinite)) throw new Error('Invalid position')
  return { ...project, objects: [...project.objects, {
    id, kind, position: [clamp(position[0], -19, 19), 0.42, clamp(position[2], -12, 16)], rotation: 0, scale: 1,
  }] }
}
export interface History { past: Project[]; present: Project; future: Project[] }
export function commit(history: History, project: Project): History {
  if (JSON.stringify(history.present) === JSON.stringify(project)) return history
  return { past: [...history.past.slice(-49), history.present], present: project, future: [] }
}
export function undo(history: History): History {
  const previous = history.past.at(-1)
  return previous ? { past: history.past.slice(0, -1), present: previous, future: [history.present, ...history.future] } : history
}
export function redo(history: History): History {
  const next = history.future[0]
  return next ? { past: [...history.past, history.present], present: next, future: history.future.slice(1) } : history
}
function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}
function isVector(value: unknown): value is Vector {
  return Array.isArray(value) && value.length === 3 && value.every(v => typeof v === 'number' && Number.isFinite(v) && Math.abs(v) <= 500)
}
function numberIn(value: unknown, min: number, max: number): value is number {
  return typeof value === 'number' && Number.isFinite(value) && value >= min && value <= max
}
function isObject(value: unknown): value is SceneObject {
  return isRecord(value) && typeof value.id === 'string' && value.id.length > 0 && value.id.length < 100 &&
    ['palm', 'olive', 'agave', 'lounger'].includes(String(value.kind)) && isVector(value.position) &&
    numberIn(value.rotation, -360, 360) && numberIn(value.scale, 0.3, 3)
}
function isShot(value: unknown): value is CameraShot {
  return isRecord(value) && typeof value.id === 'string' && value.id.length > 0 && value.id.length < 100 &&
    typeof value.name === 'string' && value.name.length <= 60 && isVector(value.position) && isVector(value.target) &&
    numberIn(value.fov, 20, 90) && value.position.some((n, i) => n !== (value.target as Vector)[i])
}
export function parseProject(raw: string): Project {
  const value: unknown = JSON.parse(raw)
  if (!isRecord(value) || value.version !== 1 || typeof value.name !== 'string' || value.name.length > 100 ||
    !numberIn(value.time, 6, 22) || !numberIn(value.sunHeading, 0, 360) ||
    !['clear', 'overcast', 'mist'].includes(String(value.weather)) || !numberIn(value.cloud, 0, 100) ||
    !Object.keys(materialColors).includes(String(value.material)) || !numberIn(value.roughness, 0, 1) ||
    !numberIn(value.interior, 0, 100) || !numberIn(value.exposure, 0.4, 1.8) ||
    !numberIn(value.bloom, 0, 1.2) || !numberIn(value.saturation, 0, 1.5) || !numberIn(value.vignette, 0, 0.8) ||
    !Array.isArray(value.objects) || value.objects.length > 100 || !value.objects.every(isObject) ||
    !Array.isArray(value.shots) || value.shots.length > 12 || value.shots.length < 1 || !value.shots.every(isShot)) {
    throw new Error('This file is not a valid Solune v1 project.')
  }
  if (new Set(value.objects.map(o => o.id)).size !== value.objects.length ||
    new Set(value.shots.map(s => s.id)).size !== value.shots.length) throw new Error('Duplicate object or camera IDs.')
  return value as unknown as Project
}
export function exportProject(project: Project): string {
  return JSON.stringify(parseProject(JSON.stringify(project)), null, 2)
}
