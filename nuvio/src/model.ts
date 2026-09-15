export type Vec3 = [number, number, number];
export type AssetKind = 'pavilion' | 'deck' | 'pine' | 'maple' | 'birch' | 'fern' | 'rock' | 'chair' | 'bench' | 'lamp';
export type MaterialId = 'cedar' | 'oak' | 'charcoal' | 'limestone' | 'sage' | 'terracotta';
export interface SceneObject {
  id: string;
  name: string;
  kind: AssetKind;
  position: Vec3;
  rotation: number;
  scale: number;
  material: MaterialId;
  visible: boolean;
}
export interface Ambience {
  time: number;
  season: 'Summer' | 'Autumn' | 'Winter';
  weather: 'Clear' | 'Overcast' | 'Mist';
  fog: number;
}
export interface CameraShot {
  id: string;
  name: string;
  position: Vec3;
  target: Vec3;
  ambience: Ambience;
}
export interface Project {
  version: 1;
  name: string;
  objects: SceneObject[];
  ambience: Ambience;
  shots: CameraShot[];
}
export interface History {
  past: Project[];
  present: Project;
  future: Project[];
}
export const STORAGE_KEY = 'nuvio.project.v1';
export const MATERIALS: { id: MaterialId; name: string; color: string; roughness: number }[] = [
  { id: 'cedar', name: 'Natural cedar', color: '#a17a50', roughness: 0.8 },
  { id: 'oak', name: 'White oak', color: '#cfb587', roughness: 0.75 },
  { id: 'charcoal', name: 'Charred timber', color: '#343a39', roughness: 0.85 },
  { id: 'limestone', name: 'Limestone', color: '#c4c1b0', roughness: 0.9 },
  { id: 'sage', name: 'Sage textile', color: '#718276', roughness: 1 },
  { id: 'terracotta', name: 'Terracotta', color: '#b56f4e', roughness: 0.85 },
];
export const LIBRARY: { kind: AssetKind; name: string; category: string; detail: string }[] = [
  { kind: 'pine', name: 'Scots pine', category: 'Vegetation', detail: 'Pinus sylvestris · 8 m' },
  { kind: 'maple', name: 'Japanese maple', category: 'Vegetation', detail: 'Acer palmatum · 4 m' },
  { kind: 'birch', name: 'Silver birch', category: 'Vegetation', detail: 'Betula pendula · 7 m' },
  { kind: 'fern', name: 'Woodland fern', category: 'Vegetation', detail: 'Dryopteris · 0.7 m' },
  { kind: 'rock', name: 'River stone', category: 'Objects', detail: 'Weathered granite' },
  { kind: 'chair', name: 'Lounge chair', category: 'Objects', detail: 'Oak & woven linen' },
  { kind: 'bench', name: 'Timber bench', category: 'Objects', detail: 'Solid cedar · 1.8 m' },
  { kind: 'lamp', name: 'Path light', category: 'Lights', detail: 'Warm white · 2700 K' },
];
export const DEFAULT_AMBIENCE: Ambience = { time: 16.5, season: 'Summer', weather: 'Clear', fog: 18 };
export function createProject(): Project {
  return {
    version: 1,
    name: 'Forest House',
    ambience: { ...DEFAULT_AMBIENCE },
    objects: [
      { id: 'pavilion', name: 'Cantilever pavilion', kind: 'pavilion', position: [0, 0, -3], rotation: 0, scale: 1, material: 'cedar', visible: true },
      { id: 'deck', name: 'Cedar terrace', kind: 'deck', position: [0, 0, -3], rotation: 0, scale: 1, material: 'cedar', visible: true },
      { id: 'maple-1', name: 'Japanese maple', kind: 'maple', position: [-9, 0, 0], rotation: 0, scale: 1.15, material: 'sage', visible: true },
      { id: 'birch-1', name: 'Silver birch', kind: 'birch', position: [9, 0, -4], rotation: 0, scale: 1, material: 'sage', visible: true },
      { id: 'chair-1', name: 'Lounge chair', kind: 'chair', position: [5.2, 1.03, 0.4], rotation: -20, scale: 1, material: 'oak', visible: true },
      { id: 'chair-2', name: 'Lounge chair 02', kind: 'chair', position: [3.3, 1.03, 0.4], rotation: 12, scale: 1, material: 'oak', visible: true },
      { id: 'lamp-1', name: 'Path light', kind: 'lamp', position: [-7, 0, 6], rotation: 0, scale: 1, material: 'charcoal', visible: true },
    ],
    shots: [
      { id: 'hero', name: '01 · Forest arrival', position: [22, 12, 27], target: [0, 2.2, -1], ambience: { ...DEFAULT_AMBIENCE } },
      { id: 'terrace', name: '02 · On the terrace', position: [13, 6, 12], target: [0, 2.2, -3], ambience: { ...DEFAULT_AMBIENCE, time: 17.5 } },
      { id: 'aerial', name: '03 · Above the canopy', position: [23, 29, 27], target: [0, 0, -2], ambience: { ...DEFAULT_AMBIENCE, time: 12 } },
    ],
  };
}
export function searchLibrary(query: string, category: string) {
  const needle = query.trim().toLocaleLowerCase();
  return LIBRARY.filter(asset => (category === 'All' || asset.category === category) &&
    `${asset.name} ${asset.detail}`.toLocaleLowerCase().includes(needle));
}
export function addObject(project: Project, kind: AssetKind, id: string): Project {
  const asset = LIBRARY.find(item => item.kind === kind);
  if (!asset || project.objects.some(item => item.id === id) || project.objects.length >= 150) return project;
  const count = project.objects.filter(item => item.kind === kind).length;
  return { ...project, objects: [...project.objects, {
    id, kind, name: `${asset.name}${count ? ` ${String(count + 1).padStart(2, '0')}` : ''}`,
    position: [7 + count * 1.4, 0, 4], rotation: 0, scale: 1,
    material: kind === 'chair' || kind === 'bench' ? 'oak' : 'sage', visible: true,
  }] };
}
export function updateObject(project: Project, id: string, patch: Partial<Omit<SceneObject, 'id' | 'kind'>>): Project {
  return { ...project, objects: project.objects.map(object => object.id === id ? { ...object, ...patch } : object) };
}
export function commit(history: History, next: Project): History {
  if (JSON.stringify(history.present) === JSON.stringify(next)) return history;
  return { past: [...history.past, history.present].slice(-60), present: next, future: [] };
}
export function undo(history: History): History {
  if (!history.past.length) return history;
  return { past: history.past.slice(0, -1), present: history.past.at(-1)!, future: [history.present, ...history.future] };
}
export function redo(history: History): History {
  if (!history.future.length) return history;
  return { past: [...history.past, history.present], present: history.future[0], future: history.future.slice(1) };
}
const record = (value: unknown): value is Record<string, unknown> => typeof value === 'object' && value !== null && !Array.isArray(value);
const text = (value: unknown): value is string => typeof value === 'string' && value.length > 0 && value.length <= 100;
const number = (value: unknown, min: number, max: number): value is number => typeof value === 'number' && Number.isFinite(value) && value >= min && value <= max;
const vector = (value: unknown): value is Vec3 => Array.isArray(value) && value.length === 3 && value.every(n => number(n, -1000, 1000));
function ambience(value: unknown): value is Ambience {
  return record(value) && number(value.time, 6, 21) && number(value.fog, 0, 100) &&
    ['Summer', 'Autumn', 'Winter'].includes(String(value.season)) && ['Clear', 'Overcast', 'Mist'].includes(String(value.weather));
}
export function parseProject(raw: string): Project | null {
  try {
    if (raw.length > 500_000) return null;
    const p: unknown = JSON.parse(raw);
    if (!record(p) || p.version !== 1 || !text(p.name) || !ambience(p.ambience) ||
      !Array.isArray(p.objects) || p.objects.length > 150 || !Array.isArray(p.shots) || p.shots.length > 20) return null;
    if (!p.objects.every(o => record(o) && text(o.id) && text(o.name) &&
      ['pavilion', 'deck', ...LIBRARY.map(a => a.kind)].includes(String(o.kind)) &&
      vector(o.position) && number(o.rotation, -360, 360) && number(o.scale, 0.1, 5) &&
      MATERIALS.some(m => m.id === o.material) && typeof o.visible === 'boolean')) return null;
    if (new Set(p.objects.map(o => o.id)).size !== p.objects.length) return null;
    if (!p.shots.every(s => record(s) && text(s.id) && text(s.name) && vector(s.position) && vector(s.target) && ambience(s.ambience))) return null;
    if (new Set(p.shots.map(s => s.id)).size !== p.shots.length) return null;
    return p as unknown as Project;
  } catch { return null; }
}
export function exportProject(project: Project): string {
  return JSON.stringify(project, null, 2);
}
export function sunPosition(time: number): Vec3 {
  const angle = ((time - 6) / 15) * Math.PI;
  return [Math.cos(angle) * 35, Math.max(2, Math.sin(angle) * 27), 12];
}
export function seededRandom(seed: number) {
  return () => {
    seed = (seed * 1664525 + 1013904223) >>> 0;
    return seed / 4294967296;
  };
}
