import * as THREE from 'three'
import { relativeLuminance } from '../config'

const W = 720
const H = 520

/**
 * Renders the engraved heel text to an offscreen canvas and returns it as a texture.
 * The background stays transparent so the tab's own material shows through.
 */
export function makeEngravingTexture(text: string, tabColor: string): THREE.CanvasTexture {
  const canvas = document.createElement('canvas')
  canvas.width = W
  canvas.height = H
  const ctx = canvas.getContext('2d')!
  ctx.clearRect(0, 0, W, H)

  const light = relativeLuminance(tabColor) > 0.35
  const ink = light ? 'rgba(20, 20, 24, 0.92)' : 'rgba(245, 242, 235, 0.95)'
  const shadow = light ? 'rgba(255,255,255,0.55)' : 'rgba(0,0,0,0.6)'

  // Stitched border to make the tab read as a sewn label.
  ctx.strokeStyle = light ? 'rgba(0,0,0,0.28)' : 'rgba(255,255,255,0.28)'
  ctx.lineWidth = 6
  ctx.setLineDash([18, 14])
  ctx.strokeRect(34, 34, W - 68, H - 68)
  ctx.setLineDash([])

  if (!text) return finish(canvas)

  ctx.save()
  ctx.translate(W / 2, H / 2 + 8)
  ctx.textAlign = 'center'
  ctx.textBaseline = 'middle'
  const maxWidth = W - 130
  let size = 190
  ctx.font = `800 ${size}px "Inter", "Segoe UI", system-ui, sans-serif`
  while (ctx.measureText(text).width > maxWidth && size > 40) {
    size -= 6
    ctx.font = `800 ${size}px "Inter", "Segoe UI", system-ui, sans-serif`
  }
  ctx.shadowColor = shadow
  ctx.shadowBlur = 2
  ctx.shadowOffsetX = 0
  ctx.shadowOffsetY = 3
  ctx.fillStyle = ink
  ctx.fillText(text, 0, 0)
  ctx.restore()

  return finish(canvas)
}

function finish(canvas: HTMLCanvasElement): THREE.CanvasTexture {
  const tex = new THREE.CanvasTexture(canvas)
  tex.colorSpace = THREE.SRGBColorSpace
  tex.anisotropy = 8
  tex.needsUpdate = true
  return tex
}
