export const categories = ['Wall', 'Curtain Wall', 'Door', 'Floor', 'Roof', 'Timber Fins', 'Furniture', 'Landscape'] as const
export type Category = typeof categories[number]
export const materials = ['Concrete', 'Limestone', 'Timber', 'Glass', 'Plaster', 'Metal'] as const
export type Material = typeof materials[number]
export type View = '3D' | 'Level 1' | 'South'
export type Point = { x: number; z: number }
export interface Element {
  id: string
  name: string
  category: Category
  material: Material
  x: number
  z: number
  y: number
  w: number
  d: number
  h: number
  rotation: number
  hostId?: string
}
export interface Project {
  version: 1
  name: string
  elements: Element[]
  hidden: Category[]
}
export interface History {
  past: Project[]
  present: Project
  future: Project[]
}
export const STORAGE_KEY = 'veyra.project.v1'
export const round = (n: number) => Math.round(n * 1000) / 1000
export const snap = (n: number) => Math.round(n * 2) / 2
export const isWall = (e: Element) => e.category === 'Wall' || e.category === 'Curtain Wall'
export const localPoint = (e: Element, p: Point): Point => ({
  x: (p.x - e.x) * Math.cos(e.rotation) + (p.z - e.z) * Math.sin(e.rotation),
  z: -(p.x - e.x) * Math.sin(e.rotation) + (p.z - e.z) * Math.cos(e.rotation),
})
export const worldPoint = (e: Element, p: Point): Point => ({
  x: e.x + p.x * Math.cos(e.rotation) - p.z * Math.sin(e.rotation),
  z: e.z + p.x * Math.sin(e.rotation) + p.z * Math.cos(e.rotation),
})

export function createProject(): Project {
  const elements: Element[] = []
  const add = (id: string, name: string, category: Category, material: Material, x: number, z: number, y: number, w: number, d: number, h: number, rotation = 0) => {
    elements.push({ id, name, category, material, x, z, y, w, d, h, rotation })
  }
  add('slab-01', 'Ground terrace · honed limestone', 'Floor', 'Limestone', 0, 0, -.45, 33, 23, .45)
  add('slab-02', 'Gallery floor · Level 2', 'Floor', 'Concrete', -6, -1, 4, 19, 17, .42)
  add('slab-03', 'East gallery floor', 'Floor', 'Concrete', 9.5, 0, 4, 12, 19, .42)
  add('roof-01', 'Floating gallery canopy', 'Roof', 'Concrete', -6, -1, 8.2, 20, 18, .38)
  add('roof-02', 'East wing roof garden', 'Roof', 'Concrete', 9.5, 0, 7, 12.6, 19.6, .38)
  add('wall-01', 'Gallery · north concrete wall', 'Wall', 'Concrete', -6, -8.2, 0, 18, .35, 8.2)
  add('wall-02', 'West gallery enclosure', 'Wall', 'Concrete', -14.6, -1, 0, 14.4, .35, 8.2, Math.PI / 2)
  add('wall-03', 'Gallery partition', 'Wall', 'Plaster', -7, 0, 0, 7, .2, 3.9, Math.PI / 2)
  add('wall-04', 'Archive · enclosure', 'Wall', 'Concrete', 8.8, -8.5, 0, 11.6, .35, 7)
  add('wall-05', 'Gallery partition · Level 2', 'Wall', 'Plaster', -7, -3, 4.42, 6, .2, 3.7)
  add('glass-01', 'South curtain wall · ground', 'Curtain Wall', 'Glass', -6, 6.5, 0, 18, .12, 4)
  add('glass-02', 'South curtain wall · upper', 'Curtain Wall', 'Glass', -6, 6.5, 4.42, 18, .12, 3.78)
  add('glass-03', 'Courtyard curtain wall', 'Curtain Wall', 'Glass', 3, -1, 0, 15, .12, 8.2, Math.PI / 2)
  add('glass-04', 'East facade · ground', 'Curtain Wall', 'Glass', 15.2, 0, 0, 17, .12, 4, Math.PI / 2)
  add('glass-05', 'East facade · upper', 'Curtain Wall', 'Glass', 15.2, 0, 4.42, 17, .12, 2.58, Math.PI / 2)
  add('glass-06', 'Atrium entrance glazing', 'Curtain Wall', 'Glass', 9.3, 8.5, 0, 11.8, .12, 4)
  add('glass-07', 'Reading room · upper', 'Curtain Wall', 'Glass', 9.3, 8.5, 4.42, 11.8, .12, 2.58)
  add('fins-01', 'Vertical oak solar screen', 'Timber Fins', 'Timber', -6, 7.12, 4.42, 18.3, .48, 3.78)
  add('fins-02', 'East wing oak solar screen', 'Timber Fins', 'Timber', 15.8, 0, 4.42, 17.2, .48, 2.58, Math.PI / 2)
  add('door-01', 'Main entrance · glazed double', 'Door', 'Glass', 9.3, 8.5, 0, 2.4, .16, 2.8)
  elements[elements.length - 1].hostId = 'glass-06'
  add('door-02', 'Gallery connecting door', 'Door', 'Timber', -7, 1, 0, 1.2, .2, 2.4, Math.PI / 2)
  elements[elements.length - 1].hostId = 'wall-03'
  for (let i = 0; i < 3; i++) {
    add(`bench-${i}`, `Gallery bench ${i + 1}`, 'Furniture', 'Timber', -11 + i * 5, 3, .45, 3.1, .7, .28)
    add(`art-${i}`, `Sculpture plinth ${i + 1}`, 'Furniture', 'Limestone', -11 + i * 5, -.5, 0, .9, .9, 1.05)
  }
  for (let i = 0; i < 4; i++) add(`table-${i}`, `Reading table ${i + 1}`, 'Furniture', 'Timber', 6 + (i % 2) * 5, -4 + Math.floor(i / 2) * 6, 4.42, 2.4, 1.2, .78)
  add('landscape-01', 'Public realm · trees and planting', 'Landscape', 'Timber', 0, 0, -.5, 54, 40, .3)
  return { version: 1, name: 'Alder Cultural Pavilion', elements, hidden: [] }
}

