export type Role = 'main' | 'propulsion' | 'guidance'
export type ConsoleRole = Exclude<Role, 'main'>

export type StepId =
  | 'arm-fuel'
  | 'confirm-fuel'
  | 'target-orbit'
  | 'pressurise'
  | 'countdown'
  | 'ready-check'
  | 'launch'

export type StepOwner = Role | 'consoles'

export interface StepDef {
  id: StepId
  owner: StepOwner
  title: string
  instruction: string
}

export type LogLevel = 'info' | 'ok' | 'warn' | 'error'

export interface LogEntry {
  id: number
  met: number
  source: Role | 'system'
  level: LogLevel
  text: string
}

export interface TargetOrbit {
  altitudeKm: number
  inclinationDeg: number
}

export type Phase = 'checklist' | 'countdown' | 'aborted' | 'launched'

export interface MissionState {
  seed: string
  vehicle: string
  targetOrbit: TargetOrbit
  /** Index into STEPS. Equals STEPS.length once launched. */
  stepIndex: number
  phase: Phase
  fuelArmed: boolean
  fuelConfirmed: boolean
  orbitLocked: boolean
  orbitAttempts: number
  pressure: number
  pressurising: boolean
  countdown: number | null
  ready: Record<ConsoleRole, boolean>
  online: Record<ConsoleRole, boolean>
  altitudeKm: number
  velocityKmh: number
  met: number
  log: LogEntry[]
}

export type Command =
  | { type: 'arm-fuel' }
  | { type: 'confirm-fuel' }
  | { type: 'lock-orbit'; orbit: TargetOrbit }
  | { type: 'pressurise-start' }
  | { type: 'pressurise-stop' }
  | { type: 'start-countdown' }
  | { type: 'abort' }
  | { type: 'report-ready' }
  | { type: 'launch' }
  | { type: 'reset' }

export type InternalEvent =
  | { type: 'met-tick' }
  | { type: 'pressure-tick'; delta: number }
  | { type: 'countdown-tick' }
  | { type: 'flight-tick'; dt: number }
  | { type: 'presence'; role: ConsoleRole; online: boolean }
  | { type: 'note'; level: LogLevel; text: string }

export type Action =
  | { kind: 'command'; from: Role; command: Command }
  | { kind: 'internal'; event: InternalEvent }

/** Messages exchanged over the BroadcastChannel. */
export type BusMessage =
  | { kind: 'hello'; role: ConsoleRole }
  | { kind: 'bye'; role: ConsoleRole }
  | { kind: 'who' }
  | { kind: 'command'; from: ConsoleRole; command: Command }
  | { kind: 'state'; state: MissionState }
