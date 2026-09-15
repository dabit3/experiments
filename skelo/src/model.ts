export type Vec3 = [number, number, number]
export type EntityKind = 'pavilion' | 'deck' | 'tree' | 'garden' | 'furniture' | 'volume'
export type MaterialId = 'cedar' | 'oak' | 'plaster' | 'concrete' | 'charcoal' | 'sage' | 'terracotta' | 'glass'
export type Tag = 'Architecture' | 'Landscape' | 'Furniture' | 'Study'
export interface Entity {
  id: string
  name: string
  kind: EntityKind
  position: Vec3
  size: Vec3
  material: MaterialId
  tag: Tag
  group?: string
  rotation: number
}
export interface SavedScene {
  id: string
  name: string
  position: Vec3
  target: Vec3
  tags: Record<Tag, boolean>
}
export interface Project {
  version: 1
  name: string
  entities: Entity[]
  scenes: SavedScene[]
  tags: Record<Tag, boolean>
  shadows: boolean
  time: number
  edges: boolean
  axes: boolean
}
export const STORAGE_KEY = 'skelo.project.v1'
export const materials: { id: MaterialId; name: string; color: string; family: string }[] = [
  { id: 'cedar', name: 'Western red cedar', color: '#b17a49', family: 'Wood' },
  { id: 'oak', name: 'Natural white oak', color: '#d7b989', family: 'Wood' },
  { id: 'plaster', name: 'Warm lime plaster', color: '#eee8da', family: 'Stone' },
  { id: 'concrete', name: 'Board-formed concrete', color: '#aaa99d', family: 'Stone' },
  { id: 'charcoal', name: 'Charcoal standing seam', color: '#4d5c60', family: 'Metal' },
  { id: 'sage', name: 'Sage mineral finish', color: '#819885', family: 'Color' },
  { id: 'terracotta', name: 'Burnished terracotta', color: '#b86649', family: 'Color' },
  { id: 'glass', name: 'Blue tinted glass', color: '#aac5c5', family: 'Glass' },
]
export const tagNames: Tag[] = ['Architecture', 'Landscape', 'Furniture', 'Study']
export const allTags: Record<Tag, boolean> = { Architecture: true, Landscape: true, Furniture: true, Study: true }
export const standardViews: Record<string, { position: Vec3; target: Vec3 }> = {
  Perspective: { position: [26, 19, 30], target: [0, 1.8, 0] },
  Top: { position: [0, 42, 0.01], target: [0, 0, 0] },
  Front: { position: [0, 8, 37], target: [0, 2, 0] },
  Right: { position: [37, 8, 0], target: [0, 2, 0] },
  Courtyard: { position: [17, 10, 22], target: [-1, 2, -1] },
}

