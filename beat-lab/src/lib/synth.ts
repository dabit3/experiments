import { midiToFreq, type TrackId } from '../types'

/**
 * All drum voices are synthesised from oscillators and filtered noise; no
 * samples are loaded. Every voice is a fire-and-forget node graph that is
 * scheduled at `time` and disconnects itself when the envelope ends.
 */
export class Synth {
  readonly ctx: AudioContext
  private readonly master: GainNode
  private readonly noise: AudioBuffer

  constructor() {
    this.ctx = new AudioContext()
    const comp = this.ctx.createDynamicsCompressor()
    comp.threshold.value = -10
    comp.knee.value = 12
    comp.ratio.value = 4
    comp.attack.value = 0.003
    comp.release.value = 0.12
    this.master = this.ctx.createGain()
    this.master.gain.value = 0.8
    this.master.connect(comp)
    comp.connect(this.ctx.destination)
    this.noise = this.makeNoise()
  }

  resume(): Promise<void> {
    return this.ctx.state === 'suspended' ? this.ctx.resume() : Promise.resolve()
  }

  get now(): number {
    return this.ctx.currentTime
  }

  private makeNoise(): AudioBuffer {
    const seconds = 1.5
    const buf = this.ctx.createBuffer(1, Math.floor(this.ctx.sampleRate * seconds), this.ctx.sampleRate)
    const data = buf.getChannelData(0)
    for (let i = 0; i < data.length; i++) data[i] = Math.random() * 2 - 1
    return buf
  }

  private env(time: number, peak: number, decay: number, attack = 0.001): GainNode {
    const g = this.ctx.createGain()
    g.gain.setValueAtTime(0.0001, time)
    g.gain.exponentialRampToValueAtTime(Math.max(peak, 0.0001), time + attack)
    g.gain.exponentialRampToValueAtTime(0.0001, time + attack + decay)
    g.connect(this.master)
    return g
  }

  private noiseSource(time: number, stop: number): AudioBufferSourceNode {
    const src = this.ctx.createBufferSource()
    src.buffer = this.noise
    src.loop = true
    src.start(time, Math.random() * 0.5)
    src.stop(stop)
    return src
  }

  private osc(type: OscillatorType, freq: number, time: number, stop: number): OscillatorNode {
    const o = this.ctx.createOscillator()
    o.type = type
    o.frequency.setValueAtTime(freq, time)
    o.start(time)
    o.stop(stop)
    return o
  }

  private filter(type: BiquadFilterType, freq: number, q = 1): BiquadFilterNode {
    const f = this.ctx.createBiquadFilter()
    f.type = type
    f.frequency.value = freq
    f.Q.value = q
    return f
  }

  trigger(track: TrackId, time: number, gain: number): void {
    switch (track) {
      case 'kick':
        return this.kick(time, gain)
      case 'snare':
        return this.snare(time, gain)
      case 'chat':
        return this.hat(time, gain, 0.06)
      case 'ohat':
        return this.hat(time, gain, 0.32)
      case 'clap':
        return this.clap(time, gain)
      case 'rim':
        return this.rim(time, gain)
      case 'tom':
        return this.tom(time, gain)
      case 'cowbell':
        return this.cowbell(time, gain)
    }
  }

  private kick(t: number, v: number): void {
    const decay = 0.42
    const o = this.osc('sine', 160, t, t + decay + 0.05)
    o.frequency.exponentialRampToValueAtTime(42, t + 0.14)
    const g = this.env(t, 1.1 * v, decay, 0.002)
    o.connect(g)
    // click transient
    const click = this.noiseSource(t, t + 0.03)
    const hp = this.filter('highpass', 2500)
    const cg = this.env(t, 0.35 * v, 0.02)
    click.connect(hp).connect(cg)
  }

  private snare(t: number, v: number): void {
    const n = this.noiseSource(t, t + 0.25)
    const bp = this.filter('bandpass', 1900, 0.8)
    const ng = this.env(t, 0.9 * v, 0.19)
    n.connect(bp).connect(ng)
    const o = this.osc('triangle', 185, t, t + 0.14)
    o.frequency.exponentialRampToValueAtTime(140, t + 0.08)
    const og = this.env(t, 0.7 * v, 0.11)
    o.connect(og)
  }