export function wallFromPoints(start: Point, end: Point, id: string): Element {
  if (![start.x, start.z, end.x, end.z].every(n => Number.isFinite(n) && Math.abs(n) <= 100)) throw new Error('Wall points exceed supported model bounds.')
  const a = { x: snap(start.x), z: snap(start.z) }
  const b = { x: snap(end.x), z: snap(end.z) }
  const w = Math.hypot(b.x - a.x, b.z - a.z)
  if (w < .5) throw new Error('Wall must be at least 0.5 m long.')
  if (w > 100) throw new Error('Wall length cannot exceed 100 m.')
  return {
    id, name: 'Interior wall · new', category: 'Wall', material: 'Plaster',
    x: round((a.x + b.x) / 2), z: round((a.z + b.z) / 2), y: 0,
    w: round(w), d: .2, h: 3.6, rotation: Math.atan2(b.z - a.z, b.x - a.x),
  }
}

export function placeDoor(project: Project, p: Point, id: string): Element {
  const walls = project.elements.filter(e => isWall(e) && e.y < 1 && !project.hidden.includes(e.category))
    .map(e => ({ e, local: localPoint(e, p) }))
    .filter(({ e, local }) => Math.abs(local.z) < 1 && Math.abs(local.x) <= e.w / 2 && e.w >= 1.4 && e.h >= 2.4)
    .sort((a, b) => Math.abs(a.local.z) - Math.abs(b.local.z))
  if (!walls.length) throw new Error('Click within 1 m of a Level 1 wall to host the door.')
  const { e: host, local } = walls[0]
  const x = Math.max(-host.w / 2 + .7, Math.min(host.w / 2 - .7, snap(local.x)))
  if (project.elements.some(e => e.hostId === host.id && Math.abs(localPoint(host, e).x - x) < (e.w + 1.2) / 2 + .1)) {
    throw new Error('This opening overlaps another door. Choose another point.')
  }
  const pos = worldPoint(host, { x, z: 0 })
  return { id, name: 'Single flush door · new', category: 'Door', material: 'Timber', ...pos, y: host.y, w: 1.2, d: host.d, h: 2.4, rotation: host.rotation, hostId: host.id }
}

