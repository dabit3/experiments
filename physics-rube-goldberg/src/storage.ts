import { LEVELS } from './levels.ts'
import { PART_DEFS, type PlacedPart } from './parts.ts'

const KEY = 'rube-goldberg-lab:v1'

export interface SaveData {
  level: number
  parts: Record<number, PlacedPart[]>
  solved: number[]
}

const EMPTY: SaveData = { level: 0, parts: {}, solved: [] }

function isPlacedPart(v: unknown): v is PlacedPart {
  if (typeof v !== 'object' || v === null) return false
  const p = v as Record<string, unknown>
  return (
    typeof p.id === 'string' &&
    typeof p.type === 'string' &&
    p.type in PART_DEFS &&
    typeof p.x === 'number' &&
    typeof p.y === 'number' &&
    typeof p.angle === 'number'
  )
}

export function loadSave(): SaveData {
  try {
    const raw = localStorage.getItem(KEY)
    if (!raw) return EMPTY
    const data = JSON.parse(raw) as Partial<SaveData>
    const level =
      typeof data.level === 'number' && data.level >= 0 && data.level < LEVELS.length ? data.level : 0
    const parts: Record<number, PlacedPart[]> = {}
    if (data.parts && typeof data.parts === 'object') {
      for (const [k, v] of Object.entries(data.parts)) {
        if (Array.isArray(v)) parts[Number(k)] = v.filter(isPlacedPart)
      }
    }
    const solved = Array.isArray(data.solved) ? data.solved.filter((n): n is number => typeof n === 'number') : []
    return { level, parts, solved }
  } catch {
    return EMPTY
  }
}

export function storeSave(data: SaveData) {
  try {
    localStorage.setItem(KEY, JSON.stringify(data))
  } catch {
    /* storage unavailable (private mode / quota) — progress simply is not persisted */
  }
}
