import type { ReactNode } from 'react'
import { STEPS, currentStep, formatOrbit } from '../lib/mission'
import type { Command, MissionState } from '../lib/types'
import { Countdown } from './Countdown'
import { Gauge } from './Gauge'
import { Lamp } from './Lamp'
import { Rocket } from './Rocket'

interface StageProps {
  state: MissionState
  send: (command: Command) => void
}

function Waiting({ who, what }: { who: string; what: string }) {
  return (
    <div className="stage__waiting">
      <span className="stage__pulse" aria-hidden="true" />
      <div>
        <div className="caption">Waiting on {who}</div>
        <p className="stage__what">{what}</p>
      </div>
    </div>
  )
}

export function Stage({ state, send }: StageProps) {
  const step = currentStep(state)
  const launched = state.phase === 'launched'
  const engineHot = state.pressurising || state.pressure >= 100 || state.phase === 'countdown' || launched

  let content: ReactNode
  if (state.phase === 'aborted') {
    content = (
      <div className="stage__aborted" role="alert">
        <div className="stage__bigword display stage__bigword--red">Aborted</div>
        <p className="stage__what">Countdown was stopped. Reset the mission to run the sequence again.</p>
        <button type="button" className="btn btn--lg" onClick={() => send({ type: 'reset' })}>
          Reset mission
        </button>
      </div>
    )
  } else if (state.phase === 'countdown' && state.countdown !== null) {
    content = <Countdown value={state.countdown} onAbort={() => send({ type: 'abort' })} />
  } else if (launched) {
    content = (
      <div className="stage__launched">
        <div className="stage__bigword display stage__bigword--green">Lift-off</div>
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
        <button type="button" className="btn btn--ghost" onClick={() => send({ type: 'reset' })}>
          Reset mission
        </button>
      </div>
    )
  } else {
    switch (step?.id) {
      case 'arm-fuel':
        content = <Waiting who="Propulsion" what="Throw the ARM FUEL switch in the Propulsion console." />
        break
      case 'confirm-fuel':
        content = (
          <div className="stage__action">
            <Lamp on label="Fuel armed" tone="amber" />
            <p className="stage__what">Propulsion reports the fuel system is armed. Confirm to release the flight plan.</p>
            <button type="button" className="btn btn--amber btn--lg" onClick={() => send({ type: 'confirm-fuel' })}>
              Confirm fuel armed
            </button>
          </div>
        )
        break
      case 'target-orbit':
        content = (
          <div className="stage__action">
            <div className="flightplan">
              <span className="caption">Flight plan · target orbit</span>
              <div className="flightplan__values">
                <div>
                  <span className="flightplan__value mono">{state.targetOrbit.altitudeKm}</span>
                  <span className="flightplan__unit mono">km</span>
                </div>
                <span className="flightplan__times mono">×</span>
                <div>
                  <span className="flightplan__value mono">{state.targetOrbit.inclinationDeg.toFixed(1)}</span>
                  <span className="flightplan__unit mono">°</span>
                </div>
              </div>
              <span className="flightplan__note">Shown only here. Guidance must enter it exactly.</span>
            </div>
            <Waiting who="Guidance" what={`Enter ${formatOrbit(state.targetOrbit)} and lock the target.`} />
          </div>
        )
        break
      case 'pressurise':
        content = (
          <div className="stage__action stage__action--gauge">
            <Gauge value={state.pressure} label="Tank pressure" />
            <Waiting
              who="Propulsion"
              what={state.pressurising ? 'Holding… keep PRESSURISE pressed.' : 'Hold PRESSURISE for 3 seconds.'}
            />
          </div>
        )
        break
      case 'countdown':
        content = (
          <div className="stage__action">
            <Lamp on label="Tanks nominal · 100%" />
            <p className="stage__what">All pre-count items complete. Start the terminal count.</p>
            <button type="button" className="btn btn--amber btn--lg" onClick={() => send({ type: 'start-countdown' })}>
              Start countdown
            </button>
          </div>
        )
        break
      case 'ready-check':
      case 'launch': {
        const both = state.ready.propulsion && state.ready.guidance
        content = (
          <div className="stage__action">
            <div className="readyboard">
              <Lamp on={state.ready.propulsion} label="Propulsion GO" tone="amber" />
              <Lamp on={state.ready.guidance} label="Guidance GO" tone="cyan" />
            </div>
            <p className="stage__what">
              {both ? 'All consoles GO. You are clear to launch.' : 'Holding at T-0 until both consoles report GO.'}
            </p>
            <button
              type="button"
              className={`btn btn--green btn--lg launch${both ? ' launch--armed' : ''}`}
              disabled={!both}
              onClick={() => send({ type: 'launch' })}
            >
              Launch
            </button>
          </div>
        )
        break
      }
      default:
        content = null
    }
  }

  const stepNo = Math.min(state.stepIndex + 1, STEPS.length)

  return (
    <section className={`panel stage${launched ? ' stage--launched' : ''}`} aria-label="Launch stage">
      <div className="panel__head">
        <span className="panel__title">
          {launched ? 'Flight' : state.phase === 'aborted' ? 'Hold' : `Step ${stepNo} · ${step?.title ?? ''}`}
        </span>
        <span className="caption">{state.phase === 'checklist' && step ? step.instruction : ''}</span>
      </div>
      <div className="stage__body">
        <Rocket launched={launched} engineHot={engineHot} />
        <div className="stage__controls">{content}</div>
      </div>
    </section>
  )
}
