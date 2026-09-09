import { STEPS, TRACKS, type Pattern, type TrackId, type Velocity } from './types'

export interface ReferencePattern {
  name: string
  description: string
  bpm: number
  hits: Record<TrackId, number[]>
}

/**
 * The reference the user must reproduce. Steps are 1-based here so the
 * numbers line up with the labels shown on the grid.
 */
export const BOOM_BAP: ReferencePattern = {
  name: 'Boom Bap',
  description: 'Lazy kick, backbeat snare + clap, straight eighth hats.',
  bpm: 92,
  hits: {
    kick: [1, 8, 11],
    snare: [5, 13],
    chat: [1, 3, 5, 7, 9, 11, 13, 15],
    ohat: [7, 15],
    clap: [5, 13],
    rim: [4, 12],
    tom: [14],
    cowbell: [10],
  },
}

export function referenceToPattern(ref: ReferencePattern): Pattern {
  return {
    drums: TRACKS.map((t) => {
      const row = Array<Velocity>(STEPS).fill(0)
      for (const s of ref.hits[t.id]) row[s - 1] = 3
      return row
    }),
    bass: Array<number | null>(STEPS).fill(null),
  }
}

export interface StepDiff {
  track: number
  step: number
  kind: 'missing' | 'extra'
}

/** Compares on/off state only; velocity is not part of the reference. */
export function compareDrums(current: Velocity[][], reference: Velocity[][]): StepDiff[] {
  const diffs: StepDiff[] = []
  for (let t = 0; t < TRACKS.length; t++) {
    for (let s = 0; s < STEPS; s++) {
      const have = current[t][s] > 0
      const want = reference[t][s] > 0
      if (have !== want) diffs.push({ track: t, step: s, kind: want ? 'missing' : 'extra' })
    }
  }
  return diffs
}
