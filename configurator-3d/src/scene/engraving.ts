import * as THREE from 'three'
import { relativeLuminance } from '../config'

// Aspect matches the heel label patch (~1.9 : 1) so glyphs are never stretched.
const W = 1024
const H = 540

const FONT = '"Helvetica Neue", Helvetica, "Inter", Arial, "Liberation Sans", system-ui, sans-serif'

/** Draws `text` as embroidered lettering: a soft drop shadow, the thread colour, then a thread-direction hatch. */
function embroider(ctx: CanvasRenderingContext2D, text: string, x: number, y: number, ink: string, shadow: string): void {
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
  lc.strokeStyle = 'rgba(255, 255, 255, 0.16)'
  lc.lineWidth = 2
  lc.beginPath()
  for (let k = -H; k < W + H; k += 9) {
    lc.moveTo(k, 0)
    lc.lineTo(k + H * 0.55, H)
  }
  lc.stroke()
  lc.globalCompositeOperation = 'source-over'

  ctx.save()
  ctx.fillStyle = shadow
  ctx.fillText(text, x + 3, y + 5)
  ctx.restore()
  ctx.drawImage(layer, 0, 0)
}

/**
 * Renders the heel label to an offscreen canvas and returns it as a texture: a running stitch
 * around the edge, the engraved name in heavy italic embroidery and a small model caption.
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
  ctx.lineWidth = 6
  ctx.lineCap = 'round'
  ctx.setLineDash([18, 14])
  ctx.beginPath()
  ctx.roundRect(46, 46, W - 92, H - 92, 40)
  ctx.stroke()
  ctx.restore()

  ctx.textAlign = 'center'
  ctx.textBaseline = 'middle'

  if (text) {
    let size = 250
    ctx.letterSpacing = '4px'
    ctx.font = `italic 900 ${size}px ${FONT}`
    while (ctx.measureText(text).width > W - 200 && size > 60) {
      size -= 6
      ctx.font = `italic 900 ${size}px ${FONT}`
    }
    embroider(ctx, text, W / 2, H / 2 - 30, ink, shadow)

    ctx.letterSpacing = '12px'
    ctx.font = `700 42px ${FONT}`
    ctx.fillStyle = soft
    ctx.fillText('COURT CLASSIC', W / 2, H - 112)
  } else {
    ctx.letterSpacing = '14px'
    ctx.font = `italic 900 96px ${FONT}`
    embroider(ctx, 'COURT', W / 2, H / 2 - 52, ink, shadow)
    ctx.letterSpacing = '18px'
    ctx.font = `700 54px ${FONT}`
    ctx.fillStyle = soft
    ctx.fillText('CLASSIC', W / 2, H / 2 + 60)
  }

  const tex = new THREE.CanvasTexture(canvas)
  tex.colorSpace = THREE.SRGBColorSpace
  tex.anisotropy = 8
  tex.needsUpdate = true
  return tex
}
