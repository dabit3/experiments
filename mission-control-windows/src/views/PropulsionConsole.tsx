import { Control, type ControlStatus } from '../components/Control'
import { HoldButton } from '../components/HoldButton'
import { currentStep } from '../lib/mission'
import { useMissionConsole } from '../lib/useMission'
import { ConsoleShell } from './ConsoleShell'

export function PropulsionConsole() {
  const { state, send, linked } = useMissionConsole('propulsion')
  const step = state ? currentStep(state)?.id : undefined
  const checklist = state?.phase === 'checklist'

  const fuelArmed = !!state?.fuelArmed
  const pressure = state?.pressure ?? 0
  const go = !!state?.ready.propulsion

  const fuelStatus: ControlStatus = fuelArmed ? 'done' : checklist && step === 'arm-fuel' ? 'live' : 'pending'
  const pressureStatus: ControlStatus =
    pressure >= 100 ? 'done' : checklist && step === 'pressurise' ? 'live' : 'pending'
  const readyStatus: ControlStatus = go ? 'done' : checklist && step === 'ready-check' ? 'live' : 'pending'

  return (
    <ConsoleShell role="propulsion" state={state} linked={linked} send={send}>
      <Control
        step={1}
        title="Fuel system"
        status={fuelStatus}
        lampOn={fuelArmed}
        lampLabel={fuelArmed ? 'Armed' : 'Safe'}
        lampTone="amber"
        summary={
          fuelArmed
            ? state?.fuelConfirmed
              ? 'Armed and confirmed by Main.'
              : 'Armed. Waiting for Main to confirm.'
            : 'First item on the checklist.'
        }
      >
        <button type="button" className="btn btn--amber btn--lg btn--block" onClick={() => send({ type: 'arm-fuel' })}>
          Arm fuel
        </button>
        <p className="control__hint">Throws the fuel system to ARMED. Main must confirm before Guidance can proceed.</p>
      </Control>

      <Control
        step={4}
        title="Tank pressure"
        status={pressureStatus}
        lampOn={pressure >= 100}
        lampLabel={pressure >= 100 ? 'Nominal' : 'Vented'}
        summary={pressure >= 100 ? 'Tanks at 100%. Nominal.' : 'Unlocks after Guidance locks the target orbit.'}
      >
        <HoldButton
          label="Pressurise"
          hint={state?.pressurising ? 'Holding… keep the button pressed.' : 'Press and hold for 3 seconds. Main shows the live gauge.'}
          progress={pressure}
          active={!!state?.pressurising}
          onHoldStart={() => send({ type: 'pressurise-start' })}
          onHoldEnd={() => send({ type: 'pressurise-stop' })}
        />
      </Control>

      <Control
        step={6}
        title="Ready check"
        status={readyStatus}
        lampOn={go}
        lampLabel={go ? 'GO' : 'Standby'}
        summary={go ? 'Propulsion is GO for launch.' : 'Unlocks after the countdown. LAUNCH needs GO from both consoles.'}
      >
        <button type="button" className="btn btn--green btn--lg btn--block" onClick={() => send({ type: 'report-ready' })}>
          Report propulsion GO
        </button>
        <p className="control__hint">Main can only launch once Guidance reports GO as well.</p>
      </Control>
    </ConsoleShell>
  )
}
