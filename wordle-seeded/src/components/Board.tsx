import type { TileState } from '../lib/evaluate'
import { MAX_GUESSES, WORD_LENGTH } from '../lib/words'
import { FLIP_STAGGER_MS } from '../hooks/useGame'
import './Board.css'

interface BoardProps {
  guesses: string[]
  evaluations: TileState[][]
  current: string
  shakeKey: number
  won: boolean
}

export function Board({ guesses, evaluations, current, shakeKey, won }: BoardProps) {
  const activeRow = guesses.length
  const rows = Array.from({ length: MAX_GUESSES }, (_, r) => r)

  return (
    <div className="board" role="grid" aria-label="Guess grid">
      {rows.map((r) => {
        const isActive = r === activeRow
        const isSubmitted = r < guesses.length
        const word = isSubmitted ? guesses[r] : isActive ? current : ''
        const evaluation = evaluations[r]
        const isWinRow = won && r === guesses.length - 1
        const className = ['row', isActive && shakeKey > 0 ? 'row--shake' : '', isWinRow ? 'row--win' : '']
          .filter(Boolean)
          .join(' ')

        return (
          <div className={className} key={isActive ? `${r}-${shakeKey}` : r} role="row">
            {Array.from({ length: WORD_LENGTH }, (_, c) => {
              const letter = word[c] ?? ''
              const state = evaluation?.[c]
              const tileClass = [
                'tile',
                letter && !state ? 'tile--filled' : '',
                state ? `tile--reveal tile--${state}` : '',
              ]
                .filter(Boolean)
                .join(' ')
              return (
                <div
                  className={tileClass}
                  key={c}
                  role="gridcell"
                  aria-label={letter ? `${letter.toUpperCase()}${state ? ` ${state}` : ''}` : 'empty'}
                >
                  <div
                    className="tile__flip"
                    style={{ animationDelay: state ? `${c * FLIP_STAGGER_MS}ms` : undefined }}
                  >
                    <span className="tile__inner tile__front">{letter}</span>
                    <span className="tile__inner tile__back">{letter}</span>
                  </div>
                </div>
              )
            })}
          </div>
        )
      })}
    </div>
  )
}
