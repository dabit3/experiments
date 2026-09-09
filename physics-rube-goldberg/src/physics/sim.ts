import Matter from 'matter-js'
import { BALL_RADIUS, BELL_RADIUS, SCENE_H, SCENE_W, type Level } from '../levels.ts'
import { FAN_ZONE_LENGTH, FAN_ZONE_WIDTH, PART_DEFS, type PlacedPart } from '../parts.ts'

const { Bodies, Body, Composite, Constraint, Engine, Events, Vector, World } = Matter

export const STEP_MS = 1000 / 60
const MAX_STEPS_PER_FRAME = 4
const REST_SPEED = 1
const REST_STEPS = 90
const MIN_STEPS_BEFORE_REST = 45
const TIME_LIMIT_STEPS = 60 * 30
/** Steps the ball may spend inside territory it has already covered before the run is called off. */
const STALL_STEPS = 60 * 4
const FAN_STRENGTH = 0.0018
/** Static bodies always have restitution 0 in Matter, so trampolines bounce via a velocity override. */
const TRAMPOLINE_BOUNCE = 1.15
const TRAMPOLINE_MIN_LAUNCH = 7

export type SimMode = 'edit' | 'running' | 'won' | 'failed'
export type FailReason = 'rest' | 'stalled' | 'lost' | 'timeout'

export interface SimStatus {
  mode: SimMode
  reason?: FailReason
  steps: number
}

export interface FanBody {
  part: PlacedPart
  body: Matter.Body
  dir: Matter.Vector
}

export interface SeesawBody {
  part: PlacedPart
  plank: Matter.Body
}

interface ExtraPlugin {
  partId?: string
}

export function degToRad(deg: number): number {
  return (deg * Math.PI) / 180
}

/**
 * Owns the Matter.js engine for the current level. The world is rebuilt from
 * scratch (same body order, fixed timestep) on every reset so a given layout
 * always plays out identically.
 */
export class Sim {
  engine: Matter.Engine
  level: Level
  parts: PlacedPart[] = []
  ball!: Matter.Body
  bell!: Matter.Body
  fans: FanBody[] = []
  seesaws: SeesawBody[] = []
  partBodies = new Map<string, Matter.Body>()

  mode: SimMode = 'edit'
  failReason?: FailReason
  steps = 0
  trail: { x: number; y: number }[] = []
  bellRungAt = -1
  private restSteps = 0
  private stallSteps = 0
  private reach = { minX: 0, maxX: 0, minY: 0, maxY: 0 }
  private accumulator = 0
  private lastTime: number | null = null
  private listeners = new Set<(s: SimStatus) => void>()

  constructor(level: Level) {
    this.level = level
    this.engine = Engine.create({ enableSleeping: false })
    this.engine.gravity.y = 1
    this.engine.positionIterations = 8
    this.engine.velocityIterations = 6
    Events.on(this.engine, 'beforeUpdate', () => this.applyFans())
    Events.on(this.engine, 'collisionStart', (e) => this.onCollision(e))
    this.build(level, [])
  }

  subscribe(fn: (s: SimStatus) => void): () => void {
    this.listeners.add(fn)
    return () => {
      this.listeners.delete(fn)
    }
  }

  private emit() {
    const status: SimStatus = { mode: this.mode, reason: this.failReason, steps: this.steps }
    for (const fn of this.listeners) fn(status)
  }

