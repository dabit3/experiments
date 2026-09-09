import type {
  Action,
  ConsoleRole,
  LogLevel,
  MissionState,
  Role,
  StepDef,
  StepId,
  StepOwner,
  TargetOrbit,
} from './types'

export const DEFAULT_SEED = 'ARTEMIS-7'
export const VEHICLE = 'Kestrel IV'
export const PRESSURISE_HOLD_MS = 3000
export const COUNTDOWN_FROM = 3
export const MAX_LOG = 60

export const STEPS: StepDef[] = [
  {
    id: 'arm-fuel',
    owner: 'propulsion',
    title: 'Arm fuel',
    instruction: 'Propulsion: throw the ARM FUEL switch.',
  },
  {
    id: 'confirm-fuel',
    owner: 'main',
    title: 'Confirm fuel armed',
    instruction: 'Main: acknowledge the armed fuel system.',
  },
  {
    id: 'target-orbit',
    owner: 'guidance',
    title: 'Lock target orbit',
    instruction: 'Guidance: enter the orbit from the flight plan shown in Main.',
  },
  {
    id: 'pressurise',
    owner: 'propulsion',
    title: 'Pressurise tanks',
    instruction: 'Propulsion: hold PRESSURISE for 3 seconds while Main watches the gauge.',
  },
  {
    id: 'countdown',
    owner: 'main',
    title: 'Countdown',
    instruction: 'Main: start the 3-2-1 countdown. Do not abort.',
  },
  {
    id: 'ready-check',
    owner: 'consoles',
    title: 'Ready check',
    instruction: 'Both consoles: report GO.',
  },
  {
    id: 'launch',
    owner: 'main',
    title: 'Launch',
    instruction: 'Main: press LAUNCH.',
  },
]

export const ROLE_LABEL: Record<Role, string> = {
  main: 'Main',
  propulsion: 'Propulsion',
  guidance: 'Guidance',
}

export function ownerLabel(owner: StepOwner): string {
  return owner === 'consoles' ? 'Both consoles' : ROLE_LABEL[owner]
}

export const ROLE_SHORT: Record<Role | 'system', string> = {
  main: 'MAIN',
  propulsion: 'PROP',
  guidance: 'GUID',
  system: 'SYS',
}

export function stepIndexOf(id: StepId): number {
  return STEPS.findIndex((s) => s.id === id)
}

/** FNV-1a; small, deterministic, good enough for seeding a flight plan. */
function hash32(input: string): number {
  let h = 0x811c9dc5
  for (let i = 0; i < input.length; i++) {
    h ^= input.charCodeAt(i)
    h = Math.imul(h, 0x01000193) >>> 0
  }
  return h >>> 0
}

const INCLINATIONS = [28.5, 39.0, 45.0, 51.6, 63.4, 97.8]

export function deriveTargetOrbit(seed: string): TargetOrbit {
  const h = hash32(seed.trim().toUpperCase())
  const altitudeKm = 300 + (h % 301) // 300..600
  const inclinationDeg = INCLINATIONS[(h >>> 9) % INCLINATIONS.length]
  return { altitudeKm, inclinationDeg }
}

export function orbitMatches(a: TargetOrbit, b: TargetOrbit): boolean {
  return (
    Math.abs(a.altitudeKm - b.altitudeKm) < 0.5 &&
    Math.abs(a.inclinationDeg - b.inclinationDeg) < 0.05
  )
}

export function formatOrbit(o: TargetOrbit): string {
  return `${o.altitudeKm} km × ${o.inclinationDeg.toFixed(1)}°`
}

export function formatMet(seconds: number): string {
  const s = Math.max(0, Math.floor(seconds))
  const mm = String(Math.floor(s / 60)).padStart(2, '0')
  const ss = String(s % 60).padStart(2, '0')
  return `T+${mm}:${ss}`
}

export function initialState(seed: string, online?: Record<ConsoleRole, boolean>): MissionState {
  const base: MissionState = {
    seed,
    vehicle: VEHICLE,
    targetOrbit: deriveTargetOrbit(seed),
    stepIndex: 0,
    phase: 'checklist',
    fuelArmed: false,
    fuelConfirmed: false,
    orbitLocked: false,
    orbitAttempts: 0,
    pressure: 0,
    pressurising: false,
    countdown: null,
    ready: { propulsion: false, guidance: false },
    online: online ?? { propulsion: false, guidance: false },
    altitudeKm: 0,
    velocityKmh: 0,
    met: 0,
    log: [],
  }
  return log(base, 'system', 'info', `Mission ${seed} loaded. Vehicle ${VEHICLE} on the pad.`)
}

let logSeq = 0

function log(
  state: MissionState,
  source: Role | 'system',
  level: LogLevel,
  text: string,
): MissionState {
  const entry = { id: ++logSeq, met: state.met, source, level, text }
  const next = [...state.log, entry]
  return { ...state, log: next.length > MAX_LOG ? next.slice(next.length - MAX_LOG) : next }
}

export function currentStep(state: MissionState): StepDef | null {
  return STEPS[state.stepIndex] ?? null
}

function isStep(state: MissionState, id: StepId): boolean {
  return state.phase === 'checklist' && currentStep(state)?.id === id
}

function outOfSequence(state: MissionState, from: Role, attempted: string): MissionState {
  const step = currentStep(state)
  const expected = step ? `"${step.title}" (${ownerLabel(step.owner)})` : 'nothing'
  return log(state, from, 'warn', `${attempted} ignored — current step is ${expected}.`)
}

