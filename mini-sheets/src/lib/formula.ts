import { cellKey, colName, inBounds, normalizeRange, parseRef, rangePositions } from './cells'

export interface CellError {
  error: string
}

export type CellValue = number | string | null | CellError

export const isError = (v: CellValue): v is CellError => typeof v === 'object' && v !== null

const err = (code: string): CellError => ({ error: code })

// ---------------------------------------------------------------------------
// Tokenizer
// ---------------------------------------------------------------------------

type Token =
  | { type: 'num'; value: number; start: number; end: number }
  | { type: 'str'; value: string; start: number; end: number }
  | { type: 'ref'; text: string; start: number; end: number }
  | { type: 'name'; text: string; start: number; end: number }
  | { type: 'op'; text: string; start: number; end: number }
  | { type: 'err'; text: string; start: number; end: number }

class FormulaError extends Error {
  code: string
  constructor(code: string) {
    super(code)
    this.code = code
  }
}

const NUMBER_RE = /^(\d+\.?\d*|\.\d+)(e[+-]?\d+)?/i
const REF_RE = /^\$?[A-Za-z]+\$?\d+/
const NAME_RE = /^[A-Za-z_][A-Za-z0-9_.]*/
const ERR_RE = /^#[A-Z0-9/!?]+/
const OPS = new Set(['+', '-', '*', '/', '^', '&', '(', ')', ',', ':'])

function tokenize(src: string): Token[] {
  const tokens: Token[] = []
  let i = 0
  while (i < src.length) {
    const ch = src[i]
    const rest = src.slice(i)
    if (/\s/.test(ch)) {
      i++
      continue
    }
    let m: RegExpExecArray | null
    if ((m = NUMBER_RE.exec(rest))) {
      tokens.push({ type: 'num', value: Number(m[0]), start: i, end: i + m[0].length })
      i += m[0].length
    } else if (ch === '"') {
      const close = src.indexOf('"', i + 1)
      if (close === -1) throw new FormulaError('#ERROR!')
      tokens.push({ type: 'str', value: src.slice(i + 1, close), start: i, end: close + 1 })
      i = close + 1
    } else if ((m = REF_RE.exec(rest)) && !/^[A-Za-z0-9_.]/.test(rest.slice(m[0].length))) {
      tokens.push({ type: 'ref', text: m[0], start: i, end: i + m[0].length })
      i += m[0].length
    } else if ((m = NAME_RE.exec(rest))) {
      tokens.push({ type: 'name', text: m[0], start: i, end: i + m[0].length })
      i += m[0].length
    } else if ((m = ERR_RE.exec(rest))) {
      tokens.push({ type: 'err', text: m[0], start: i, end: i + m[0].length })
      i += m[0].length
    } else if (OPS.has(ch)) {
      tokens.push({ type: 'op', text: ch, start: i, end: i + 1 })
      i++
    } else {
      throw new FormulaError('#ERROR!')
    }
  }
  return tokens
}

// ---------------------------------------------------------------------------
// Parser
// ---------------------------------------------------------------------------

type Node =
  | { kind: 'num'; value: number }
  | { kind: 'str'; value: string }
  | { kind: 'ref'; key: string }
  | { kind: 'range'; keys: string[] }
  | { kind: 'err'; code: string }
  | { kind: 'unary'; op: string; operand: Node }
  | { kind: 'binary'; op: string; left: Node; right: Node }
  | { kind: 'call'; name: string; args: Node[] }

class Parser {
  private i = 0
  private tokens: Token[]

  constructor(tokens: Token[]) {
    this.tokens = tokens
  }

  parse(): Node {
    if (this.tokens.length === 0) throw new FormulaError('#ERROR!')
    const node = this.concat()
    if (this.i < this.tokens.length) throw new FormulaError('#ERROR!')
    return node
  }

  private peek(): Token | undefined {
    return this.tokens[this.i]
  }

  private isOp(text: string): boolean {
    const t = this.peek()
    return t?.type === 'op' && t.text === text
  }

  private expectOp(text: string) {
    if (!this.isOp(text)) throw new FormulaError('#ERROR!')
    this.i++
  }

  /** Consumes the current token (known to be an operator) and returns its text. */
  private takeOp(): string {
    const t = this.tokens[this.i++]
    return t.type === 'op' ? t.text : ''
  }

