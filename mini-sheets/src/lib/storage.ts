import type { Cells } from './sheet'

const STORAGE_KEY = 'mini-sheets:v1'

export function loadCells(): Cells {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return {}
    const parsed: unknown = JSON.parse(raw)
    if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) return {}
    const cells: Cells = {}
    for (const [key, cell] of Object.entries(parsed as Record<string, unknown>)) {
      if (typeof cell !== 'object' || cell === null) continue
      const { raw, bold } = cell as { raw?: unknown; bold?: unknown }
      if (typeof raw !== 'string') continue
      cells[key] = bold === true ? { raw, bold: true } : { raw }
    }
    return cells
  } catch {
    return {}
  }
}

export function saveCells(cells: Cells): void {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(cells))
  } catch {
    // Storage may be unavailable (private mode, quota); the sheet still works in memory.
  }
}
