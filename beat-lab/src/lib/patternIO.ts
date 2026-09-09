import {
  BASS_HIGH,
  BASS_LOW,
  BPM_MAX,
  BPM_MIN,
  STEPS,
  SWING_MAX,
  TRACKS,
  type Pattern,
  type Song,
  type Velocity,
} from '../types'

export const FILE_NAME = 'beat-lab-pattern.json'

export function serializeSong(song: Song): string {
  return JSON.stringify(song, null, 2)
}

export function downloadSong(song: Song): void {
  const blob = new Blob([serializeSong(song)], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = FILE_NAME
  document.body.appendChild(a)
  a.click()
  a.remove()
  setTimeout(() => URL.revokeObjectURL(url), 1000)
}

export type ParseResult = { ok: true; song: Song } | { ok: false; error: string }

function isRecord(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v)
}

function clampInt(v: unknown, min: number, max: number, fallback: number): number {
  if (typeof v !== 'number' || !Number.isFinite(v)) return fallback
  return Math.min(max, Math.max(min, Math.round(v)))
}

function parsePattern(v: unknown, label: string): Pattern | string {
  if (!isRecord(v)) return `pattern ${label} is not an object`
  const { drums, bass } = v
  if (!Array.isArray(drums) || drums.length !== TRACKS.length) {
    return `pattern ${label}: "drums" must have ${TRACKS.length} tracks`
  }
  const parsedDrums: Velocity[][] = []
  for (let t = 0; t < TRACKS.length; t++) {
    const row = drums[t]
    if (!Array.isArray(row) || row.length !== STEPS) {
      return `pattern ${label}: track ${t + 1} must have ${STEPS} steps`
    }
    parsedDrums.push(
      row.map((cell) => {
        const n = clampInt(cell, 0, 3, 0)
        return n as Velocity
      }),
    )
  }
  if (!Array.isArray(bass) || bass.length !== STEPS) {
    return `pattern ${label}: "bass" must have ${STEPS} steps`
  }
  const parsedBass = bass.map((cell) => {
    if (cell === null) return null
    if (typeof cell !== 'number' || cell < BASS_LOW || cell > BASS_HIGH) return null
    return Math.round(cell)
  })
  return { drums: parsedDrums, bass: parsedBass }
}

export function parseSong(text: string): ParseResult {
  let data: unknown
  try {
    data = JSON.parse(text)
  } catch {
    return { ok: false, error: 'File is not valid JSON.' }
  }
  if (!isRecord(data)) return { ok: false, error: 'JSON root must be an object.' }
  if (data.version !== 1) return { ok: false, error: 'Unsupported file version.' }
  if (!isRecord(data.patterns)) return { ok: false, error: 'Missing "patterns".' }
  const a = parsePattern(data.patterns.A, 'A')
  if (typeof a === 'string') return { ok: false, error: a }
  const b = parsePattern(data.patterns.B, 'B')
  if (typeof b === 'string') return { ok: false, error: b }
  return {
    ok: true,
    song: {
      version: 1,
      bpm: clampInt(data.bpm, BPM_MIN, BPM_MAX, 120),
      swing: clampInt(data.swing, 0, SWING_MAX, 0),
      chain: data.chain === true,
      patterns: { A: a, B: b },
    },
  }
}
