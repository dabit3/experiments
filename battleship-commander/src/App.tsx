import {
  useCallback,
  useEffect,
  useMemo,
  useReducer,
  useRef,
  useState,
} from 'react'
import './App.css'
import { Board } from './components/Board'
import { Dock, DragGhost } from './components/Dock'
import { Logo } from './components/Logo'
import { LaunchScreen } from './components/LaunchScreen'
import {
  EndScreen,
  FleetStatus,
  HeatmapControl,
  ShotLog,
  Toast,
} from './components/Panels'
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
  const [launched, setLaunched] = useState(false)

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
  const drag = usePlacementDrag({
    ships: state.playerShips,
    setShips,
    enabled: placing && launched,
  })

  const heatmap = useMemo(
    () =>
      state.showHeatmap && state.phase !== 'placement'
        ? computeHeatmap(state.shotsOnEnemy)
        : null,
    [state.showHeatmap, state.phase, state.shotsOnEnemy],
  )

  // Seeded too, so the n-th "Random placement" click yields the same layout for a given seed.
  const randomise = () => {
    setPlacementNonce((n) => n + 1)
    setShips(
      randomFleet(createRng((state.seed * 7919 + placementNonce + 1) >>> 0)),
    )
  }

  const newSeed = () => {
    const url = new URL(window.location.href)
    url.searchParams.set('seed', String(Math.floor(Math.random() * 100000)))
    window.location.assign(url.toString())
  }

  const dismiss = useCallback(
    (id: number) => dispatch({ type: 'dismissAnnouncement', id }),
    [],
  )

  const ready = state.playerShips.length === FLEET.length
  const yourStats = statsFor(state.shotsOnEnemy)
  const lastPlayer =
    state.lastShot?.side === 'player' ? state.lastShot.coord : null
  const lastEnemy =
    state.lastShot?.side === 'enemy' ? state.lastShot.coord : null
  const enemyStats = statsFor(state.shotsOnPlayer)
  const recentShot = state.log.at(-1)

  let status: string
  if (placing) {
    status = ready
      ? 'Fleet deployed. Start the battle when ready.'
      : `Drag ${FLEET.length - state.playerShips.length} more ship${FLEET.length - state.playerShips.length === 1 ? '' : 's'} onto your grid. Press R to rotate.`
  } else if (state.phase === 'over') {
    status =
      state.winner === 'player'
        ? 'Enemy fleet destroyed.'
        : 'Your fleet was destroyed.'
  } else if (state.turn === 'player') {
    status = 'Your turn — click a cell in enemy waters to fire.'
  } else {
    status = 'Enemy is choosing a target…'
  }

  if (!launched)
    return <LaunchScreen seed={state.seed} onStart={() => setLaunched(true)} />

  return (
    <div className={`app app--${state.phase}`}>
      <header className="topbar">
        <div className="brand">
          <Logo size={46} className="brand__mark" />
          <div className="brand__text">
            <h1 className="brand__title">Battleship</h1>
            <p className="brand__sub">Commander</p>
          </div>
          <span className="brand__tag">
            ARCADE
            <br />
            EDITION / 01
          </span>
        </div>
        <nav className="phase-nav" aria-label="Mission progress">
          <span className={placing ? 'is-active' : ''}>
            <b>01</b> Deploy
          </span>
          <i />
          <span className={state.phase === 'battle' ? 'is-active' : ''}>
            <b>02</b> Battle
          </span>
          <i />
          <span className={state.phase === 'over' ? 'is-active' : ''}>
            <b>03</b> Result
          </span>
        </nav>
        <div className="topbar__right">
          <span
            className="readout"
            title="Deterministic seed — same seed, same enemy fleet and AI shots"
          >
            <span className="readout__label">Seed</span>
            <b className="readout__value">{state.seed}</b>
          </span>
          <span className="readout">
            <span className="readout__label">Game</span>
            <b className="readout__value">
              {String(state.round).padStart(2, '0')}
            </b>
          </span>
          <button type="button" className="btn btn--ghost" onClick={newSeed}>
            New seed
          </button>
        </div>
      </header>

      <section className="mission">
        <div>
          <p className="eyebrow">
            {placing
              ? 'PREPARE FOR CONTACT'
              : 'PACIFIC THEATER / LIVE ENGAGEMENT'}
          </p>
          <h2>
            {placing ? 'Your fleet. Your formation.' : 'Make every shot count.'}
          </h2>
          <p>
            {placing
              ? 'Position your ships. Keep them guessing. Own the ocean.'
              : 'Read both waters. Follow the hits. Sink all five to win.'}
          </p>
        </div>
        <div className="scoreboard" aria-label="Battle score">
          <div className="scoreboard__player">
            <span>YOU</span>
            <strong>
              {yourStats.sunk}
              <small> / 5</small>
            </strong>
          </div>
          <b className="scoreboard__vs">VS</b>
          <div className="scoreboard__enemy">
            <span>ENEMY AI</span>
            <strong>
              {enemyStats.sunk}
              <small> / 5</small>
            </strong>
          </div>
          <div className="scoreboard__accuracy">
            <span>ACCURACY</span>
            <strong>
              {yourStats.accuracy}
              <small>%</small>
            </strong>
          </div>
        </div>
      </section>
      <div
        className={`status status--${state.turn}${state.phase === 'battle' && state.turn === 'enemy' ? ' status--thinking' : ''}`}
        role="status"
      >
        <span className="status__dot" />
        <strong>
          {placing
            ? ready
              ? 'READY TO LAUNCH'
              : 'DEPLOYMENT PHASE'
            : state.phase === 'over'
              ? 'MISSION COMPLETE'
              : state.turn === 'player'
                ? 'YOUR TURN'
                : 'INCOMING FIRE'}
        </strong>
        <span className="status__text">{status}</span>
        <span className="status__tail">
          {placing
            ? `${state.playerShips.length * 20}% DEPLOYED`
            : `TURN ${String(state.shotsOnEnemy.size + 1).padStart(2, '0')}`}
        </span>
      </div>
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
          badge={
            placing
              ? `${state.playerShips.length}/${FLEET.length} placed`
              : undefined
          }
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
                <h3 className="panel__label">
                  Deployment dock <span>{state.playerShips.length} / 5</span>
                </h3>
                <p className="side__help">
                  Drag to your waters.
                  <br />
                  Press <kbd>R</kbd> to rotate your ship.
                </p>
                <Dock
                  placed={state.playerShips}
                  orientations={drag.dockOrientations}
                  focusId={drag.focusId}
                  draggingId={
                    drag.drag?.origin === 'dock' ? drag.drag.spec.id : null
                  }
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
                  Start battle <span aria-hidden="true">→</span>
                </button>
              </section>
            </>
          ) : (
            <>
              <section className="side__block side__intel">
                <span className="eyebrow">TACTICAL ASSIST</span>
                <h3>
                  Trust your instincts.
                  <br />
                  <em>Or use your radar.</em>
                </h3>
              </section>
              <section className="side__block">
                <HeatmapControl
                  enabled={state.showHeatmap}
                  onToggle={() => dispatch({ type: 'toggleHeatmap' })}
                  heatmap={heatmap}
                />
              </section>
              <section className="side__block side__fleets">
                <FleetStatus
                  title="Enemy fleet"
                  ships={state.enemyShips}
                  shots={state.shotsOnEnemy}
                  detailed={false}
                />
                <FleetStatus
                  title="Your fleet"
                  ships={state.playerShips}
                  shots={state.shotsOnPlayer}
                  detailed
                />
              </section>
              <section className="side__block side__log">
                <ShotLog log={state.log} />
              </section>
            </>
          )}
        </aside>
      </main>
      <footer className="arena-footer">
        <div className="legend">
          <span>
            <i className="legend__ship" /> Your ship
          </span>
          <span>
            <i className="legend__hit" /> Hit
          </span>
          <span>
            <i className="legend__miss" /> Miss
          </span>
          <span>
            <i className="legend__sunk" /> Sunk
          </span>
        </div>
        <p>
          FIVE SHIPS. ONE COMMANDER. <b>MAKE YOUR MOVE.</b>
        </p>
        <span>
          LOCAL PLAY <i className="connection-dot" />
        </span>
      </footer>
      {!placing && recentShot && recentShot.result !== 'sunk' ? (
        <div
          key={state.log.length}
          className={`shot-flash shot-flash--${recentShot.result}${state.announcement ? ' shot-flash--suppressed' : ''}`}
          aria-hidden="true"
        >
          <span>
            {recentShot.side === 'player' ? 'YOU' : 'ENEMY'} ·{' '}
            {coordLabel(recentShot.coord)}
          </span>
          <strong>
            {recentShot.result === 'miss' ? 'SPLASH' : 'DIRECT HIT!'}
          </strong>
        </div>
      ) : null}

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
