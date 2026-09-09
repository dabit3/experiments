import { useCallback, useRef, useState, type PointerEvent as ReactPointerEvent } from 'react'
import type { Color, Move, PieceSymbol, Square } from 'chess.js'
import type { TrackedPiece } from '../lib/useGame'
import { COLOR_NAME, PIECE_NAME, pieceImage } from '../lib/pieces'
import './Board.css'

const FILES = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'] as const
const DRAG_THRESHOLD_PX = 5

interface BoardProps {
  pieces: TrackedPiece[]
  turn: Color
  flipped: boolean
  interactive: boolean
  lastMove: Move | null
  checkSquare: Square | null
  legalMovesFrom: (square: Square) => Move[]
  onMove: (from: Square, to: Square) => boolean
}

interface Drag {
  from: Square
  pointerId: number
  rect: DOMRect
  startX: number
  startY: number
  x: number
  y: number
  active: boolean
  wasSelected: boolean
}

/** 0-based column/row of a square on the *rendered* board (respects flip). */
function squareToGrid(square: Square, flipped: boolean): { col: number; row: number } {
  const file = FILES.indexOf(square[0] as (typeof FILES)[number])
  const rank = Number(square[1]) - 1
  return flipped ? { col: 7 - file, row: rank } : { col: file, row: 7 - rank }
}

function gridToSquare(col: number, row: number, flipped: boolean): Square {
  const file = flipped ? 7 - col : col
  const rank = flipped ? row + 1 : 8 - row
  return `${FILES[file]}${rank}` as Square
}

