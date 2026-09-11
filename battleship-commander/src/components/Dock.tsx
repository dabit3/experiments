import type { CSSProperties, PointerEvent as ReactPointerEvent } from 'react'
import type { DockOrientations } from '../hooks/usePlacementDrag'
import {
  FLEET,
  type Orientation,
  type PlacedShip,
  type ShipSpec,
} from '../game/types'
import './Dock.css'
import { Vessel } from './Vessel'

interface DockProps {
  placed: readonly PlacedShip[]
  orientations: DockOrientations
  focusId: string | null
  draggingId: string | null
  onFocus: (id: string) => void
  onRotate: (id: string) => void
  onPointerDown: (spec: ShipSpec, segment: number, e: ReactPointerEvent) => void
}

export function Dock({
  placed,
  orientations,
  focusId,
  draggingId,
  onFocus,
  onRotate,
  onPointerDown,
}: DockProps) {
  const placedIds = new Set(placed.map((s) => s.id))
  return (
    <div className="dock">
      {FLEET.map((spec) => {
        const deployed = placedIds.has(spec.id)
        const orientation: Orientation = orientations[spec.id]
        const isFocus = focusId === spec.id
        const isDragging = draggingId === spec.id
        return (
          <div
            key={spec.id}
            className={`dock-ship${deployed ? ' dock-ship--deployed' : ''}${isFocus && !deployed ? ' dock-ship--focus' : ''}${isDragging ? ' dock-ship--dragging' : ''}`}
            onPointerEnter={() => {
              if (!deployed) onFocus(spec.id)
            }}
          >
            <div className="dock-ship__meta">
              <span className="dock-ship__name">{spec.name}</span>
              <span className="dock-ship__size">
                {deployed
                  ? 'DEPLOYED'
                  : `${spec.size} CELLS · ${orientation === 'h' ? 'H' : 'V'}`}
              </span>
              <button
                type="button"
                className="dock-ship__rotate"
                aria-label={`Rotate ${spec.name}`}
                title="Rotate (R)"
                onClick={() => onRotate(spec.id)}
                disabled={deployed}
              >
                <svg
                  viewBox="0 0 24 24"
                  width="16"
                  height="16"
                  aria-hidden="true"
                >
                  <path
                    d="M4 12a8 8 0 0 1 13.66-5.66L20 8.7M20 4v5h-5"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                  <path
                    d="M20 12a8 8 0 0 1-13.66 5.66L4 15.3M4 20v-5h5"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
              </button>
            </div>
            <div
              className="dock-ship__hull"
              aria-label={
                deployed
                  ? `${spec.name} deployed`
                  : `Drag ${spec.name} onto your grid`
              }
            >
              <Vessel kind={spec.id} />
              {Array.from({ length: spec.size }, (_, i) => (
                <span
                  key={i}
                  className="dock-ship__seg"
                  onPointerDown={
                    deployed ? undefined : (e) => onPointerDown(spec, i, e)
                  }
                />
              ))}
            </div>
          </div>
        )
      })}
    </div>
  )
}

interface GhostProps {
  spec: ShipSpec
  orientation: Orientation
  grabIndex: number
  x: number
  y: number
}

export function DragGhost({ spec, orientation, grabIndex, x, y }: GhostProps) {
  const style = {
    '--gx': `${x}px`,
    '--gy': `${y}px`,
    '--grab': grabIndex,
    '--size': spec.size,
  } as CSSProperties
  return (
    <div
      className={`ghost ghost--${orientation}`}
      style={style}
      aria-hidden="true"
    >
      <Vessel kind={spec.id} />
      {Array.from({ length: spec.size }, (_, i) => (
        <span key={i} className="ghost__seg" />
      ))}
    </div>
  )
}
