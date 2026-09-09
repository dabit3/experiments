import type Matter from 'matter-js'
import { BALL_RADIUS, BELL_RADIUS, SCENE_H, SCENE_W, type Level } from './levels.ts'
import { FAN_ZONE_LENGTH, FAN_ZONE_WIDTH, PART_DEFS, type PartType, type PlacedPart } from './parts.ts'
import { degToRad, type Sim } from './physics/sim.ts'

export interface Ghost {
  type: PartType
  x: number
  y: number
  angle: number
  valid: boolean
}

export interface RenderState {
  sim: Sim
  level: Level
  parts: PlacedPart[]
  ghost: Ghost | null
  selectedId: string | null
  hoverId: string | null
  hiddenId: string | null
  /** Wall-clock ms, used only for cosmetic animation. */
  now: number
  wonAt: number | null
}

const COLORS = {
  bgTop: '#0f1a2e',
  bgBottom: '#0b1220',
  grid: 'rgba(148, 163, 184, 0.07)',
  gridMajor: 'rgba(148, 163, 184, 0.13)',
  obstacle: '#2b3a4f',
  obstacleEdge: '#3f5168',
  obstacleTop: 'rgba(255,255,255,0.12)',
  ball: '#f43f5e',
  ballShine: 'rgba(255,255,255,0.55)',
  trail: 'rgba(244, 63, 94, 0.35)',
  bell: '#f5b301',
  bellDark: '#9a5b04',
  bellRope: '#8b98ab',
  ghost: 'rgba(226, 232, 240, 0.9)',
  ghostBad: 'rgba(248, 113, 113, 0.9)',
  select: '#60a5fa',
}

export function drawScene(ctx: CanvasRenderingContext2D, s: RenderState) {
  const { sim, level } = s
  ctx.save()
  drawBackground(ctx)
  drawObstacles(ctx, level)
  drawBellMount(ctx, level)
  drawFanZones(ctx, s)
  drawParts(ctx, s)
  drawTrail(ctx, sim)
  drawBell(ctx, s)
  drawBall(ctx, sim.ball)
  if (s.ghost) drawGhost(ctx, s.ghost)
  ctx.restore()
}

function drawBackground(ctx: CanvasRenderingContext2D) {
  const g = ctx.createLinearGradient(0, 0, 0, SCENE_H)
  g.addColorStop(0, COLORS.bgTop)
  g.addColorStop(1, COLORS.bgBottom)
  ctx.fillStyle = g
  ctx.fillRect(0, 0, SCENE_W, SCENE_H)
  ctx.lineWidth = 1
  for (const [step, color] of [
    [40, COLORS.grid],
    [200, COLORS.gridMajor],
  ] as const) {
    ctx.strokeStyle = color
    ctx.beginPath()
    for (let x = step; x < SCENE_W; x += step) {
      ctx.moveTo(x + 0.5, 0)
      ctx.lineTo(x + 0.5, SCENE_H)
    }
    for (let y = step; y < SCENE_H; y += step) {
      ctx.moveTo(0, y + 0.5)
      ctx.lineTo(SCENE_W, y + 0.5)
    }
    ctx.stroke()
  }
}

function drawObstacles(ctx: CanvasRenderingContext2D, level: Level) {
  for (const r of level.obstacles) {
    ctx.fillStyle = COLORS.obstacle
    ctx.fillRect(r.x, r.y, r.w, r.h)
    ctx.fillStyle = COLORS.obstacleTop
    ctx.fillRect(r.x, r.y, r.w, Math.min(4, r.h))
    ctx.strokeStyle = COLORS.obstacleEdge
    ctx.lineWidth = 1
    ctx.strokeRect(r.x + 0.5, r.y + 0.5, r.w - 1, r.h - 1)
  }
}

function drawBellMount(ctx: CanvasRenderingContext2D, level: Level) {
  const { x, y, mount } = level.bell
  ctx.strokeStyle = COLORS.bellRope
  ctx.lineWidth = 3
  ctx.beginPath()
  if (mount === 'hang') {
    ctx.moveTo(x, 0)
    ctx.lineTo(x, y - BELL_RADIUS + 2)
  } else {
    const floor = surfaceBelow(level, x, y)
    ctx.moveTo(x, y + BELL_RADIUS - 2)
    ctx.lineTo(x, floor)
    ctx.moveTo(x - 22, floor)
    ctx.lineTo(x + 22, floor)
  }
  ctx.stroke()
}

function surfaceBelow(level: Level, x: number, y: number): number {
  let best = SCENE_H
  for (const r of level.obstacles) {
    if (x >= r.x && x <= r.x + r.w && r.y >= y && r.y < best) best = r.y
  }
  return best
}

