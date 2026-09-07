export interface Rect {
  x: number
  y: number
  w: number
  h: number
}

export interface Size {
  w: number
  h: number
}

export type Handle = 'n' | 's' | 'e' | 'w' | 'nw' | 'ne' | 'sw' | 'se'

export const HANDLES: Handle[] = ['nw', 'n', 'ne', 'e', 'se', 's', 'sw', 'w']

export const MIN_SIZE = 24

export interface AspectPreset {
  label: string
  /** width / height, or null for free-form */
  ratio: number | null
}

export const ASPECT_PRESETS: AspectPreset[] = [
  { label: 'Free', ratio: null },
  { label: '1:1', ratio: 1 },
  { label: '4:3', ratio: 4 / 3 },
  { label: '16:9', ratio: 16 / 9 },
]

export function fullRect(bounds: Size): Rect {
  return { x: 0, y: 0, w: bounds.w, h: bounds.h }
}

export function roundRect(r: Rect): Rect {
  return { x: Math.round(r.x), y: Math.round(r.y), w: Math.round(r.w), h: Math.round(r.h) }
}

/** Shift the rect so it lies inside bounds (shrinking only if it is larger than bounds). */
export function moveInto(r: Rect, bounds: Size): Rect {
  const w = Math.min(r.w, bounds.w)
  const h = Math.min(r.h, bounds.h)
  const x = Math.min(Math.max(r.x, 0), bounds.w - w)
  const y = Math.min(Math.max(r.y, 0), bounds.h - h)
  return { x, y, w, h }
}

/** Largest rect with the given aspect centred on `r`, no bigger than `r` and inside bounds. */
export function fitAspect(r: Rect, ratio: number | null, bounds: Size): Rect {
  if (ratio === null) return moveInto(r, bounds)
  let w = Math.min(r.w, r.h * ratio)
  let h = w / ratio
  if (w > bounds.w) {
    w = bounds.w
    h = w / ratio
  }
  if (h > bounds.h) {
    h = bounds.h
    w = h * ratio
  }
  const cx = r.x + r.w / 2
  const cy = r.y + r.h / 2
  return moveInto({ x: cx - w / 2, y: cy - h / 2, w, h }, bounds)
}

export function moveRect(start: Rect, dx: number, dy: number, bounds: Size): Rect {
  return moveInto({ ...start, x: start.x + dx, y: start.y + dy }, bounds)
}

/**
 * Resize `start` by dragging `handle` by (dx, dy) image pixels. The edge/corner opposite the
 * handle stays anchored. When `ratio` is set the box keeps that aspect ratio.
 */
export function resizeRect(
  start: Rect,
  handle: Handle,
  dx: number,
  dy: number,
  ratio: number | null,
  bounds: Size,
): Rect {
  let left = start.x
  let top = start.y
  let right = start.x + start.w
  let bottom = start.y + start.h

  const hasW = handle.includes('w')
  const hasE = handle.includes('e')
  const hasN = handle.includes('n')
  const hasS = handle.includes('s')

  if (hasW) left = clamp(left + dx, 0, right - MIN_SIZE)
  if (hasE) right = clamp(right + dx, left + MIN_SIZE, bounds.w)
  if (hasN) top = clamp(top + dy, 0, bottom - MIN_SIZE)
  if (hasS) bottom = clamp(bottom + dy, top + MIN_SIZE, bounds.h)

  if (ratio === null) {
    return { x: left, y: top, w: right - left, h: bottom - top }
  }

  const isCorner = (hasW || hasE) && (hasN || hasS)
  let w = right - left
  let h = bottom - top

  if (isCorner) {
    // Let the dominant axis of the drag drive the size.
    if (Math.abs(dx) >= Math.abs(dy)) h = w / ratio
    else w = h * ratio
  } else if (hasW || hasE) {
    h = w / ratio
  } else {
    w = h * ratio
  }

  // Anchor the opposite side; edge handles stay centred along their free axis.
  const anchorX = hasW ? right : hasE ? left : start.x + start.w / 2
  const anchorY = hasN ? bottom : hasS ? top : start.y + start.h / 2

  const maxW = hasW ? anchorX : hasE ? bounds.w - anchorX : 2 * Math.min(anchorX, bounds.w - anchorX)
  const maxH = hasN ? anchorY : hasS ? bounds.h - anchorY : 2 * Math.min(anchorY, bounds.h - anchorY)

  if (w > maxW) {
    w = maxW
    h = w / ratio
  }
  if (h > maxH) {
    h = maxH
    w = h * ratio
  }
  if (w < MIN_SIZE || h < MIN_SIZE) {
    if (ratio >= 1) {
      h = MIN_SIZE
      w = h * ratio
    } else {
      w = MIN_SIZE
      h = w / ratio
    }
  }

  const x = hasW ? anchorX - w : hasE ? anchorX : anchorX - w / 2
  const y = hasN ? anchorY - h : hasS ? anchorY : anchorY - h / 2
  return { x, y, w, h }
}

function clamp(v: number, min: number, max: number): number {
  return Math.min(Math.max(v, min), max)
}