export function updateElement(project: Project, next: Element): Project {
  const prev = project.elements.find(e => e.id === next.id)
  if (!prev) throw new Error('Element not found.')
  if (!next.name.trim() || next.name.length > 120) throw new Error('Name must contain 1–120 characters.')
  if (![next.x, next.z, next.y, next.w, next.d, next.h, next.rotation].every(Number.isFinite)) throw new Error('Enter valid numeric dimensions.')
  if (next.w < .1 || next.d < .05 || next.h < .1 || next.w > 100 || next.h > 30 || next.d > 100 || Math.abs(next.x) > 100 || Math.abs(next.z) > 100 || next.y < -5 || next.y > 30 || Math.abs(next.rotation) > Math.PI * 2) throw new Error('Dimensions or position exceed the supported model bounds.')
  const elements = project.elements.map(e => {
    if (e.id === next.id) return { ...next, name: next.name.trim() }
    if (e.hostId === next.id) {
      const local = localPoint(prev, e)
      if (Math.abs(local.x) + e.w / 2 > next.w / 2 || e.h > next.h) throw new Error('The wall must contain all its hosted doors.')
      return { ...e, ...worldPoint(next, local), rotation: next.rotation, y: next.y, d: next.d }
    }
    return e
  })
  const result = { ...project, elements }
  validateHosts(result)
  return result
}

export function removeElement(project: Project, id: string): Project {
  return { ...project, elements: project.elements.filter(e => e.id !== id && e.hostId !== id) }
}

export function wallSegments(wall: Element, project: Project) {
  const openings = project.elements.filter(e => e.hostId === wall.id)
    .map(door => ({ door, start: localPoint(wall, door).x - door.w / 2, end: localPoint(wall, door).x + door.w / 2 }))
    .sort((a, b) => a.start - b.start)
  const segments: { x: number; y: number; width: number; height: number }[] = []
  let cursor = -wall.w / 2
  for (const opening of openings) {
    if (opening.start > cursor) segments.push({ x: (cursor + opening.start) / 2, y: wall.h / 2, width: opening.start - cursor, height: wall.h })
    if (wall.h > opening.door.h) segments.push({ x: (opening.start + opening.end) / 2, y: (wall.h + opening.door.h) / 2, width: opening.door.w, height: wall.h - opening.door.h })
    cursor = opening.end
  }
  if (cursor < wall.w / 2) segments.push({ x: (cursor + wall.w / 2) / 2, y: wall.h / 2, width: wall.w / 2 - cursor, height: wall.h })
  return segments
}

export function commit(history: History, next: Project): History {
  if (JSON.stringify(next) === JSON.stringify(history.present)) return history
  return { past: [...history.past, history.present].slice(-50), present: next, future: [] }
}
export function undo(history: History): History {
  if (!history.past.length) return history
  return { past: history.past.slice(0, -1), present: history.past[history.past.length - 1], future: [history.present, ...history.future] }
}
export function redo(history: History): History {
  if (!history.future.length) return history
  return { past: [...history.past, history.present], present: history.future[0], future: history.future.slice(1) }
}

