export type PartType = 'ramp' | 'domino' | 'trampoline' | 'fan' | 'seesaw'

export interface PartDef {
  type: PartType
  label: string
  description: string
  /** Body footprint in scene pixels (before rotation). */
  w: number
  h: number
  rotatable: boolean
  color: string
}

export const PART_DEFS: Record<PartType, PartDef> = {
  ramp: {
    type: 'ramp',
    label: 'Ramp',
    description: 'Fixed plank. Rotate it to steer the ball.',
    w: 170,
    h: 14,
    rotatable: true,
    color: '#3b82f6',
  },
  domino: {
    type: 'domino',
    label: 'Domino',
    description: 'Light block that topples when struck.',
    w: 14,
    h: 64,
    rotatable: false,
    color: '#e2e8f0',
  },
  trampoline: {
    type: 'trampoline',
    label: 'Trampoline',
    description: 'Bouncy pad that launches the ball.',
    w: 120,
    h: 18,
    rotatable: true,
    color: '#c084fc',
  },
  fan: {
    type: 'fan',
    label: 'Fan',
    description: 'Blows anything in front of it.',
    w: 48,
    h: 48,
    rotatable: true,
    color: '#38bdf8',
  },
  seesaw: {
    type: 'seesaw',
    label: 'Seesaw',
    description: 'Pivoting plank. Tips under weight.',
    w: 220,
    h: 14,
    rotatable: false,
    color: '#4ade80',
  },
}

export const PART_ORDER: PartType[] = ['ramp', 'domino', 'trampoline', 'fan', 'seesaw']

export const FAN_ZONE_LENGTH = 260
export const FAN_ZONE_WIDTH = 96

export const ROTATION_STEP = 15

export interface PlacedPart {
  id: string
  type: PartType
  x: number
  y: number
  /** Degrees, always a multiple of ROTATION_STEP. */
  angle: number
}

export function snapAngle(deg: number): number {
  const snapped = Math.round(deg / ROTATION_STEP) * ROTATION_STEP
  const norm = ((snapped % 360) + 360) % 360
  return norm > 180 ? norm - 360 : norm
}
