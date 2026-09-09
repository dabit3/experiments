export type TileState = 'correct' | 'present' | 'absent'
export type KeyState = TileState | 'unused'

const ORDINALS = ['1st', '2nd', '3rd', '4th', '5th']

/** Standard two-pass Wordle scoring that handles repeated letters correctly. */
export function evaluateGuess(guess: string, answer: string): TileState[] {
  const result: TileState[] = Array<TileState>(guess.length).fill('absent')
  const remaining: Record<string, number> = {}

  for (let i = 0; i < guess.length; i++) {
    if (guess[i] === answer[i]) {
      result[i] = 'correct'
    } else {
      remaining[answer[i]] = (remaining[answer[i]] ?? 0) + 1
    }
  }
  for (let i = 0; i < guess.length; i++) {
    if (result[i] === 'correct') continue
    const count = remaining[guess[i]] ?? 0
    if (count > 0) {
      result[i] = 'present'
      remaining[guess[i]] = count - 1
    }
  }
  return result
}

const RANK: Record<KeyState, number> = { unused: 0, absent: 1, present: 2, correct: 3 }

/** Best-known state for each letter across all evaluated guesses (drives keyboard colours). */
export function keyboardStates(guesses: string[], evaluations: TileState[][]): Map<string, KeyState> {
  const map = new Map<string, KeyState>()
  guesses.forEach((guess, row) => {
    const evaluation = evaluations[row]
    if (!evaluation) return
    for (let i = 0; i < guess.length; i++) {
      const letter = guess[i]
      const prev = map.get(letter) ?? 'unused'
      if (RANK[evaluation[i]] > RANK[prev]) map.set(letter, evaluation[i])
    }
  })
  return map
}

/**
 * Hard mode: any revealed hint must be reused. Returns a human-readable
 * violation message, or null when the guess honours every hint.
 */
export function hardModeViolation(
  guess: string,
  guesses: string[],
  evaluations: TileState[][],
): string | null {
  for (let row = 0; row < guesses.length; row++) {
    const prev = guesses[row]
    const evaluation = evaluations[row]
    if (!evaluation) continue

    for (let i = 0; i < prev.length; i++) {
      if (evaluation[i] === 'correct' && guess[i] !== prev[i]) {
        return `${ORDINALS[i]} letter must be ${prev[i].toUpperCase()}`
      }
    }

    // Count the letters the previous guess proved are in the answer and make
    // sure the new guess contains at least that many of each.
    const required: Record<string, number> = {}
    for (let i = 0; i < prev.length; i++) {
      if (evaluation[i] !== 'absent') required[prev[i]] = (required[prev[i]] ?? 0) + 1
    }
    const available: Record<string, number> = {}
    for (const letter of guess) available[letter] = (available[letter] ?? 0) + 1

    for (const letter of Object.keys(required)) {
      if ((available[letter] ?? 0) < required[letter]) {
        return `Guess must contain ${letter.toUpperCase()}`
      }
    }
  }
  return null
}
