export type Point = [number, number, number]
export type Kind = 'canopy' | 'pavilion' | 'site' | 'landscape' | 'curve' | 'extrusion' | 'loft'
export type Layer = { id: string; name: string; color: string; visible: boolean; locked: boolean }
export type Entity = {
  id: string
  name: string
  kind: Kind
  layerId: string
  position: Point
  rotation: number
  scale: number
  points: Point[]
  sections: Point[][]
  height: number
  ribs: number
}
export type Project = { version: 1; name: string; layers: Layer[]; objects: Entity[] }
export type History = { past: Project[]; present: Project; future: Project[] }
export const STORAGE_KEY = 'rhova.project.v1'
export const freshEntity = (kind: Kind, id: string, layerId: string, name: string): Entity => ({
  id, name, kind, layerId, position: [0, 0, 0], rotation: 0, scale: 1,
  points: [], sections: [], height: 9, ribs: 32,
})

export function createMuseum(): Project {
  return {
    version: 1,
    name: 'Aurelian Museum',
    layers: [
      { id: 'canopy', name: '01  Canopy · structure', color: '#bb995d', visible: true, locked: false },
      { id: 'pavilion', name: '02  Pavilion · glazing', color: '#689da6', visible: true, locked: false },
      { id: 'site', name: '03  Site · hardscape', color: '#ada898', visible: true, locked: false },
      { id: 'landscape', name: '04  Landscape', color: '#728772', visible: true, locked: false },
      { id: 'curves', name: '05  Construction curves', color: '#9c6ca6', visible: true, locked: false },
      { id: 'design', name: '06  Design studies', color: '#b68659', visible: true, locked: false },
    ],
    objects: [
      freshEntity('canopy', 'roof', 'canopy', 'Canopy / ribbed shell'),
      freshEntity('pavilion', 'building', 'pavilion', 'Museum / glazed pavilion'),
      freshEntity('site', 'ground', 'site', 'Terraces / reflecting pool'),
      freshEntity('landscape', 'trees', 'landscape', 'Grove / planted landscape'),
      { ...freshEntity('curve', 'profile-a', 'curves', 'Profile A / west'), points: [[-16, -8, 5], [-9, -8, 11], [0, -8, 15], [9, -8, 12], [16, -8, 5]] },
      { ...freshEntity('curve', 'profile-b', 'curves', 'Profile B / east'), points: [[-16, 8, 5], [-9, 8, 11], [0, 8, 14], [9, 8, 10], [16, 8, 5]] },
    ],
  }
}

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
export function updateEntity(project: Project, id: string, patch: Partial<Entity>): Project {
  return { ...project, objects: project.objects.map(object => object.id === id ? { ...object, ...patch } : object) }
}
export function transformPoint(point: Point, object: Entity): Point {
  const a = object.rotation * Math.PI / 180
  const [x, y, z] = point.map(value => value * object.scale)
  return [x * Math.cos(a) - y * Math.sin(a) + object.position[0], x * Math.sin(a) + y * Math.cos(a) + object.position[1], z + object.position[2]]
}
export function inversePoint(point: Point, object: Entity): Point {
  const [x, y, z] = point.map((value, i) => value - object.position[i])
  const a = -object.rotation * Math.PI / 180
  return [(x * Math.cos(a) - y * Math.sin(a)) / object.scale, (x * Math.sin(a) + y * Math.cos(a)) / object.scale, z / object.scale]
}
export function extrudeCurve(curve: Entity, height: number, id: string): Entity {
  if (curve.kind !== 'curve' || curve.points.length < 2 || !Number.isFinite(height) || height <= 0 || height > 100) throw new Error('Select a curve and use a height between 0 and 100 m.')
  return { ...freshEntity('extrusion', id, 'design', `Extrusion / ${curve.name}`), points: curve.points.map(point => transformPoint(point, curve)), height }
}
export function loftCurves(curves: Entity[], id: string): Entity {
  if (curves.length !== 2 || curves.some(curve => curve.kind !== 'curve' || curve.points.length < 2)) throw new Error('Select two curves to loft. Hold Shift to add to selection.')
  return { ...freshEntity('loft', id, 'design', 'Loft / ruled surface'), sections: curves.map(curve => curve.points.map(point => transformPoint(point, curve))) }
}
export function serializeProject(project: Project): string {
  return JSON.stringify(project, null, 2)
}
const record = (value: unknown): value is Record<string, unknown> => typeof value === 'object' && value !== null && !Array.isArray(value)
const finite = (value: unknown): value is number => typeof value === 'number' && Number.isFinite(value) && Math.abs(value) <= 10000
const point = (value: unknown): value is Point => Array.isArray(value) && value.length === 3 && value.every(finite)
const points = (value: unknown): value is Point[] => Array.isArray(value) && value.length <= 200 && value.every(point)
const shortText = (value: unknown): value is string => typeof value === 'string' && value.length > 0 && value.length <= 120
const kinds: Kind[] = ['canopy', 'pavilion', 'site', 'landscape', 'curve', 'extrusion', 'loft']

export function parseProject(text: string): Project {
  if (text.length > 2_000_000) throw new Error('Project exceeds the 2 MB limit.')
  const data: unknown = JSON.parse(text)
  if (!record(data) || data.version !== 1 || !shortText(data.name) || !Array.isArray(data.layers) || !Array.isArray(data.objects) || data.layers.length < 1 || data.layers.length > 30 || data.objects.length > 200) throw new Error('Invalid Rhova project.')
  const layers: Layer[] = data.layers.map(value => {
    if (!record(value) || !shortText(value.id) || !shortText(value.name) || typeof value.color !== 'string' || !/^#[0-9a-f]{6}$/i.test(value.color) || typeof value.visible !== 'boolean' || typeof value.locked !== 'boolean') throw new Error('Invalid layer.')
    return { id: value.id, name: value.name, color: value.color, visible: value.visible, locked: value.locked }
  })
  const objects: Entity[] = data.objects.map(value => {
    if (!record(value) || !shortText(value.id) || !shortText(value.name) || !kinds.includes(value.kind as Kind) || typeof value.layerId !== 'string' || !layers.some(layer => layer.id === value.layerId) || !point(value.position) || !finite(value.rotation) || !finite(value.scale) || value.scale <= 0 || value.scale > 20 || !points(value.points) || !Array.isArray(value.sections) || value.sections.length > 2 || !value.sections.every(points) || !finite(value.height) || value.height <= 0 || value.height > 100 || !Number.isInteger(value.ribs) || typeof value.ribs !== 'number' || value.ribs < 8 || value.ribs > 64) throw new Error('Invalid geometry or transform.')
    if (['curve', 'extrusion'].includes(value.kind as string) && value.points.length < 2) throw new Error('A curve needs at least two points.')
    if (value.kind === 'loft' && (value.sections.length !== 2 || value.sections.some(section => section.length < 2))) throw new Error('A loft needs two sections.')
    return { id: value.id, name: value.name, kind: value.kind as Kind, layerId: value.layerId, position: value.position, rotation: value.rotation, scale: value.scale, points: value.points, sections: value.sections as Point[][], height: value.height, ribs: value.ribs }
  })
  if (new Set(layers.map(layer => layer.id)).size !== layers.length || new Set(objects.map(object => object.id)).size !== objects.length) throw new Error('Duplicate project identifiers.')
  return { version: 1, name: data.name, layers, objects }
}
