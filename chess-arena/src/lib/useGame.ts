import { useCallback, useEffect, useMemo, useState } from 'react'
import { Chess, type Color, type Move, type PieceSymbol, type Square } from 'chess.js'
import { chooseEngineMove, PIECE_VALUE } from './engine'

export const ENGINE_DELAY_MS = 450
export const DEFAULT_SEED = 7

export interface TrackedPiece {
  id: string
  color: Color
  type: PieceSymbol
  square: Square
}

export interface Captured {
  w: PieceSymbol[]
  b: PieceSymbol[]
}

export type GameResult =
  | { kind: 'checkmate'; winner: Color }
  | { kind: 'stalemate' }
  | { kind: 'draw'; reason: string }

export function readSeedFromUrl(): number {
  const raw = new URLSearchParams(window.location.search).get('seed')
  const n = raw === null ? NaN : Number.parseInt(raw, 10)
  return Number.isFinite(n) && n >= 0 ? n : DEFAULT_SEED
}

function writeSeedToUrl(seed: number) {
  const url = new URL(window.location.href)
  url.searchParams.set('seed', String(seed))
  window.history.replaceState(null, '', url)
}

function initialPieces(): TrackedPiece[] {
  const pieces: TrackedPiece[] = []
  const board = new Chess().board()
  for (const row of board) {
    for (const cell of row) {
      if (cell) pieces.push({ id: `${cell.color}${cell.type}-${cell.square}`, ...cell })
    }
  }
  return pieces
}

/** Follow every piece through the move list so the UI can animate moves. */
function trackPieces(history: Move[]): TrackedPiece[] {
  let pieces = initialPieces()
  for (const m of history) {
    const rankBack = m.color === 'w' ? '5' : '4'
    const epSquare = m.isEnPassant() ? (`${m.to[0]}${rankBack}` as Square) : null
    pieces = pieces
      .filter((p) => p.square !== m.to && p.square !== epSquare)
      .map((p) => {
        if (p.square === m.from) {
          return { ...p, square: m.to, type: m.promotion ?? p.type }
        }
        if (m.isKingsideCastle() && p.square === (`h${m.from[1]}` as Square)) {
          return { ...p, square: `f${m.from[1]}` as Square }
        }
        if (m.isQueensideCastle() && p.square === (`a${m.from[1]}` as Square)) {
          return { ...p, square: `d${m.from[1]}` as Square }
        }
        return p
      })
  }
  return pieces
}

function resultOf(chess: Chess): GameResult | null {
  if (chess.isCheckmate()) return { kind: 'checkmate', winner: chess.turn() === 'w' ? 'b' : 'w' }
  if (chess.isStalemate()) return { kind: 'stalemate' }
  if (chess.isThreefoldRepetition()) return { kind: 'draw', reason: 'threefold repetition' }
  if (chess.isInsufficientMaterial()) return { kind: 'draw', reason: 'insufficient material' }
  if (chess.isDrawByFiftyMoves()) return { kind: 'draw', reason: 'fifty-move rule' }
  if (chess.isDraw()) return { kind: 'draw', reason: 'draw' }
  return null
}

export function useGame() {
  const [seed, setSeed] = useState(readSeedFromUrl)
  const [sans, setSans] = useState<string[]>([])

  const chess = useMemo(() => {
    const c = new Chess()
    for (const san of sans) c.move(san)
    return c
  }, [sans])

  const history = useMemo(() => chess.history({ verbose: true }), [chess])
  const pieces = useMemo(() => trackPieces(history), [history])
  const result = useMemo(() => resultOf(chess), [chess])
  const lastMove = history.length > 0 ? history[history.length - 1] : null
  const turn = chess.turn()
  const inCheck = chess.inCheck()
  const playerToMove = turn === 'w' && result === null
  const engineThinking = turn === 'b' && result === null

  const captured = useMemo<Captured>(() => {
    const out: Captured = { w: [], b: [] }
    for (const m of history) {
      if (m.captured) out[m.color].push(m.captured)
    }
    const order: PieceSymbol[] = ['q', 'r', 'b', 'n', 'p']
    const sortByValue = (a: PieceSymbol, b: PieceSymbol) => order.indexOf(a) - order.indexOf(b)
    out.w.sort(sortByValue)
    out.b.sort(sortByValue)
    return out
  }, [history])

  const materialBalance = useMemo(() => {
    const sum = (list: PieceSymbol[]) => list.reduce((acc, p) => acc + PIECE_VALUE[p], 0)
    return sum(captured.w) - sum(captured.b)
  }, [captured])

  // The engine replies a beat after every White move (StrictMode-safe via cleanup).
  useEffect(() => {
    if (!engineThinking) return
    const expectedLength = sans.length
    const timer = window.setTimeout(() => {
      const reply = chooseEngineMove(chess, seed)
      if (!reply) return
      setSans((prev) => (prev.length === expectedLength ? [...prev, reply.san] : prev))
    }, ENGINE_DELAY_MS)
    return () => window.clearTimeout(timer)
  }, [engineThinking, chess, seed, sans.length])

  const legalMovesFrom = useCallback(
    (square: Square): Move[] => (playerToMove ? chess.moves({ square, verbose: true }) : []),
    [chess, playerToMove],
  )

  /**
   * Try to play a White move. Returns 'moved', 'promotion' (a promotion piece is
   * required first) or 'illegal'.
   */
  const playMove = useCallback(
    (from: Square, to: Square, promotion?: PieceSymbol): 'moved' | 'promotion' | 'illegal' => {
      if (!playerToMove) return 'illegal'
      const candidates = chess.moves({ square: from, verbose: true }).filter((m) => m.to === to)
      if (candidates.length === 0) return 'illegal'
      const needsPromotion = candidates.some((m) => m.promotion !== undefined)
      if (needsPromotion && !promotion) return 'promotion'
      const chosen = needsPromotion
        ? candidates.find((m) => m.promotion === promotion)
        : candidates[0]
      if (!chosen) return 'illegal'
      setSans((prev) => [...prev, chosen.san])
      return 'moved'
    },
    [chess, playerToMove],
  )

  const newGame = useCallback((nextSeed?: number) => {
    if (nextSeed !== undefined) {
      setSeed(nextSeed)
      writeSeedToUrl(nextSeed)
    }
    setSans([])
  }, [])

  /** Take back the last full move so it is White's turn again. */
  const undo = useCallback(() => {
    setSans((prev) => {
      if (prev.length === 0) return prev
      const remove = prev.length % 2 === 0 ? 2 : 1
      return prev.slice(0, prev.length - remove)
    })
  }, [])

  const pgn = useCallback(() => {
    const c = new Chess()
    c.setHeader('Event', 'Chess Arena')
    c.setHeader('Site', 'chess-arena (local)')
    c.setHeader('Date', new Date().toISOString().slice(0, 10).replaceAll('-', '.'))
    c.setHeader('White', 'Devin')
    c.setHeader('Black', `Greedy engine (seed ${seed})`)
    for (const san of sans) c.move(san)
    if (result) {
      c.setHeader(
        'Result',
        result.kind === 'checkmate' ? (result.winner === 'w' ? '1-0' : '0-1') : '1/2-1/2',
      )
    }
    return c.pgn()
  }, [sans, seed, result])

  return {
    chess,
    seed,
    sans,
    history,
    pieces,
    result,
    lastMove,
    turn,
    inCheck,
    playerToMove,
    engineThinking,
    captured,
    materialBalance,
    legalMovesFrom,
    playMove,
    newGame,
    undo,
    pgn,
  }
}

export type Game = ReturnType<typeof useGame>
