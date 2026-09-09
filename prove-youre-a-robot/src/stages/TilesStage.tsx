import { useMemo, useState } from 'react'
import { mulberry32, pick, range, rangeInt, shuffle } from '../lib/rng'
import type { StageProps } from './types'
import './TilesStage.css'

type Kind = 'cone' | 'hydrant' | 'tree' | 'bench' | 'mailbox' | 'barrel' | 'lamp'

const DECOYS: readonly Kind[] = ['hydrant', 'tree', 'bench', 'mailbox', 'barrel', 'lamp']
const KIND_LABEL: Record<Kind, string> = {
  cone: 'traffic cone',
  hydrant: 'fire hydrant',
  tree: 'tree',
  bench: 'bench',
  mailbox: 'mailbox',
  barrel: 'traffic barrel',
  lamp: 'street lamp',
}

interface Tile {
  kind: Kind
  sky: string
  ground: string
  offsetX: number
  scale: number
}

const SKIES = ['#bae6fd', '#fde68a', '#c7d2fe', '#fbcfe8', '#a7f3d0', '#e2e8f0'] as const
const GROUNDS = ['#57534e', '#6b7280', '#78716c', '#4b5563'] as const

function ObjectSvg({ kind }: { kind: Kind }) {
  switch (kind) {
    case 'cone':
      return (
        <g>
          <rect x={-22} y={28} width={44} height={8} rx={2} fill="#111827" />
          <path d="M -13 28 L -4 -30 L 4 -30 L 13 28 Z" fill="#f97316" />
          <path d="M -9.6 8 L 9.6 8 L 8 -2 L -8 -2 Z" fill="#fff" />
          <path d="M -6.4 -12 L 6.4 -12 L 5.4 -19 L -5.4 -19 Z" fill="#fff" />
        </g>
      )
    case 'barrel':
      return (
        <g>
          <rect x={-18} y={-26} width={36} height={56} rx={4} fill="#f97316" />
          <rect x={-18} y={-12} width={36} height={8} fill="#fff" />
          <rect x={-18} y={8} width={36} height={8} fill="#fff" />
          <ellipse cx={0} cy={-26} rx={18} ry={5} fill="#c2410c" />
          <rect x={-22} y={28} width={44} height={6} rx={2} fill="#111827" />
        </g>
      )
    case 'hydrant':
      return (
        <g>
          <rect x={-10} y={-18} width={20} height={48} rx={4} fill="#dc2626" />
          <rect x={-16} y={-24} width={32} height={8} rx={2} fill="#b91c1c" />
          <circle cx={0} cy={-30} r={7} fill="#dc2626" />
          <rect x={-20} y={-6} width={40} height={8} rx={3} fill="#b91c1c" />
          <rect x={-14} y={30} width={28} height={6} rx={2} fill="#7f1d1d" />
        </g>
      )
    case 'tree':
      return (
        <g>
          <rect x={-5} y={8} width={10} height={26} fill="#78350f" />
          <circle cx={0} cy={-10} r={24} fill="#16a34a" />
          <circle cx={-14} cy={2} r={16} fill="#15803d" />
          <circle cx={14} cy={2} r={16} fill="#15803d" />
        </g>
      )
    case 'bench':
      return (
        <g>
          <rect x={-30} y={-4} width={60} height={8} rx={2} fill="#92400e" />
          <rect x={-30} y={-18} width={60} height={7} rx={2} fill="#92400e" />
          <rect x={-26} y={4} width={5} height={30} fill="#1f2937" />
          <rect x={21} y={4} width={5} height={30} fill="#1f2937" />
        </g>
      )
    case 'mailbox':
      return (
        <g>
          <rect x={-3} y={6} width={6} height={28} fill="#374151" />
          <rect x={-22} y={-22} width={44} height={30} rx={10} fill="#1d4ed8" />
          <rect x={-22} y={-8} width={44} height={14} fill="#1e40af" />
          <rect x={-10} y={-14} width={20} height={4} rx={2} fill="#93c5fd" />
        </g>
      )
    case 'lamp':
      return (
        <g>
          <rect x={-3} y={-30} width={6} height={64} fill="#4b5563" />
          <rect x={-12} y={34} width={24} height={4} rx={2} fill="#374151" />
          <path d="M -12 -30 L 12 -30 L 8 -44 L -8 -44 Z" fill="#374151" />
          <circle cx={0} cy={-36} r={7} fill="#fde047" />
        </g>
      )
  }
}

