export const STEPS = 16

export type TrackId =
  | 'kick'
  | 'snare'
  | 'chat'
  | 'ohat'
  | 'clap'
  | 'rim'
  | 'tom'
  | 'cowbell'

export interface TrackDef {
  id: TrackId
  name: string
  short: string
  color: string
}

export const TRACKS: readonly TrackDef[] = [
  { id: 'kick', name: 'Kick', short: 'BD', color: '#ff5c4d' },
  { id: 'snare', name: 'Snare', short: 'SD', color: '#ffb547' },
  { id: 'chat', name: 'Closed hat', short: 'CH', color: '#ffe27a' },
  { id: 'ohat', name: 'Open hat', short: 'OH', color: '#c8f26b' },
  { id: 'clap', name: 'Clap', short: 'CP', color: '#ff8fb1' },
  { id: 'rim', name: 'Rim', short: 'RS', color: '#9ad0ff' },
  { id: 'tom', name: 'Tom', short: 'LT', color: '#c59cff' },
  { id: 'cowbell', name: 'Cowbell', short: 'CB', color: '#7ee0a8' },
]

/** 0 = off, 1 = soft, 2 = medium, 3 = full. */
export type Velocity = 0 | 1 | 2 | 3

export const VELOCITY_GAIN: Record<Velocity, number> = { 0: 0, 1: 0.45, 2: 0.72, 3: 1 }
export const VELOCITY_LABEL: Record<Velocity, string> = { 0: 'off', 1: 'soft', 2: 'medium', 3: 'full' }

export type PatternId = 'A' | 'B'

export interface Pattern {
  /** drums[trackIndex][step] */
  drums: Velocity[][]
  /** bass[step] = MIDI note number or null */
  bass: (number | null)[]
}

export interface Song {
  version: 1
  bpm: number
  swing: number
  chain: boolean
  patterns: Record<PatternId, Pattern>
}

export const BPM_MIN = 60
export const BPM_MAX = 200
export const SWING_MAX = 75

/** Piano roll range: C2 (36) .. C4 (60), inclusive. */
export const BASS_LOW = 36
export const BASS_HIGH = 60

export function emptyPattern(): Pattern {
  return {
    drums: TRACKS.map(() => Array<Velocity>(STEPS).fill(0)),
    bass: Array<number | null>(STEPS).fill(null),
  }
}

export function emptySong(): Song {
  return {
    version: 1,
    bpm: 120,
    swing: 0,
    chain: false,
    patterns: { A: emptyPattern(), B: emptyPattern() },
  }
}

const NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']

export function midiToName(midi: number): string {
  return `${NOTE_NAMES[midi % 12]}${Math.floor(midi / 12) - 1}`
}

export function isBlackKey(midi: number): boolean {
  return NOTE_NAMES[midi % 12].includes('#')
}

export function midiToFreq(midi: number): number {
  return 440 * Math.pow(2, (midi - 69) / 12)
}
