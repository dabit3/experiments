import * as THREE from 'three'
import { relativeLuminance } from '../config'

// Matches the 0.2 × 0.12 plane on the heel tab so glyphs are never stretched.
const W = 800
const H = 480

const FONT = '"Helvetica Neue", Helvetica, "Inter", Arial, system-ui, sans-serif'

/**
 * Renders the heel label to an offscreen canvas and returns it as a texture: a thin inset
 * frame, the engraved name (embossed) and a small model caption. The background stays
 * transparent so the tab's own material shows through.
 */
export function makeEngravingTexture(text: string, tabColor: string): THREE.CanvasTexture {
  const canvas = document.createElement('canvas')
  canvas.width = W
  canvas.height = H
  const ctx = canvas.getContext('2d')!
  ctx.clearRect(0, 0, W, H)

  const light = relativeLuminance(tabColor) > 0.35
  const ink = light ? 'rgba(17, 17, 17, 0.94)' : 'rgba(248, 246, 240, 0.96)'
  const soft = light ? 'rgba(17, 17, 17, 0.35)' : 'rgba(248, 246, 240, 0.4)'
  const emboss = light ? 'rgba(255, 255, 255, 0.7)' : 'rgba(0, 0, 0, 0.7)'

  ctx.strokeStyle = soft
  ctx.lineWidth = 5
  ctx.beginPath()
  ctx.roundRect(30, 30, W - 60, H - 60, 34)
  ctx.stroke()

  ctx.textAlign = 'center'
  ctx.textBaseline = 'middle'

  if (text) {
    ctx.save()
    ctx.translate(W / 2, H / 2 - 26)
    let size = 230
    ctx.letterSpacing = '6px'
    ctx.font = `900 ${size}px ${FONT}`
    while (ctx.measureText(text).width > W - 140 && size > 48) {
      size -= 6
      ctx.font = `900 ${size}px ${FONT}`
    }
    ctx.fillStyle = emboss
    ctx.fillText(text, 0, light ? 4 : -4)
    ctx.fillStyle = ink
    ctx.fillText(text, 0, 0)
    ctx.restore()
  }

  ctx.save()
  ctx.translate(W / 2, text ? H - 96 : H / 2)
  ctx.letterSpacing = '10px'
  ctx.font = `700 ${text ? 40 : 56}px ${FONT}`
  ctx.fillStyle = text ? soft : ink
  ctx.fillText('COURT CLASSIC', 0, 0)
  ctx.restore()

  const tex = new THREE.CanvasTexture(canvas)
  tex.colorSpace = THREE.SRGBColorSpace
  tex.anisotropy = 8
  tex.needsUpdate = true
  return tex
}
