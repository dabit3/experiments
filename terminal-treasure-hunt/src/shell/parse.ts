export interface SimpleCommand {
  name: string
  args: string[]
}

/** Split a raw line into tokens, honouring single/double quotes and backslash escapes. */
export function tokenize(line: string): string[] {
  const tokens: string[] = []
  let cur = ''
  let quote: '"' | "'" | null = null
  let has = false
  for (let i = 0; i < line.length; i++) {
    const ch = line[i]
    if (quote) {
      if (ch === quote) quote = null
      else if (ch === '\\' && quote === '"' && i + 1 < line.length) cur += line[++i]
      else cur += ch
      continue
    }
    if (ch === '"' || ch === "'") {
      quote = ch
      has = true
    } else if (ch === '\\' && i + 1 < line.length) {
      cur += line[++i]
      has = true
    } else if (/\s/.test(ch)) {
      if (has) tokens.push(cur)
      cur = ''
      has = false
    } else if (ch === '|' || ch === ';' || (ch === '&' && line[i + 1] === '&')) {
      if (has) tokens.push(cur)
      cur = ''
      has = false
      if (ch === '&') {
        tokens.push('&&')
        i++
      } else tokens.push(ch)
    } else {
      cur += ch
      has = true
    }
  }
  if (has) tokens.push(cur)
  return tokens
}

/** Sequence of pipelines; each pipeline is a list of simple commands joined by `|`. */
export function parse(line: string): SimpleCommand[][] {
  const tokens = tokenize(line)
  const sequence: SimpleCommand[][] = []
  let pipeline: SimpleCommand[] = []
  let words: string[] = []
  const flush = () => {
    if (words.length) pipeline.push({ name: words[0], args: words.slice(1) })
    words = []
  }
  for (const tok of tokens) {
    if (tok === '|') flush()
    else if (tok === '&&' || tok === ';') {
      flush()
      if (pipeline.length) sequence.push(pipeline)
      pipeline = []
    } else words.push(tok)
  }
  flush()
  if (pipeline.length) sequence.push(pipeline)
  return sequence
}

/** Split `-la` style flag clusters into individual flags; values after `-n` are kept as-is. */
export function parseFlags(
  args: string[],
  valueFlags: string[] = [],
): { flags: Set<string>; values: Map<string, string>; positional: string[] } {
  const flags = new Set<string>()
  const values = new Map<string, string>()
  const positional: string[] = []
  for (let i = 0; i < args.length; i++) {
    const a = args[i]
    if (a === '--') {
      positional.push(...args.slice(i + 1))
      break
    }
    if (a.startsWith('--') && a.length > 2) {
      flags.add(a.slice(2))
    } else if (a.startsWith('-') && a.length > 1) {
      const body = a.slice(1)
      if (/^\d+$/.test(body)) {
        values.set('n', body)
        continue
      }
      for (let j = 0; j < body.length; j++) {
        const f = body[j]
        if (valueFlags.includes(f)) {
          const rest = body.slice(j + 1)
          if (rest) values.set(f, rest)
          else if (i + 1 < args.length) values.set(f, args[++i])
          else values.set(f, '')
          break
        }
        flags.add(f)
      }
    } else positional.push(a)
  }
  return { flags, values, positional }
}

/** Convert a shell glob (`*`, `?`) into an anchored RegExp. */
export function globToRegExp(glob: string): RegExp {
  const src = glob
    .split('')
    .map((c) => (c === '*' ? '.*' : c === '?' ? '.' : c.replace(/[.+^${}()|[\]\\]/g, '\\$&')))
    .join('')
  return new RegExp(`^${src}$`)
}
