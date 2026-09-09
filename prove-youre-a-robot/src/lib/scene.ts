import { mulberry32, pick, range, rangeInt, type Rng } from './rng'

export interface Hill {
  color: string
  path: string
}

export interface Tree {
  x: number
  baseY: number
  height: number
  canopy: string
}

export interface Cloud {
  x: number
  y: number
  scale: number
}

export interface Star {
  x: number
  y: number
  r: number
}

export interface Robot {
  x: number
  baseY: number
  scale: number
  body: string
  accent: string
}

export interface SceneSpec {
  w: number
  h: number
  skyTop: string
  skyBottom: string
  night: boolean
  sun: { x: number; y: number; r: number; color: string }
  stars: Star[]
  clouds: Cloud[]
  hills: Hill[]
  horizonY: number
  ground: string
  trees: Tree[]
  robot: Robot
}

const PALETTES = [
  { skyTop: '#38bdf8', skyBottom: '#e0f2fe', hills: ['#4ade80', '#22c55e', '#15803d'], ground: '#166534', sun: '#fde047', night: false },
  { skyTop: '#c084fc', skyBottom: '#fdba74', hills: ['#7c3aed', '#5b21b6', '#3b0764'], ground: '#2e1065', sun: '#fb923c', night: false },
  { skyTop: '#1e1b4b', skyBottom: '#4c1d95', hills: ['#312e81', '#1e1b4b', '#0f0a2e'], ground: '#0b0720', sun: '#f5f3ff', night: true },
  { skyTop: '#0ea5e9', skyBottom: '#fef3c7', hills: ['#f59e0b', '#d97706', '#92400e'], ground: '#78350f', sun: '#fef08a', night: false },
  { skyTop: '#f43f5e', skyBottom: '#fde68a', hills: ['#0f766e', '#115e59', '#134e4a'], ground: '#042f2e', sun: '#fff7ed', night: false },
] as const

function hillPath(rng: Rng, w: number, h: number, baseY: number, amp: number): string {
  const f1 = range(rng, 0.6, 1.4)
  const f2 = range(rng, 1.6, 3.2)
  const p1 = range(rng, 0, Math.PI * 2)
  const p2 = range(rng, 0, Math.PI * 2)
  const steps = 32
  let d = `M -20 ${h + 20} L -20 ${baseY.toFixed(1)}`
  for (let i = 0; i <= steps; i++) {
    const x = (i / steps) * w
    const t = i / steps
    const y = baseY - amp * (0.6 * Math.sin(t * Math.PI * f1 + p1) + 0.4 * Math.sin(t * Math.PI * f2 + p2) + 1) * 0.5
    d += ` L ${x.toFixed(1)} ${y.toFixed(1)}`
  }
  return `${d} L ${w + 20} ${h + 20} Z`
}

export function buildScene(seed: number, w: number, h: number): SceneSpec {
  const rng = mulberry32(seed)
  const pal = pick(rng, PALETTES)
  const horizonY = Math.round(h * range(rng, 0.62, 0.72))
  const hills: Hill[] = pal.hills.map((color, i) => ({
    color,
    path: hillPath(rng, w, h, horizonY - 8 + i * 14, h * (0.22 - i * 0.05)),
  }))
  const trees: Tree[] = []
  const treeCount = rangeInt(rng, 3, 5)
  for (let i = 0; i < treeCount; i++) {
    trees.push({
      x: Math.round(range(rng, 30, w - 30)),
      baseY: Math.round(range(rng, horizonY + 6, h - 20)),
      height: Math.round(range(rng, 40, 70)),
      canopy: pick(rng, ['#16a34a', '#15803d', '#4d7c0f', '#0f766e'] as const),
    })
  }
  const stars: Star[] = []
  if (pal.night) {
    for (let i = 0; i < 40; i++) {
      stars.push({ x: range(rng, 0, w), y: range(rng, 0, horizonY - 30), r: range(rng, 0.6, 1.8) })
    }
  }
  const clouds: Cloud[] = []
  const cloudCount = pal.night ? 1 : rangeInt(rng, 2, 4)
  for (let i = 0; i < cloudCount; i++) {
    clouds.push({ x: range(rng, 40, w - 40), y: range(rng, 24, horizonY * 0.55), scale: range(rng, 0.7, 1.3) })
  }
  const robot: Robot = {
    x: Math.round(range(rng, w * 0.25, w * 0.75)),
    baseY: h - 14,
    scale: range(rng, 1.4, 1.8),
    body: pick(rng, ['#e5e7eb', '#a5b4fc', '#fca5a5', '#fcd34d'] as const),
    accent: pick(rng, ['#22d3ee', '#f472b6', '#4ade80'] as const),
  }
  return {
    w,
    h,
    skyTop: pal.skyTop,
    skyBottom: pal.skyBottom,
    night: pal.night,
    sun: { x: Math.round(range(rng, w * 0.15, w * 0.85)), y: Math.round(range(rng, 40, horizonY * 0.5)), r: rangeInt(rng, 22, 36), color: pal.sun },
    stars,
    clouds,
    hills,
    horizonY,
    ground: pal.ground,
    trees,
    robot,
  }
}