export function Board({
  pieces,
  turn,
  flipped,
  interactive,
  lastMove,
  checkSquare,
  legalMovesFrom,
  onMove,
}: BoardProps) {
  const boardRef = useRef<HTMLDivElement>(null)
  const [selectedSquare, setSelected] = useState<Square | null>(null)
  const [drag, setDrag] = useState<Drag | null>(null)

  const pieceAt = useCallback(
    (square: Square) => pieces.find((p) => p.square === square) ?? null,
    [pieces],
  )

  // A selection is only meaningful while it points at a piece the player may move.
  const selected =
    interactive && selectedSquare && pieceAt(selectedSquare)?.color === turn ? selectedSquare : null

  const squareFromPoint = useCallback(
    (clientX: number, clientY: number): Square | null => {
      const el = boardRef.current
      if (!el) return null
      const rect = el.getBoundingClientRect()
      const col = Math.floor(((clientX - rect.left) / rect.width) * 8)
      const row = Math.floor(((clientY - rect.top) / rect.height) * 8)
      if (col < 0 || col > 7 || row < 0 || row > 7) return null
      return gridToSquare(col, row, flipped)
    },
    [flipped],
  )

  const legalTargets = selected ? legalMovesFrom(selected) : []
  const targetSquares = new Set(legalTargets.map((m) => m.to))

  const handlePointerDown = (e: ReactPointerEvent<HTMLDivElement>) => {
    if (!interactive || e.button !== 0) return
    const square = squareFromPoint(e.clientX, e.clientY)
    if (!square) return
    const piece = pieceAt(square)

    if (selected && targetSquares.has(square)) {
      onMove(selected, square)
      setSelected(null)
      return
    }

    if (piece && piece.color === turn) {
      const board = e.currentTarget
      board.setPointerCapture(e.pointerId)
      setDrag({
        from: square,
        pointerId: e.pointerId,
        rect: board.getBoundingClientRect(),
        startX: e.clientX,
        startY: e.clientY,
        x: e.clientX,
        y: e.clientY,
        active: false,
        wasSelected: selected === square,
      })
      setSelected(square)
      return
    }

    setSelected(null)
  }

  const handlePointerMove = (e: ReactPointerEvent<HTMLDivElement>) => {
    if (!drag || e.pointerId !== drag.pointerId) return
    const dx = e.clientX - drag.startX
    const dy = e.clientY - drag.startY
    const active = drag.active || Math.hypot(dx, dy) > DRAG_THRESHOLD_PX
    setDrag({ ...drag, x: e.clientX, y: e.clientY, active })
  }

  const handlePointerUp = (e: ReactPointerEvent<HTMLDivElement>) => {
    if (!drag || e.pointerId !== drag.pointerId) return
    e.currentTarget.releasePointerCapture(e.pointerId)
    const dropSquare = squareFromPoint(e.clientX, e.clientY)
    setDrag(null)

    if (dropSquare && dropSquare !== drag.from) {
      // A real drag (or a press/release across squares): drop the piece.
      const ok = onMove(drag.from, dropSquare)
      if (ok || !pieceAt(dropSquare) || pieceAt(dropSquare)?.color !== turn) setSelected(null)
      else setSelected(dropSquare)
      return
    }

    if (!drag.active && drag.wasSelected) setSelected(null)
  }

  const handlePointerCancel = () => setDrag(null)

  const dragStyle = drag?.active
    ? {
        transform: `translate(${drag.x - drag.rect.left - drag.rect.width / 16}px, ${
          drag.y - drag.rect.top - drag.rect.height / 16
        }px)`,
      }
    : null

  const squares: Square[] = []
  for (let row = 0; row < 8; row++) {
    for (let col = 0; col < 8; col++) squares.push(gridToSquare(col, row, flipped))
  }

  return (
    <div className={`board-frame${flipped ? ' flipped' : ''}`}>
      <div className="ranks" aria-hidden="true">
        {Array.from({ length: 8 }, (_, i) => (
          <span key={i}>{flipped ? i + 1 : 8 - i}</span>
        ))}
      </div>
      <div
        ref={boardRef}
        className={`board${interactive ? ' interactive' : ''}${drag?.active ? ' dragging' : ''}`}
        role="grid"
        aria-label="Chess board"
        onPointerDown={handlePointerDown}
        onPointerMove={handlePointerMove}
        onPointerUp={handlePointerUp}
        onPointerCancel={handlePointerCancel}
      >
        {squares.map((sq) => {
          const { col, row } = squareToGrid(sq, flipped)
          const light = (col + row) % 2 === 0
          const occupant = pieceAt(sq)
          const isTarget = targetSquares.has(sq)
          const isCapture = isTarget && occupant !== null
          const classes = ['square', light ? 'light' : 'dark']
          if (interactive && occupant?.color === turn) classes.push('grabbable')
          if (selected === sq) classes.push('selected')
          if (lastMove && (lastMove.from === sq || lastMove.to === sq)) classes.push('last-move')
          if (checkSquare === sq) classes.push('in-check')
          if (isTarget) classes.push(isCapture ? 'target-capture' : 'target')
          return (
            <div
              key={sq}
              className={classes.join(' ')}
              data-square={sq}
              role="gridcell"
              aria-label={sq}
            >
              {isTarget && <span className="hint" />}
            </div>
          )
        })}

        {pieces.map((p) => {
          const { col, row } = squareToGrid(p.square, flipped)
          const isDragged = drag?.active && drag.from === p.square
          const style =
            isDragged && dragStyle
              ? dragStyle
              : { transform: `translate(${col * 100}%, ${row * 100}%)` }
          return (
            <img
              key={p.id}
              src={pieceImage(p.color, p.type)}
              alt={`${COLOR_NAME[p.color]} ${PIECE_NAME[p.type as PieceSymbol]} on ${p.square}`}
              className={`piece${isDragged ? ' dragged' : ''}`}
              data-piece={`${p.color}${p.type}`}
              data-square={p.square}
              style={style}
              draggable={false}
            />
          )
        })}
      </div>
      <div className="files" aria-hidden="true">
        {FILES.map((f, i) => (
          <span key={f}>{flipped ? FILES[7 - i] : f}</span>
        ))}
      </div>
    </div>
  )
}
