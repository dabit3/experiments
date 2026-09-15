import { randomFleet } from './placement'
import { createRng } from './rng'
import {
  FLEET,
  cellsOf,
  key,
  type Coord,
  type LogEntry,
  type PlacedShip,
  type Shot,
  type ShotResult,
  type Side,
} from './types'

export type Phase = 'placement' | 'battle' | 'over'

export interface Announcement {
  id: number
  side: Side
  text: string
}

export interface GameState {
  seed: number
  phase: Phase
  round: number
  turn: Side
  playerShips: PlacedShip[]
  enemyShips: PlacedShip[]
  /** Player's shots at the enemy board. */
  shotsOnEnemy: Map<string, Shot>
  /** Enemy's shots at the player board. */
  shotsOnPlayer: Map<string, Shot>
  log: LogEntry[]
  winner: Side | null
  announcement: Announcement | null
  lastShot: { side: Side; coord: Coord } | null
  showHeatmap: boolean
}

export type Action =
  | { type: 'setPlayerShips'; ships: PlacedShip[] }
  | { type: 'startBattle' }
  | { type: 'playerFire'; coord: Coord }
  | { type: 'enemyFire'; coord: Coord }
  | { type: 'toggleHeatmap' }
  | { type: 'dismissAnnouncement'; id: number }
  | { type: 'rematch' }
  | { type: 'editFleet' }

export const enemyFleetForSeed = (seed: number): PlacedShip[] =>
  randomFleet(createRng(seed))

export const aiRngForSeed = (seed: number) => createRng((seed ^ 0x5bd1e995) >>> 0)

export function initialState(seed: number): GameState {
  return {
    seed,
    phase: 'placement',
    round: 1,
    turn: 'player',
    playerShips: [],
    enemyShips: enemyFleetForSeed(seed),
    shotsOnEnemy: new Map(),
    shotsOnPlayer: new Map(),
    log: [],
    winner: null,
    announcement: null,
    lastShot: null,
    showHeatmap: false,
  }
}

function resolveShot(
  ships: readonly PlacedShip[],
  shots: ReadonlyMap<string, Shot>,
  coord: Coord,
): { result: ShotResult; ship?: PlacedShip } {
  const k = key(coord)
  const ship = ships.find((s) => cellsOf(s).some((c) => key(c) === k))
  if (!ship) return { result: 'miss' }
  const hitsSoFar = cellsOf(ship).filter((c) => shots.has(key(c))).length
  return { result: hitsSoFar + 1 >= ship.size ? 'sunk' : 'hit', ship }
}

export function isFleetSunk(ships: readonly PlacedShip[], shots: ReadonlyMap<string, Shot>): boolean {
  return ships.every((s) => cellsOf(s).every((c) => shots.has(key(c))))
}

function fire(state: GameState, side: Side, coord: Coord): GameState {
  const targetShips = side === 'player' ? state.enemyShips : state.playerShips
  const shots = side === 'player' ? state.shotsOnEnemy : state.shotsOnPlayer
  if (shots.has(key(coord))) return state

  const { result, ship } = resolveShot(targetShips, shots, coord)
  const nextShots = new Map(shots)
  nextShots.set(key(coord), { coord, result, shipId: ship?.id })

  const entry: LogEntry = {
    turn: Math.floor(state.log.length / 2) + 1,
    side,
    coord,
    result,
    shipName: result === 'sunk' ? ship?.name : undefined,
  }

  const allSunk = isFleetSunk(targetShips, nextShots)
  let announcement = state.announcement
  if (result === 'sunk' && ship) {
    announcement = {
      id: state.log.length + 1,
      side,
      text:
        side === 'player'
          ? `You sank the enemy ${ship.name}!`
          : `Your ${ship.name} was sunk!`,
    }
  }

  return {
    ...state,
    shotsOnEnemy: side === 'player' ? nextShots : state.shotsOnEnemy,
    shotsOnPlayer: side === 'enemy' ? nextShots : state.shotsOnPlayer,
    log: [...state.log, entry],
    lastShot: { side, coord },
    announcement,
    phase: allSunk ? 'over' : state.phase,
    winner: allSunk ? side : state.winner,
    turn: side === 'player' ? 'enemy' : 'player',
  }
}

export function reducer(state: GameState, action: Action): GameState {
  switch (action.type) {
    case 'setPlayerShips':
      return state.phase === 'placement' ? { ...state, playerShips: action.ships } : state
    case 'startBattle':
      if (state.phase !== 'placement' || state.playerShips.length !== FLEET.length) return state
      return { ...state, phase: 'battle', turn: 'player' }
    case 'playerFire':
      if (state.phase !== 'battle' || state.turn !== 'player') return state
      return fire(state, 'player', action.coord)
    case 'enemyFire':
      if (state.phase !== 'battle' || state.turn !== 'enemy') return state
      return fire(state, 'enemy', action.coord)
    case 'toggleHeatmap':
      return { ...state, showHeatmap: !state.showHeatmap }
    case 'dismissAnnouncement':
      return state.announcement?.id === action.id ? { ...state, announcement: null } : state
    case 'rematch':
      return {
        ...initialState(state.seed),
        playerShips: state.playerShips,
        phase: 'battle',
        round: state.round + 1,
        showHeatmap: state.showHeatmap,
      }
    case 'editFleet':
      return {
        ...initialState(state.seed),
        playerShips: state.playerShips,
        round: state.round + 1,
        showHeatmap: state.showHeatmap,
      }
  }
}

export interface Stats {
  shots: number
  hits: number
  accuracy: number
  sunk: number
}

export function statsFor(
  shots: ReadonlyMap<string, Shot>,
): Stats {
  let hits = 0
  let sunk = 0
  for (const s of shots.values()) {
    if (s.result !== 'miss') hits += 1
    if (s.result === 'sunk') sunk += 1
  }
  return {
    shots: shots.size,
    hits,
    accuracy: shots.size === 0 ? 0 : Math.round((hits / shots.size) * 100),
    sunk,
  }
}
