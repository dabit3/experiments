import type { Color, PieceSymbol } from 'chess.js'
import wK from '../assets/pieces/klt.svg'
import wQ from '../assets/pieces/qlt.svg'
import wR from '../assets/pieces/rlt.svg'
import wB from '../assets/pieces/blt.svg'
import wN from '../assets/pieces/nlt.svg'
import wP from '../assets/pieces/plt.svg'
import bK from '../assets/pieces/kdt.svg'
import bQ from '../assets/pieces/qdt.svg'
import bR from '../assets/pieces/rdt.svg'
import bB from '../assets/pieces/bdt.svg'
import bN from '../assets/pieces/ndt.svg'
import bP from '../assets/pieces/pdt.svg'

const IMAGES: Record<Color, Record<PieceSymbol, string>> = {
  w: { k: wK, q: wQ, r: wR, b: wB, n: wN, p: wP },
  b: { k: bK, q: bQ, r: bR, b: bB, n: bN, p: bP },
}

export function pieceImage(color: Color, type: PieceSymbol): string {
  return IMAGES[color][type]
}

export const PIECE_NAME: Record<PieceSymbol, string> = {
  k: 'king',
  q: 'queen',
  r: 'rook',
  b: 'bishop',
  n: 'knight',
  p: 'pawn',
}

export const COLOR_NAME: Record<Color, string> = { w: 'White', b: 'Black' }
