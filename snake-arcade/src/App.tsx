import { GameCanvas } from './components/GameCanvas'
import { Overlay } from './components/Overlay'
import { Telemetry } from './components/Telemetry'
import { useSnakeGame } from './game/useSnakeGame'

function App() {
  const { state, setDifficulty } = useSnakeGame()

  return (
    <div className="arcade">
      <header className="marquee">
        <div className="brand">
          <span className="brand-badge">Devin's turn</span>
          <span className="brand-sub">computer-use showcase</span>
        </div>
        <h1 className="title">Snake Arcade</h1>
      </header>

      <main className="cabinet">
        <section className="screen">
          <div className="hud">
            <div className="hud-stat">
              <span className="hud-label">Score</span>
              <span className="hud-value" data-testid="score">
                {state.score}
              </span>
            </div>
            <div className="hud-stat is-right">
              <span className="hud-label">High score</span>
              <span className="hud-value" data-testid="high-score">
                {state.highScore}
              </span>
            </div>
          </div>

          <div className="board" data-phase={state.phase}>
            <GameCanvas state={state} />
            <Overlay state={state} onSelectDifficulty={setDifficulty} />
          </div>
        </section>

        <Telemetry state={state} />
      </main>
    </div>
  )
}

export default App
