import { MAX_GUESSES } from './words'

export interface Stats {
  gamesPlayed: number
  gamesWon: number
  currentStreak: number
  maxStreak: number
  /** Index 0..5 = solved in 1..6 guesses. */
  guessDistribution: number[]
  lastGuessCount: number | null
}

const STATS_KEY = 'wordle-seeded:stats'
const HARD_KEY = 'wordle-seeded:hard-mode'

export const EMPTY_STATS: Stats = {
  gamesPlayed: 0,
  gamesWon: 0,
  currentStreak: 0,
  maxStreak: 0,
  guessDistribution: Array<number>(MAX_GUESSES).fill(0),
  lastGuessCount: null,
}

function safeStorage(): Storage | null {
  try {
    return window.localStorage
  } catch {
    return null
  }
}

export function loadStats(): Stats {
  const raw = safeStorage()?.getItem(STATS_KEY)
  if (!raw) return EMPTY_STATS
  try {
    const parsed = JSON.parse(raw) as Partial<Stats>
    const distribution = Array.isArray(parsed.guessDistribution)
      ? parsed.guessDistribution.map((n) => (typeof n === 'number' ? n : 0))
      : []
    return {
      gamesPlayed: parsed.gamesPlayed ?? 0,
      gamesWon: parsed.gamesWon ?? 0,
      currentStreak: parsed.currentStreak ?? 0,
      maxStreak: parsed.maxStreak ?? 0,
      guessDistribution: Array.from({ length: MAX_GUESSES }, (_, i) => distribution[i] ?? 0),
      lastGuessCount: parsed.lastGuessCount ?? null,
    }
  } catch {
    return EMPTY_STATS
  }
}

export function saveStats(stats: Stats): void {
  safeStorage()?.setItem(STATS_KEY, JSON.stringify(stats))
}

export function recordResult(stats: Stats, won: boolean, guessCount: number): Stats {
  const distribution = [...stats.guessDistribution]
  if (won) distribution[guessCount - 1] += 1
  const currentStreak = won ? stats.currentStreak + 1 : 0
  return {
    gamesPlayed: stats.gamesPlayed + 1,
    gamesWon: stats.gamesWon + (won ? 1 : 0),
    currentStreak,
    maxStreak: Math.max(stats.maxStreak, currentStreak),
    guessDistribution: distribution,
    lastGuessCount: won ? guessCount : null,
  }
}

export function loadHardMode(): boolean {
  return safeStorage()?.getItem(HARD_KEY) === '1'
}

export function saveHardMode(enabled: boolean): void {
  safeStorage()?.setItem(HARD_KEY, enabled ? '1' : '0')
}
