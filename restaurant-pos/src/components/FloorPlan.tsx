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
      setScale(Math.min((width - 52) / FLOOR_W, (height - 40) / FLOOR_H, 1.4))
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

  const openChecks = tables.flatMap((t) => (t.checkId && checks[t.checkId] ? [checks[t.checkId]] : []))
  const seated = openChecks.length
  const guests = openChecks.reduce((s, c) => s + c.partySize, 0)
  const openSales = openChecks.reduce((s, c) => s + checkTotals(c).total, 0)
  const paying = openChecks.filter((c) => c.payments.length > 0 || c.splitMode !== 'none').length
  const occupancy = Math.round((seated / tables.length) * 100)

  return (
    <div className="floor-page">
      <div className="floor-header">
        <div className="floor-heading">
          <span className="eyebrow">Ember · Service overview</span>
          <h1>The dining room</h1>
          <p className="muted">
            {editLayout
              ? 'Drag tables to rearrange the room, then press Done editing.'
              : 'Select a table to seat guests or open its check.'}
          </p>
        </div>
        <div className="service-session">
          <span className="service-live">
            <i className="dot dot-seated" /> Dinner service
          </span>
          <span className="muted">Thoughtful service. Every table.</span>
        </div>
      </div>
      <div className="kpis" aria-label="Service summary">
        <div className="kpi">
          <span className="kpi-label">Occupied tables</span>
          <span className="kpi-value">
            {seated}
            <small>/ {tables.length}</small>
          </span>
          <span className="kpi-detail">{tables.length - seated} tables available</span>
        </div>
        <div className="kpi">
          <span className="kpi-label">Guests in the room</span>
          <span className="kpi-value">{guests}</span>
          <span className="kpi-detail">Across {seated} seated parties</span>
        </div>
        <div className="kpi">
          <span className="kpi-label">Open checks</span>
          <span className="kpi-value num">{fmt(openSales)}</span>
          <span className="kpi-detail">Including tax &amp; gratuity</span>
        </div>
        <div className="kpi">
          <span className="kpi-label">Ready for settlement</span>
          <span className="kpi-value">{paying.toString().padStart(2, '0')}</span>
          <span className="kpi-detail">Tables splitting or paying</span>
        </div>
      </div>

      <div className="floor-workspace">
        <section className="floor-board" aria-label="Dining room layout">
          <div className="room-toolbar">
            <div>
              <span className="room-active-dot" />
              <strong>Main dining room</strong>
              <span className="room-count">{tables.length} tables</span>
            </div>
            <span className="eyebrow">{editLayout ? 'Editing layout' : 'Floor plan'}</span>
          </div>
          <div className={`floor-wrap ${editLayout ? 'editing' : ''}`} ref={wrapRef}>
            <div
              className="floor"
              style={{ width: FLOOR_W, height: FLOOR_H, transform: `scale(${scale})` }}
              aria-label="Restaurant floor plan"
            >
              <div className="zone zone-kitchen">Kitchen pass</div>
              <div className="zone zone-bar">
                <span>Bar</span>
              </div>
              <div className="zone zone-entrance">Entrance</div>
              <div className="room-window window-one" aria-hidden="true" />
              <div className="room-window window-two" aria-hidden="true" />

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
                    {Array.from({ length: table.capacity }, (_, i) => {
                      const angle = (i / table.capacity) * Math.PI * 2
                      const round = table.shape === 'round'
                      const perSide = Math.ceil(table.capacity / 2)
                      const vertical = table.h > table.w
                      const position = ((i % perSide) + 1) / (perSide + 1)
                      return (
                        <i
                          className="table-chair"
                          aria-hidden="true"
                          key={i}
                          style={
                            round
                              ? {
                                  left: table.w / 2 + Math.cos(angle) * (table.w / 2 + 6),
                                  top: table.h / 2 + Math.sin(angle) * (table.h / 2 + 6),
                                  transform: `translate(-50%, -50%) rotate(${angle + Math.PI / 2}rad)`,
                                }
                              : {
                                  left: vertical ? (i < perSide ? -6 : table.w + 6) : table.w * position,
                                  top: vertical ? table.h * position : i < perSide ? -6 : table.h + 6,
                                  transform: `translate(-50%, -50%) rotate(${vertical ? 90 : 0}deg)`,
                                }
                          }
                        />
                      )
                    })}
                    <span className="table-label">Table</span>
                    <span className="table-number">{table.number.toString().padStart(2, '0')}</span>
                    <span className="table-caption">
                      {check ? (
                        <>
                          <span className="table-party">{check.partySize} guests</span>
                          <span className="table-total num">{fmt(totals!.total)}</span>
                        </>
                      ) : (
                        <span className="table-party">{table.capacity} seats</span>
                      )}
                    </span>
                  </button>
                )
              })}
            </div>
          </div>
          <footer className="room-footer">
            <div className="legend">
              <span>
                <i className="dot dot-open" /> Available
              </span>
              <span>
                <i className="dot dot-seated" /> Seated
              </span>
              <span>
                <i className="dot dot-paying" /> Paying
              </span>
            </div>
            <span>
              Click a table to begin service <span aria-hidden="true">↗</span>
            </span>
          </footer>
        </section>
        <aside className="service-sidebar">
          <div className="service-sidebar-heading">
            <span className="eyebrow">At a glance</span>
            <h2>On the floor</h2>
            <span className="sidebar-count">{seated} active tables</span>
          </div>
          <div className="service-checks">
            {tables
              .filter((table) => table.checkId && checks[table.checkId])
              .map((table) => {
                const check = checks[table.checkId!]
                const isPaying = check.splitMode !== 'none' || check.payments.length > 0
                const pending = check.lines.filter((line) => line.status === 'pending').length
                return (
                  <button
                    type="button"
                    key={table.id}
                    className="service-check"
                    disabled={editLayout}
                    onClick={() => onOpenTable(table.id)}
                  >
                    <span className="service-table-number">{table.number.toString().padStart(2, '0')}</span>
                    <span className="service-check-main">
                      <strong>Table {table.number}</strong>
                      <small>
                        {check.partySize} guests · {fmtTime(check.openedAt)}
                      </small>
                      <span className={`service-check-state ${isPaying ? 'settling' : ''}`}>
                        <i className={`dot ${isPaying ? 'dot-paying' : 'dot-seated'}`} />
                        {isPaying ? 'Settling check' : pending > 0 ? `${pending} items to fire` : 'In service'}
                      </span>
                    </span>
                    <span className="service-check-total">
                      {fmt(checkTotals(check).total)}
                      <span aria-hidden="true">↗</span>
                    </span>
                  </button>
                )
              })}
            {seated === 0 && (
              <p className="muted">The room is ready. Select an available table to welcome your first guests.</p>
            )}
          </div>
          <div className="room-occupancy">
            <div>
              <span>Room occupancy</span>
              <strong>{occupancy}%</strong>
            </div>
            <progress value={seated} max={tables.length} aria-label="Room occupancy" />
            <span>
              {seated} of {tables.length} tables seated
            </span>
          </div>
          <div className="service-note">
            <span className="eyebrow">The service standard</span>
            <h3>
              A little care.
              <br />
              An exceptional evening.
            </h3>
            <p>Keep preferences close, fire each course with intention, and settle every check with confidence.</p>
            <span className="service-note-rule" />
            <small>18% gratuity for parties of six or more</small>
          </div>
        </aside>
      </div>
    </div>
  )
}
