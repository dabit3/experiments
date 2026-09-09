import { FPS } from '../types'

export const clamp = (v: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, v))

const pad = (n: number) => String(n).padStart(2, '0')

/** HH:MM:SS:FF timecode */
export function timecode(seconds: number, fps = FPS): string {
  const s = Math.max(0, seconds)
  const totalFrames = Math.round(s * fps)
  const ff = totalFrames % fps
  const totalSeconds = Math.floor(totalFrames / fps)
  const ss = totalSeconds % 60
  const mm = Math.floor(totalSeconds / 60) % 60
  const hh = Math.floor(totalSeconds / 3600)
  return `${pad(hh)}:${pad(mm)}:${pad(ss)}:${pad(ff)}`
}

/** Short M:SS.mm form for the UI */
export function shortTime(seconds: number): string {
  const s = Math.max(0, seconds)
  const mm = Math.floor(s / 60)
  const ss = s - mm * 60
  return `${mm}:${ss.toFixed(2).padStart(5, '0')}`
}

export const fmtSeconds = (s: number) => `${s.toFixed(2)}s`

export const round3 = (n: number) => Math.round(n * 1000) / 1000
