import type { GameResult } from './useGame'

export function describeResult(result: GameResult): { title: string; subtitle: string; tone: string } {
  switch (result.kind) {
    case 'checkmate':
      return result.winner === 'w'
        ? { title: 'Checkmate!', subtitle: 'White wins — the engine has been mated.', tone: 'win' }
        : { title: 'Checkmate', subtitle: 'Black wins — the engine got you this time.', tone: 'loss' }
    case 'stalemate':
      return { title: 'Stalemate', subtitle: 'No legal moves and no check — it is a draw.', tone: 'draw' }
    case 'draw':
      return { title: 'Draw', subtitle: `Game drawn by ${result.reason}.`, tone: 'draw' }
  }
}