function drawBell(ctx: CanvasRenderingContext2D, s: RenderState) {
  const { x, y } = s.level.bell
  const rung = s.wonAt !== null
  const t = rung ? (s.now - (s.wonAt ?? 0)) / 1000 : 0
  const swing = rung ? Math.sin(t * 9) * 0.35 * Math.exp(-t * 1.2) : 0

  if (rung) {
    for (let i = 0; i < 3; i++) {
      const phase = (t * 0.9 + i * 0.33) % 1
      ctx.strokeStyle = `rgba(251, 191, 36, ${(1 - phase) * 0.6})`
      ctx.lineWidth = 3
      ctx.beginPath()
      ctx.arc(x, y, BELL_RADIUS + 6 + phase * 60, 0, Math.PI * 2)
      ctx.stroke()
    }
  }

  ctx.save()
  ctx.translate(x, y - BELL_RADIUS)
  ctx.rotate(swing)
  ctx.translate(0, BELL_RADIUS)
  const g = ctx.createRadialGradient(-8, -8, 4, 0, 0, BELL_RADIUS + 4)
  g.addColorStop(0, '#fde68a')
  g.addColorStop(0.6, COLORS.bell)
  g.addColorStop(1, COLORS.bellDark)
  ctx.fillStyle = g
  ctx.beginPath()
  ctx.moveTo(-BELL_RADIUS, BELL_RADIUS * 0.75)
  ctx.quadraticCurveTo(-BELL_RADIUS * 0.9, -BELL_RADIUS * 0.4, -BELL_RADIUS * 0.35, -BELL_RADIUS * 0.85)
  ctx.arc(0, -BELL_RADIUS * 0.85, BELL_RADIUS * 0.35, Math.PI, 0)
  ctx.quadraticCurveTo(BELL_RADIUS * 0.9, -BELL_RADIUS * 0.4, BELL_RADIUS, BELL_RADIUS * 0.75)
  ctx.closePath()
  ctx.fill()
  ctx.fillStyle = COLORS.bellDark
  ctx.fillRect(-BELL_RADIUS, BELL_RADIUS * 0.6, BELL_RADIUS * 2, 5)
  ctx.beginPath()
  ctx.arc(0, BELL_RADIUS * 0.85, 5, 0, Math.PI * 2)
  ctx.fill()
  ctx.restore()
}

function drawBall(ctx: CanvasRenderingContext2D, ball: Matter.Body) {
  const { x, y } = ball.position
  ctx.save()
  ctx.shadowColor = 'rgba(244, 63, 94, 0.55)'
  ctx.shadowBlur = 14
  ctx.fillStyle = COLORS.ball
  ctx.beginPath()
  ctx.arc(x, y, BALL_RADIUS, 0, Math.PI * 2)
  ctx.fill()
  ctx.restore()
  ctx.save()
  ctx.translate(x, y)
  ctx.rotate(ball.angle)
  ctx.fillStyle = 'rgba(0,0,0,0.18)'
  ctx.beginPath()
  ctx.arc(0, 0, BALL_RADIUS - 3, 0.2, 1.4)
  ctx.lineTo(0, 0)
  ctx.fill()
  ctx.restore()
  ctx.fillStyle = COLORS.ballShine
  ctx.beginPath()
  ctx.arc(x - 4, y - 5, 4, 0, Math.PI * 2)
  ctx.fill()
}

function drawTrail(ctx: CanvasRenderingContext2D, sim: Sim) {
  const n = sim.trail.length
  if (n < 2) return
  for (let i = 0; i < n; i++) {
    const p = sim.trail[i]
    const a = (i / n) * 0.45
    ctx.fillStyle = `rgba(244, 63, 94, ${a})`
    ctx.beginPath()
    ctx.arc(p.x, p.y, 2.5, 0, Math.PI * 2)
    ctx.fill()
  }
}

function drawFanZones(ctx: CanvasRenderingContext2D, s: RenderState) {
  const running = s.sim.mode === 'running'
  for (const part of s.parts) {
    if (part.type !== 'fan' || part.id === s.hiddenId) continue
    drawFanZone(ctx, part.x, part.y, part.angle, running ? s.now : 0, 0.5)
  }
  if (s.ghost?.type === 'fan') drawFanZone(ctx, s.ghost.x, s.ghost.y, s.ghost.angle, 0, 0.35)
}

