import type { Chess, Move, PieceSymbol } from 'chess.js'

export const PIECE_VALUE: Record<PieceSymbol, number> = {
  p: 1,
  n: 3,
  b: 3,
  r: 5,
  q: 9,
  k: 0,
}

/** Small, fast, seedable PRNG (32-bit state). */
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

export function plyOf(chess: Chess): number {
  return (chess.moveNumber() - 1) * 2 + (chess.turn() === 'b' ? 1 : 0)
}

const bySan = (a: Move, b: Move) => (a.san < b.san ? -1 : a.san > b.san ? 1 : 0)

/**
 * The built-in opponent. 1-ply greedy: if any capture is available, take the
 * most valuable victim (ties broken by a PRNG seeded from `seed` and the
 * current ply, so a given seed always produces the same game). Otherwise play
 * the first legal move in alphabetical SAN order.
 */
export function chooseEngineMove(chess: Chess, seed: number): Move | null {
  const moves = chess.moves({ verbose: true })
  if (moves.length === 0) return null

  const captures = moves.filter((m) => m.captured !== undefined)
  if (captures.length > 0) {
    let best = -1
    for (const m of captures) best = Math.max(best, PIECE_VALUE[m.captured as PieceSymbol])
    const top = captures
      .filter((m) => PIECE_VALUE[m.captured as PieceSymbol] === best)
      .sort(bySan)
    const rng = mulberry32(seed * 7919 + plyOf(chess))
    return top[Math.floor(rng() * top.length)]
  }

  return [...moves].sort(bySan)[0]
}