function validateHosts(project: Project) {
  if (project.elements.some(e => e.hostId && e.category !== 'Door')) throw new Error('Only doors can have wall hosts.')
  for (const door of project.elements.filter(e => e.category === 'Door')) {
    const host = project.elements.find(e => e.id === door.hostId)
    if (!host || !isWall(host)) throw new Error('Door must reference a valid wall.')
    const local = localPoint(host, door)
    if (Math.abs(local.z) > .01 || Math.abs(door.rotation - host.rotation) > .01 || Math.abs(door.y - host.y) > .01 || Math.abs(local.x) + door.w / 2 > host.w / 2 + .01 || door.h > host.h) throw new Error('Door opening must fit within its host wall.')
    if (project.elements.some(e => e.id !== door.id && e.hostId === host.id && Math.abs(localPoint(host, e).x - local.x) < (door.w + e.w) / 2 - .01)) throw new Error('Door openings cannot overlap.')
  }
}
export function parseProject(text: string): Project {
  if (text.length > 2_000_000) throw new Error('Project file exceeds 2 MB.')
  const value: unknown = JSON.parse(text)
  if (!value || typeof value !== 'object' || !('version' in value) || value.version !== 1 || !('name' in value) || typeof value.name !== 'string' || !value.name.trim() || value.name.length > 120 || !('elements' in value) || !Array.isArray(value.elements) || value.elements.length > 2000 || !('hidden' in value) || !Array.isArray(value.hidden)) throw new Error('Unsupported Veyra project.')
  const elements: Element[] = value.elements.map((e: unknown) => {
    if (!e || typeof e !== 'object' || !('id' in e) || typeof e.id !== 'string' || !e.id || e.id.length > 120 || !('name' in e) || typeof e.name !== 'string' || !e.name.trim() || e.name.length > 120 || !('category' in e) || !categories.includes(e.category as Category) || !('material' in e) || !materials.includes(e.material as Material)) throw new Error('Invalid element identity.')
    for (const key of ['x', 'z', 'y', 'w', 'd', 'h', 'rotation']) {
      const v: unknown = Object.getOwnPropertyDescriptor(e, key)?.value
      if (typeof v !== 'number' || !Number.isFinite(v)) throw new Error('Invalid element dimensions.')
    }
    const el = e as Element
    if (el.w < .1 || el.w > 100 || el.d < .05 || el.d > 100 || el.h < .1 || el.h > 30 || Math.abs(el.x) > 100 || Math.abs(el.z) > 100 || el.y < -5 || el.y > 30 || Math.abs(el.rotation) > Math.PI * 2 || (el.hostId !== undefined && typeof el.hostId !== 'string')) throw new Error('Element dimensions outside model bounds.')
    return { id: el.id, name: el.name, category: el.category, material: el.material, x: el.x, z: el.z, y: el.y, w: el.w, d: el.d, h: el.h, rotation: el.rotation, ...(el.hostId ? { hostId: el.hostId } : {}) }
  })
  if (new Set(elements.map(e => e.id)).size !== elements.length) throw new Error('Element IDs must be unique.')
  if (!value.hidden.every(c => categories.includes(c))) throw new Error('Invalid hidden category.')
  const project: Project = { version: 1, name: value.name, elements, hidden: [...new Set<Category>(value.hidden)] }
  validateHosts(project)
  return project
}
export const serializeProject = (project: Project) => JSON.stringify(project, null, 2)
const csvCell = (value: string | number) => `"${String(typeof value === 'string' && /^[=+\-@\t\r]/.test(value) ? `'${value}` : value).replaceAll('"', '""')}"`
export function exportSchedule(project: Project): string {
  const header = ['ID', 'Category', 'Name', 'Material', 'Host ID', 'Level (m)', 'Length (m)', 'Thickness (m)', 'Height (m)', 'Volume (m3)']
  return [header, ...project.elements.map(e => [e.id, e.category, e.name, e.material, e.hostId ?? '', e.y, e.w, e.d, e.h, round(e.w * e.d * e.h)])].map(row => row.map(csvCell).join(',')).join('\r\n')
}
export const escapeXml = (value: string) => value.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;')
export function exportPlan(project: Project): string {
  const elements = project.elements.filter(e => e.y < 1 && !project.hidden.includes(e.category) && e.category !== 'Landscape')
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="-240 -180 480 360"><rect x="-240" y="-180" width="480" height="360" fill="white"/><g transform="scale(10)" stroke="#26343e" stroke-width=".08">${elements.map(e => `<g transform="translate(${e.x} ${e.z}) rotate(${e.rotation * 180 / Math.PI})"><title>${escapeXml(e.name)}</title><rect data-id="${escapeXml(e.id)}" x="${-e.w / 2}" y="${-e.d / 2}" width="${e.w}" height="${e.d}" fill="${e.category === 'Floor' ? '#f3f0e9' : e.category === 'Door' ? 'white' : e.category === 'Curtain Wall' ? '#b6d3dd' : '#a7aba9'}"/></g>`).join('')}</g><text x="-215" y="155" font-family="sans-serif" font-size="9">${escapeXml(project.name)} · LEVEL 1 · metres</text></svg>`
}