export function reduce(state: MissionState, action: Action): MissionState {
  if (action.kind === 'internal') return reduceInternal(state, action.event)

  const { from, command } = action
  switch (command.type) {
    case 'arm-fuel': {
      if (from !== 'propulsion' || !isStep(state, 'arm-fuel')) {
        return outOfSequence(state, from, 'Arm fuel')
      }
      return log(
        { ...state, fuelArmed: true, stepIndex: state.stepIndex + 1 },
        from,
        'ok',
        'Fuel system ARMED. Awaiting confirmation from Main.',
      )
    }
    case 'confirm-fuel': {
      if (from !== 'main' || !isStep(state, 'confirm-fuel')) {
        return outOfSequence(state, from, 'Confirm fuel')
      }
      return log(
        { ...state, fuelConfirmed: true, stepIndex: state.stepIndex + 1 },
        from,
        'ok',
        `Fuel arm confirmed. Flight plan released to Guidance.`,
      )
    }
    case 'lock-orbit': {
      if (from !== 'guidance' || !isStep(state, 'target-orbit')) {
        return outOfSequence(state, from, 'Lock orbit')
      }
      const attempts = state.orbitAttempts + 1
      if (!orbitMatches(command.orbit, state.targetOrbit)) {
        return log(
          { ...state, orbitAttempts: attempts },
          from,
          'error',
          `Target ${formatOrbit(command.orbit)} rejected — does not match the flight plan.`,
        )
      }
      return log(
        { ...state, orbitAttempts: attempts, orbitLocked: true, stepIndex: state.stepIndex + 1 },
        from,
        'ok',
        `Target orbit locked: ${formatOrbit(command.orbit)}.`,
      )
    }
    case 'pressurise-start': {
      if (from !== 'propulsion' || !isStep(state, 'pressurise')) {
        return outOfSequence(state, from, 'Pressurise')
      }
      if (state.pressurising) return state
      return log({ ...state, pressurising: true, pressure: 0 }, from, 'info', 'Pressurising tanks…')
    }
    case 'pressurise-stop': {
      if (!state.pressurising) return state
      return log(
        { ...state, pressurising: false, pressure: 0 },
        from,
        'warn',
        `Released at ${Math.round(state.pressure)}% — pressure vented. Hold for the full 3 s.`,
      )
    }
    case 'start-countdown': {
      if (from !== 'main' || !isStep(state, 'countdown')) {
        return outOfSequence(state, from, 'Start countdown')
      }
      return log(
        { ...state, phase: 'countdown', countdown: COUNTDOWN_FROM },
        from,
        'info',
        `Countdown started. T-${COUNTDOWN_FROM}. Abort is live in every window.`,
      )
    }
    case 'abort': {
      if (state.phase !== 'countdown') {
        return log(state, from, 'warn', 'Abort ignored — no countdown running.')
      }
      return log(
        { ...state, phase: 'aborted', countdown: null },
        from,
        'error',
        `ABORT commanded from ${ROLE_LABEL[from]}. Countdown stopped. Reset the mission to retry.`,
      )
    }
    case 'report-ready': {
      if (from === 'main' || !isStep(state, 'ready-check')) {
        return outOfSequence(state, from, 'Report ready')
      }
      if (state.ready[from]) return state
      const ready = { ...state.ready, [from]: true }
      const both = ready.propulsion && ready.guidance
      const next = log(
        { ...state, ready, stepIndex: both ? state.stepIndex + 1 : state.stepIndex },
        from,
        'ok',
        `${ROLE_LABEL[from]} reports GO.`,
      )
      return both
        ? log(next, 'system', 'ok', 'All consoles GO. LAUNCH is enabled in Main.')
        : next
    }
    case 'launch': {
      if (from !== 'main' || !isStep(state, 'launch')) {
        return outOfSequence(state, from, 'Launch')
      }
      return log(
        { ...state, phase: 'launched', stepIndex: STEPS.length },
        from,
        'ok',
        `LIFT-OFF. ${state.vehicle} has cleared the tower.`,
      )
    }
    case 'reset': {
      return log(initialState(state.seed, state.online), from, 'info', 'Mission reset to step 1.')
    }
  }
}

function reduceInternal(state: MissionState, event: Extract<Action, { kind: 'internal' }>['event']): MissionState {
  switch (event.type) {
    case 'met-tick':
      return { ...state, met: state.met + 1 }
    case 'pressure-tick': {
      if (!state.pressurising) return state
      const pressure = Math.min(100, state.pressure + event.delta)
      if (pressure >= 100) {
        return log(
          { ...state, pressure: 100, pressurising: false, stepIndex: state.stepIndex + 1 },
          'system',
          'ok',
          'Tanks at 100% — nominal pressure. Countdown may begin.',
        )
      }
      return { ...state, pressure }
    }
    case 'countdown-tick': {
      if (state.phase !== 'countdown' || state.countdown === null) return state
      const next = state.countdown - 1
      if (next <= 0) {
        return log(
          { ...state, phase: 'checklist', countdown: null, stepIndex: state.stepIndex + 1 },
          'system',
          'ok',
          'Countdown complete. Holding at T-0 for the ready check.',
        )
      }
      return { ...state, countdown: next }
    }
    case 'flight-tick': {
      if (state.phase !== 'launched') return state
      const velocityKmh = Math.min(27600, state.velocityKmh + 1900 * event.dt)
      const altitudeKm = state.altitudeKm + (velocityKmh / 3600) * event.dt * 3.2
      return { ...state, velocityKmh, altitudeKm }
    }
    case 'presence': {
      if (state.online[event.role] === event.online) return state
      const online = { ...state.online, [event.role]: event.online }
      return log(
        { ...state, online },
        'system',
        event.online ? 'ok' : 'warn',
        `${ROLE_LABEL[event.role]} console ${event.online ? 'linked' : 'disconnected'}.`,
      )
    }
    case 'note':
      return log(state, 'system', event.level, event.text)
  }
}
