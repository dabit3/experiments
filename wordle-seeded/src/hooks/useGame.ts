import { useCallback, useEffect, useRef, useState } from 'react'
import { evaluateGuess, hardModeViolation, type TileState } from '../lib/evaluate'
import { loadStats, recordResult, saveStats, type Stats } from '../lib/stats'
import { answerForSeed, isValidWord, MAX_GUESSES, WORD_LENGTH } from '../lib/words'

export type GameStatus = 'playing' | 'won' | 'lost'

export interface Toast {
  id: number
  message: string
  tone: 'info' | 'error' | 'success'
}

/** Per-tile flip duration and stagger; the row is fully revealed after REVEAL_TOTAL_MS. */
export const FLIP_MS = 500
export const FLIP_STAGGER_MS = 300
export const REVEAL_TOTAL_MS = FLIP_MS + FLIP_STAGGER_MS * (WORD_LENGTH - 1)
const STATS_DELAY_MS = 1400

const WIN_MESSAGES = ['Genius', 'Magnificent', 'Impressive', 'Splendid', 'Great', 'Phew']

interface UseGameOptions {
  seed: number
  hardMode: boolean
}

export function useGame({ seed, hardMode }: UseGameOptions) {
  const answer = answerForSeed(seed)
  const [guesses, setGuesses] = useState<string[]>([])
  const [evaluations, setEvaluations] = useState<TileState[][]>([])
  const [current, setCurrent] = useState('')
  const [status, setStatus] = useState<GameStatus>('playing')
  const [revealing, setRevealing] = useState(false)
  const [shakeKey, setShakeKey] = useState(0)
  const [toast, setToast] = useState<Toast | null>(null)
  const [stats, setStats] = useState<Stats>(() => loadStats())
  const [statsOpen, setStatsOpen] = useState(false)
  const toastTimer = useRef<{ id: number | null }>({ id: null })
  const timers = useRef<number[]>([])

  useEffect(() => {
    const pending = timers.current
    const toastHandle = toastTimer.current
    return () => {
      pending.forEach((t) => window.clearTimeout(t))
      if (toastHandle.id !== null) window.clearTimeout(toastHandle.id)
    }
  }, [])

  const showToast = useCallback((message: string, tone: Toast['tone'] = 'info', duration = 1800) => {
    if (toastTimer.current.id !== null) window.clearTimeout(toastTimer.current.id)
    setToast({ id: Date.now(), message, tone })
    if (duration > 0) {
      toastTimer.current.id = window.setTimeout(() => setToast(null), duration)
    }
  }, [])

  const reject = useCallback(
    (message: string) => {
      setShakeKey((k) => k + 1)
      showToast(message, 'error')
    },
    [showToast],
  )

  const submit = useCallback(() => {
    if (status !== 'playing' || revealing) return
    if (current.length < WORD_LENGTH) return reject('Not enough letters')
    if (!isValidWord(current)) return reject('Not in word list')
    if (hardMode) {
      const violation = hardModeViolation(current, guesses, evaluations)
      if (violation) return reject(violation)
    }

    const evaluation = evaluateGuess(current, answer)
    const nextGuesses = [...guesses, current]
    const nextEvaluations = [...evaluations, evaluation]
    setGuesses(nextGuesses)
    setEvaluations(nextEvaluations)
    setCurrent('')
    setShakeKey(0)
    setRevealing(true)

    const won = current === answer
    const lost = !won && nextGuesses.length >= MAX_GUESSES

    timers.current.push(
      window.setTimeout(() => {
        setRevealing(false)
        if (!won && !lost) return
        setStatus(won ? 'won' : 'lost')
        const nextStats = recordResult(stats, won, nextGuesses.length)
        setStats(nextStats)
        saveStats(nextStats)
        if (won) {
          showToast(WIN_MESSAGES[nextGuesses.length - 1], 'success', 2200)
        } else {
          showToast(`The word was ${answer.toUpperCase()}`, 'info', 4000)
        }
        timers.current.push(window.setTimeout(() => setStatsOpen(true), STATS_DELAY_MS))
      }, REVEAL_TOTAL_MS),
    )
  }, [answer, current, evaluations, guesses, hardMode, reject, revealing, showToast, stats, status])

  const addLetter = useCallback(
    (letter: string) => {
      if (status !== 'playing' || revealing) return
      setCurrent((c) => (c.length < WORD_LENGTH ? c + letter.toLowerCase() : c))
    },
    [revealing, status],
  )

  const removeLetter = useCallback(() => {
    if (status !== 'playing' || revealing) return
    setCurrent((c) => c.slice(0, -1))
  }, [revealing, status])

  const handleKey = useCallback(
    (key: string) => {
      if (key === 'Enter') submit()
      else if (key === 'Backspace') removeLetter()
      else if (/^[a-zA-Z]$/.test(key)) addLetter(key)
    },
    [addLetter, removeLetter, submit],
  )

  return {
    answer,
    guesses,
    evaluations,
    current,
    status,
    revealing,
    shakeKey,
    toast,
    stats,
    statsOpen,
    setStatsOpen,
    showToast,
    handleKey,
  }
}
