import type { Color, PieceSymbol } from 'chess.js'
import { COLOR_NAME, PIECE_NAME, pieceImage } from '../lib/pieces'

interface CapturedPiecesProps {
  /** Colour of the side that did the capturing. */
  by: Color
  pieces: PieceSymbol[]
  /** Material advantage of `by` (only shown when positive). */
  advantage: number
}

export function CapturedPieces({ by, pieces, advantage }: CapturedPiecesProps) {
  const victimColor: Color = by === 'w' ? 'b' : 'w'
  return (
    <div className="captured" aria-label={`Pieces captured by ${COLOR_NAME[by]}`}>
      <span className="captured-label">{COLOR_NAME[by]} took</span>
      <div className="captured-row">
        {pieces.length === 0 && <span className="captured-none">nothing yet</span>}
        {pieces.map((p, i) => (
          <img
            key={`${p}-${i}`}
            className="captured-piece"
            src={pieceImage(victimColor, p)}
            alt={`${COLOR_NAME[victimColor]} ${PIECE_NAME[p]}`}
          />
        ))}
        {advantage > 0 && <span className="advantage">+{advantage}</span>}
      </div>
    </div>
  )
}
