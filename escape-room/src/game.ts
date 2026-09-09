export type Stage = 1 | 2 | 3 | 4 | 5 | 6 | 7

export type Color = 'crimson' | 'amber' | 'teal' | 'violet' | 'emerald' | 'ivory'

export const COLORS: Color[] = ['crimson', 'amber', 'teal', 'violet', 'emerald', 'ivory']

export const COLOR_HEX: Record<Color, string> = {
  crimson: '#b8312f',
  amber: '#d9a441',
  teal: '#2f8f8a',
  violet: '#6b4b9e',
  emerald: '#3f8a4f',
  ivory: '#efe6cf',
}

/** Painting stripes, top to bottom. Also the lockbox combination. */
export const PAINTING: Color[] = ['amber', 'teal', 'crimson', 'violet']

export const MORSE_WORD = 'OWL'

export const MORSE: Record<string, string> = {
  A: '.-', B: '-...', C: '-.-.', D: '-..', E: '.', F: '..-.', G: '--.', H: '....',
  I: '..', J: '.---', K: '-.-', L: '.-..', M: '--', N: '-.', O: '---', P: '.--.',
  Q: '--.-', R: '.-.', S: '...', T: '-', U: '..-', V: '...-', W: '.--', X: '-..-',
  Y: '-.--', Z: '--..',
}

/** One Morse unit in ms. Dot = 1, dash = 3, intra-letter gap = 1, letter gap = 3, word gap = 7. */
export const MORSE_UNIT = 800

export interface MorseFrame {
  on: boolean
  ms: number
}

export function morseFrames(word: string): MorseFrame[] {
  const frames: MorseFrame[] = []
  const letters = word.toUpperCase().split('')
  letters.forEach((letter, li) => {
    const code = MORSE[letter]
    code.split('').forEach((symbol, si) => {
      frames.push({ on: true, ms: (symbol === '-' ? 3 : 1) * MORSE_UNIT })
      if (si < code.length - 1) frames.push({ on: false, ms: MORSE_UNIT })
    })
    frames.push({ on: false, ms: (li < letters.length - 1 ? 3 : 7) * MORSE_UNIT })
  })
  return frames
}

export const SAFE_CODE = [4, 1, 9]

export const NOTE_TEXT = 'Lemon ink, dear reader. The safe answers to 4 · 1 · 9.'

export const CIPHER_PLAIN = 'THE LETTER ON THE DESK NUMBERS THE BOOKS'
export const CIPHER_SHIFT = 7

export function caesar(text: string, shift: number): string {
  const s = ((shift % 26) + 26) % 26
  return text
    .split('')
    .map((ch) => {
      const code = ch.charCodeAt(0)
      if (code >= 65 && code <= 90) return String.fromCharCode(((code - 65 + s) % 26) + 65)
      return ch
    })
    .join('')
}

export const CIPHER_TEXT = caesar(CIPHER_PLAIN, CIPHER_SHIFT)

export interface Book {
  id: string
  title: string
  color: string
  spine: string
}

export const BOOKS: Book[] = [
  { id: 'astronomy', title: 'Astronomy', color: '#2d4a6e', spine: '#3b5f8a' },
  { id: 'botany', title: 'Botany', color: '#3f6b3a', spine: '#4f8548' },
  { id: 'cartography', title: 'Cartography', color: '#8a3a2f', spine: '#a8493b' },
  { id: 'alchemy', title: 'Alchemy', color: '#5a3f7a', spine: '#6f4f96' },
  { id: 'poetry', title: 'Poetry', color: '#8a6a24', spine: '#a8842f' },
]

/** Order in which the books must be pulled, as numbered in the letter's margins. */
export const BOOK_ORDER = ['cartography', 'poetry', 'astronomy', 'alchemy', 'botany']

export const HINTS: Record<Stage, string> = {
  1: 'The lockbox has four dials stacked top to bottom. So, in a way, does the painting.',
  2: 'The lamp is signalling. I hear it as: long long long · short long long · short long short short. The poster by the door knows the alphabet.',
  3: 'Lemon-juice ink shows up under warmth. Rest your hand on the pinned note for a moment.',
  4: 'Rugs move if you pull them. Whatever you find, carry it to the drawer that is locked.',
  5: 'Turn the brass dial until the sampler on the wall reads like English.',
  6: 'The letter on the desk is long — scroll all of it. Small roman numerals sit in the margins beside book names.',
  7: 'The bolt is drawn. There is nothing left but the door.',
}

export const STAGE_TITLES: Record<Stage, string> = {
  1: 'The lockbox',
  2: 'The lamp',
  3: 'The note',
  4: 'The rug',
  5: 'The sampler',
  6: 'The bookshelf',
  7: 'The door',
}

export function formatTime(ms: number): string {
  const total = Math.floor(ms / 1000)
  const m = Math.floor(total / 60)
  const s = total % 60
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
}
