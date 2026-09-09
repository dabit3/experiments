import type { CSSProperties, PointerEvent as ReactPointerEvent, Ref } from 'react'
import type { Heatmap } from '../game/heatmap'
import {
  BOARD_SIZE,
  cellsOf,
  coordLabel,
  key,
  type Coord,
  type PlacedShip,
  type Shot,
} from '../game/types'
import './Board.css'

export interface Preview {
  cells: Coord[]
  valid: boolean
}

interface BoardProps {
  title: string
  subtitle?: string
  ships?: readonly PlacedShip[]
  shots: ReadonlyMap<string, Shot>
  heatmap?: Heatmap | null
  preview?: Preview | null
  interactive?: boolean
  onFire?: (coord: Coord) => void
  onShipPointerDown?: (ship: PlacedShip, segment: number, e: ReactPointerEvent) => void
  lastShot?: Coord | null
  boardRef?: Ref<HTMLDivElement>
  dimmed?: boolean
  badge?: string
  tone?: 'own' | 'enemy'
}

interface SegmentInfo {
  ship: PlacedShip
  index: number
}

export function Board({
  title,
  subtitle,
  ships = [],
  shots,
  heatmap,
  preview,
  interactive = false,
  onFire,
  onShipPointerDown,
  lastShot,
  boardRef,
  dimmed = false,
  badge,
  tone = 'own',
}: BoardProps) {
  const segments = new Map<string, SegmentInfo>()
  for (const ship of ships) {
    cellsOf(ship).forEach((c, index) => segments.set(key(c), { ship, index }))
  }

  const sunkIds = new Set<string>()
  for (const s of shots.values()) if (s.result === 'sunk' && s.shipId) sunkIds.add(s.shipId)

  const previewMap = new Map<string, boolean>()
  if (preview) for (const c of preview.cells) previewMap.set(key(c), preview.valid)

  const lastKey = lastShot ? key(lastShot) : null
  const bestKey = heatmap?.best ? key(heatmap.best) : null

  const cells = []
  for (let r = 0; r < BOARD_SIZE; r++) {
    for (let c = 0; c < BOARD_SIZE; c++) {
      const coord = { r, c }
      const k = key(coord)
      const seg = segments.get(k)
      const shot = shots.get(k)
      const isSunk = shot?.shipId !== undefined && sunkIds.has(shot.shipId)
      const classes = ['cell']
      if (seg) {
        classes.push('cell--ship', `cell--ship-${seg.ship.orientation}`)
        if (seg.index === 0) classes.push('cell--bow')
        if (seg.index === seg.ship.size - 1) classes.push('cell--stern')
        if (sunkIds.has(seg.ship.id)) classes.push('cell--wreck')
      }
      if (shot) {
        classes.push(`cell--${shot.result}`)
        if (isSunk) classes.push('cell--sunk')
      }
      if (previewMap.has(k)) classes.push(previewMap.get(k) ? 'cell--ok' : 'cell--bad')
      if (lastKey === k) classes.push('cell--last')
      if (bestKey === k && !shot) classes.push('cell--best')

      let ratio: number | undefined
      let heat: number | undefined
      if (heatmap && !shot && heatmap.max > 0) {
        ratio = heatmap.weights[r][c] / heatmap.max
        heat = ratio ** 2
      }
      const pct =
        heatmap && !shot && heatmap.total > 0
          ? Math.round((heatmap.weights[r][c] / heatmap.total) * 100)
          : 0

      const label = coordLabel(coord)
      const common = {
        className: classes.join(' '),
        'data-cell': '',
        'data-r': r,
        'data-c': c,
        style: heat !== undefined ? ({ '--heat': heat } as CSSProperties) : undefined,
      }

      if (interactive) {
        cells.push(
          <button
            key={k}
            {...common}
            type="button"
            aria-label={`${label}${shot ? ` (${shot.result})` : ''}`}
            title={heatmap && !shot ? `${label} · ${pct}%` : label}
            disabled={shot !== undefined}
            onClick={() => onFire?.(coord)}
          >
            {ratio !== undefined && ratio >= 0.4 && pct > 0 ? (
              <span className="cell__pct">{pct}</span>
            ) : null}
            <span className="cell__mark" />
          </button>,
        )
      } else {
        cells.push(
          <div
            key={k}
            {...common}
            role="presentation"
            title={label}
            onPointerDown={
              seg && onShipPointerDown ? (e) => onShipPointerDown(seg.ship, seg.index, e) : undefined
            }
          >
            <span className="cell__mark" />
          </div>,
        )
      }
    }
  }

  return (
    <section className={`board board--${tone}${dimmed ? ' board--dimmed' : ''}`} aria-label={title}>
      <header className="board__header">
        <div className="board__heading">
          <h2 className="board__title">{title}</h2>
          {subtitle ? <p className="board__subtitle">{subtitle}</p> : null}
        </div>
        {badge ? <span className="board__badge">{badge}</span> : null}
      </header>
      <div className="board__frame">
        <span className="board__rivet board__rivet--tl" aria-hidden="true" />
        <span className="board__rivet board__rivet--tr" aria-hidden="true" />
        <span className="board__rivet board__rivet--bl" aria-hidden="true" />
        <span className="board__rivet board__rivet--br" aria-hidden="true" />
        <div className="board__corner" />
        <div className="board__cols">
          {Array.from({ length: BOARD_SIZE }, (_, i) => (
            <span key={i}>{i + 1}</span>
          ))}
        </div>
        <div className="board__rows">
          {Array.from({ length: BOARD_SIZE }, (_, i) => (
            <span key={i}>{String.fromCharCode(65 + i)}</span>
          ))}
        </div>
        <div
          className={`board__grid${interactive ? ' board__grid--live' : ''}${heatmap ? ' board__grid--heat' : ''}`}
          ref={boardRef}
        >
          {cells}
        </div>
      </div>
    </section>
  )
}