  private concat(): Node {
    let left = this.additive()
    while (this.isOp('&')) {
      this.i++
      left = { kind: 'binary', op: '&', left, right: this.additive() }
    }
    return left
  }

  private additive(): Node {
    let left = this.term()
    while (this.isOp('+') || this.isOp('-')) {
      left = { kind: 'binary', op: this.takeOp(), left, right: this.term() }
    }
    return left
  }

  private term(): Node {
    let left = this.unary()
    while (this.isOp('*') || this.isOp('/')) {
      left = { kind: 'binary', op: this.takeOp(), left, right: this.unary() }
    }
    return left
  }

  private unary(): Node {
    if (this.isOp('-') || this.isOp('+')) {
      return { kind: 'unary', op: this.takeOp(), operand: this.unary() }
    }
    return this.power()
  }

  private power(): Node {
    const base = this.primary()
    if (this.isOp('^')) {
      this.i++
      return { kind: 'binary', op: '^', left: base, right: this.unary() }
    }
    return base
  }

  private primary(): Node {
    const t = this.peek()
    if (!t) throw new FormulaError('#ERROR!')
    switch (t.type) {
      case 'num':
        this.i++
        return { kind: 'num', value: t.value }
      case 'str':
        this.i++
        return { kind: 'str', value: t.value }
      case 'err':
        this.i++
        return { kind: 'err', code: t.text }
      case 'ref': {
        this.i++
        const from = parseRef(t.text)
        if (!from) return { kind: 'err', code: '#REF!' }
        if (this.isOp(':')) {
          this.i++
          const toTok = this.peek()
          if (toTok?.type !== 'ref') throw new FormulaError('#ERROR!')
          this.i++
          const to = parseRef(toTok.text)
          if (!to) return { kind: 'err', code: '#REF!' }
          const keys = [...rangePositions(normalizeRange(from, to))].map(cellKey)
          return { kind: 'range', keys }
        }
        return { kind: 'ref', key: cellKey(from) }
      }
      case 'name': {
        this.i++
        this.expectOp('(')
        const args: Node[] = []
        if (!this.isOp(')')) {
          args.push(this.concat())
          while (this.isOp(',')) {
            this.i++
            args.push(this.concat())
          }
        }
        this.expectOp(')')
        return { kind: 'call', name: t.text.toUpperCase(), args }
      }
      case 'op':
        if (t.text === '(') {
          this.i++
          const inner = this.concat()
          this.expectOp(')')
          return inner
        }
        throw new FormulaError('#ERROR!')
    }
  }
}

// ---------------------------------------------------------------------------
// Evaluator
// ---------------------------------------------------------------------------

type Value = CellValue | CellValue[]

export type Resolver = (key: string) => CellValue

function toNumber(v: Value): number | CellError {
  if (Array.isArray(v)) return err('#VALUE!')
  if (v === null) return 0
  if (typeof v === 'number') return v
  if (isError(v)) return v
  const trimmed = v.trim()
  if (trimmed !== '' && Number.isFinite(Number(trimmed))) return Number(trimmed)
  return err('#VALUE!')
}

function toText(v: Value): string | CellError {
  if (Array.isArray(v)) return err('#VALUE!')
  if (v === null) return ''
  if (isError(v)) return v
  return typeof v === 'number' ? formatNumber(v) : v
}

/** Collects the numeric values for aggregate functions. Text inside ranges is ignored, like in Excel. */
function collectNumbers(args: Value[]): number[] | CellError {
  const out: number[] = []
  for (const arg of args) {
    if (Array.isArray(arg)) {
      for (const v of arg) {
        if (isError(v)) return v
        if (typeof v === 'number') out.push(v)
      }
    } else {
      const n = toNumber(arg)
      if (isError(n)) return n
      out.push(n)
    }
  }
  return out
}

type Aggregate = (nums: number[]) => number | CellError

const FUNCTIONS: Record<string, Aggregate> = {
  SUM: (nums) => nums.reduce((a, b) => a + b, 0),
  AVERAGE: (nums) => (nums.length === 0 ? err('#DIV/0!') : nums.reduce((a, b) => a + b, 0) / nums.length),
  MIN: (nums) => (nums.length === 0 ? 0 : Math.min(...nums)),
  MAX: (nums) => (nums.length === 0 ? 0 : Math.max(...nums)),
  COUNT: (nums) => nums.length,
  ABS: (nums) => (nums.length === 1 ? Math.abs(nums[0]) : err('#VALUE!')),
  ROUND: (nums) => {
    if (nums.length < 1 || nums.length > 2) return err('#VALUE!')
    const factor = 10 ** (nums[1] ?? 0)
    return Math.round(nums[0] * factor) / factor
  },
}

