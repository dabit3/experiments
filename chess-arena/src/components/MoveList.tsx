import { useEffect, useRef } from 'react'
import type { Move } from 'chess.js'

interface MoveListProps {
  history: Move[]
}

export function MoveList({ history }: MoveListProps) {
  const endRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    endRef.current?.scrollIntoView({ block: 'nearest', behavior: 'smooth' })
  }, [history.length])

  const rows: { n: number; white?: Move; black?: Move }[] = []
  for (let i = 0; i < history.length; i += 2) {
    rows.push({ n: i / 2 + 1, white: history[i], black: history[i + 1] })
  }

  return (
    <div className="move-list" aria-label="Move list" data-testid="move-list">
      {rows.length === 0 && <p className="move-list-empty">No moves yet — you are White. Make a move!</p>}
      {rows.map((row, idx) => {
        const last = idx === rows.length - 1
        return (
          <div className="move-row" key={row.n}>
            <span className="move-no">{row.n}.</span>
            <span className={`san${last && !row.black ? ' current' : ''}`}>{row.white?.san}</span>
            <span className={`san${last && row.black ? ' current' : ''}`}>{row.black?.san ?? ''}</span>
          </div>
        )
      })}
      <div ref={endRef} />
    </div>
  )
}
