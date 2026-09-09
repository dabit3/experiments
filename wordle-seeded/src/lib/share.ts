import type { TileState } from './evaluate'
import { MAX_GUESSES } from './words'

const EMOJI: Record<TileState, string> = {
  correct: '🟩',
  present: '🟨',
  absent: '⬛',
}

export function buildShareText(
  seed: number,
  evaluations: TileState[][],
  won: boolean,
  hardMode: boolean,
): string {
  const score = won ? String(evaluations.length) : 'X'
  const header = `Wordle Seeded #${seed} ${score}/${MAX_GUESSES}${hardMode ? '*' : ''}`
  const grid = evaluations.map((row) => row.map((s) => EMOJI[s]).join('')).join('\n')
  return `${header}\n\n${grid}`
}

export async function copyToClipboard(text: string): Promise<boolean> {
  try {
    if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(text)
      return true
    }
  } catch {
    // fall through to the legacy path
  }
  try {
    const textarea = document.createElement('textarea')
    textarea.value = text
    textarea.setAttribute('readonly', '')
    textarea.style.position = 'fixed'
    textarea.style.opacity = '0'
    document.body.appendChild(textarea)
    textarea.select()
    const ok = document.execCommand('copy')
    document.body.removeChild(textarea)
    return ok
  } catch {
    return false
  }
}