  /** Rebuild the whole world for `level` with `parts` placed. Puts the sim in edit mode. */
  build(level: Level, parts: PlacedPart[]) {
    this.level = level
    this.parts = parts
    World.clear(this.engine.world, false)
    Engine.clear(this.engine)
    this.fans = []
    this.seesaws = []
    this.partBodies.clear()
    this.trail = []
    this.steps = 0
    this.restSteps = 0
    this.stallSteps = 0
    this.reach = { minX: level.spawn.x, maxX: level.spawn.x, minY: level.spawn.y, maxY: level.spawn.y }
    this.accumulator = 0
    this.lastTime = null
    this.bellRungAt = -1
    this.failReason = undefined

    const world = this.engine.world
    const statics: Matter.Body[] = []
    for (const r of level.obstacles) {
      statics.push(
        Bodies.rectangle(r.x + r.w / 2, r.y + r.h / 2, r.w, r.h, {
          isStatic: true,
          label: 'obstacle',
        }),
      )
    }
    Composite.add(world, statics)

    this.bell = Bodies.circle(level.bell.x, level.bell.y, BELL_RADIUS, {
      isStatic: true,
      label: 'bell',
    })
    Composite.add(world, this.bell)

    const sorted = [...parts].sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0))
    for (const part of sorted) this.addPartBody(part)

    this.ball = Bodies.circle(level.spawn.x, level.spawn.y, BALL_RADIUS, {
      label: 'ball',
      density: 0.0025,
      friction: 0,
      frictionStatic: 0,
      frictionAir: 0.001,
      restitution: 0.35,
    })
    Composite.add(world, this.ball)

    this.mode = 'edit'
    this.emit()
  }

  private addPartBody(part: PlacedPart) {
    const def = PART_DEFS[part.type]
    const angle = degToRad(part.angle)
    const world = this.engine.world
    const plugin: ExtraPlugin = { partId: part.id }
    switch (part.type) {
      case 'ramp': {
        const body = Bodies.rectangle(part.x, part.y, def.w, def.h, {
          isStatic: true,
          angle,
          label: 'ramp',
          chamfer: { radius: 4 },
          plugin,
        })
        Composite.add(world, body)
        this.partBodies.set(part.id, body)
        break
      }
      case 'trampoline': {
        const body = Bodies.rectangle(part.x, part.y, def.w, def.h, {
          isStatic: true,
          angle,
          label: 'trampoline',
          plugin,
        })
        Composite.add(world, body)
        this.partBodies.set(part.id, body)
        break
      }
      case 'domino': {
        const body = Bodies.rectangle(part.x, part.y, def.w, def.h, {
          label: 'domino',
          density: 0.0012,
          friction: 0.5,
          frictionAir: 0.01,
          restitution: 0.05,
          plugin,
        })
        Composite.add(world, body)
        this.partBodies.set(part.id, body)
        break
      }
      case 'fan': {
        const body = Bodies.rectangle(part.x, part.y, def.w, def.h, {
          isStatic: true,
          angle,
          label: 'fan',
          chamfer: { radius: 8 },
          plugin,
        })
        Composite.add(world, body)
        this.partBodies.set(part.id, body)
        this.fans.push({ part, body, dir: { x: Math.cos(angle), y: Math.sin(angle) } })
        break
      }
      case 'seesaw': {
        const plank = Bodies.rectangle(part.x, part.y, def.w, def.h, {
          label: 'seesaw',
          density: 0.0015,
          friction: 0.4,
          frictionAir: 0.02,
          restitution: 0.05,
          chamfer: { radius: 3 },
          plugin,
        })
        const pivot = Constraint.create({
          pointA: { x: part.x, y: part.y },
          bodyB: plank,
          pointB: { x: 0, y: 0 },
          length: 0,
          stiffness: 1,
        })
        const base = Bodies.trapezoid(part.x, part.y + 30, 56, 34, 0.6, {
          isStatic: true,
          label: 'seesaw-base',
          plugin,
        })
        Composite.add(world, [base, plank, pivot])
        this.partBodies.set(part.id, plank)
        this.seesaws.push({ part, plank })
        break
      }
    }
  }

  run() {
    if (this.mode !== 'edit') return
    this.mode = 'running'
    this.lastTime = null
    this.accumulator = 0
    this.emit()
  }

  /** Put the ball back on its spawn, keeping every placed part. */
  reset() {
    this.build(this.level, this.parts)
  }

  private applyFans() {
    if (this.fans.length === 0) return
    const bodies = Composite.allBodies(this.engine.world)
    for (const fan of this.fans) {
      const perp = { x: -fan.dir.y, y: fan.dir.x }
      for (const body of bodies) {
        if (body.isStatic) continue
        const rel = Vector.sub(body.position, fan.body.position)
        const along = Vector.dot(rel, fan.dir)
        const across = Vector.dot(rel, perp)
        if (along < 20 || along > FAN_ZONE_LENGTH || Math.abs(across) > FAN_ZONE_WIDTH / 2) continue
        const falloff = 1 - (along / FAN_ZONE_LENGTH) * 0.35
        const f = body.mass * FAN_STRENGTH * falloff
        Body.applyForce(body, body.position, { x: fan.dir.x * f, y: fan.dir.y * f })
      }
    }
  }

  private onCollision(e: Matter.IEventCollision<Matter.Engine>) {
    for (const pair of e.pairs) {
      const a = pair.bodyA
      const b = pair.bodyB
      if (a.label === 'trampoline' && !b.isStatic) this.bounce(a, b)
      else if (b.label === 'trampoline' && !a.isStatic) this.bounce(b, a)

      if (this.mode === 'running' && ((a.label === 'ball' && b.label === 'bell') || (a.label === 'bell' && b.label === 'ball'))) {
        this.mode = 'won'
        this.bellRungAt = this.steps
        this.emit()
      }
    }
  }

  private bounce(pad: Matter.Body, body: Matter.Body) {
    const n = { x: Math.sin(pad.angle), y: -Math.cos(pad.angle) }
    const rel = Vector.sub(body.position, pad.position)
    if (Vector.dot(rel, n) <= 0) return
    const v = body.velocity
    const vn = Vector.dot(v, n)
    if (vn > 0) return
    const launch = Math.max(-vn * TRAMPOLINE_BOUNCE, TRAMPOLINE_MIN_LAUNCH)
    Body.setVelocity(body, { x: v.x + (launch - vn) * n.x, y: v.y + (launch - vn) * n.y })
  }

  /** Advance the fixed-step simulation using wall-clock time for pacing only. */
  tick(now: number) {
    if (this.mode !== 'running' && this.mode !== 'won') return
    if (this.lastTime === null) this.lastTime = now
    this.accumulator += Math.min(now - this.lastTime, STEP_MS * MAX_STEPS_PER_FRAME)
    this.lastTime = now
    let n = 0
    while (this.accumulator >= STEP_MS && n < MAX_STEPS_PER_FRAME) {
      this.step()
      this.accumulator -= STEP_MS
      n++
    }
  }

  private step() {
    Engine.update(this.engine, STEP_MS)
    this.steps++
    const p = this.ball.position
    if (this.steps % 2 === 0) {
      this.trail.push({ x: p.x, y: p.y })
      if (this.trail.length > 400) this.trail.shift()
    }
    if (this.mode !== 'running') return

    if (p.y > SCENE_H + 80 || p.x < -80 || p.x > SCENE_W + 80) {
      this.fail('lost')
      return
    }
    if (this.steps > TIME_LIMIT_STEPS) {
      this.fail('timeout')
      return
    }
    if (this.steps > MIN_STEPS_BEFORE_REST && this.ball.speed < REST_SPEED) {
      this.restSteps++
      if (this.restSteps >= REST_STEPS) {
        this.fail('rest')
        return
      }
    } else {
      this.restSteps = 0
    }

    const r = this.reach
    if (p.x < r.minX - 1 || p.x > r.maxX + 1 || p.y < r.minY - 1 || p.y > r.maxY + 1) {
      r.minX = Math.min(r.minX, p.x)
      r.maxX = Math.max(r.maxX, p.x)
      r.minY = Math.min(r.minY, p.y)
      r.maxY = Math.max(r.maxY, p.y)
      this.stallSteps = 0
    } else if (++this.stallSteps >= STALL_STEPS) {
      this.fail('stalled')
    }
  }

  private fail(reason: FailReason) {
    this.mode = 'failed'
    this.failReason = reason
    this.emit()
  }

  /** Placed part whose (padded) footprint contains the scene point; later parts win. */
  partAt(x: number, y: number): PlacedPart | undefined {
    const pad = 8
    for (let i = this.parts.length - 1; i >= 0; i--) {
      const part = this.parts[i]
      const def = PART_DEFS[part.type]
      const ang = degToRad(part.angle)
      const dx = x - part.x
      const dy = y - part.y
      const lx = dx * Math.cos(ang) + dy * Math.sin(ang)
      const ly = -dx * Math.sin(ang) + dy * Math.cos(ang)
      if (Math.abs(lx) <= def.w / 2 + pad && Math.abs(ly) <= def.h / 2 + pad) return part
    }
    return undefined
  }

  /** Seconds elapsed in the current run. */
  get elapsed(): number {
    return this.steps / 60
  }
}
