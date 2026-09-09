export type Grid = number[] // 81 entries, 0 = empty

export const rowOf = (i: number): number => Math.floor(i / 9)
export const colOf = (i: number): number => i % 9
export const boxOf = (i: number): number =>
  Math.floor(rowOf(i) / 3) * 3 + Math.floor(colOf(i) / 3)

const buildPeers = (): number[][] =>
  Array.from({ length: 81 }, (_, i) => {
    const out: number[] = []
    for (let j = 0; j < 81; j++) {
      if (j === i) continue
      if (rowOf(j) === rowOf(i) || colOf(j) === colOf(i) || boxOf(j) === boxOf(i)) {
        out.push(j)
      }
    }
    return out
  })

export const PEERS: number[][] = buildPeers()

export const parseGrid = (s: string): Grid => {
  if (s.length !== 81) throw new Error(`puzzle string must be 81 chars, got ${s.length}`)
  return Array.from(s, (ch) => {
    const n = ch.charCodeAt(0) - 48
    return n >= 1 && n <= 9 ? n : 0
  })
}

const candidates = (g: Grid, i: number): number[] => {
  const used = new Set<number>()
  for (const p of PEERS[i]) used.add(g[p])
  const out: number[] = []
  for (let v = 1; v <= 9; v++) if (!used.has(v)) out.push(v)
  return out
}

/** Backtracking solver; returns null when the grid has no solution. */
export const solve = (grid: Grid): Grid | null => {
  const g = grid.slice()
  const rec = (): boolean => {
    let best = -1
    let bestCands: number[] = []
    for (let i = 0; i < 81; i++) {
      if (g[i] !== 0) continue
      const c = candidates(g, i)
      if (c.length === 0) return false
      if (best === -1 || c.length < bestCands.length) {
        best = i
        bestCands = c
        if (c.length === 1) break
      }
    }
    if (best === -1) return true
    for (const v of bestCands) {
      g[best] = v
      if (rec()) return true
    }
    g[best] = 0
    return false
  }
  return rec() ? g : null
}

/** Indices whose value collides with a peer holding the same value. */
export const findConflicts = (g: Grid): Set<number> => {
  const out = new Set<number>()
  for (let i = 0; i < 81; i++) {
    const v = g[i]
    if (v === 0) continue
    for (const p of PEERS[i]) {
      if (g[p] === v) {
        out.add(i)
        out.add(p)
      }
    }
  }
  return out
}

export const isSolved = (g: Grid, solution: Grid): boolean =>
  g.every((v, i) => v !== 0 && v === solution[i])

export const formatTime = (seconds: number): string => {
  const m = Math.floor(seconds / 60)
  const s = seconds % 60
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
}
