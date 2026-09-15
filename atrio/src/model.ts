export type Kind = 'wall' | 'slab' | 'door'
export type Material = 'limestone' | 'concrete' | 'timber' | 'glass' | 'terracotta'
export type Layer = 'Structure' | 'Glazing' | 'Roofs' | 'Landscape'
export type Combination = 'All elements' | 'Architecture' | 'Structure only'
export type Element = {
  id: string
  name: string
  kind: Kind
  x: number
  z: number
  width: number
  depth: number
  height: number
  elevation: number
  rotation: number
  story: number
  material: Material
  layer: Layer
  hostId?: string
  offset?: number
}
export type Project = { version: 1; name: string; elements: Element[] }
export type History = { past: Project[]; present: Project; future: Project[] }
export type Point = { x: number; z: number }

export const STORAGE_KEY = 'atrio-project-v1'
export const MATERIALS: Record<Material, { label: string; color: string }> = {
  limestone: { label: 'Limestone · warm white', color: '#ded6c4' },
  concrete: { label: 'Concrete · off-white', color: '#e6e5df' },
  timber: { label: 'Timber · natural oak', color: '#a67a4d' },
  glass: { label: 'Glass · low iron', color: '#98b8b7' },
  terracotta: { label: 'Terracotta · clay', color: '#b77859' },
}
export const STORIES = ['0. Ground Floor', '1. Mezzanine', '2. Roof Plan']
export const PAVILIONS = [
  { name: 'Atelier', x: -19, z: 0, w: 15, d: 22, h: 4.3, number: '01' },
  { name: 'Gallery', x: 0, z: -16, w: 24, d: 12, h: 5.2, number: '02' },
  { name: 'Library', x: 20, z: -2, w: 14, d: 24, h: 4.3, number: '03' },
]
export const TREES: [number, number, number][] = [
  [-32, -23, 1.2], [-28, -17, 1], [-32, -7, 1.15], [-32, 9, 1.15],
  [-28, 22, 1.25], [-19, 25, 1], [-9, 25, 1.05], [6, 25, 1.2],
  [20, 25, 1.1], [31, 19, 1.15], [33, 6, 1.1], [33, -8, 1.3],
  [29, -22, 1], [18, -28, 1.1], [-14, -28, 1], [-4, -28, .85],
  [7, 4, .8], [-6, 5, .65],
]

export function initialProject(): Project {
  const elements: Element[] = []
  const add = (e: Partial<Element> & Pick<Element, 'id' | 'name' | 'kind'>) => {
    elements.push({
      x: 0, z: 0, width: 1, depth: .25, height: 4.3, elevation: 0,
      rotation: 0, story: 0, material: 'concrete', layer: 'Structure', ...e,
    })
  }
  PAVILIONS.forEach((p, i) => {
    add({ id: `floor-${i}`, name: `${p.name} / floor slab`, kind: 'slab', x: p.x, z: p.z, width: p.w + 1.4, depth: p.d + 1.4, height: .3, elevation: -.05, material: 'limestone' })
    add({ id: `roof-${i}`, name: `${p.name} / floating roof`, kind: 'slab', x: p.x, z: p.z, width: p.w + 2.4, depth: p.d + 2.4, height: .32, elevation: p.h, layer: 'Roofs' })
    add({ id: `north-${i}`, name: `${p.name} / north wall`, kind: 'wall', x: p.x, z: p.z - p.d / 2, width: p.w, height: p.h, material: 'limestone' })
    add({ id: `south-${i}`, name: `${p.name} / curtain wall`, kind: 'wall', x: p.x, z: p.z + p.d / 2, width: p.w, height: p.h, material: 'glass', layer: 'Glazing' })
    add({ id: `west-${i}`, name: `${p.name} / west wall`, kind: 'wall', x: p.x - p.w / 2, z: p.z, width: p.d, height: p.h, rotation: 90, material: i === 2 ? 'glass' : 'timber', layer: i === 2 ? 'Glazing' : 'Structure' })
    add({ id: `east-${i}`, name: `${p.name} / east wall`, kind: 'wall', x: p.x + p.w / 2, z: p.z, width: p.d, height: p.h, rotation: 90, material: i === 0 ? 'glass' : 'timber', layer: i === 0 ? 'Glazing' : 'Structure' })
    add({ id: `partition-${i}`, name: `${p.name} / interior partition`, kind: 'wall', x: p.x, z: p.z - p.d / 4, width: p.w * .58, height: p.h - .35, material: 'limestone' })
    add({ id: `door-${i}`, name: `${p.name} / entrance`, kind: 'door', x: p.x, z: p.z + p.d / 2, width: 1.8, height: 2.8, material: 'timber', hostId: `south-${i}`, offset: 0 })
  })
  add({ id: 'mezzanine', name: 'Gallery / mezzanine deck', kind: 'slab', x: 0, z: -19.5, width: 22, depth: 4, height: .22, elevation: 3, story: 1, material: 'timber' })
  return { version: 1, name: 'Oak & Light Arts Campus', elements }
}

