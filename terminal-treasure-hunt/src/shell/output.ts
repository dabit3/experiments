export type SpanStyle =
  | 'plain'
  | 'dir'
  | 'exec'
  | 'hidden'
  | 'match'
  | 'error'
  | 'muted'
  | 'success'
  | 'accent'
  | 'flag'
  | 'heading'

export interface Span {
  text: string
  style?: SpanStyle
}

export type Line = Span[]

export const span = (text: string, style?: SpanStyle): Span => (style ? { text, style } : { text })
export const plain = (text: string): Line => [span(text)]
export const styled = (text: string, style: SpanStyle): Line => [span(text, style)]

export const lineText = (line: Line): string => line.map((s) => s.text).join('')

export const textLines = (text: string): Line[] => {
  const parts = text.split('\n')
  if (parts.length > 1 && parts[parts.length - 1] === '') parts.pop()
  return parts.map(plain)
}

/** Highlight every occurrence of `re` inside `text`. */
export function highlight(text: string, re: RegExp, style: SpanStyle = 'match'): Line {
  const out: Line = []
  const g = new RegExp(re.source, re.flags.includes('g') ? re.flags : re.flags + 'g')
  let last = 0
  for (const m of text.matchAll(g)) {
    const start = m.index
    if (m[0].length === 0) continue
    if (start > last) out.push(span(text.slice(last, start)))
    out.push(span(m[0], style))
    last = start + m[0].length
  }
  if (last < text.length) out.push(span(text.slice(last)))
  return out.length ? out : [span('')]
}