export function createProject(): Project {
  const entities: Entity[] = [
    { id: 'living', name: 'Living pavilion', kind: 'pavilion', position: [-2, 0.7, -5], size: [14, 3.6, 5.5], material: 'cedar', tag: 'Architecture', rotation: 0 },
    { id: 'tea', name: 'Tea room', kind: 'pavilion', position: [-7, 0.7, 0.4], size: [4.4, 3.2, 6], material: 'oak', tag: 'Architecture', rotation: Math.PI / 2 },
    { id: 'studio', name: 'Garden studio', kind: 'pavilion', position: [6, 0.7, -0.5], size: [3.5, 3.1, 6.5], material: 'cedar', tag: 'Architecture', rotation: 0 },
    { id: 'engawa', name: 'Engawa · timber terrace', kind: 'deck', position: [-1, 0.4, -0.3], size: [17.5, 0.3, 12], material: 'cedar', tag: 'Architecture', rotation: 0 },
    { id: 'zen', name: 'Karesansui · stone garden', kind: 'garden', position: [-0.5, 0.72, 2.5], size: [7.5, 0.12, 6.7], material: 'concrete', tag: 'Landscape', rotation: 0 },
    { id: 'maple', name: 'Japanese maple', kind: 'tree', position: [-11, -0.1, 4.5], size: [4.6, 6.5, 4.6], material: 'sage', tag: 'Landscape', rotation: 0 },
    { id: 'pine', name: 'Black pine', kind: 'tree', position: [9.5, -0.1, -6.8], size: [4.5, 7.2, 4.5], material: 'sage', tag: 'Landscape', rotation: 1 },
    { id: 'birch', name: 'Mountain ash', kind: 'tree', position: [-9.8, -0.1, -9.1], size: [4, 7.4, 4], material: 'sage', tag: 'Landscape', rotation: 2 },
    { id: 'bench', name: 'Courtyard bench', kind: 'furniture', position: [4.2, 0.7, 5.2], size: [2.7, 0.9, 0.9], material: 'oak', tag: 'Furniture', rotation: 0 },
  ]
  return {
    version: 1, name: 'Komorebi House', entities, tags: { ...allTags }, shadows: true, time: 15, edges: true, axes: true,
    scenes: [
      { id: 'scene-1', name: '01 · Overview', ...standardViews.Perspective, tags: { ...allTags } },
      { id: 'scene-2', name: '02 · Courtyard', ...standardViews.Courtyard, tags: { ...allTags } },
      { id: 'scene-3', name: '03 · Plan', ...standardViews.Top, tags: { ...allTags } },
    ],
  }
}

export function updateEntity(project: Project, ids: string[], patch: Partial<Pick<Entity, 'name' | 'material' | 'size' | 'position' | 'tag'>>): Project {
  if (patch.size && !patch.size.every(n => Number.isFinite(n) && n >= 0.05 && n <= 50)) throw new Error('Dimensions must be between 0.05 and 50 m.')
  if (patch.name !== undefined && (!patch.name.trim() || patch.name.length > 100)) throw new Error('Use a name between 1 and 100 characters.')
  return { ...project, entities: project.entities.map(entity => ids.includes(entity.id) ? { ...entity, ...patch } : entity) }
}

export function createVolume(project: Project, first: Vec3, second: Vec3, height = 1, id: string = crypto.randomUUID()): Project {
  const width = Math.round(Math.abs(second[0] - first[0]) * 100) / 100
  const depth = Math.round(Math.abs(second[2] - first[2]) * 100) / 100
  if (![width, depth, height].every(n => Number.isFinite(n) && n >= 0.05 && n <= 50)) throw new Error('Each dimension must be between 0.05 and 50 m.')
  if (project.entities.length >= 300) throw new Error('This demo supports up to 300 entities.')
  const entity: Entity = {
    id, kind: 'volume', name: `Volume ${project.entities.filter(e => e.kind === 'volume').length + 1}`,
    position: [(first[0] + second[0]) / 2, Math.max(first[1], second[1]), (first[2] + second[2]) / 2],
    size: [width, height, depth], rotation: 0, material: 'plaster', tag: 'Study',
  }
  return { ...project, tags: { ...project.tags, Study: true }, entities: [...project.entities, entity] }
}

export function groupEntities(project: Project, ids: string[], group: string = crypto.randomUUID()): Project {
  if (ids.length < 2) throw new Error('Select at least two entities to make a group.')
  return { ...project, entities: project.entities.map(e => ids.includes(e.id) ? { ...e, group } : e) }
}
export function ungroupEntities(project: Project, ids: string[]): Project {
  return { ...project, entities: project.entities.map(e => ids.includes(e.id) ? { ...e, group: undefined } : e) }
}
export function selectionFor(project: Project, id: string): string[] {
  const entity = project.entities.find(e => e.id === id)
  return entity?.group ? project.entities.filter(e => e.group === entity.group).map(e => e.id) : entity ? [id] : []
}
export function volume(entity: Entity): number { return entity.size[0] * entity.size[1] * entity.size[2] }
export function serializeProject(project: Project): string { return JSON.stringify(project, null, 2) }

