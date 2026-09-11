import { useCallback, useState } from 'react'

export interface LevelResult {
  bestMoves: number
  bestPushes: number
  stars: 1 | 2 | 3
}

export type Progress = Record<number, LevelResult>

const STORAGE_KEY = 'sokoban-depot:progress:v1'

function load(): Progress {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return {}
    const parsed: unknown = JSON.parse(raw)
    if (typeof parsed !== 'object' || parsed === null) return {}
    return parsed as Progress
  } catch {
    return {}
  }
}

function save(progress: Progress) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(progress))
  } catch {
    // Storage may be unavailable (private mode, quota); progress is then session-only.
  }
}

export function useProgress() {
  const [progress, setProgress] = useState<Progress>(load)

  const record = useCallback((levelId: number, result: LevelResult) => {
    setProgress((prev) => {
      const existing = prev[levelId]
      const next: Progress = {
        ...prev,
        [levelId]: existing
          ? {
              bestMoves: Math.min(existing.bestMoves, result.bestMoves),
              bestPushes: Math.min(existing.bestPushes, result.bestPushes),
              stars: Math.max(existing.stars, result.stars) as 1 | 2 | 3,
            }
          : result,
      }
      save(next)
      return next
    })
  }, [])

  const reset = useCallback(() => {
    save({})
    setProgress({})
  }, [])

  return { progress, record, reset }
}

/** A level is playable once the previous one has been completed. */
export function isUnlocked(progress: Progress, levelId: number): boolean {
  return levelId === 1 || progress[levelId - 1] !== undefined
}
