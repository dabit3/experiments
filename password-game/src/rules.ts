import { findElements } from './data/elements'

export const SPONSORS = ['pepsi', 'starbucks', 'shell'] as const

export const MONTHS = [
  'january', 'february', 'march', 'april', 'may', 'june',
  'july', 'august', 'september', 'october', 'november', 'december',
] as const

export const ATOMIC_TARGET = 200
export const DIGIT_TARGET = 25
export const ROMAN_TARGET = 35

export interface RuleContext {
  password: string
  /** Current time as shown on the clock widget, "HH:MM". */
  time: string
  /** Today's Wordle answer as shown on the mini-board. */
  wordle: string
}

export interface RuleResult {
  pass: boolean
  /** Live progress shown on the card, e.g. "sum 34 / 25". */
  detail?: string
}

export interface Rule {
  id: number
  title: string
  check: (ctx: RuleContext) => RuleResult
}

export function digitSum(text: string): number {
  let sum = 0
  for (const ch of text) if (ch >= '0' && ch <= '9') sum += Number(ch)
  return sum
}

export function romanRuns(text: string): string[] {
  return text.match(/[IVXLCDM]+/g) ?? []
}

const ROMAN_VALUE: Record<string, number> = { I: 1, V: 5, X: 10, L: 50, C: 100, D: 500, M: 1000 }

export function romanToInt(numeral: string): number {
  let total = 0
  for (let i = 0; i < numeral.length; i++) {
    const cur = ROMAN_VALUE[numeral[i]]
    const next = i + 1 < numeral.length ? ROMAN_VALUE[numeral[i + 1]] : 0
    total += cur < next ? -cur : cur
  }
  return total
}

export function romanProduct(text: string): number | null {
  const runs = romanRuns(text)
  if (runs.length === 0) return null
  return runs.reduce((acc, run) => acc * romanToInt(run), 1)
}

export function isPrime(n: number): boolean {
  if (n < 2) return false
  for (let d = 2; d * d <= n; d++) if (n % d === 0) return false
  return true
}

export function formatClock(now: Date): string {
  const hh = String(now.getHours()).padStart(2, '0')
  const mm = String(now.getMinutes()).padStart(2, '0')
  return `${hh}:${mm}`
}

const includesAny = (haystack: string, needles: readonly string[]) =>
  needles.find((n) => haystack.includes(n))

export const RULES: Rule[] = [
  {
    id: 1,
    title: 'Your password must be at least 5 characters.',
    check: ({ password }) => ({
      pass: password.length >= 5,
      detail: `${password.length} / 5 characters`,
    }),
  },
  {
    id: 2,
    title: 'Your password must include a number.',
    check: ({ password }) => ({ pass: /\d/.test(password) }),
  },
  {
    id: 3,
    title: 'Your password must include an uppercase letter.',
    check: ({ password }) => ({ pass: /[A-Z]/.test(password) }),
  },
  {
    id: 4,
    title: 'Your password must include a special character.',
    check: ({ password }) => ({ pass: /[^A-Za-z0-9\s]/.test(password) }),
  },
  {
    id: 5,
    title: `The digits in your password must add up to ${DIGIT_TARGET}.`,
    check: ({ password }) => {
      const sum = digitSum(password)
      return { pass: sum === DIGIT_TARGET, detail: `digits sum to ${sum} / ${DIGIT_TARGET}` }
    },
  },
  {
    id: 6,
    title: 'Your password must include a month of the year.',
    check: ({ password }) => {
      const hit = includesAny(password.toLowerCase(), MONTHS)
      return { pass: hit !== undefined, detail: hit ? `found "${hit}"` : 'no month yet' }
    },
  },
  {
    id: 7,
    title: 'Your password must include a Roman numeral (uppercase I V X L C D M).',
    check: ({ password }) => {
      const runs = romanRuns(password)
      return {
        pass: runs.length > 0,
        detail: runs.length ? `found ${runs.map((r) => `${r} = ${romanToInt(r)}`).join(', ')}` : 'none yet',
      }
    },
  },
  {
    id: 8,
    title: 'Your password must include one of our sponsors: Pepsi, Starbucks or Shell.',
    check: ({ password }) => {
      const hit = includesAny(password.toLowerCase(), SPONSORS)
      return { pass: hit !== undefined, detail: hit ? `found "${hit}"` : 'no sponsor yet' }
    },
  },
  {
    id: 9,
    title: `The Roman numerals in your password must multiply to ${ROMAN_TARGET}.`,
    check: ({ password }) => {
      const product = romanProduct(password)
      return {
        pass: product === ROMAN_TARGET,
        detail: product === null ? 'no Roman numerals' : `product is ${product} / ${ROMAN_TARGET}`,
      }
    },
  },
  {
    id: 10,
    title: 'Your password must include a two-letter chemical element symbol (e.g. He, Fe, Ti).',
    check: ({ password }) => {
      const twos = findElements(password).filter((e) => e.symbol.length === 2)
      return {
        pass: twos.length > 0,
        detail: twos.length ? `found ${twos.map((e) => e.symbol).join(', ')}` : 'none yet',
      }
    },
  },
  {
    id: 11,
    title: 'Your password must include the current time as HH:MM (see the clock).',
    check: ({ password, time }) => ({
      pass: password.includes(time),
      detail: `clock reads ${time}`,
    }),
  },
  {
    id: 12,
    title: "Your password must include today's Wordle answer (see the board).",
    check: ({ password, wordle }) => ({
      pass: password.toLowerCase().includes(wordle),
      detail: 'the green row on the board',
    }),
  },
  {
    id: 13,
    title: `The atomic numbers of the element symbols in your password must add up to ${ATOMIC_TARGET}.`,
    check: ({ password }) => {
      const hits = findElements(password)
      const sum = hits.reduce((acc, e) => acc + e.number, 0)
      const list = hits.map((e) => `${e.symbol}\u00a0${e.number}`).join(' + ')
      return {
        pass: sum === ATOMIC_TARGET,
        detail: hits.length ? `${list} = ${sum} / ${ATOMIC_TARGET}` : `0 / ${ATOMIC_TARGET}`,
      }
    },
  },
  {
    id: 14,
    title: 'The length of your password must be a prime number.',
    check: ({ password }) => {
      const n = password.length
      return { pass: isPrime(n), detail: `${n} is ${isPrime(n) ? '' : 'not '}prime` }
    },
  },
]

export interface RuleState {
  rule: Rule
  result: RuleResult
}

/**
 * Rules are revealed one at a time: rule N+1 appears once rules 1..N all pass.
 * Once revealed, a rule stays visible even if a later edit breaks it.
 */
export function evaluate(ctx: RuleContext, revealed: number): { states: RuleState[]; nextRevealed: number } {
  const states = RULES.map((rule) => ({ rule, result: rule.check(ctx) }))
  let next = revealed
  while (next < RULES.length && states.slice(0, next).every((s) => s.result.pass)) {
    next++
  }
  return { states: states.slice(0, next), nextRevealed: next }
}
