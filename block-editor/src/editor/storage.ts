import type { Doc } from './model'

const STORAGE_KEY = 'block-editor:document'

export function loadDoc(): Doc | null {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return null
    const parsed: unknown = JSON.parse(raw)
    if (!isDoc(parsed) || parsed.blocks.length === 0) return null
    return parsed
  } catch {
    return null
  }
}

export function saveDoc(doc: Doc): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(doc))
}

function isDoc(value: unknown): value is Doc {
  if (typeof value !== 'object' || value === null) return false
  const candidate = value as Partial<Doc>
  return typeof candidate.title === 'string' && Array.isArray(candidate.blocks)
}