function drawFanZone(ctx: CanvasRenderingContext2D, x: number, y: number, angleDeg: number, now: number, alpha: number) {
  ctx.save()
  ctx.translate(x, y)
  ctx.rotate(degToRad(angleDeg))
  const g = ctx.createLinearGradient(20, 0, FAN_ZONE_LENGTH, 0)
  g.addColorStop(0, `rgba(56, 189, 248, ${0.28 * alpha})`)
  g.addColorStop(1, 'rgba(56, 189, 248, 0)')
  ctx.fillStyle = g
  ctx.fillRect(20, -FAN_ZONE_WIDTH / 2, FAN_ZONE_LENGTH - 20, FAN_ZONE_WIDTH)
  ctx.strokeStyle = `rgba(56, 189, 248, ${0.6 * alpha})`
  ctx.lineWidth = 2
  const offset = ((now / 25) % 40) as number
  for (let i = 0; i < 6; i++) {
    const sx = 30 + i * 40 + offset
    if (sx > FAN_ZONE_LENGTH - 10) continue
    const fade = 1 - sx / FAN_ZONE_LENGTH
    ctx.globalAlpha = fade * alpha
    for (const dy of [-28, 0, 28]) {
      ctx.beginPath()
      ctx.moveTo(sx, dy)
      ctx.lineTo(sx + 16, dy)
      ctx.stroke()
    }
  }
  ctx.restore()
}

function drawParts(ctx: CanvasRenderingContext2D, s: RenderState) {
  for (const part of s.parts) {
    if (part.id === s.hiddenId) continue
    const body = s.sim.partBodies.get(part.id)
    const x = body ? body.position.x : part.x
    const y = body ? body.position.y : part.y
    const angle = body ? body.angle : degToRad(part.angle)
    const emphasis = part.id === s.selectedId ? 'selected' : part.id === s.hoverId ? 'hover' : 'none'
    drawPart(ctx, part.type, x, y, angle, 1, emphasis, s)
  }
}

function drawGhost(ctx: CanvasRenderingContext2D, g: Ghost) {
  const def = PART_DEFS[g.type]
  ctx.save()
  ctx.translate(g.x, g.y)
  ctx.rotate(degToRad(g.angle))
  ctx.globalAlpha = 0.9
  ctx.setLineDash([7, 5])
  ctx.lineWidth = 2
  ctx.strokeStyle = g.valid ? COLORS.ghost : COLORS.ghostBad
  ctx.fillStyle = g.valid ? 'rgba(226, 232, 240, 0.10)' : 'rgba(248, 113, 113, 0.12)'
  const extraH = g.type === 'seesaw' ? 46 : 0
  ctx.beginPath()
  ctx.roundRect(-def.w / 2 - 4, -def.h / 2 - 4, def.w + 8, def.h + 8 + extraH, 6)
  ctx.fill()
  ctx.stroke()
  ctx.setLineDash([])
  ctx.restore()
  ctx.save()
  ctx.globalAlpha = 0.55
  drawPart(ctx, g.type, g.x, g.y, degToRad(g.angle), 0.55, 'none', null)
  ctx.restore()
  if (def.rotatable) {
    ctx.save()
    const label = `${g.angle}°`
    const ly = g.y - def.h / 2 - Math.abs(Math.sin(degToRad(g.angle))) * (def.w / 2) - 22
    ctx.font = '600 12px Inter, system-ui, sans-serif'
    ctx.textAlign = 'center'
    ctx.textBaseline = 'middle'
    const tw = ctx.measureText(label).width + 16
    ctx.fillStyle = g.valid ? 'rgba(11, 18, 32, 0.85)' : 'rgba(127, 29, 29, 0.85)'
    ctx.beginPath()
    ctx.roundRect(g.x - tw / 2, ly - 11, tw, 22, 6)
    ctx.fill()
    ctx.fillStyle = g.valid ? '#fff' : '#fecaca'
    ctx.fillText(label, g.x, ly + 0.5)
    ctx.restore()
  }
}

