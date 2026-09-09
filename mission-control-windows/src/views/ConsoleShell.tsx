import type { ReactNode } from 'react'
import { Countdown } from '../components/Countdown'
import { Lamp } from '../components/Lamp'
import { StatusLog } from '../components/StatusLog'
import { WindowHeader } from '../components/WindowHeader'
import { ROLE_LABEL } from '../lib/mission'
import type { Command, ConsoleRole, MissionState } from '../lib/types'
import './console.css'

interface ConsoleShellProps {
  role: ConsoleRole
  state: MissionState | null
  linked: boolean
  send: (command: Command) => void
  children: ReactNode
}

export function ConsoleShell({ role, state, linked, send, children }: ConsoleShellProps) {
  const tone = role === 'guidance' ? 'cyan' : 'amber'
  let overlay: ReactNode = null

  if (!linked || !state) {
    overlay = (
      <div className="overlay">
        <span className="stage__pulse" aria-hidden="true" />
        <h2 className="overlay__title display">Awaiting Main window</h2>
        <p className="overlay__text">
          This console mirrors the Main window over a BroadcastChannel. Open the Main window in this
          browser (same origin) and the link will come up on its own.
        </p>
        <a className="btn btn--ghost btn--link" href="/" target="_blank" rel="noreferrer">
          Open Main ↗
        </a>
      </div>
    )
  } else if (state.phase === 'countdown' && state.countdown !== null) {
    overlay = (
      <div className="overlay overlay--count">
        <Countdown value={state.countdown} onAbort={() => send({ type: 'abort' })} compact />
      </div>
    )
  } else if (state.phase === 'aborted') {
    overlay = (
      <div className="overlay overlay--aborted" role="alert">
        <h2 className="overlay__word display">Aborted</h2>
        <p className="overlay__text">Countdown stopped. Reset the mission from the Main window.</p>
      </div>
    )
  } else if (state.phase === 'launched') {
    overlay = (
      <div className="overlay overlay--launched" role="status">
        <h2 className="overlay__word display">Launched</h2>
        <div className="telemetry">
          <div className="telemetry__item">
            <span className="caption">Altitude</span>
            <span className="telemetry__value mono">{state.altitudeKm.toFixed(1)} km</span>
          </div>
          <div className="telemetry__item">
            <span className="caption">Velocity</span>
            <span className="telemetry__value mono">{Math.round(state.velocityKmh).toLocaleString()} km/h</span>
          </div>
        </div>
        <p className="overlay__text">Synced from Main. {ROLE_LABEL[role]} console standing down.</p>
      </div>
    )
  }

  return (
    <div className={`console console--${role}`}>
      <WindowHeader role={role} title={`${ROLE_LABEL[role]} console`} state={state}>
        <Lamp on={linked} label={linked ? 'Linked to Main' : 'No link'} tone={tone} />
      </WindowHeader>
      <div className="console__body">
        <div className="console__main">
          <div className="console__controls">{children}</div>
          {overlay}
        </div>
        <StatusLog entries={state?.log ?? []} />
      </div>
    </div>
  )
}
