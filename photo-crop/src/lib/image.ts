import type { Rect, Size } from './crop'

export interface Transform {
  /** Number of clockwise quarter turns (0–3). */
  quarterTurns: number
  /** Additional free rotation in degrees. */
  angle: number
  flipH: boolean
  flipV: boolean
}

export const DEFAULT_TRANSFORM: Transform = { quarterTurns: 0, angle: 0, flipH: false, flipV: false }

export interface Filters {
  brightness: number
  contrast: number
  saturation: number
  blur: number
  grayscale: number
}

export const DEFAULT_FILTERS: Filters = {
  brightness: 100,
  contrast: 100,
  saturation: 100,
  blur: 0,
  grayscale: 0,
}

export interface FilterDef {
  key: keyof Filters
  label: string
  min: number
  max: number
  unit: string
}

export const FILTER_DEFS: FilterDef[] = [
  { key: 'brightness', label: 'Brightness', min: 0, max: 200, unit: '%' },
  { key: 'contrast', label: 'Contrast', min: 0, max: 200, unit: '%' },
  { key: 'saturation', label: 'Saturation', min: 0, max: 200, unit: '%' },
  { key: 'blur', label: 'Blur', min: 0, max: 20, unit: 'px' },
  { key: 'grayscale', label: 'Grayscale', min: 0, max: 100, unit: '%' },
]

export type ExportFormat = 'png' | 'jpeg'

export function filtersToCss(f: Filters): string {
  return [
    `brightness(${f.brightness}%)`,
    `contrast(${f.contrast}%)`,
    `saturate(${f.saturation}%)`,
    `blur(${f.blur}px)`,
    `grayscale(${f.grayscale}%)`,
  ].join(' ')
}

export function filtersAreDefault(f: Filters): boolean {
  return (Object.keys(DEFAULT_FILTERS) as (keyof Filters)[]).every((k) => f[k] === DEFAULT_FILTERS[k])
}

export function totalAngle(t: Transform): number {
  return t.quarterTurns * 90 + t.angle
}

/** Bounding box of the source after rotation (flips never change the size). */
export function transformedSize(source: ImageBitmap, t: Transform): Size {
  const rad = (totalAngle(t) * Math.PI) / 180
  const cos = Math.abs(Math.cos(rad))
  const sin = Math.abs(Math.sin(rad))
  return {
    w: Math.round(source.width * cos + source.height * sin),
    h: Math.round(source.width * sin + source.height * cos),
  }
}

/** Draw `source` rotated and flipped so that it fills a canvas of `transformedSize`. */
export function drawTransformed(
  ctx: CanvasRenderingContext2D,
  source: ImageBitmap,
  t: Transform,
  filters?: Filters,
): void {
  const { w, h } = transformedSize(source, t)
  ctx.canvas.width = w
  ctx.canvas.height = h
  ctx.clearRect(0, 0, w, h)
  ctx.save()
  if (filters) ctx.filter = filtersToCss(filters)
  ctx.translate(w / 2, h / 2)
  ctx.scale(t.flipH ? -1 : 1, t.flipV ? -1 : 1)
  ctx.rotate((totalAngle(t) * Math.PI) / 180)
  ctx.drawImage(source, -source.width / 2, -source.height / 2)
  ctx.restore()
}

export async function loadBitmap(file: Blob): Promise<ImageBitmap> {
  return createImageBitmap(file)
}

/** Bake the transform into the pixels and cut out `crop` (in transformed coordinates). */
export async function cropBitmap(source: ImageBitmap, t: Transform, crop: Rect): Promise<ImageBitmap> {
  const canvas = document.createElement('canvas')
  const ctx = canvas.getContext('2d')
  if (!ctx) throw new Error('2D canvas is not supported')
  drawTransformed(ctx, source, t)
  return createImageBitmap(canvas, crop.x, crop.y, Math.max(1, crop.w), Math.max(1, crop.h))
}

export async function exportBlob(
  source: ImageBitmap,
  t: Transform,
  filters: Filters,
  format: ExportFormat,
): Promise<Blob> {
  const canvas = document.createElement('canvas')
  const ctx = canvas.getContext('2d')
  if (!ctx) throw new Error('2D canvas is not supported')
  drawTransformed(ctx, source, t, filters)
  if (format === 'jpeg') {
    // JPEG has no alpha channel; give the rotated corners a solid background.
    ctx.globalCompositeOperation = 'destination-over'
    ctx.fillStyle = '#000'
    ctx.fillRect(0, 0, canvas.width, canvas.height)
  }
  return new Promise((resolve, reject) => {
    canvas.toBlob(
      (blob) => (blob ? resolve(blob) : reject(new Error('Export failed'))),
      format === 'png' ? 'image/png' : 'image/jpeg',
      0.92,
    )
  })
}

export function downloadBlob(blob: Blob, filename: string): void {
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  document.body.appendChild(a)
  a.click()
  a.remove()
  setTimeout(() => URL.revokeObjectURL(url), 1000)
}

export function exportFilename(originalName: string, format: ExportFormat): string {
  const base = originalName.replace(/\.[^.]+$/, '') || 'image'
  return `${base}-edited.${format === 'png' ? 'png' : 'jpg'}`
}