  private hat(t: number, v: number, decay: number): void {
    // 808-style: six square oscillators through a high-pass + band-pass.
    const ratios = [1, 1.342, 1.2312, 1.6532, 1.9523, 2.1523]
    const base = 340
    const hp = this.filter('highpass', 7000)
    const bp = this.filter('bandpass', 10000, 0.6)
    const g = this.env(t, 0.42 * v, decay)
    hp.connect(bp).connect(g)
    for (const r of ratios) {
      const o = this.osc('square', base * r, t, t + decay + 0.02)
      o.connect(hp)
    }
    const n = this.noiseSource(t, t + decay + 0.02)
    const nhp = this.filter('highpass', 9000)
    const ng = this.env(t, 0.18 * v, decay * 0.8)
    n.connect(nhp).connect(ng)
  }

  private clap(t: number, v: number): void {
    const bp = this.filter('bandpass', 1300, 1.2)
    const total = 0.25
    const n = this.noiseSource(t, t + total + 0.02)
    const g = this.ctx.createGain()
    g.gain.setValueAtTime(0.0001, t)
    // three fast bursts then a tail
    const spacing = 0.011
    for (let i = 0; i < 3; i++) {
      const s = t + i * spacing
      g.gain.setValueAtTime(0.9 * v, s)
      g.gain.exponentialRampToValueAtTime(0.25 * v, s + spacing)
    }
    const tail = t + 3 * spacing
    g.gain.setValueAtTime(0.9 * v, tail)
    g.gain.exponentialRampToValueAtTime(0.0001, tail + 0.17)
    n.connect(bp).connect(g).connect(this.master)
  }

  private rim(t: number, v: number): void {
    const o = this.osc('triangle', 1720, t, t + 0.06)
    const g = this.env(t, 0.6 * v, 0.04)
    o.connect(g)
    const o2 = this.osc('square', 455, t, t + 0.05)
    const g2 = this.env(t, 0.35 * v, 0.03)
    o2.connect(g2)
    const n = this.noiseSource(t, t + 0.03)
    const hp = this.filter('highpass', 4000)
    const ng = this.env(t, 0.3 * v, 0.02)
    n.connect(hp).connect(ng)
  }

  private tom(t: number, v: number): void {
    const decay = 0.34
    const o = this.osc('sine', 230, t, t + decay + 0.05)
    o.frequency.exponentialRampToValueAtTime(95, t + 0.2)
    const g = this.env(t, 0.9 * v, decay, 0.002)
    o.connect(g)
    const n = this.noiseSource(t, t + 0.05)
    const bp = this.filter('bandpass', 900, 1)
    const ng = this.env(t, 0.25 * v, 0.03)
    n.connect(bp).connect(ng)
  }

  private cowbell(t: number, v: number): void {
    const decay = 0.32
    const bp = this.filter('bandpass', 2640, 3.5)
    const g = this.env(t, 0.55 * v, decay)
    bp.connect(g)
    for (const f of [587, 845]) {
      const o = this.osc('square', f, t, t + decay + 0.02)
      o.connect(bp)
    }
  }

  bass(midi: number, time: number, duration: number, gain: number): void {
    const freq = midiToFreq(midi)
    const stop = time + duration + 0.08
    const saw = this.osc('sawtooth', freq, time, stop)
    const sub = this.osc('square', freq / 2, time, stop)
    const subGain = this.ctx.createGain()
    subGain.gain.value = 0.35
    const lp = this.filter('lowpass', 1400, 8)
    lp.frequency.setValueAtTime(1600, time)
    lp.frequency.exponentialRampToValueAtTime(220, time + duration)
    const g = this.ctx.createGain()
    g.gain.setValueAtTime(0.0001, time)
    g.gain.exponentialRampToValueAtTime(0.5 * gain, time + 0.006)
    g.gain.setValueAtTime(0.5 * gain, time + duration * 0.6)
    g.gain.exponentialRampToValueAtTime(0.0001, time + duration)
    saw.connect(lp)
    sub.connect(subGain).connect(lp)
    lp.connect(g).connect(this.master)
  }
}