export function TilesStage({ seed, locked, onPass, onFail }: StageProps) {
  const tiles = useMemo<Tile[]>(() => {
    const rng = mulberry32(seed)
    const coneCount = rangeInt(rng, 4, 6)
    const coneSlots = new Set(shuffle(rng, Array.from({ length: 16 }, (_, i) => i)).slice(0, coneCount))
    return Array.from({ length: 16 }, (_, i) => ({
      kind: coneSlots.has(i) ? 'cone' : pick(rng, DECOYS),
      sky: pick(rng, SKIES),
      ground: pick(rng, GROUNDS),
      offsetX: Math.round(range(rng, -14, 14)),
      scale: range(rng, 0.85, 1.15),
    }))
  }, [seed])

  const [selected, setSelected] = useState<ReadonlySet<number>>(() => new Set())

  const toggle = (i: number) => {
    if (locked) return
    setSelected((prev) => {
      const next = new Set(prev)
      if (next.has(i)) next.delete(i)
      else next.add(i)
      return next
    })
  }

  const verify = () => {
    if (locked) return
    let missed = 0
    let wrong = 0
    tiles.forEach((t, i) => {
      const isCone = t.kind === 'cone'
      if (isCone && !selected.has(i)) missed++
      if (!isCone && selected.has(i)) wrong++
    })
    if (missed === 0 && wrong === 0) {
      onPass()
    } else {
      setSelected(new Set())
      onFail(
        `${missed} cone tile${missed === 1 ? '' : 's'} missed, ${wrong} non-cone tile${wrong === 1 ? '' : 's'} selected.`,
      )
    }
  }

  return (
    <div className="tiles">
      <div className="tiles__grid" role="group" aria-label="Image tiles">
        {tiles.map((t, i) => {
          const on = selected.has(i)
          return (
            <button
              key={i}
              type="button"
              className={`tile${on ? ' is-selected' : ''}${locked && t.kind === 'cone' ? ' is-correct' : ''}`}
              onClick={() => toggle(i)}
              aria-pressed={on}
              aria-label={`Tile ${i + 1}`}
              disabled={locked}
            >
              <svg viewBox="0 0 100 100" width={104} height={104} aria-hidden="true">
                <rect width={100} height={100} fill={t.sky} />
                <rect y={66} width={100} height={34} fill={t.ground} />
                <line x1={0} y1={66} x2={100} y2={66} stroke="rgba(0,0,0,0.25)" />
                <g transform={`translate(${50 + t.offsetX} 62) scale(${t.scale})`}>
                  <ObjectSvg kind={t.kind} />
                </g>
              </svg>
              <span className="tile__check" aria-hidden="true">
                <svg viewBox="0 0 24 24" width={16} height={16}>
                  <path d="M5 12.5 10 17.5 19 7" fill="none" stroke="#020617" strokeWidth={3} strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </span>
            </button>
          )
        })}
      </div>
      <div className="tiles__footer">
        <div className="telemetry">
          <span>
            selected = <b>{selected.size}</b> / 16
          </span>
          <span>
            decoys include <b>{KIND_LABEL.barrel}s</b>
          </span>
        </div>
        <button type="button" className="btn btn--primary" onClick={verify} disabled={locked || selected.size === 0}>
          Verify selection
        </button>
      </div>
    </div>
  )
}