function isRecord(value: unknown): value is Record<string, unknown> { return typeof value === 'object' && value !== null && !Array.isArray(value) }
function isVec(value: unknown, dimension = false): value is Vec3 {
  return Array.isArray(value) && value.length === 3 && value.every(n => typeof n === 'number' && Number.isFinite(n) && (dimension ? n >= 0.05 && n <= 50 : Math.abs(n) <= 1000))
}
function isTags(value: unknown): value is Record<Tag, boolean> { return isRecord(value) && tagNames.every(key => typeof value[key] === 'boolean') }
function isText(value: unknown): value is string { return typeof value === 'string' && value.trim().length > 0 && value.length <= 100 }
function isEntity(e: unknown): e is Entity {
  return isRecord(e) && isText(e.id) && isText(e.name) && ['pavilion', 'deck', 'tree', 'garden', 'furniture', 'volume'].includes(String(e.kind))
    && isVec(e.position) && isVec(e.size, true) && materials.some(m => m.id === e.material) && tagNames.some(t => t === e.tag)
    && typeof e.rotation === 'number' && Number.isFinite(e.rotation) && Math.abs(e.rotation) <= Math.PI * 2
    && (e.group === undefined || isText(e.group))
}
function isScene(s: unknown): s is SavedScene {
  return isRecord(s) && isText(s.id) && isText(s.name) && isVec(s.position) && isVec(s.target) && isTags(s.tags)
    && s.position.some((n, i) => Math.abs(n - (s.target as Vec3)[i]) > 0.001)
}
export function parseProject(text: string): Project {
  if (text.length > 2_000_000) throw new Error('Project file exceeds the 2 MB limit.')
  let value: unknown
  try { value = JSON.parse(text) } catch { throw new Error('This is not a valid JSON project.') }
  if (!isRecord(value) || value.version !== 1 || !isText(value.name) || !Array.isArray(value.entities) || value.entities.length > 300
    || !value.entities.every(isEntity) || new Set(value.entities.map(e => e.id)).size !== value.entities.length
    || !Array.isArray(value.scenes) || value.scenes.length < 1 || value.scenes.length > 30 || !value.scenes.every(isScene)
    || new Set(value.scenes.map(s => s.id)).size !== value.scenes.length || !isTags(value.tags)
    || typeof value.shadows !== 'boolean' || typeof value.edges !== 'boolean' || typeof value.axes !== 'boolean'
    || typeof value.time !== 'number' || value.time < 6 || value.time > 18) throw new Error('Unsupported or invalid Skelo project. Expected version 1 with valid dimensions, scenes and tags.')
  return { version: 1, name: value.name, entities: value.entities, scenes: value.scenes, tags: value.tags, shadows: value.shadows, time: value.time, edges: value.edges, axes: value.axes }
}
export interface History { past: Project[]; present: Project; future: Project[] }
export function commit(history: History, project: Project): History {
  if (serializeProject(history.present) === serializeProject(project)) return history
  return { past: [...history.past.slice(-49), history.present], present: project, future: [] }
}
export function undo(history: History): History {
  return history.past.length ? { past: history.past.slice(0, -1), present: history.past.at(-1)!, future: [history.present, ...history.future] } : history
}
export function redo(history: History): History {
  return history.future.length ? { past: [...history.past, history.present], present: history.future[0], future: history.future.slice(1) } : history
}
export function parseMeasurements(text: string, mode: 'rectangle' | 'height'): number[] {
  const values = text.replace(/m/g, '').split(/[,;x×]/).map(n => Number(n.trim()))
  if (values.length !== (mode === 'height' ? 1 : 3) || !values.every(n => Number.isFinite(n) && n >= 0.05 && n <= 50)) {
    throw new Error(mode === 'height' ? 'Enter a height in meters, from 0.05 to 50.' : 'Enter width, depth, height in meters. Example: 3, 2, 1.5')
  }
  return values
}
