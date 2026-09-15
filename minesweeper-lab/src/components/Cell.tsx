import type { KeyboardEvent, MouseEvent, ReactNode } from 'react'
import type { Cell as CellModel } from '../lib/board'
import type { Status } from '../hooks/useGame'

interface Props {
  index: number
  cell: CellModel
  status: Status
  exploded: boolean
  pressed: boolean
  onMouseDown: (index: number, e: MouseEvent<HTMLButtonElement>) => void
  onMouseUp: (index: number, e: MouseEvent<HTMLButtonElement>) => void
  onMouseEnter: (index: number, e: MouseEvent<HTMLButtonElement>) => void
  onKeyDown: (index: number, e: KeyboardEvent<HTMLButtonElement>) => void
}

function label(cell: CellModel, gameOver: boolean, exploded: boolean): string {
  if (cell.revealed) {
    if (cell.mine) return exploded ? 'exploded mine' : 'mine'
    return cell.adjacent === 0 ? 'empty' : `${cell.adjacent}`
  }
  if (cell.mark === 'flag') return gameOver && !cell.mine ? 'wrong flag' : 'flag'
  if (cell.mark === 'question') return 'question mark'
  return 'hidden'
}

function FlagIcon() {
  return (
    <svg className="glyph flag-glyph" viewBox="0 0 24 24" aria-hidden="true">
      <path d="M7 3v18" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" />
      <path d="M8 4h9.5l-2.6 4 2.6 4H8z" fill="var(--flag)" />
      <path d="M4.5 21h6" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" />
    </svg>
  )
}

function MineIcon() {
  return (
    <svg className="glyph mine-glyph" viewBox="0 0 24 24" aria-hidden="true">
      <circle cx="12" cy="13" r="6.5" fill="currentColor" />
      <path
        d="M12 3.5v4M12 18.5v3M3.5 13h3M17.5 13h3M6 7l2.2 2.2M18 7l-2.2 2.2M6 19l2.2-2.2M18 19l-2.2-2.2"
        stroke="currentColor"
        strokeWidth="2.2"
        strokeLinecap="round"
      />
      <circle cx="9.6" cy="10.6" r="1.6" fill="#fff" opacity="0.85" />
    </svg>
  )
}

export function Cell({ index, cell, status, exploded, pressed, onMouseDown, onMouseUp, onMouseEnter, onKeyDown }: Props) {
  const gameOver = status === 'won' || status === 'lost'
  const wrongFlag = gameOver && cell.mark === 'flag' && !cell.mine

  const classes = ['cell']
  if (cell.revealed) {
    classes.push('is-revealed')
    if (cell.mine) classes.push('is-mine')
    if (exploded) classes.push('is-exploded')
    if (!cell.mine && cell.adjacent > 0) classes.push(`n${cell.adjacent}`)
  } else {
    classes.push('is-hidden')
    if (pressed) classes.push('is-pressed')
    if (cell.mark === 'flag') classes.push('is-flag')
    if (cell.mark === 'question') classes.push('is-question')
    if (wrongFlag) classes.push('is-wrong')
  }

  let content: ReactNode = null
  if (cell.revealed) {
    if (cell.mine) content = <MineIcon />
    else if (cell.adjacent > 0) content = <span className="digit">{cell.adjacent}</span>
  } else if (cell.mark === 'flag') {
    content = <FlagIcon />
  } else if (cell.mark === 'question') {
    content = <span className="glyph question-glyph" aria-hidden="true">?</span>
  }

  return (
    <button
      type="button"
      className={classes.join(' ')}
      data-index={index}
      aria-label={label(cell, gameOver, exploded)}
      onMouseDown={(e) => onMouseDown(index, e)}
      onMouseUp={(e) => onMouseUp(index, e)}
      onMouseEnter={(e) => onMouseEnter(index, e)}
      onKeyDown={(e) => onKeyDown(index, e)}
      onContextMenu={(e) => e.preventDefault()}
      onAuxClick={(e) => e.preventDefault()}
    >
      {content}
      {wrongFlag && <span className="wrong-x" aria-hidden="true" />}
    </button>
  )
}
