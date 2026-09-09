import { useCallback, useEffect, useRef, useState, type KeyboardEvent, type MouseEvent } from 'react'
import { neighbors, type Board as BoardModel } from '../lib/board'
import type { Status } from '../hooks/useGame'
import { Cell } from './Cell'

interface Props {
  board: BoardModel
  status: Status
  exploded: number | null
  onReveal: (index: number) => void
  onChord: (index: number) => void
  onMark: (index: number) => void
  onPressChange: (pressed: boolean) => void
}

const LEFT = 1
const RIGHT = 2
const MIDDLE = 4

/**
 * Mouse protocol (mirrors classic Minesweeper):
 *  - left press+release on a hidden cell   -> reveal
 *  - right press                           -> cycle flag / question / clear
 *  - middle press+release, or left+right   -> chord on the cell under the cursor
 * Once a chord gesture starts, the pending left reveal is cancelled.
 */
export function Board({ board, status, exploded, onReveal, onChord, onMark, onPressChange }: Props) {
  const [pressedCells, setPressedCells] = useState<number[]>([])
  const gesture = useRef<{ chord: boolean; active: boolean }>({ chord: false, active: false })
  const gameOver = status === 'won' || status === 'lost'

  const clearPress = useCallback(() => {
    gesture.current = { chord: false, active: false }
    setPressedCells([])
    onPressChange(false)
  }, [onPressChange])

  useEffect(() => {
    const onUp = (e: globalThis.MouseEvent) => {
      if (e.buttons === 0) clearPress()
    }
    window.addEventListener('mouseup', onUp)
    window.addEventListener('blur', clearPress)
    return () => {
      window.removeEventListener('mouseup', onUp)
      window.removeEventListener('blur', clearPress)
    }
  }, [clearPress])

  const showPress = useCallback(
    (index: number, chordMode: boolean) => {
      const cell = board.cells[index]
      if (chordMode) {
        const targets = cell.revealed
          ? neighbors(board, index).filter((n) => !board.cells[n].revealed && board.cells[n].mark !== 'flag')
          : []
        setPressedCells(targets)
      } else {
        setPressedCells(!cell.revealed && cell.mark !== 'flag' ? [index] : [])
      }
    },
    [board],
  )

  const handleMouseDown = useCallback(
    (index: number, e: MouseEvent<HTMLButtonElement>) => {
      if (gameOver) return
      const buttons = e.buttons
      const chordMode = buttons === (LEFT | RIGHT) || (buttons & MIDDLE) !== 0
      if (chordMode) {
        gesture.current = { chord: true, active: true }
        onPressChange(true)
        showPress(index, true)
        return
      }
      if (e.button === 2) {
        if (!board.cells[index].revealed) onMark(index)
        gesture.current = { chord: false, active: true }
        return
      }
      if (e.button === 0) {
        gesture.current = { chord: false, active: true }
        onPressChange(true)
        showPress(index, false)
      }
    },
    [board, gameOver, onMark, onPressChange, showPress],
  )

  const handleMouseUp = useCallback(
    (index: number, e: MouseEvent<HTMLButtonElement>) => {
      if (gameOver || !gesture.current.active) return
      const wasChord = gesture.current.chord
      if (wasChord) {
        if (e.button === 0 || e.button === 1 || e.button === 2) onChord(index)
        // Left+right chord: consume the whole gesture so the trailing release does nothing.
        gesture.current = { chord: true, active: false }
        setPressedCells([])
        return
      }
      if (e.button === 0) {
        onReveal(index)
        gesture.current = { chord: false, active: false }
        setPressedCells([])
      }
    },
    [gameOver, onChord, onReveal],
  )

  const handleMouseEnter = useCallback(
    (index: number, e: MouseEvent<HTMLButtonElement>) => {
      if (gameOver || !gesture.current.active) return
      if (e.buttons === 0) return
      showPress(index, gesture.current.chord)
    },
    [gameOver, showPress],
  )

  const handleKeyDown = useCallback(
    (index: number, e: KeyboardEvent<HTMLButtonElement>) => {
      if (gameOver) return
      const key = e.key.toLowerCase()
      if (key === 'enter' || key === ' ') {
        e.preventDefault()
        if (board.cells[index].revealed) onChord(index)
        else onReveal(index)
      } else if (key === 'f') {
        e.preventDefault()
        onMark(index)
      }
    },
    [board, gameOver, onChord, onMark, onReveal],
  )

  const pressedSet = new Set(pressedCells)

  return (
    <div
      className={`board status-${status}`}
      role="grid"
      aria-label={`${board.rows} by ${board.cols} minefield`}
      style={{ gridTemplateColumns: `repeat(${board.cols}, var(--cell))` }}
      onContextMenu={(e) => e.preventDefault()}
    >
      {board.cells.map((cell, i) => (
        <Cell
          key={i}
          index={i}
          cell={cell}
          status={status}
          exploded={exploded === i}
          pressed={pressedSet.has(i)}
          onMouseDown={handleMouseDown}
          onMouseUp={handleMouseUp}
          onMouseEnter={handleMouseEnter}
          onKeyDown={handleKeyDown}
        />
      ))}
    </div>
  )
}
