import { APPLES_PER_SPEED_UP, DIFFICULTIES } from '../game/engine'
import type { GameState } from '../game/types'

const HEADING_ARROWS = { up: '↑', down: '↓', left: '←', right: '→' } as const

const PHASE_LABELS = { ready: 'Ready', playing: 'Playing', paused: 'Paused', over: 'Game over' } as const

function Row({ label, value, testId }: { label: string; value: string; testId: string }) {
  return (
    <div className="telemetry-row">
      <dt>{label}</dt>
      <dd data-testid={testId}>{value}</dd>
    </div>
  )
}

export function Telemetry({ state }: { state: GameState }) {
  const head = state.snake[0]
  const applesToSpeedUp = APPLES_PER_SPEED_UP - (state.score % APPLES_PER_SPEED_UP)

  return (
    <aside className="telemetry" aria-label="Game telemetry">
      <h3 className="panel-title">Telemetry</h3>
      <dl>
        <Row label="Status" value={PHASE_LABELS[state.phase]} testId="telemetry-phase" />
        <Row label="Mode" value={DIFFICULTIES[state.difficulty].label} testId="telemetry-mode" />
        <Row label="Speed" value={`${state.cellsPerSecond.toFixed(1)} cells/s`} testId="telemetry-speed" />
        <Row label="Speed up in" value={`${applesToSpeedUp} apples`} testId="telemetry-speed-up" />
        <Row label="Length" value={`${state.snake.length} cells`} testId="telemetry-length" />
        <Row label="Head" value={`(${head.x}, ${head.y})`} testId="telemetry-head" />
        <Row
          label="Heading"
          value={`${HEADING_ARROWS[state.direction]} ${state.direction}`}
          testId="telemetry-heading"
        />
        <Row label="Apple" value={`(${state.apple.x}, ${state.apple.y})`} testId="telemetry-apple" />
      </dl>

      <h3 className="panel-title">Controls</h3>
      <ul className="controls">
        <li>
          <kbd>↑</kbd>
          <kbd>↓</kbd>
          <kbd>←</kbd>
          <kbd>→</kbd> or <kbd>W</kbd>
          <kbd>A</kbd>
          <kbd>S</kbd>
          <kbd>D</kbd> steer
        </li>
        <li>
          <kbd>Space</kbd> start / restart
        </li>
        <li>
          <kbd>P</kbd> pause / resume
        </li>
        <li>
          <kbd>1</kbd>
          <kbd>2</kbd>
          <kbd>3</kbd> difficulty (on the start screen)
        </li>
      </ul>
    </aside>
  )
}
