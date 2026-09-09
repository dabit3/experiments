import type { Color, PieceSymbol, Square } from 'chess.js'
import { PIECE_NAME, pieceImage } from '../lib/pieces'

const CHOICES: PieceSymbol[] = ['q', 'r', 'b', 'n']

interface PromotionPickerProps {
  color: Color
  to: Square
  onPick: (piece: PieceSymbol) => void
  onCancel: () => void
}

export function PromotionPicker({ color, to, onPick, onCancel }: PromotionPickerProps) {
  return (
    <div className="overlay" role="dialog" aria-modal="true" aria-label="Choose promotion piece">
      <div className="promotion-card">
        <h2>Promote on {to}</h2>
        <p>Pick the piece your pawn becomes.</p>
        <div className="promotion-choices">
          {CHOICES.map((p) => (
            <button
              key={p}
              type="button"
              className="promotion-choice"
              onClick={() => onPick(p)}
              data-testid={`promote-${p}`}
            >
              <img src={pieceImage(color, p)} alt="" />
              <span>{PIECE_NAME[p]}</span>
            </button>
          ))}
        </div>
        <button type="button" className="btn ghost" onClick={onCancel}>
          Cancel
        </button>
      </div>
    </div>
  )
}
