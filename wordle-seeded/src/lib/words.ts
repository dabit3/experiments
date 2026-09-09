import answersJson from '../data/answers.json'
import allowedJson from '../data/allowed.json'
import { mulberry32 } from './random'

export const WORD_LENGTH = 5
export const MAX_GUESSES = 6

export const ANSWERS: readonly string[] = answersJson
const VALID_WORDS = new Set<string>([...answersJson, ...allowedJson])

export const DICTIONARY_SIZE = VALID_WORDS.size

export function isValidWord(word: string): boolean {
  return VALID_WORDS.has(word.toLowerCase())
}

/** Every seed maps to exactly one answer; the same seed always yields the same word. */
export function answerForSeed(seed: number): string {
  const rand = mulberry32(seed)
  return ANSWERS[Math.floor(rand() * ANSWERS.length)]
}

export function parseSeed(search: string): number | null {
  const raw = new URLSearchParams(search).get('seed')
  if (raw === null || raw.trim() === '') return null
  const n = Number(raw)
  if (!Number.isFinite(n) || !Number.isInteger(n) || n < 0) return null
  return n
}

export function randomSeed(): number {
  return Math.floor(Math.random() * 100000)
}
