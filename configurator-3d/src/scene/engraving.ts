import * as THREE from 'three'
import { relativeLuminance } from '../config'

// Aspect matches the heel label patch.
const W = 1024
const H = 540

const FONT = '"Helvetica Neue", Helvetica, "Inter", Arial, "Liberation Sans", system-ui, sans-serif'

/** Satin thread catches light along fine diagonal ridges. */
function embroider(
  ctx: CanvasRenderingContext2D,
  text: string,
  x: number,
  y: number,
  ink: string,
  shadow: string,
): void {
  const layer = document.createElement('canvas')
  layer.width = W
  layer.height = H
  const lc = layer.getContext('2d')!
  lc.font = ctx.font
  lc.letterSpacing = ctx.letterSpacing
  lc.textAlign = 'center'
  lc.textBaseline = 'middle'
  lc.fillStyle = ink
  lc.fillText(text, x, y)
  // Satin-stitch sheen: fine diagonal lines only where thread was laid.
  lc.globalCompositeOperation = 'source-atop'
  lc.strokeStyle = 'rgba(255, 255, 255, 0.12)'
  lc.lineWidth = 1
  lc.beginPath()
  for (let k = -H; k < W + H; k += 9) {
    lc.moveTo(k, 0)
    lc.lineTo(k + H * 0.55, H)
  }
  lc.stroke()
  lc.globalCompositeOperation = 'source-over'

  ctx.save()
  ctx.fillStyle = shadow
  ctx.fillText(text, x + 1, y + 2)
  ctx.restore()
  ctx.drawImage(layer, 0, 0)
}

/**
 * Renders the heel label to an offscreen canvas and returns it as a texture: a running stitch
 * around the edge, the engraved name in spaced embroidery and a small model caption.
 * The background stays transparent so the label's own leather shows through.
 */
export function makeEngravingTexture(text: string, tabColor: string): THREE.CanvasTexture {
  const canvas = document.createElement('canvas')
  canvas.width = W
  canvas.height = H
  const ctx = canvas.getContext('2d')!
  ctx.clearRect(0, 0, W, H)

  const light = relativeLuminance(tabColor) > 0.35
  const ink = light ? '#141414' : '#f6f3ec'
  const soft = light ? 'rgba(20, 20, 20, 0.55)' : 'rgba(246, 243, 236, 0.6)'
  const shadow = light ? 'rgba(0, 0, 0, 0.28)' : 'rgba(0, 0, 0, 0.55)'

  // Running stitch just inside the label edge.
  ctx.save()
  ctx.strokeStyle = soft
  ctx.lineWidth = 3
  ctx.lineCap = 'round'
  ctx.setLineDash([12, 11])
  ctx.beginPath()
  ctx.roundRect(38, 38, W - 76, H - 76, 26)
  ctx.stroke()
  ctx.restore()

  ctx.textAlign = 'center'
  ctx.textBaseline = 'middle'

  ctx.letterSpacing = '10px'
  ctx.font = `500 36px ${FONT}`
  ctx.fillStyle = soft
  ctx.fillText('COURT / 01', W / 2, 120)

  const label = text || 'COURT'
  let size = 156
  ctx.letterSpacing = '12px'
  ctx.font = `600 ${size}px ${FONT}`
  while (ctx.measureText(label).width > W - 180 && size > 60) {
    size -= 4
    ctx.font = `600 ${size}px ${FONT}`
  }
  embroider(ctx, label, W / 2, H / 2 + 5, ink, shadow)
  ctx.letterSpacing = '12px'
  ctx.font = `500 30px ${FONT}`
  ctx.fillStyle = soft
  ctx.fillText('ONE OF ONE', W / 2, H - 117)

  const tex = new THREE.CanvasTexture(canvas)
  tex.colorSpace = THREE.SRGBColorSpace
  tex.anisotropy = 8
  tex.needsUpdate = true
  return tex
}