export function createHistory(project: Project): History {
  return { past: [], present: project, future: [] }
}
export function commit(history: History, project: Project): History {
  if (JSON.stringify(history.present) === JSON.stringify(project)) return history
  return { past: [...history.past.slice(-79), history.present], present: project, future: [] }
}
export function undo(h: History): History {
  if (!h.past.length) return h
  return { past: h.past.slice(0, -1), present: h.past[h.past.length - 1], future: [h.present, ...h.future] }
}
export function redo(h: History): History {
  if (!h.future.length) return h
  return { past: [...h.past, h.present], present: h.future[0], future: h.future.slice(1) }
}
export function snap(value: number): number { return Math.round(value * 4) / 4 }
export function wallFromPoints(id: string, a: Point, b: Point, story: number, material: Material): Element {
  const dx = b.x - a.x, dz = b.z - a.z
  const width = Math.hypot(dx, dz)
  if (width < .5) throw new Error('A wall must be at least 0.50 m long.')
  return { id, name: 'New wall', kind: 'wall', x: (a.x + b.x) / 2, z: (a.z + b.z) / 2, width, depth: .25, height: 3.6, elevation: story * 3, rotation: Math.atan2(dz, dx) * 180 / Math.PI, story, material, layer: 'Structure' }
}
export function slabFromPoints(id: string, a: Point, b: Point, story: number, material: Material): Element {
  if (Math.abs(b.x - a.x) < .5 || Math.abs(b.z - a.z) < .5) throw new Error('A slab must be at least 0.50 × 0.50 m.')
  return { id, name: 'New slab', kind: 'slab', x: (a.x + b.x) / 2, z: (a.z + b.z) / 2, width: Math.abs(b.x - a.x), depth: Math.abs(b.z - a.z), height: .25, elevation: story * 3, rotation: 0, story, material, layer: 'Structure' }
}
export function doorOnWall(id: string, wall: Element, point: Point, project: Project): Element {
  if (wall.kind !== 'wall') throw new Error('Place a door on a wall.')
  if (project.elements.some(e => e.hostId === wall.id)) throw new Error('This wall already has a door. Select it to edit.')
  if (wall.width < 1.4 || wall.height < 2.2) throw new Error('The wall is too small for a door.')
  const r = wall.rotation * Math.PI / 180
  const offset = Math.max(-wall.width / 2 + .65, Math.min(wall.width / 2 - .65, (point.x - wall.x) * Math.cos(r) + (point.z - wall.z) * Math.sin(r)))
  return { ...wall, id, name: 'New door', kind: 'door', width: 1.2, height: 2.1, material: 'timber', hostId: wall.id, offset, x: wall.x + Math.cos(r) * offset, z: wall.z + Math.sin(r) * offset }
}
export function updateElement(project: Project, id: string, patch: Partial<Element>): Project {
  let elements = project.elements.map(e => e.id === id ? { ...e, ...patch } : e)
  elements = elements.map(e => {
    if (!e.hostId) return e
    const host = elements.find(w => w.id === e.hostId)
    if (!host) return e
    if (e.width > host.width - .1 || e.height > host.height) throw new Error('The door must fit within its host wall.')
    const offset = Math.max(-host.width / 2 + e.width / 2, Math.min(host.width / 2 - e.width / 2, e.offset ?? 0))
    const r = host.rotation * Math.PI / 180
    return { ...e, offset, x: host.x + Math.cos(r) * offset, z: host.z + Math.sin(r) * offset, elevation: host.elevation, story: host.story, rotation: host.rotation, depth: host.depth }
  })
  return parseProject(JSON.stringify({ ...project, elements }))
}
export function deleteElement(project: Project, id: string): Project {
  return { ...project, elements: project.elements.filter(e => e.id !== id && e.hostId !== id) }
}
export function visibleElements(project: Project, combination: Combination, story?: number, cutaway = false): Element[] {
  return project.elements.filter(e => (story === undefined || (story === 2 ? e.layer === 'Roofs' : e.story === story && e.layer !== 'Roofs')) && (!cutaway || e.layer !== 'Roofs') && (combination !== 'Structure only' || e.layer === 'Structure') && (combination !== 'Architecture' || e.layer !== 'Landscape'))
}
function record(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
}
export function parseProject(json: string): Project {
  if (json.length > 2_000_000) throw new Error('Project file exceeds 2 MB.')
  const data: unknown = JSON.parse(json)
  if (!record(data) || data.version !== 1 || typeof data.name !== 'string' || !data.name.trim() || data.name.length > 100 || !Array.isArray(data.elements) || data.elements.length > 1000) throw new Error('Invalid Atrio project.')
  const ids = new Set<string>()
  const elements = data.elements.map((raw: unknown): Element => {
    if (!record(raw) || typeof raw.id !== 'string' || !raw.id || ids.has(raw.id) || typeof raw.name !== 'string' || raw.name.length > 100) throw new Error('Invalid element identity.')
    ids.add(raw.id)
    if (!['wall', 'slab', 'door'].includes(String(raw.kind)) || !Object.hasOwn(MATERIALS, String(raw.material)) || !['Structure', 'Glazing', 'Roofs', 'Landscape'].includes(String(raw.layer))) throw new Error('Invalid element type or material.')
    for (const k of ['x', 'z', 'width', 'depth', 'height', 'elevation', 'rotation', 'story']) {
      if (typeof raw[k] !== 'number' || !Number.isFinite(raw[k]) || Math.abs(raw[k]) > 500) throw new Error(`Invalid ${k}.`)
    }
    if (Number(raw.width) < .05 || Number(raw.depth) < .05 || Number(raw.height) < .05 || ![0, 1, 2].includes(Number(raw.story))) throw new Error('Dimensions must be positive and the story must exist.')
    if (raw.hostId !== undefined && (typeof raw.hostId !== 'string' || typeof raw.offset !== 'number' || !Number.isFinite(raw.offset))) throw new Error('Invalid door host.')
    if (raw.kind === 'door' && typeof raw.hostId !== 'string') throw new Error('A door requires a host wall.')
    return {
      id: raw.id, name: raw.name, kind: raw.kind as Kind,
      x: Number(raw.x), z: Number(raw.z), width: Number(raw.width), depth: Number(raw.depth),
      height: Number(raw.height), elevation: Number(raw.elevation), rotation: Number(raw.rotation),
      story: Number(raw.story), material: raw.material as Material, layer: raw.layer as Layer,
      ...(typeof raw.hostId === 'string' ? { hostId: raw.hostId, offset: Number(raw.offset) } : {}),
    }
  })
  const hosts = new Set<string>()
  for (const e of elements) {
    if (!e.hostId) continue
    const host = elements.find(w => w.id === e.hostId)
    if (!host || host.kind !== 'wall' || hosts.has(host.id) || e.width > host.width - .1 || e.height > host.height || Math.abs(e.offset ?? 0) + e.width / 2 > host.width / 2 + .001) throw new Error('Door opening does not fit its host wall.')
    const r = host.rotation * Math.PI / 180, offset = e.offset ?? 0
    if (Math.abs(e.x - host.x - Math.cos(r) * offset) > .001 || Math.abs(e.z - host.z - Math.sin(r) * offset) > .001 || e.rotation !== host.rotation || e.story !== host.story || e.elevation !== host.elevation) throw new Error('Door placement must match its host wall.')
    hosts.add(host.id)
  }
  return { version: 1, name: data.name, elements }
}
export function area(e: Element): number { return e.width * e.depth }
export function escapeXml(value: string): string {
  return value.replace(/[<>&"']/g, c => ({ '<': '&lt;', '>': '&gt;', '&': '&amp;', '"': '&quot;', "'": '&apos;' })[c] ?? c)
}
export function exportPlan(project: Project, story: number, combination: Combination, scale = 200): string {
  const items = visibleElements(project, combination, story)
  const shapes = items.map(e => `<g transform="translate(${e.x} ${e.z}) rotate(${e.rotation})"><rect x="${-e.width / 2}" y="${-e.depth / 2}" width="${e.width}" height="${e.depth}" fill="${e.kind === 'door' ? '#ffffff' : MATERIALS[e.material].color}" stroke="#293a3e" stroke-width="0.08"/><title>${escapeXml(e.name)}</title>${e.kind === 'wall' ? `<line x1="${-e.width / 2}" y1="-1.2" x2="${e.width / 2}" y2="-1.2" stroke="#5d6d72" stroke-width=".05"/><text x="0" y="-1.4" text-anchor="middle" font-size=".65">${e.width.toFixed(2)} m</text>` : ''}</g>`).join('')
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="-44 -36 88 78" width="${88000 / scale}mm" height="${78000 / scale}mm"><rect x="-44" y="-36" width="88" height="78" fill="white"/><g font-family="Arial,sans-serif">${shapes}<text x="-39" y="34" font-size="1.5">${escapeXml(project.name)}</text><text x="-39" y="37" font-size=".8">${STORIES[story]} · ${escapeXml(combination)} · 1:${scale} · dimensions in metres</text><path d="M32 35h8m-8-.3v.6m8-.6v.6" stroke="#26383b" stroke-width=".1"/><text x="34" y="37" font-size=".8">8 metres</text></g></svg>`
}
