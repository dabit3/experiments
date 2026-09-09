import { useState, type FormEvent } from 'react'
import { Control, type ControlStatus } from '../components/Control'
import { currentStep, formatOrbit } from '../lib/mission'
import { useMissionConsole } from '../lib/useMission'
import { ConsoleShell } from './ConsoleShell'

export function GuidanceConsole() {
  const { state, send, linked } = useMissionConsole('guidance')
  const step = state ? currentStep(state)?.id : undefined
  const checklist = state?.phase === 'checklist'

  const locked = !!state?.orbitLocked
  const go = !!state?.ready.guidance
  const attempts = state?.orbitAttempts ?? 0

  const orbitStatus: ControlStatus = locked ? 'done' : checklist && step === 'target-orbit' ? 'live' : 'pending'
  const readyStatus: ControlStatus = go ? 'done' : checklist && step === 'ready-check' ? 'live' : 'pending'

  const [altitude, setAltitude] = useState('')
  const [inclination, setInclination] = useState('')

  // Clear the form when Main resets the mission back to step 0.
  const stepIndex = state?.stepIndex ?? 0
  const [seenStep, setSeenStep] = useState(stepIndex)
  if (stepIndex !== seenStep) {
    setSeenStep(stepIndex)
    if (stepIndex === 0) {
      setAltitude('')
      setInclination('')
    }
  }

  const rejected = attempts > 0 && !locked
  const altitudeNum = Number(altitude)
  const inclinationNum = Number(inclination)
  const formValid =
    altitude.trim() !== '' &&
    inclination.trim() !== '' &&
    Number.isFinite(altitudeNum) &&
    Number.isFinite(inclinationNum)

  const onSubmit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    if (orbitStatus !== 'live' || !formValid) return
    send({ type: 'lock-orbit', orbit: { altitudeKm: altitudeNum, inclinationDeg: inclinationNum } })
  }

  return (
    <ConsoleShell role="guidance" state={state} linked={linked} send={send}>
      <Control
        as="form"
        onSubmit={onSubmit}
        step={3}
        title="Target orbit"
        status={orbitStatus}
        lampOn={locked}
        lampLabel={locked ? 'Locked' : 'Open'}
        lampTone="cyan"
        summary={
          locked && state
            ? `Locked · ${formatOrbit(state.targetOrbit)}`
            : 'Unlocks after Main confirms fuel arming. The flight plan is only displayed in Main.'
        }
      >
        <div className="orbit" key={attempts} data-shake={rejected ? 'true' : undefined}>
          <label className="field">
            <span className="field__label">Altitude</span>
            <span className="field__control">
              <input
                className="field__input"
                inputMode="numeric"
                placeholder="—"
                autoComplete="off"
                value={altitude}
                onChange={(e) => setAltitude(e.target.value)}
                aria-invalid={rejected || undefined}
              />
              <span className="field__unit">km</span>
            </span>
          </label>
          <label className="field">
            <span className="field__label">Inclination</span>
            <span className="field__control">
              <input
                className="field__input"
                inputMode="decimal"
                placeholder="—"
                autoComplete="off"
                value={inclination}
                onChange={(e) => setInclination(e.target.value)}
                aria-invalid={rejected || undefined}
              />
              <span className="field__unit">°</span>
            </span>
          </label>
        </div>
        <button type="submit" className="btn btn--cyan btn--lg btn--block" disabled={!formValid}>
          Lock target orbit
        </button>
        <p className={`control__hint${rejected ? ' control__hint--error' : ''}`}>
          {rejected
            ? `Rejected ${attempts === 1 ? 'once' : `${attempts} times`} — the values must match the flight plan shown in Main.`
            : 'Read the flight plan in the Main window and enter it exactly.'}
        </p>
      </Control>

      <Control
        step={6}
        title="Ready check"
        status={readyStatus}
        lampOn={go}
        lampLabel={go ? 'GO' : 'Standby'}
        summary={go ? 'Guidance is GO for launch.' : 'Unlocks after the countdown. LAUNCH needs GO from both consoles.'}
      >
        <button type="button" className="btn btn--green btn--lg btn--block" onClick={() => send({ type: 'report-ready' })}>
          Report guidance GO
        </button>
        <p className="control__hint">Main can only launch once Propulsion reports GO as well.</p>
      </Control>
    </ConsoleShell>
  )
}
