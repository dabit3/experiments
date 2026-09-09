import { useCallback, useEffect, useReducer, useRef, useState } from 'react'
import { createBus, type Bus } from './bus'
import { PRESSURISE_HOLD_MS, initialState, reduce } from './mission'
import type { BusMessage, Command, ConsoleRole, MissionState, Role } from './types'

const PRESSURE_TICK_MS = 50
const FLIGHT_TICK_MS = 100
const FLIGHT_DURATION_MS = 14000
const LINK_TIMEOUT_MS = 3500

/**
 * The Main window is the single authority: it owns the reducer, runs every
 * timer, and broadcasts the full state after each change. Popups send
 * commands and render whatever comes back, so all three windows can never
 * disagree about where the launch sequence is.
 */
export function useMissionAuthority(seed: string) {
  const [state, dispatch] = useReducer(reduce, seed, (s) => initialState(s))
  const bus = useRef<Bus | null>(null)
  const latest = useRef(state)

  const send = useCallback(
    (command: Command, from: Role = 'main') => dispatch({ kind: 'command', from, command }),
    [],
  )

  useEffect(() => {
    const channel = createBus()
    bus.current = channel
    const unsubscribe = channel.subscribe((message: BusMessage) => {
      switch (message.kind) {
        case 'hello':
          dispatch({ kind: 'internal', event: { type: 'presence', role: message.role, online: true } })
          channel.post({ kind: 'state', state: latest.current })
          break
        case 'bye':
          dispatch({ kind: 'internal', event: { type: 'presence', role: message.role, online: false } })
          break
        case 'command':
          dispatch({ kind: 'command', from: message.from, command: message.command })
          break
        case 'who':
        case 'state':
          break
      }
    })
    channel.post({ kind: 'who' })
    return () => {
      unsubscribe()
      channel.close()
      bus.current = null
    }
  }, [])

  useEffect(() => {
    latest.current = state
    bus.current?.post({ kind: 'state', state })
  }, [state])

  useEffect(() => {
    const id = window.setInterval(
      () => dispatch({ kind: 'internal', event: { type: 'met-tick' } }),
      1000,
    )
    return () => window.clearInterval(id)
  }, [])

  useEffect(() => {
    if (!state.pressurising) return
    const delta = (100 * PRESSURE_TICK_MS) / PRESSURISE_HOLD_MS
    const id = window.setInterval(
      () => dispatch({ kind: 'internal', event: { type: 'pressure-tick', delta } }),
      PRESSURE_TICK_MS,
    )
    return () => window.clearInterval(id)
  }, [state.pressurising])

  useEffect(() => {
    if (state.phase !== 'countdown') return
    const id = window.setInterval(
      () => dispatch({ kind: 'internal', event: { type: 'countdown-tick' } }),
      1000,
    )
    return () => window.clearInterval(id)
  }, [state.phase])

  useEffect(() => {
    if (state.phase !== 'launched') return
    const started = performance.now()
    const id = window.setInterval(() => {
      if (performance.now() - started > FLIGHT_DURATION_MS) {
        window.clearInterval(id)
        return
      }
      dispatch({ kind: 'internal', event: { type: 'flight-tick', dt: FLIGHT_TICK_MS / 1000 } })
    }, FLIGHT_TICK_MS)
    return () => window.clearInterval(id)
  }, [state.phase])

  const setPresence = useCallback((role: ConsoleRole, online: boolean) => {
    dispatch({ kind: 'internal', event: { type: 'presence', role, online } })
  }, [])

  const note = useCallback((text: string, level: 'info' | 'warn' | 'error' | 'ok' = 'info') => {
    dispatch({ kind: 'internal', event: { type: 'note', level, text } })
  }, [])

  return { state, send, setPresence, note }
}

/**
 * Popup consoles are thin clients: announce themselves, mirror the state the
 * Main window broadcasts, and send commands back over the same channel.
 */
export function useMissionConsole(role: ConsoleRole) {
  const [state, setState] = useState<MissionState | null>(null)
  const [linked, setLinked] = useState(false)
  const lastSeen = useRef(0)
  const bus = useRef<Bus | null>(null)

  useEffect(() => {
    const channel = createBus()
    bus.current = channel
    const unsubscribe = channel.subscribe((message: BusMessage) => {
      if (message.kind === 'state') {
        setState(message.state)
        lastSeen.current = Date.now()
        setLinked(true)
      } else if (message.kind === 'who') {
        channel.post({ kind: 'hello', role })
      }
    })
    channel.post({ kind: 'hello', role })
    const onHide = () => channel.post({ kind: 'bye', role })
    window.addEventListener('pagehide', onHide)
    // Main broadcasts at least once a second (mission clock); silence means it is gone.
    const watchdog = window.setInterval(
      () => setLinked(Date.now() - lastSeen.current < LINK_TIMEOUT_MS),
      1000,
    )
    return () => {
      window.removeEventListener('pagehide', onHide)
      window.clearInterval(watchdog)
      unsubscribe()
      channel.close()
      bus.current = null
    }
  }, [role])

  const send = useCallback(
    (command: Command) => bus.current?.post({ kind: 'command', from: role, command }),
    [role],
  )

  return { state, send, linked }
}

