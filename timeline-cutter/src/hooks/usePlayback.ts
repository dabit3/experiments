import { useCallback, useEffect, useRef, useState } from 'react'
import { clamp } from '../lib/time'

export type Speed = -4 | -2 | -1 | 0 | 1 | 2 | 4

/** rAF-driven playhead with J/K/L style shuttle speeds. */
export function usePlayback(duration: number) {
  const [time, setTimeState] = useState(0)
  const [speed, setSpeed] = useState<Speed>(0)
  const timeRef = useRef(0)
  const durationRef = useRef(duration)
  useEffect(() => {
    durationRef.current = duration
  }, [duration])

  const setTime = useCallback((t: number) => {
    const v = clamp(t, 0, Math.max(0, durationRef.current))
    timeRef.current = v
    setTimeState(v)
  }, [])

  useEffect(() => {
    if (speed === 0) return
    let last = performance.now()
    let raf = 0
    const tick = (now: number) => {
      const dt = (now - last) / 1000
      last = now
      const next = timeRef.current + dt * speed
      const max = Math.max(0, durationRef.current)
      if (next >= max && speed > 0) {
        timeRef.current = max
        setTimeState(max)
        setSpeed(0)
        return
      }
      if (next <= 0 && speed < 0) {
        timeRef.current = 0
        setTimeState(0)
        setSpeed(0)
        return
      }
      timeRef.current = next
      setTimeState(next)
      raf = requestAnimationFrame(tick)
    }
    raf = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(raf)
  }, [speed])

  // Keep the playhead inside the sequence when it shrinks.
  useEffect(() => {
    if (timeRef.current > duration) setTime(duration)
  }, [duration, setTime])

  const togglePlay = useCallback(() => {
    setSpeed((s) => {
      if (s !== 0) return 0
      if (timeRef.current >= durationRef.current) {
        timeRef.current = 0
        setTimeState(0)
      }
      return 1
    })
  }, [])

  const shuttle = useCallback((dir: 1 | -1) => {
    setSpeed((s) => {
      if (Math.sign(s) !== dir) return dir
      const mag = Math.abs(s)
      const next = mag >= 4 ? 4 : mag * 2
      return (dir * next) as Speed
    })
  }, [])

  const pause = useCallback(() => setSpeed(0), [])

  return { time, speed, setTime, togglePlay, shuttle, pause, isPlaying: speed !== 0 }
}
