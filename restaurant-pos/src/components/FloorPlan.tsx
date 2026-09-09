import { useCallback, useEffect, useRef, useState, type PointerEvent as ReactPointerEvent } from 'react'
import { FLOOR_H, FLOOR_W } from '../data/seed'
import { checkTotals } from '../lib/calc'
import { fmt } from '../lib/money'
import { fmtTime } from '../lib/time'
import type { Check, Table } from '../types'
import './FloorPlan.css'

interface Props {
  tables: Table[]
  checks: Record<string, Check>
  editLayout: boolean
  onOpenTable: (tableId: string) => void
  onMoveTable: (tableId: string, x: number, y: number) => void
}

interface Drag {
  tableId: string
  startX: number
  startY: number
  originX: number
  originY: number
  x: number
  y: number
  moved: boolean
}

const GRID = 10

function snap(v: number): number {
  return Math.round(v / GRID) * GRID
}

export function FloorPlan({ tables, checks, editLayout, onOpenTable, onMoveTable }: Props) {
  const wrapRef = useRef<HTMLDivElement>(null)
  const [scale, setScale] = useState(1)
  const [drag, setDrag] = useState<Drag | null>(null)

  useEffect(() => {
    const el = wrapRef.current
    if (!el) return
    const update = () => {
      const { width, height } = el.getBoundingClientRect()
      setScale(Math.min(width / FLOOR_W, height / FLOOR_H, 1.4))
    }
    update()
    const ro = new ResizeObserver(update)
    ro.observe(el)
    return () => ro.disconnect()
  }, [])

  const onPointerDown = useCallback(
    (e: ReactPointerEvent<HTMLButtonElement>, table: Table) => {
      if (!editLayout) return
      e.currentTarget.setPointerCapture(e.pointerId)
      setDrag({
        tableId: table.id,
        startX: e.clientX,
        startY: e.clientY,
        originX: table.x,
        originY: table.y,
        x: table.x,
        y: table.y,
        moved: false,
      })
    },
    [editLayout],
  )

  const onPointerMove = useCallback(
    (e: ReactPointerEvent<HTMLButtonElement>, table: Table) => {
      if (!drag || drag.tableId !== table.id) return
      const dx = (e.clientX - drag.startX) / scale
      const dy = (e.clientY - drag.startY) / scale
      const x = Math.max(0, Math.min(FLOOR_W - table.w, drag.originX + dx))
      const y = Math.max(0, Math.min(FLOOR_H - table.h, drag.originY + dy))
      setDrag({ ...drag, x, y, moved: drag.moved || Math.abs(dx) + Math.abs(dy) > 2 })
    },
    [drag, scale],
  )

  const onPointerUp = useCallback(
    (table: Table) => {
      if (!drag || drag.tableId !== table.id) return
      if (drag.moved) onMoveTable(table.id, snap(drag.x), snap(drag.y))
      setDrag(null)
    },
    [drag, onMoveTable],
  )

  const seated = tables.filter((t) => t.checkId).length

  return (
    <div className="floor-page">
      <div className="floor-header">
        <div>
          <h1>Floor plan</h1>
          <p className="muted">
            {seated} of {tables.length} tables seated ·{' '}
            {editLayout ? 'Drag tables to rearrange the room, then press Done editing.' : 'Tap a table to seat guests or open its check.'}
          </p>
        </div>
        <div className="legend">
          <span>
            <i className="dot dot-open" /> Open
          </span>
          <span>
            <i className="dot dot-seated" /> Seated
          </span>
          <span>
            <i className="dot dot-paying" /> Paying
          </span>
        </div>
      </div>

      <div className={`floor-wrap ${editLayout ? 'editing' : ''}`} ref={wrapRef}>
        <div
          className="floor"
          style={{ width: FLOOR_W, height: FLOOR_H, transform: `scale(${scale})` }}
          aria-label="Restaurant floor plan"
        >
          <div className="zone zone-kitchen">Kitchen pass</div>
          <div className="zone zone-bar">Bar</div>
          <div className="zone zone-entrance">Entrance</div>

          {tables.map((table) => {
            const check = table.checkId ? checks[table.checkId] : undefined
            const isDragging = drag?.tableId === table.id
            const x = isDragging ? drag.x : table.x
            const y = isDragging ? drag.y : table.y
            const totals = check ? checkTotals(check) : null
            const paying = check ? check.payments.length > 0 || check.splitMode !== 'none' : false
            const status = check ? (paying ? 'paying' : 'seated') : 'open'
            return (
              <button
                type="button"
                key={table.id}
                className={`table table-${table.shape} status-${status} ${isDragging ? 'dragging' : ''}`}
                style={{ left: x, top: y, width: table.w, height: table.h }}
                onPointerDown={(e) => onPointerDown(e, table)}
                onPointerMove={(e) => onPointerMove(e, table)}
                onPointerUp={() => onPointerUp(table)}
                onPointerCancel={() => setDrag(null)}
                onClick={() => {
                  if (!editLayout) onOpenTable(table.id)
                }}
                aria-label={`Table ${table.number}, ${check ? `party of ${check.partySize}` : 'open'}`}
              >
                <span className="table-number">{table.number}</span>
                <span className="table-caption">
                  {check ? (
                    <>
                      <span className="table-party">
                        {check.partySize} guests · {fmtTime(check.openedAt)}
                      </span>
                      <span className="table-total">{fmt(totals!.total)}</span>
                    </>
                  ) : (
                    <span className="table-party">{table.capacity} seats</span>
                  )}
                </span>
                {check && (
                  <span className="table-seats" aria-hidden="true">
                    {Array.from({ length: Math.min(check.partySize, 8) }, (_, i) => (
                      <i key={i} />
                    ))}
                  </span>
                )}
              </button>
            )
          })}
        </div>
      </div>
    </div>
  )
}
