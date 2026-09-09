export const PART_IDS = ['sole', 'upper', 'laces', 'tongue', 'heel', 'stripe'] as const
export type PartId = (typeof PART_IDS)[number]

export const PART_LABELS: Record<PartId, string> = {
  sole: 'Sole',
  upper: 'Upper',
  laces: 'Laces',
  tongue: 'Tongue',
  heel: 'Heel tab',
  stripe: 'Stripe',
}

export const FINISHES = ['matte', 'gloss', 'metallic'] as const
export type Finish = (typeof FINISHES)[number]

export const FINISH_LABELS: Record<Finish, string> = {
  matte: 'Matte',
  gloss: 'Gloss',
  metallic: 'Metallic',
}

export const VIEWS = ['hero', 'side', 'heel', 'top'] as const
export type ViewId = (typeof VIEWS)[number]

export const VIEW_LABELS: Record<ViewId, string> = {
  hero: 'Hero',
  side: 'Side',
  heel: 'Heel',
  top: 'Top',
}

export interface PartStyle {
  color: string
  finish: Finish
}

export interface SneakerConfig {
  parts: Record<PartId, PartStyle>
  text: string
  view: ViewId
  spin: boolean
}

export const MAX_TEXT = 8

export const PALETTE: { hex: string; name: string }[] = [
  { hex: '#f5f2eb', name: 'Chalk' },
  { hex: '#111111', name: 'Onyx' },
  { hex: '#1b2a49', name: 'Navy' },
  { hex: '#8d99ae', name: 'Slate' },
  { hex: '#d62828', name: 'Crimson' },
  { hex: '#f77f00', name: 'Tangerine' },
  { hex: '#fcbf49', name: 'Saffron' },
  { hex: '#c9a227', name: 'Gold' },
  { hex: '#2a9d8f', name: 'Jade' },
  { hex: '#b8f2e6', name: 'Mint' },
  { hex: '#3ec1d3', name: 'Aqua' },
  { hex: '#3a86ff', name: 'Cobalt' },
  { hex: '#7b2cbf', name: 'Violet' },
  { hex: '#ff5d8f', name: 'Bubblegum' },
  { hex: '#7f5539', name: 'Cocoa' },
  { hex: '#e0c097', name: 'Sand' },
]

export const DEFAULT_CONFIG: SneakerConfig = {
  parts: {
    sole: { color: '#f5f2eb', finish: 'matte' },
    upper: { color: '#1b2a49', finish: 'matte' },
    laces: { color: '#f5f2eb', finish: 'matte' },
    tongue: { color: '#8d99ae', finish: 'matte' },
    heel: { color: '#111111', finish: 'matte' },
    stripe: { color: '#f77f00', finish: 'gloss' },
  },
  text: '',
  view: 'hero',
  spin: false,
}

const HEX_RE = /^#?([0-9a-f]{6})$/i

export function normalizeHex(input: string): string | null {
  const m = HEX_RE.exec(input.trim())
  return m ? `#${m[1].toLowerCase()}` : null
}

export function sanitizeText(input: string): string {
  return input
    .toUpperCase()
    .replace(/[^A-Z0-9 .\-&!]/g, '')
    .slice(0, MAX_TEXT)
}

function isFinish(v: string): v is Finish {
  return (FINISHES as readonly string[]).includes(v)
}

function isView(v: string): v is ViewId {
  return (VIEWS as readonly string[]).includes(v)
}

/** Serialise a config to a URL hash such as `#sole=f5f2eb.matte&upper=...&text=DEVIN&view=hero&spin=1`. */
export function encodeConfig(config: SneakerConfig): string {
  const params = new URLSearchParams()
  for (const id of PART_IDS) {
    const { color, finish } = config.parts[id]
    params.set(id, `${color.replace('#', '')}.${finish}`)
  }
  if (config.text) params.set('text', config.text)
  params.set('view', config.view)
  if (config.spin) params.set('spin', '1')
  return `#${params.toString()}`
}

export function decodeConfig(hash: string): SneakerConfig | null {
  const raw = hash.startsWith('#') ? hash.slice(1) : hash
  if (!raw) return null
  const params = new URLSearchParams(raw)
  const config: SneakerConfig = structuredClone(DEFAULT_CONFIG)
  let touched = false
  for (const id of PART_IDS) {
    const value = params.get(id)
    if (!value) continue
    const [hexPart, finishPart = 'matte'] = value.split('.')
    const hex = normalizeHex(hexPart)
    if (!hex) continue
    config.parts[id] = { color: hex, finish: isFinish(finishPart) ? finishPart : 'matte' }
    touched = true
  }
  const text = params.get('text')
  if (text !== null) {
    config.text = sanitizeText(text)
    touched = true
  }
  const view = params.get('view')
  if (view && isView(view)) {
    config.view = view
    touched = true
  }
  if (params.get('spin') === '1') {
    config.spin = true
    touched = true
  }
  return touched ? config : null
}

/** Deterministic PRNG (mulberry32) so "Randomise #n" always yields the same design. */
export function mulberry32(seed: number): () => number {
  let a = seed >>> 0
  return () => {
    a = (a + 0x6d2b79f5) >>> 0
    let t = a
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

export function randomConfig(seed: number, base: SneakerConfig): SneakerConfig {
  const rand = mulberry32(seed)
  const pick = <T,>(arr: readonly T[]): T => arr[Math.floor(rand() * arr.length)]
  const parts = {} as Record<PartId, PartStyle>
  for (const id of PART_IDS) {
    parts[id] = { color: pick(PALETTE).hex, finish: pick(FINISHES) }
  }
  return { ...base, parts }
}

export function relativeLuminance(hex: string): number {
  const n = parseInt(hex.replace('#', ''), 16)
  const chan = (c: number) => {
    const s = c / 255
    return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4
  }
  return 0.2126 * chan((n >> 16) & 255) + 0.7152 * chan((n >> 8) & 255) + 0.0722 * chan(n & 255)
}
