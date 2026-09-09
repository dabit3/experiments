import { useCallback, useEffect, useMemo, useReducer, useRef, useState } from 'react'
import './App.css'
import { Board } from './components/Board'
import { Dock, DragGhost } from './components/Dock'
import { Logo } from './components/Logo'
import { EndScreen, FleetStatus, HeatmapControl, ShotLog, Toast } from './components/Panels'
import { chooseShot } from './game/ai'
import { computeHeatmap } from './game/heatmap'
import { randomFleet } from './game/placement'
import { createRng, seedFromUrl, writeSeedToUrl } from './game/rng'
import { aiRngForSeed, initialState, reducer, statsFor } from './game/state'
import { FLEET, coordLabel, type PlacedShip } from './game/types'
import { usePlacementDrag } from './hooks/usePlacementDrag'

const AI_DELAY_MS = 850

export default function App() {
  const [state, dispatch] = useReducer(reducer, undefined, () => {
    const seed = seedFromUrl()
    writeSeedToUrl(seed)
    return initialState(seed)
  })
  const aiRng = useRef(aiRngForSeed(state.seed))
  const [placementNonce, setPlacementNonce] = useState(0)

  // Each battle re-seeds the AI so a rematch with the same seed replays identically.
  useEffect(() => {
    if (state.phase === 'battle' && state.log.length === 0) {
      aiRng.current = aiRngForSeed(state.seed)
    }
  }, [state.phase, state.log.length, state.seed])

  // Enemy fires after a short beat so the player can read the result of their own shot.
  useEffect(() => {
    if (state.phase !== 'battle' || state.turn !== 'enemy') return
    const t = window.setTimeout(() => {
      const decision = chooseShot(state.shotsOnPlayer, aiRng.current)
      dispatch({ type: 'enemyFire', coord: decision.coord })
    }, AI_DELAY_MS)
    return () => window.clearTimeout(t)
  }, [state.phase, state.turn, state.shotsOnPlayer])

  const setShips = useCallback(
    (ships: PlacedShip[]) => dispatch({ type: 'setPlayerShips', ships }),
    [],
  )
  const placing = state.phase === 'placement'
  const drag = usePlacementDrag({ ships: state.playerShips, setShips, enabled: placing })

  const heatmap = useMemo(
    () => (state.showHeatmap && state.phase !== 'placement' ? computeHeatmap(state.shotsOnEnemy) : null),
    [state.showHeatmap, state.phase, state.shotsOnEnemy],
  )

  // Seeded too, so the n-th "Random placement" click yields the same layout for a given seed.
  const randomise = () => {
    setPlacementNonce((n) => n + 1)
    setShips(randomFleet(createRng((state.seed * 7919 + placementNonce + 1) >>> 0)))
  }

  const newSeed = () => {
    const url = new URL(window.location.href)
    url.searchParams.set('seed', String(Math.floor(Math.random() * 100000)))
    window.location.assign(url.toString())
  }

  const dismiss = useCallback((id: number) => dispatch({ type: 'dismissAnnouncement', id }), [])

  const ready = state.playerShips.length === FLEET.length
  const yourStats = statsFor(state.shotsOnEnemy)
  const lastPlayer = state.lastShot?.side === 'player' ? state.lastShot.coord : null
  const lastEnemy = state.lastShot?.side === 'enemy' ? state.lastShot.coord : null

  let status: string
  if (placing) {
    status = ready
      ? 'Fleet deployed. Start the battle when ready.'
      : `Drag ${FLEET.length - state.playerShips.length} more ship${FLEET.length - state.playerShips.length === 1 ? '' : 's'} onto your grid. Press R to rotate.`
  } else if (state.phase === 'over') {
    status = state.winner === 'player' ? 'Enemy fleet destroyed.' : 'Your fleet was destroyed.'
  } else if (state.turn === 'player') {
    status = 'Your turn — click a cell in enemy waters to fire.'
  } else {
    status = 'Enemy is choosing a target…'
  }

  return (
    <div className={`app app--${state.phase}`}>
      <header className="topbar">
        <div className="brand">
          <Logo size={46} className="brand__mark" />
          <div className="brand__text">
            <h1 className="brand__title">Battleship</h1>
            <p className="brand__sub">Commander</p>
          </div>
          <span className="brand__tag">vs hunt-and-target AI</span>
        </div>

        <div className={`status status--${state.turn}${state.phase === 'battle' && state.turn === 'enemy' ? ' status--thinking' : ''}`} role="status">
          <span className="status__dot" />
          <span className="status__text">{status}</span>
        </div>

        <div className="topbar__right">
          <span className="readout" title="Deterministic seed — same seed, same enemy fleet and AI shots">
            <span className="readout__label">Seed</span>
            <b className="readout__value">{state.seed}</b>
          </span>
          <span className="readout">
            <span className="readout__label">Game</span>
            <b className="readout__value">{String(state.round).padStart(2, '0')}</b>
          </span>
          <button type="button" className="btn btn--ghost" onClick={newSeed}>
            New seed
          </button>
        </div>
      </header>

      <main className="arena">
        <Board
          title="Your fleet"
          subtitle={
            placing
              ? 'Drop ships here · click a placed ship to rotate'
              : `Enemy has fired ${state.shotsOnPlayer.size} shot${state.shotsOnPlayer.size === 1 ? '' : 's'}`
          }
          ships={state.playerShips}
          shots={state.shotsOnPlayer}
          preview={drag.preview}
          lastShot={lastEnemy}
          onShipPointerDown={placing ? drag.beginFromBoard : undefined}
          badge={placing ? `${state.playerShips.length}/${FLEET.length} placed` : undefined}
          tone="own"
        />

        <Board
          title="Enemy waters"
          subtitle={
            placing
              ? 'The enemy fleet is already deployed'
              : heatmap
                ? `Heatmap on · ${heatmap.mode === 'target' ? 'target mode' : 'hunt mode'}${heatmap.best ? ` · best ${coordLabel(heatmap.best)}` : ''}`
                : `${yourStats.shots} shots · ${yourStats.hits} hits · ${yourStats.accuracy}% accuracy`
          }
          shots={state.shotsOnEnemy}
          heatmap={heatmap}
          interactive={state.phase === 'battle' && state.turn === 'player'}
          onFire={(coord) => dispatch({ type: 'playerFire', coord })}
          lastShot={lastPlayer}
          dimmed={placing}
          badge={placing ? 'locked' : `${yourStats.sunk}/${FLEET.length} sunk`}
          tone="enemy"
        />

        <aside className="side">
          {placing ? (
            <>
              <section className="side__block">
                <h3 className="panel__label">Dock</h3>
                <p className="side__help">
                  Drag each ship onto your grid. Press <kbd>R</kbd> while dragging or hovering a ship to
                  rotate it. Drop somewhere invalid and it snaps back.
                </p>
                <Dock
                  placed={state.playerShips}
                  orientations={drag.dockOrientations}
                  focusId={drag.focusId}
                  draggingId={drag.drag?.origin === 'dock' ? drag.drag.spec.id : null}
                  onFocus={drag.setFocusId}
                  onRotate={(id) =>
                    drag.setDockOrientations((prev) => ({
                      ...prev,
                      [id]: prev[id] === 'h' ? 'v' : 'h',
                    }))
                  }
                  onPointerDown={drag.beginFromDock}
                />
              </section>
              <section className="side__block side__actions">
                <button type="button" className="btn" onClick={randomise}>
                  Random placement
                </button>
                <button
                  type="button"
                  className="btn"
                  onClick={() => setShips([])}
                  disabled={state.playerShips.length === 0}
                >
                  Clear
                </button>
                <button
                  type="button"
                  className="btn btn--primary btn--wide"
                  onClick={() => dispatch({ type: 'startBattle' })}
                  disabled={!ready}
                >
                  Start battle
                </button>
              </section>
            </>
          ) : (
            <>
              <section className="side__block">
                <HeatmapControl
                  enabled={state.showHeatmap}
                  onToggle={() => dispatch({ type: 'toggleHeatmap' })}
                  heatmap={heatmap}
                />
              </section>
              <section className="side__block side__fleets">
                <FleetStatus title="Enemy fleet" ships={state.enemyShips} shots={state.shotsOnEnemy} detailed={false} />
                <FleetStatus title="Your fleet" ships={state.playerShips} shots={state.shotsOnPlayer} detailed />
              </section>
              <section className="side__block side__log">
                <ShotLog log={state.log} />
              </section>
            </>
          )}
        </aside>
      </main>

      {drag.drag ? (
        <DragGhost
          spec={drag.drag.spec}
          orientation={drag.drag.orientation}
          grabIndex={drag.drag.grabIndex}
          x={drag.drag.x}
          y={drag.drag.y}
        />
      ) : null}

      <Toast announcement={state.announcement} onDone={dismiss} />

      {state.phase === 'over' && state.winner ? (
        <EndScreen
          winner={state.winner}
          seed={state.seed}
          round={state.round}
          shotsOnEnemy={state.shotsOnEnemy}
          shotsOnPlayer={state.shotsOnPlayer}
          onRematch={() => dispatch({ type: 'rematch' })}
          onEditFleet={() => dispatch({ type: 'editFleet' })}
        />
      ) : null}
    </div>
  )
}
