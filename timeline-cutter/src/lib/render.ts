import type { MediaItem } from '../types'
import { timecode } from './time'

/** Deterministic pseudo-random sequence (mulberry32) so every clip looks the same on every run. */
function seeded(seed: number) {
  let a = seed >>> 0
  return () => {
    a = (a + 0x6d2b79f5) >>> 0
    let t = a
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

const bokehCache = new Map<string, { x: number; y: number; r: number; speed: number; phase: number }[]>()
function bokehParticles(id: string) {
  let list = bokehCache.get(id)
  if (!list) {
    const rnd = seeded(id.charCodeAt(0) * 7919)
    list = Array.from({ length: 28 }, () => ({
      x: rnd(),
      y: rnd(),
      r: 0.03 + rnd() * 0.09,
      speed: 0.02 + rnd() * 0.05,
      phase: rnd() * Math.PI * 2,
    }))
    bokehCache.set(id, list)
  }
  return list
}

const noiseCache = new Map<string, number[]>()
function noiseCells(id: string, n: number) {
  const key = `${id}:${n}`
  let cells = noiseCache.get(key)
  if (!cells) {
    const rnd = seeded(id.charCodeAt(0) * 104729)
    cells = Array.from({ length: n }, () => rnd())
    noiseCache.set(key, cells)
  }
  return cells
}

export function drawFrame(ctx: CanvasRenderingContext2D, media: MediaItem, t: number, w: number, h: number, burnIn = true) {
  ctx.save()
  switch (media.pattern) {
    case 'sunrise':
      drawSunrise(ctx, media, t, w, h)
      break
    case 'ocean':
      drawOcean(ctx, media, t, w, h)
      break
    case 'grid':
      drawGrid(ctx, media, t, w, h)
      break
    case 'bokeh':
      drawBokeh(ctx, media, t, w, h)
      break
    case 'bars':
      drawBars(ctx, media, t, w, h)
      break
    case 'noise':
      drawNoise(ctx, media, t, w, h)
      break
  }
  ctx.restore()
  if (burnIn) drawBurnIn(ctx, media, t, w, h)
}

function drawSunrise(ctx: CanvasRenderingContext2D, m: MediaItem, t: number, w: number, h: number) {
  const g = ctx.createLinearGradient(0, 0, 0, h)
  g.addColorStop(0, '#1e1b4b')
  g.addColorStop(0.55, m.primary)
  g.addColorStop(1, m.secondary)
  ctx.fillStyle = g
  ctx.fillRect(0, 0, w, h)
  const sunY = h * (0.85 - 0.45 * Math.min(1, t / m.duration))
  const rg = ctx.createRadialGradient(w / 2, sunY, 0, w / 2, sunY, h * 0.28)
  rg.addColorStop(0, '#fff7ed')
  rg.addColorStop(0.4, '#fdba74')
  rg.addColorStop(1, 'rgba(253,186,116,0)')
  ctx.fillStyle = rg
  ctx.fillRect(0, 0, w, h)
  ctx.fillStyle = 'rgba(30,27,75,0.75)'
  for (let i = 0; i < 4; i++) {
    const y = h * (0.72 + i * 0.07)
    ctx.beginPath()
    ctx.moveTo(0, h)
    for (let x = 0; x <= w; x += 8) {
      ctx.lineTo(x, y + Math.sin(x / (60 + i * 20) + t * (0.6 + i * 0.2)) * 10)
    }
    ctx.lineTo(w, h)
    ctx.fill()
  }
}

function drawOcean(ctx: CanvasRenderingContext2D, m: MediaItem, t: number, w: number, h: number) {
  const g = ctx.createLinearGradient(0, 0, 0, h)
  g.addColorStop(0, '#082f49')
  g.addColorStop(1, m.primary)
  ctx.fillStyle = g
  ctx.fillRect(0, 0, w, h)
  ctx.lineWidth = 3
  for (let i = 0; i < 9; i++) {
    const y = h * (0.15 + i * 0.09)
    ctx.strokeStyle = `rgba(165,243,252,${0.15 + i * 0.08})`
    ctx.beginPath()
    for (let x = 0; x <= w; x += 6) {
      const yy = y + Math.sin(x / 70 + t * 1.6 + i * 0.7) * 14 + Math.sin(x / 23 - t * 2.2) * 4
      if (x === 0) ctx.moveTo(x, yy)
      else ctx.lineTo(x, yy)
    }
    ctx.stroke()
  }
}

function drawGrid(ctx: CanvasRenderingContext2D, m: MediaItem, t: number, w: number, h: number) {
  ctx.fillStyle = '#0a0118'
  ctx.fillRect(0, 0, w, h)
  const horizon = h * 0.45
  const sky = ctx.createLinearGradient(0, 0, 0, horizon)
  sky.addColorStop(0, '#0a0118')
  sky.addColorStop(1, m.primary)
  ctx.fillStyle = sky
  ctx.fillRect(0, 0, w, horizon)
  ctx.strokeStyle = m.secondary
  ctx.lineWidth = 2
  ctx.shadowColor = m.secondary
  ctx.shadowBlur = 8
  for (let i = -8; i <= 8; i++) {
    ctx.beginPath()
    ctx.moveTo(w / 2 + i * 40, horizon)
    ctx.lineTo(w / 2 + i * w * 0.35, h)
    ctx.stroke()
  }
  const scroll = (t * 0.8) % 1
  for (let i = 0; i < 12; i++) {
    const p = ((i + scroll) / 12) ** 2.2
    const y = horizon + p * (h - horizon)
    ctx.globalAlpha = 0.3 + p * 0.7
    ctx.beginPath()
    ctx.moveTo(0, y)
    ctx.lineTo(w, y)
    ctx.stroke()
  }
  ctx.globalAlpha = 1
  ctx.shadowBlur = 0
  ctx.fillStyle = m.secondary
  ctx.beginPath()
  ctx.arc(w / 2, horizon - 40, 34 + Math.sin(t * 2) * 3, 0, Math.PI * 2)
  ctx.fill()
}

function drawBokeh(ctx: CanvasRenderingContext2D, m: MediaItem, t: number, w: number, h: number) {
  const g = ctx.createLinearGradient(0, 0, w, h)
  g.addColorStop(0, '#052e16')
  g.addColorStop(1, '#14532d')
  ctx.fillStyle = g
  ctx.fillRect(0, 0, w, h)
  for (const p of bokehParticles(m.id)) {
    const y = ((p.y - t * p.speed) % 1 + 1) % 1
    const x = p.x + Math.sin(t * 0.7 + p.phase) * 0.03
    const r = p.r * h
    const pulse = 0.55 + 0.45 * Math.sin(t * 1.5 + p.phase)
    const rg = ctx.createRadialGradient(x * w, y * h, 0, x * w, y * h, r)
    rg.addColorStop(0, `rgba(187,247,208,${0.7 * pulse})`)
    rg.addColorStop(0.7, `rgba(34,197,94,${0.35 * pulse})`)
    rg.addColorStop(1, 'rgba(34,197,94,0)')
    ctx.fillStyle = rg
    ctx.beginPath()
    ctx.arc(x * w, y * h, r, 0, Math.PI * 2)
    ctx.fill()
  }
}

function drawBars(ctx: CanvasRenderingContext2D, m: MediaItem, t: number, w: number, h: number) {
  const colors = ['#fef3c7', m.primary, '#f59e0b', '#d97706', '#b45309', '#92400e', m.secondary]
  const bw = w / colors.length
  colors.forEach((c, i) => {
    ctx.fillStyle = c
    ctx.fillRect(i * bw, 0, bw + 1, h * 0.7)
  })
  ctx.fillStyle = '#1c1917'
  ctx.fillRect(0, h * 0.7, w, h * 0.3)
  const x = ((t / m.duration) % 1) * w
  ctx.fillStyle = 'rgba(255,255,255,0.85)'
  ctx.fillRect(x - 3, 0, 6, h)
  ctx.fillStyle = '#fef3c7'
  const steps = 8
  for (let i = 0; i < steps; i++) {
    const on = Math.floor(t * 4) % steps === i
    ctx.globalAlpha = on ? 1 : 0.25
    ctx.fillRect(w * 0.1 + i * (w * 0.8) / steps, h * 0.8, (w * 0.8) / steps - 8, h * 0.1)
  }
  ctx.globalAlpha = 1
}

function drawNoise(ctx: CanvasRenderingContext2D, m: MediaItem, t: number, w: number, h: number) {
  ctx.fillStyle = '#2e1065'
  ctx.fillRect(0, 0, w, h)
  const cols = 24
  const rows = 14
  const cells = noiseCells(m.id, cols * rows)
  const cw = w / cols
  const ch = h / rows
  for (let y = 0; y < rows; y++) {
    for (let x = 0; x < cols; x++) {
      const v = cells[y * cols + x]
      const a = 0.5 + 0.5 * Math.sin(t * 3 + v * Math.PI * 2 + x * 0.3 + y * 0.2)
      ctx.fillStyle = a > 0.6 ? m.secondary : m.primary
      ctx.globalAlpha = 0.15 + a * 0.7
      ctx.fillRect(x * cw + 1, y * ch + 1, cw - 2, ch - 2)
    }
  }
  ctx.globalAlpha = 1
}

function drawBurnIn(ctx: CanvasRenderingContext2D, m: MediaItem, t: number, w: number, h: number) {
  const fontSize = Math.max(12, Math.round(h * 0.07))
  ctx.save()
  ctx.font = `600 ${fontSize}px "JetBrains Mono", "SF Mono", Menlo, Consolas, monospace`
  ctx.textAlign = 'left'
  ctx.textBaseline = 'middle'
  const tc = timecode(t)
  const padX = fontSize * 0.6
  const tw = ctx.measureText(tc).width + padX * 2
  const bh = fontSize * 1.7
  const x = w - tw - fontSize * 0.8
  const y = h - bh - fontSize * 0.8
  ctx.fillStyle = 'rgba(0,0,0,0.65)'
  roundRect(ctx, x, y, tw, bh, fontSize * 0.35)
  ctx.fill()
  ctx.fillStyle = '#ffffff'
  ctx.fillText(tc, x + padX, y + bh / 2)

  const label = `${m.id} · ${m.name}`
  ctx.font = `600 ${Math.round(fontSize * 0.75)}px Inter, system-ui, sans-serif`
  const lw = ctx.measureText(label).width + padX * 2
  ctx.fillStyle = 'rgba(0,0,0,0.55)'
  roundRect(ctx, fontSize * 0.8, fontSize * 0.8, lw, bh * 0.8, fontSize * 0.3)
  ctx.fill()
  ctx.fillStyle = m.secondary
  ctx.fillText(label, fontSize * 0.8 + padX, fontSize * 0.8 + bh * 0.4)
  ctx.restore()
}

export function roundRect(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number) {
  ctx.beginPath()
  ctx.moveTo(x + r, y)
  ctx.arcTo(x + w, y, x + w, y + h, r)
  ctx.arcTo(x + w, y + h, x, y + h, r)
  ctx.arcTo(x, y + h, x, y, r)
  ctx.arcTo(x, y, x + w, y, r)
  ctx.closePath()
}

/** Composite frame: video (or black) plus optional title overlay with a short fade in/out. */
export function drawTitleOverlay(ctx: CanvasRenderingContext2D, text: string, progress: number, duration: number, w: number, h: number) {
  const fade = Math.min(0.4, duration / 4)
  const elapsed = progress * duration
  const remaining = duration - elapsed
  // Never fully transparent on the first/last frame so a parked playhead still shows the title.
  const alpha = Math.min(1, 0.35 + elapsed / fade, 0.35 + remaining / fade)
  ctx.save()
  ctx.globalAlpha = Math.max(0, alpha)
  const fontSize = Math.round(h * 0.11)
  ctx.font = `800 ${fontSize}px Inter, system-ui, sans-serif`
  ctx.textAlign = 'center'
  ctx.textBaseline = 'middle'
  const tw = ctx.measureText(text).width
  const bx = (w - tw) / 2 - fontSize * 0.6
  const by = h * 0.5 - fontSize * 0.85
  ctx.fillStyle = 'rgba(15,17,23,0.72)'
  roundRect(ctx, bx, by, tw + fontSize * 1.2, fontSize * 1.7, fontSize * 0.25)
  ctx.fill()
  ctx.fillStyle = '#f59e0b'
  ctx.fillRect(bx, by + fontSize * 1.7 - 5, (tw + fontSize * 1.2) * Math.min(1, progress), 5)
  ctx.fillStyle = '#ffffff'
  ctx.fillText(text, w / 2, h * 0.5)
  ctx.restore()
}

export function drawEmpty(ctx: CanvasRenderingContext2D, w: number, h: number) {
  ctx.fillStyle = '#000'
  ctx.fillRect(0, 0, w, h)
  ctx.fillStyle = 'rgba(255,255,255,0.35)'
  ctx.font = `500 ${Math.round(h * 0.05)}px Inter, system-ui, sans-serif`
  ctx.textAlign = 'center'
  ctx.textBaseline = 'middle'
  ctx.fillText('No clip at playhead', w / 2, h / 2)
}
