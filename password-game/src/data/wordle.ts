/** Bundled answer list; the day's answer is picked deterministically from it. */
const ANSWERS = [
  'crane', 'slate', 'brine', 'pouch', 'gloat', 'frost', 'medal', 'quirk', 'shard', 'tulip',
  'bloom', 'cider', 'dwarf', 'ember', 'flock', 'grove', 'haunt', 'ivory', 'jumbo', 'knelt',
  'lunar', 'mirth', 'noble', 'orbit', 'plaid', 'quota', 'rusty', 'spoke', 'thorn', 'ultra',
  'vivid', 'wharf', 'yacht', 'zesty', 'amber', 'bench', 'coral', 'dough', 'elbow', 'fjord',
] as const

/** Fixed openers used to fill the rows above the answer. */
const OPENERS = ['stare', 'point', 'lucky'] as const

export type TileState = 'correct' | 'present' | 'absent'

export interface WordleRow {
  word: string
  tiles: TileState[]
}

export interface WordleBoardData {
  puzzleNumber: number
  answer: string
  rows: WordleRow[]
}

/** Days since 2021-06-19 (Wordle #0), computed in local time. */
function dayIndex(now: Date): number {
  const epoch = new Date(2021, 5, 19).getTime()
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime()
  return Math.max(0, Math.floor((today - epoch) / 86_400_000))
}

export function scoreGuess(guess: string, answer: string): TileState[] {
  const result: TileState[] = Array.from({ length: 5 }, () => 'absent')
  const remaining: (string | null)[] = answer.split('')
  for (let i = 0; i < 5; i++) {
    if (guess[i] === answer[i]) {
      result[i] = 'correct'
      remaining[i] = null
    }
  }
  for (let i = 0; i < 5; i++) {
    if (result[i] === 'correct') continue
    const j = remaining.indexOf(guess[i])
    if (j !== -1) {
      result[i] = 'present'
      remaining[j] = null
    }
  }
  return result
}

export function todaysWordle(now: Date = new Date()): WordleBoardData {
  const day = dayIndex(now)
  const answer = ANSWERS[day % ANSWERS.length]
  const rows: WordleRow[] = OPENERS.map((word) => ({ word, tiles: scoreGuess(word, answer) }))
  rows.push({ word: answer, tiles: Array.from({ length: 5 }, () => 'correct') })
  return { puzzleNumber: day, answer, rows }
}