function drawPart(
  ctx: CanvasRenderingContext2D,
  type: PartType,
  x: number,
  y: number,
  angle: number,
  alpha: number,
  emphasis: 'none' | 'hover' | 'selected',
  s: RenderState | null,
) {
  const def = PART_DEFS[type]
  ctx.save()
  ctx.translate(x, y)
  ctx.rotate(angle)
  ctx.globalAlpha = alpha

  if (emphasis !== 'none') {
    ctx.save()
    ctx.shadowColor = emphasis === 'selected' ? COLORS.select : 'rgba(255,255,255,0.6)'
    ctx.shadowBlur = emphasis === 'selected' ? 18 : 10
    ctx.fillStyle = 'rgba(0,0,0,0.01)'
    ctx.beginPath()
    ctx.roundRect(-def.w / 2, -def.h / 2, def.w, def.h, 4)
    ctx.fill()
    ctx.restore()
  }

  switch (type) {
    case 'ramp': {
      const g = ctx.createLinearGradient(0, -def.h / 2, 0, def.h / 2)
      g.addColorStop(0, '#60a5fa')
      g.addColorStop(1, '#1d4ed8')
      ctx.fillStyle = g
      ctx.beginPath()
      ctx.roundRect(-def.w / 2, -def.h / 2, def.w, def.h, 4)
      ctx.fill()
      ctx.fillStyle = 'rgba(191, 219, 254, 0.55)'
      for (let i = -def.w / 2 + 14; i < def.w / 2 - 8; i += 22) ctx.fillRect(i, -1, 8, 2)
      break
    }
    case 'domino': {
      ctx.fillStyle = '#e2e8f0'
      ctx.beginPath()
      ctx.roundRect(-def.w / 2, -def.h / 2, def.w, def.h, 3)
      ctx.fill()
      ctx.fillStyle = '#94a3b8'
      ctx.fillRect(-def.w / 2 + 3, -1, def.w - 6, 2)
      ctx.fillStyle = '#0f172a'
      for (const [dx, dy] of [
        [-3, -20],
        [3, -12],
        [-3, 12],
        [3, 20],
      ]) {
        ctx.beginPath()
        ctx.arc(dx, dy, 1.8, 0, Math.PI * 2)
        ctx.fill()
      }
      break
    }
    case 'trampoline': {
      ctx.fillStyle = '#3b1f7a'
      ctx.beginPath()
      ctx.roundRect(-def.w / 2, -def.h / 2, def.w, def.h, 6)
      ctx.fill()
      const g = ctx.createLinearGradient(-def.w / 2, 0, def.w / 2, 0)
      g.addColorStop(0, '#a78bfa')
      g.addColorStop(0.5, '#c4b5fd')
      g.addColorStop(1, '#a78bfa')
      ctx.fillStyle = g
      ctx.beginPath()
      ctx.roundRect(-def.w / 2 + 4, -def.h / 2 + 2, def.w - 8, def.h / 2, 4)
      ctx.fill()
      ctx.strokeStyle = '#ddd6fe'
      ctx.lineWidth = 2
      ctx.beginPath()
      for (let i = -def.w / 2 + 10; i < def.w / 2 - 6; i += 12) {
        ctx.moveTo(i, -def.h / 2 + 4)
        ctx.lineTo(i + 6, def.h / 2 - 4)
      }
      ctx.stroke()
      break
    }
    case 'fan': {
      ctx.fillStyle = '#0c4a6e'
      ctx.beginPath()
      ctx.roundRect(-def.w / 2, -def.h / 2, def.w, def.h, 8)
      ctx.fill()
      ctx.strokeStyle = '#38bdf8'
      ctx.lineWidth = 2
      ctx.beginPath()
      ctx.roundRect(-def.w / 2 + 1, -def.h / 2 + 1, def.w - 2, def.h - 2, 7)
      ctx.stroke()
      const spin = s && s.sim.mode === 'running' ? s.now / 60 : 0.6
      ctx.save()
      ctx.rotate(spin)
      ctx.fillStyle = '#7dd3fc'
      for (let i = 0; i < 3; i++) {
        ctx.rotate((Math.PI * 2) / 3)
        ctx.beginPath()
        ctx.ellipse(0, -9, 5, 11, 0, 0, Math.PI * 2)
        ctx.fill()
      }
      ctx.restore()
      ctx.fillStyle = '#e0f2fe'
      ctx.beginPath()
      ctx.arc(0, 0, 4, 0, Math.PI * 2)
      ctx.fill()
      ctx.fillStyle = '#38bdf8'
      ctx.beginPath()
      ctx.moveTo(def.w / 2 - 2, -6)
      ctx.lineTo(def.w / 2 + 6, 0)
      ctx.lineTo(def.w / 2 - 2, 6)
      ctx.closePath()
      ctx.fill()
      break
    }
    case 'seesaw': {
      ctx.restore()
      ctx.save()
      ctx.translate(x, y)
      ctx.globalAlpha = alpha
      ctx.fillStyle = '#4b5b72'
      ctx.beginPath()
      ctx.moveTo(-28, 47)
      ctx.lineTo(28, 47)
      ctx.lineTo(17, 13)
      ctx.lineTo(-17, 13)
      ctx.closePath()
      ctx.fill()
      ctx.rotate(angle)
      const g = ctx.createLinearGradient(0, -def.h / 2, 0, def.h / 2)
      g.addColorStop(0, '#6ee7b7')
      g.addColorStop(1, '#059669')
      ctx.fillStyle = g
      ctx.beginPath()
      ctx.roundRect(-def.w / 2, -def.h / 2, def.w, def.h, 3)
      ctx.fill()
      ctx.rotate(-angle)
      ctx.fillStyle = '#f8fafc'
      ctx.beginPath()
      ctx.arc(0, 0, 4, 0, Math.PI * 2)
      ctx.fill()
      break
    }
  }
  ctx.restore()
}
