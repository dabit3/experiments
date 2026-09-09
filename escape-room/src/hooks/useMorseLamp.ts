import { useEffect, useState } from 'react'
import { morseFrames } from '../game'

/** Blinks `word` in Morse on a loop while `active`; returns whether the lamp is currently lit. */
export function useMorseLamp(word: string, active: boolean): boolean {
  const [on, setOn] = useState(false)

  useEffect(() => {
    if (!active) return
    const frames = morseFrames(word)
    let index = 0
    let timer = 0
    const step = () => {
      const frame = frames[index]
      setOn(frame.on)
      index = (index + 1) % frames.length
      timer = window.setTimeout(step, frame.ms)
    }
    timer = window.setTimeout(step, 1200)
    return () => {
      window.clearTimeout(timer)
      setOn(false)
    }
  }, [word, active])

  return active && on
}
