import type { Level } from './board'

export interface BestTime {
  seconds: number
  seed: number
  date: string
}

export type BestTimes = Partial<Record<Level, BestTime>>

const KEY = 'minesweeper-lab:best-times'

export function loadBestTimes(): BestTimes {
  try {
    const raw = localStorage.getItem(KEY)
    if (!raw) return {}
    const parsed: unknown = JSON.parse(raw)
    if (typeof parsed !== 'object' || parsed === null) return {}
    return parsed as BestTimes
  } catch {
    return {}
  }
}

export function saveBestTimes(times: BestTimes): void {
  try {
    localStorage.setItem(KEY, JSON.stringify(times))
  } catch {
    // Storage may be unavailable (private mode); best times are optional.
  }
}

/** Returns the table with `seconds` recorded if it beats the stored one, plus whether it was a record. */
export function recordTime(times: BestTimes, level: Level, seconds: number, seed: number): { times: BestTimes; isRecord: boolean } {
  const existing = times[level]
  if (existing && existing.seconds <= seconds) return { times, isRecord: false }
  const next: BestTimes = { ...times, [level]: { seconds, seed, date: new Date().toISOString() } }
  return { times: next, isRecord: true }
}
