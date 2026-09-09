import { useEffect, useRef } from 'react'
import type { Heatmap } from '../game/heatmap'
import { statsFor, type Announcement } from '../game/state'
import {
  FLEET,
  cellsOf,
  coordLabel,
  key,
  type LogEntry,
  type PlacedShip,
  type Shot,
  type Side,
} from '../game/types'
import { Logo } from './Logo'
import './Panels.css'

/* ------------------------------------------------------------------ */

interface FleetStatusProps {
  title: string
  ships: readonly PlacedShip[]
  shots: ReadonlyMap<string, Shot>
  /** Show per-segment damage (own fleet) instead of just sunk / afloat. */
  detailed: boolean
}

export function FleetStatus({ title, ships, shots, detailed }: FleetStatusProps) {
  const byId = new Map(ships.map((s) => [s.id, s]))
  return (
    <div className="fleet">
      <h3 className="panel__label">{title}</h3>
      <ul className="fleet__list">
        {FLEET.map((spec) => {
          const ship = byId.get(spec.id)
          const cells = ship ? cellsOf(ship) : []
          const hits = cells.filter((c) => shots.has(key(c))).length
          const sunk = ship !== undefined && hits >= spec.size
          return (
            <li key={spec.id} className={`fleet__ship${sunk ? ' fleet__ship--sunk' : ''}`}>
              <span className="fleet__name">{spec.name}</span>
              <span className="fleet__segs" aria-label={`${spec.size} segments`}>
                {Array.from({ length: spec.size }, (_, i) => {
                  const damaged = detailed ? Boolean(ship) && shots.has(key(cells[i])) : sunk
                  return <i key={i} className={damaged ? 'seg seg--hit' : 'seg'} />
                })}
              </span>
              <span className="fleet__state">{sunk ? 'Sunk' : detailed ? `${hits}/${spec.size}` : 'Afloat'}</span>
            </li>
          )
        })}
      </ul>
    </div>
  )
}

/* ------------------------------------------------------------------ */

interface ShotLogProps {
  log: readonly LogEntry[]
}

export function ShotLog({ log }: ShotLogProps) {
  const listRef = useRef<HTMLOListElement>(null)
  useEffect(() => {
    listRef.current?.scrollTo({ top: 0 })
  }, [log.length])

  return (
    <div className="log">
      <h3 className="panel__label">
        Shot log <span className="panel__count">{log.length}</span>
      </h3>
      {log.length === 0 ? (
        <p className="log__empty">No shots fired yet. Click a cell in enemy waters.</p>
      ) : (
        <ol className="log__list" ref={listRef} aria-live="polite">
          {[...log].reverse().map((e, i) => (
            <li key={log.length - i} className={`log__row log__row--${e.side} log__row--${e.result}`}>
              <span className="log__turn">T{e.turn}</span>
              <span className="log__who">{e.side === 'player' ? 'You' : 'AI'}</span>
              <span className="log__coord">{coordLabel(e.coord)}</span>
              <span className="log__result">
                {e.result === 'sunk' ? `Sunk ${e.shipName}` : e.result === 'hit' ? 'Hit' : 'Miss'}
              </span>
            </li>
          ))}
        </ol>
      )}
    </div>
  )
}

/* ------------------------------------------------------------------ */

interface HeatmapControlProps {
  enabled: boolean
  onToggle: () => void
  heatmap: Heatmap | null
}

export function HeatmapControl({ enabled, onToggle, heatmap }: HeatmapControlProps) {
  const best = heatmap?.best
  const pct = heatmap && best && heatmap.total > 0
    ? Math.round((heatmap.weights[best.r][best.c] / heatmap.total) * 100)
    : 0
  return (
    <div className={`heatctl${enabled ? ' heatctl--on' : ''}`}>
      <button
        type="button"
        role="switch"
        aria-checked={enabled}
        className="heatctl__switch"
        onClick={onToggle}
      >
        <span className="heatctl__track">
          <span className="heatctl__thumb" />
        </span>
        <span className="heatctl__text">
          <strong>Probability heatmap</strong>
          <small>Where the remaining enemy ships can still fit</small>
        </span>
      </button>
      {enabled && heatmap ? (
        <p className="heatctl__hint">
          <span className={`heatctl__mode heatctl__mode--${heatmap.mode}`}>{heatmap.mode}</span>
          {best ? (
            <>
              best guess <b>{coordLabel(best)}</b> · {pct}% of remaining placements
            </>
          ) : (
            'no candidates'
          )}
        </p>
      ) : null}
    </div>
  )
}

/* ------------------------------------------------------------------ */

interface ToastProps {
  announcement: Announcement | null
  onDone: (id: number) => void
}

export function Toast({ announcement, onDone }: ToastProps) {
  useEffect(() => {
    if (!announcement) return
    const t = window.setTimeout(() => onDone(announcement.id), 2400)
    return () => window.clearTimeout(t)
  }, [announcement, onDone])
  if (!announcement) return null
  return (
    <div
      key={announcement.id}
      className={`toast toast--${announcement.side}`}
      role="status"
    >
      {announcement.text}
    </div>
  )
}

/* ------------------------------------------------------------------ */

interface EndScreenProps {
  winner: Side
  seed: number
  round: number
  shotsOnEnemy: ReadonlyMap<string, Shot>
  shotsOnPlayer: ReadonlyMap<string, Shot>
  onRematch: () => void
  onEditFleet: () => void
}

export function EndScreen({
  winner,
  seed,
  round,
  shotsOnEnemy,
  shotsOnPlayer,
  onRematch,
  onEditFleet,
}: EndScreenProps) {
  const you = statsFor(shotsOnEnemy)
  const ai = statsFor(shotsOnPlayer)
  const won = winner === 'player'
  return (
    <div className="end" role="dialog" aria-modal="true" aria-labelledby="end-title">
      <div className={`end__card end__card--${won ? 'win' : 'lose'}`}>
        <Logo size={64} className="end__emblem" />
        <p className="end__eyebrow">
          Mission report · Game {String(round).padStart(2, '0')} · Seed {seed}
        </p>
        <h2 id="end-title" className="end__title">
          {won ? 'Victory' : 'Defeat'}
        </h2>
        <p className="end__sub">
          {won
            ? `You sank the entire enemy fleet in ${you.shots} shots.`
            : `The AI sank your fleet in ${ai.shots} shots.`}
        </p>
        <table className="end__stats">
          <thead>
            <tr>
              <th />
              <th>You</th>
              <th>Enemy AI</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Shots fired</td>
              <td>{you.shots}</td>
              <td>{ai.shots}</td>
            </tr>
            <tr>
              <td>Hits</td>
              <td>{you.hits}</td>
              <td>{ai.hits}</td>
            </tr>
            <tr>
              <td>Accuracy</td>
              <td>{you.accuracy}%</td>
              <td>{ai.accuracy}%</td>
            </tr>
            <tr>
              <td>Ships sunk</td>
              <td>{you.sunk} / 5</td>
              <td>{ai.sunk} / 5</td>
            </tr>
          </tbody>
        </table>
        <div className="end__actions">
          <button type="button" className="btn btn--primary" onClick={onRematch}>
            Rematch (same seed)
          </button>
          <button type="button" className="btn" onClick={onEditFleet}>
            Edit fleet
          </button>
        </div>
      </div>
    </div>
  )
}
