import {
  useCallback,
  useEffect,
  useRef,
  useState,
  type PointerEvent as ReactPointerEvent,
} from 'react'
import type { Preview } from '../components/Board'
import { bowFromGrab, canPlace } from '../game/placement'
import {
  FLEET,
  cellsOf,
  type Coord,
  type Orientation,
  type PlacedShip,
  type ShipSpec,
} from '../game/types'

export interface DragState {
  spec: ShipSpec
  orientation: Orientation
  grabIndex: number
  x: number
  y: number
  origin: 'dock' | 'board'
  /** The ship as it was on the board before being picked up (board origin only). */
  original?: PlacedShip
  startX: number
  startY: number
}

export type DockOrientations = Record<string, Orientation>

interface Options {
  ships: readonly PlacedShip[]
  setShips: (ships: PlacedShip[]) => void
  enabled: boolean
}

function cellFromPoint(x: number, y: number): Coord | null {
  const el = document.elementFromPoint(x, y)?.closest<HTMLElement>('[data-cell]')
  if (!el) return null
  const r = Number(el.dataset.r)
  const c = Number(el.dataset.c)
  return Number.isFinite(r) && Number.isFinite(c) ? { r, c } : null
}

export function usePlacementDrag({ ships, setShips, enabled }: Options) {
  const [drag, setDrag] = useState<DragState | null>(null)
  const [hover, setHover] = useState<Coord | null>(null)
  const [focusId, setFocusId] = useState<string | null>(FLEET[0].id)
  const [dockOrientations, setDockOrientations] = useState<DockOrientations>(() =>
    Object.fromEntries(FLEET.map((s) => [s.id, 'h' as Orientation])),
  )
  const [shake, setShake] = useState<string | null>(null)
  const shipsRef = useRef(ships)
  const dragRef = useRef(drag)
  useEffect(() => {
    shipsRef.current = ships
    dragRef.current = drag
  }, [ships, drag])

  const beginFromDock = useCallback(
    (spec: ShipSpec, grabIndex: number, e: ReactPointerEvent) => {
      if (!enabled) return
      e.preventDefault()
      setFocusId(spec.id)
      setDrag({
        spec,
        orientation: dockOrientations[spec.id],
        grabIndex,
        x: e.clientX,
        y: e.clientY,
        origin: 'dock',
        startX: e.clientX,
        startY: e.clientY,
      })
    },
    [dockOrientations, enabled],
  )

  const beginFromBoard = useCallback(
    (ship: PlacedShip, grabIndex: number, e: ReactPointerEvent) => {
      if (!enabled) return
      e.preventDefault()
      setFocusId(ship.id)
      setShips(shipsRef.current.filter((s) => s.id !== ship.id))
      setDrag({
        spec: { id: ship.id, name: ship.name, size: ship.size },
        orientation: ship.orientation,
        grabIndex,
        x: e.clientX,
        y: e.clientY,
        origin: 'board',
        original: ship,
        startX: e.clientX,
        startY: e.clientY,
      })
    },
    [enabled, setShips],
  )

  const rotate = useCallback(() => {
    const d = dragRef.current
    if (d) {
      setDrag({ ...d, orientation: d.orientation === 'h' ? 'v' : 'h' })
      return
    }
    if (!focusId) return
    const placed = shipsRef.current.find((s) => s.id === focusId)
    if (placed) {
      const rotated: PlacedShip = {
        ...placed,
        orientation: placed.orientation === 'h' ? 'v' : 'h',
      }
      if (canPlace(shipsRef.current, rotated)) {
        setShips(shipsRef.current.map((s) => (s.id === rotated.id ? rotated : s)))
      } else {
        setShake(placed.id)
        window.setTimeout(() => setShake(null), 400)
      }
      return
    }
    setDockOrientations((prev) => ({
      ...prev,
      [focusId]: prev[focusId] === 'h' ? 'v' : 'h',
    }))
  }, [focusId, setShips])

  useEffect(() => {
    if (!enabled) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'r' || e.key === 'R') {
        e.preventDefault()
        rotate()
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [enabled, rotate])

  const isDragging = drag !== null
  useEffect(() => {
    if (!isDragging) return
    const onMove = (e: PointerEvent) => {
      setDrag((d) => (d ? { ...d, x: e.clientX, y: e.clientY } : d))
      setHover(cellFromPoint(e.clientX, e.clientY))
    }
    const onUp = (e: PointerEvent) => {
      const d = dragRef.current
      if (!d) return
      const current = shipsRef.current
      const moved = Math.hypot(e.clientX - d.startX, e.clientY - d.startY) > 4
      const target = cellFromPoint(e.clientX, e.clientY)

      if (!moved && d.origin === 'board' && d.original) {
        // A plain click on a placed ship rotates it around the clicked segment.
        const rotated: PlacedShip = {
          ...d.original,
          orientation: d.original.orientation === 'h' ? 'v' : 'h',
          bow: bowFromGrab(
            cellsOf(d.original)[d.grabIndex],
            d.grabIndex,
            d.original.orientation === 'h' ? 'v' : 'h',
          ),
        }
        setShips([...current, canPlace(current, rotated) ? rotated : d.original])
      } else if (target) {
        const candidate: PlacedShip = {
          ...d.spec,
          bow: bowFromGrab(target, d.grabIndex, d.orientation),
          orientation: d.orientation,
        }
        if (canPlace(current, candidate)) {
          setShips([...current, candidate])
        } else if (d.original) {
          setShips([...current, d.original])
        }
      } else if (d.original) {
        setShips([...current, d.original])
      }
      if (d.origin === 'dock') {
        setDockOrientations((prev) => ({ ...prev, [d.spec.id]: d.orientation }))
      }
      setDrag(null)
      setHover(null)
    }
    window.addEventListener('pointermove', onMove)
    window.addEventListener('pointerup', onUp)
    window.addEventListener('pointercancel', onUp)
    return () => {
      window.removeEventListener('pointermove', onMove)
      window.removeEventListener('pointerup', onUp)
      window.removeEventListener('pointercancel', onUp)
    }
  }, [isDragging, setShips])

  let preview: Preview | null = null
  if (drag && hover) {
    const candidate: PlacedShip = {
      ...drag.spec,
      bow: bowFromGrab(hover, drag.grabIndex, drag.orientation),
      orientation: drag.orientation,
    }
    preview = { cells: cellsOf(candidate), valid: canPlace(ships, candidate) }
  }

  return {
    drag,
    preview,
    focusId,
    setFocusId,
    dockOrientations,
    setDockOrientations,
    shake,
    beginFromDock,
    beginFromBoard,
    rotate,
  }
}
