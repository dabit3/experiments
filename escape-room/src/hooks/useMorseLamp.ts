import { useEffect, useState } from 'react'
import { MORSE_UNIT, morseFrames } from '../game'

export interface Pulse {
  on: boolean
  units: number
}

export interface LampSignal {
  on: boolean
  /** The phases emitted so far (most recent last), so a full cycle can be read back like a paper tape. */
  tape: Pulse[]
}

const TAPE_LENGTH = 40

/** Blinks `word` in Morse on a loop while `active`. */
export function useMorseLamp(word: string, active: boolean): LampSignal {
  const [signal, setSignal] = useState<LampSignal>({ on: false, tape: [] })

  useEffect(() => {
    if (!active) return
    const frames = morseFrames(word)
    let index = 0
    let timer = 0
    const step = () => {
      const frame = frames[index]
      setSignal((prev) => ({
        on: frame.on,
        tape: [...prev.tape, { on: frame.on, units: Math.round(frame.ms / MORSE_UNIT) }].slice(-TAPE_LENGTH),
      }))
      index = (index + 1) % frames.length
      timer = window.setTimeout(step, frame.ms)
    }
    timer = window.setTimeout(step, 1200)
    return () => {
      window.clearTimeout(timer)
      setSignal({ on: false, tape: [] })
    }
  }, [word, active])

  return active ? signal : { on: false, tape: [] }
}
