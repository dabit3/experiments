import type { SignatureImage } from '../types'

export const SCRIPT_FONT = '"Dancing Script", "Brush Script MT", "Segoe Script", "Snell Roundhand", cursive'

export async function renderTypedSignature(text: string, width: number, height: number): Promise<SignatureImage | null> {
  const trimmed = text.trim()
  if (!trimmed) return null
  const scale = 2
  const canvas = document.createElement('canvas')
  canvas.width = width * scale
  canvas.height = height * scale
  const ctx = canvas.getContext('2d')
  if (!ctx) return null

  let size = Math.round(height * 0.5)
  const font = (px: number) => `600 ${px}px ${SCRIPT_FONT}`
  try {
    await document.fonts.load(font(size))
  } catch {
    // fall back to whatever cursive font the browser resolves
  }
  ctx.scale(scale, scale)
  ctx.font = font(size)
  while (size > 14 && ctx.measureText(trimmed).width > width - 32) {
    size -= 2
    ctx.font = font(size)
  }
  ctx.fillStyle = '#1b2a4a'
  ctx.textBaseline = 'middle'
  ctx.textAlign = 'center'
  ctx.fillText(trimmed, width / 2, height / 2 + size * 0.05)

  return { dataUrl: canvas.toDataURL('image/png'), width, height, mode: 'typed', strokes: 0 }
}
