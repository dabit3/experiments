import { STEPS, TRACKS, VELOCITY_GAIN, emptyPattern, type Pattern, type PatternId } from '../types'
import { Synth } from './synth'

export interface PlaybackSnapshot {
  bpm: number
  swing: number
  chain: boolean
  editing: PatternId
  patterns: Record<PatternId, Pattern>
  muted: boolean[]
  soloed: boolean[]
}

export interface Position {
  step: number
  pattern: PatternId
}

const LOOKAHEAD_S = 0.12
const TICK_MS = 25

/**
 * Look-ahead scheduler (Web Audio clock drives timing, a coarse JS timer
 * feeds it). UI position updates are pulled off a queue in a rAF loop so the
 * highlighted column lands when the sound is actually heard.
 */
export class Sequencer {
  private synth: Synth | null = null
  private timer: ReturnType<typeof setInterval> | null = null
  private raf = 0
  private nextTime = 0
  private step = 0
  private pattern: PatternId = 'A'
  private queue: { time: number; pos: Position }[] = []
  private _playing = false

  private snapshot: PlaybackSnapshot = {
    bpm: 120,
    swing: 0,
    chain: false,
    editing: 'A',
    patterns: { A: emptyPattern(), B: emptyPattern() },
    muted: TRACKS.map(() => false),
    soloed: TRACKS.map(() => false),
  }
  private readonly onPosition: (pos: Position | null) => void

  constructor(onPosition: (pos: Position | null) => void) {
    this.onPosition = onPosition
  }

  /** Called whenever the UI state changes; the scheduler reads it each tick. */
  update(snapshot: PlaybackSnapshot): void {
    this.snapshot = snapshot
  }

  get playing(): boolean {
    return this._playing
  }

  private ensureSynth(): Synth {
    if (!this.synth) this.synth = new Synth()
    return this.synth
  }

  /** Audition a drum immediately (used when a step is switched on). */
  async preview(trackIndex: number, gain: number): Promise<void> {
    const s = this.ensureSynth()
    await s.resume()
    s.trigger(TRACKS[trackIndex].id, s.now, gain)
  }

  async previewBass(midi: number): Promise<void> {
    const s = this.ensureSynth()
    await s.resume()
    s.bass(midi, s.now, 0.22, 0.9)
  }

  async start(): Promise<void> {
    if (this._playing) return
    const s = this.ensureSynth()
    await s.resume()
    const snap = this.snapshot
    this._playing = true
    this.step = 0
    this.pattern = snap.chain ? 'A' : snap.editing
    this.queue = []
    this.nextTime = s.now + 0.05
    this.timer = setInterval(() => this.schedule(), TICK_MS)
    this.schedule()
    const loop = () => {
      this.drainQueue()
      this.raf = requestAnimationFrame(loop)
    }
    this.raf = requestAnimationFrame(loop)
  }

  stop(): void {
    if (!this._playing) return
    this._playing = false
    if (this.timer) clearInterval(this.timer)
    this.timer = null
    cancelAnimationFrame(this.raf)
    this.queue = []
    this.onPosition(null)
  }

  private schedule(): void {
    const s = this.synth
    if (!s) return
    const snap = this.snapshot
    const sixteenth = 60 / snap.bpm / 4
    while (this.nextTime < s.now + LOOKAHEAD_S) {
      const swingOffset = this.step % 2 === 1 ? sixteenth * (snap.swing / 100) : 0
      const t = this.nextTime + swingOffset
      this.fire(s, snap, t, sixteenth)
      this.queue.push({ time: t, pos: { step: this.step, pattern: this.pattern } })
      this.nextTime += sixteenth
      this.step += 1
      if (this.step >= STEPS) {
        this.step = 0
        if (snap.chain) this.pattern = this.pattern === 'A' ? 'B' : 'A'
        else this.pattern = snap.editing
      }
    }
  }

  private fire(s: Synth, snap: PlaybackSnapshot, t: number, sixteenth: number): void {
    const pat = snap.patterns[this.pattern]
    const anySolo = snap.soloed.some(Boolean)
    for (let i = 0; i < TRACKS.length; i++) {
      const vel = pat.drums[i][this.step]
      if (vel === 0) continue
      if (anySolo ? !snap.soloed[i] : snap.muted[i]) continue
      s.trigger(TRACKS[i].id, t, VELOCITY_GAIN[vel])
    }
    const note = pat.bass[this.step]
    if (note !== null) s.bass(note, t, sixteenth * 0.92, 0.9)
  }

  private drainQueue(): void {
    const s = this.synth
    if (!s) return
    let latest: Position | null = null
    while (this.queue.length && this.queue[0].time <= s.now + 0.005) {
      latest = this.queue.shift()!.pos
    }
    if (latest) this.onPosition(latest)
  }
}
