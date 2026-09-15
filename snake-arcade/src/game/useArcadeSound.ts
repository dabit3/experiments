import { useEffect, useRef, useState } from 'react'
import type { GameState } from './types'

export function useArcadeSound(state: GameState) {
  const [soundEnabled, setSoundEnabled] = useState(false)
  const context = useRef<AudioContext | null>(null)
  const previous = useRef(state)

  function toggleSound() {
    if (!soundEnabled) {
      context.current ??= new AudioContext()
      void context.current.resume()
    }
    setSoundEnabled(!soundEnabled)
  }

  useEffect(() => {
    const last = previous.current
    previous.current = state
    const audio = context.current
    if (!soundEnabled || !audio || audio.state !== 'running') return
    let notes: number[] = []
    if (state.phase === 'over' && last.phase !== 'over') notes = [220, 164, 110]
    else if (state.phase === 'playing' && (last.phase === 'ready' || last.phase === 'over'))
      notes = [330, 440, 660]
    else if (state.score > last.score)
      notes = state.score % 5 === 0 ? [523, 659, 784, 1046] : [660, 880]
    else if (state.phase !== last.phase) notes = [330]
    notes.forEach((frequency, index) => {
      const oscillator = audio.createOscillator()
      const gain = audio.createGain()
      const start = audio.currentTime + index * 0.085
      oscillator.type = 'triangle'
      oscillator.frequency.value = frequency
      gain.gain.setValueAtTime(0, start)
      gain.gain.linearRampToValueAtTime(0.12, start + 0.01)
      gain.gain.exponentialRampToValueAtTime(0.001, start + 0.16)
      oscillator.connect(gain)
      gain.connect(audio.destination)
      oscillator.start(start)
      oscillator.stop(start + 0.17)
      oscillator.onended = () => {
        oscillator.disconnect()
        gain.disconnect()
      }
    })
  }, [state, soundEnabled])

  useEffect(
    () => () => {
      void context.current?.close()
    },
    [],
  )

  return { soundEnabled, toggleSound }
}