function evaluate(node: Node, resolve: Resolver): Value {
  switch (node.kind) {
    case 'num':
      return node.value
    case 'str':
      return node.value
    case 'err':
      return err(node.code)
    case 'ref':
      return resolve(node.key)
    case 'range':
      return node.keys.map(resolve)
    case 'unary': {
      const n = toNumber(evaluate(node.operand, resolve))
      if (isError(n)) return n
      return node.op === '-' ? -n : n
    }
    case 'binary': {
      const left = evaluate(node.left, resolve)
      const right = evaluate(node.right, resolve)
      if (node.op === '&') {
        const a = toText(left)
        if (isError(a)) return a
        const b = toText(right)
        if (isError(b)) return b
        return a + b
      }
      const a = toNumber(left)
      if (isError(a)) return a
      const b = toNumber(right)
      if (isError(b)) return b
      switch (node.op) {
        case '+':
          return a + b
        case '-':
          return a - b
        case '*':
          return a * b
        case '/':
          return b === 0 ? err('#DIV/0!') : a / b
        case '^':
          return a ** b
        default:
          return err('#ERROR!')
      }
    }
    case 'call': {
      const fn = FUNCTIONS[node.name]
      if (!fn) return err('#NAME?')
      const nums = collectNumbers(node.args.map((arg) => evaluate(arg, resolve)))
      if (!Array.isArray(nums)) return nums
      return fn(nums)
    }
  }
}

/** Evaluates the text after the leading `=`. */
export function evaluateFormula(src: string, resolve: Resolver): CellValue {
  try {
    const result = evaluate(new Parser(tokenize(src)).parse(), resolve)
    if (Array.isArray(result)) return result.length === 1 ? result[0] : err('#VALUE!')
    if (typeof result === 'number' && !Number.isFinite(result)) return err('#NUM!')
    return result
  } catch (e) {
    return err(e instanceof FormulaError ? e.code : '#ERROR!')
  }
}

export function parseLiteral(raw: string): CellValue {
  if (raw === '') return null
  const trimmed = raw.trim()
  if (trimmed !== '' && /^[-+]?(\d+\.?\d*|\.\d+)(e[+-]?\d+)?$/i.test(trimmed)) return Number(trimmed)
  return raw
}

// ---------------------------------------------------------------------------
// Relative reference adjustment (used by copy/paste and fill down)
// ---------------------------------------------------------------------------

function shiftRef(text: string, dRow: number, dCol: number): string {
  const ref = parseRef(text)
  if (!ref) return '#REF!'
  const row = ref.absRow ? ref.row : ref.row + dRow
  const col = ref.absCol ? ref.col : ref.col + dCol
  if (!inBounds({ row, col })) return '#REF!'
  return `${ref.absCol ? '$' : ''}${colName(col)}${ref.absRow ? '$' : ''}${row + 1}`
}

/** Returns `raw` with every relative cell reference in a formula shifted by the given offset. */
export function shiftFormula(raw: string, dRow: number, dCol: number): string {
  if (!raw.startsWith('=') || (dRow === 0 && dCol === 0)) return raw
  const src = raw.slice(1)
  let tokens: Token[]
  try {
    tokens = tokenize(src)
  } catch {
    return raw
  }
  let out = ''
  let last = 0
  for (const t of tokens) {
    if (t.type !== 'ref') continue
    out += src.slice(last, t.start) + shiftRef(t.text, dRow, dCol)
    last = t.end
  }
  return '=' + out + src.slice(last)
}

// ---------------------------------------------------------------------------
// Formatting
// ---------------------------------------------------------------------------

const numberFormat = new Intl.NumberFormat('en-US', { maximumFractionDigits: 6 })

export function formatNumber(n: number): string {
  return numberFormat.format(Number(n.toPrecision(12)))
}

export function formatValue(v: CellValue): string {
  if (v === null) return ''
  if (isError(v)) return v.error
  if (typeof v === 'string') return v
  return formatNumber(v)
}
