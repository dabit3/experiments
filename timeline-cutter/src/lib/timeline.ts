import { MIN_CLIP_DURATION, type Project, type TitleClip, type VideoClip } from '../types'
import { mediaById } from './media'
import { clamp } from './time'

let counter = 0
export const newId = (prefix: string) => `${prefix}${++counter}`

export const clipDuration = (c: VideoClip) => c.out - c.in

export interface PlacedClip {
  clip: VideoClip
  start: number
  end: number
  index: number
}

/** The video track is magnetic: clips are laid out back to back with no gaps. */
export function placeVideo(video: VideoClip[]): PlacedClip[] {
  let t = 0
  return video.map((clip, index) => {
    const start = t
    t += clipDuration(clip)
    return { clip, start, end: t, index }
  })
}

export function sequenceDuration(project: Project): number {
  const v = placeVideo(project.video)
  const videoEnd = v.length ? v[v.length - 1].end : 0
  const titleEnd = project.titles.reduce((m, t) => Math.max(m, t.start + t.duration), 0)
  return Math.max(videoEnd, titleEnd)
}

export function videoAt(project: Project, time: number): PlacedClip | null {
  const placed = placeVideo(project.video)
  return placed.find((p) => time >= p.start && time < p.end) ?? null
}

export function titleAt(project: Project, time: number): TitleClip | null {
  return project.titles.find((t) => time >= t.start && time < t.start + t.duration) ?? null
}

export function appendClip(project: Project, mediaId: string): Project {
  const m = mediaById(mediaId)
  return { ...project, video: [...project.video, { id: newId('v'), mediaId: m.id, in: 0, out: m.duration }] }
}

/**
 * Trim a clip edge. `delta` is the change in *timeline* seconds of the edge being dragged.
 * Head trims shift the source in-point, tail trims the out-point; the magnetic track ripples.
 */
export function trimClip(project: Project, id: string, edge: 'head' | 'tail', newEdgeSourceTime: number): Project {
  return {
    ...project,
    video: project.video.map((c) => {
      if (c.id !== id) return c
      const m = mediaById(c.mediaId)
      if (edge === 'head') {
        const nextIn = clamp(newEdgeSourceTime, 0, c.out - MIN_CLIP_DURATION)
        return { ...c, in: nextIn }
      }
      const nextOut = clamp(newEdgeSourceTime, c.in + MIN_CLIP_DURATION, m.duration)
      return { ...c, out: nextOut }
    }),
  }
}

export function splitAt(project: Project, time: number): Project {
  const hit = videoAt(project, time)
  if (!hit) return project
  const local = time - hit.start
  if (local < MIN_CLIP_DURATION || hit.end - time < MIN_CLIP_DURATION) return project
  const { clip } = hit
  const left: VideoClip = { ...clip, out: clip.in + local }
  const right: VideoClip = { ...clip, id: newId('v'), in: clip.in + local }
  const video = [...project.video]
  video.splice(hit.index, 1, left, right)
  return { ...project, video }
}

export function rippleDelete(project: Project, id: string): Project {
  return { ...project, video: project.video.filter((c) => c.id !== id) }
}

/** Remove `id` from the track and re-insert it at `index` among the remaining clips. */
export function reorderClip(project: Project, id: string, index: number): Project {
  const clip = project.video.find((c) => c.id === id)
  if (!clip) return project
  const video = project.video.filter((c) => c.id !== id)
  video.splice(clamp(index, 0, video.length), 0, clip)
  return { ...project, video }
}

/** Where a clip whose centre sits at `center` would be inserted among `others` (already placed without it). */
export function insertionIndex(others: PlacedClip[], center: number): number {
  return others.filter((o) => (o.start + o.end) / 2 < center).length
}

export function addTitle(project: Project, start: number, text: string, duration = 4): Project {
  return { ...project, titles: [...project.titles, { id: newId('t'), text, start: Math.max(0, start), duration }] }
}

export function updateTitle(project: Project, id: string, patch: Partial<TitleClip>): Project {
  return { ...project, titles: project.titles.map((t) => (t.id === id ? { ...t, ...patch } : t)) }
}

export function deleteTitle(project: Project, id: string): Project {
  return { ...project, titles: project.titles.filter((t) => t.id !== id) }
}

/** Times worth snapping to: clip boundaries on both tracks, sequence start, plus the playhead. */
export function snapPoints(project: Project, playhead: number, exclude: string[] = []): number[] {
  const pts = new Set<number>([0, playhead])
  for (const p of placeVideo(project.video)) {
    if (exclude.includes(p.clip.id)) continue
    pts.add(p.start)
    pts.add(p.end)
  }
  for (const t of project.titles) {
    if (exclude.includes(t.id)) continue
    pts.add(t.start)
    pts.add(t.start + t.duration)
  }
  return [...pts]
}

export interface SnapResult {
  time: number
  snapped: number | null
}

export function snapTime(time: number, points: number[], thresholdSeconds: number): SnapResult {
  let best: number | null = null
  let bestDist = thresholdSeconds
  for (const p of points) {
    const d = Math.abs(p - time)
    if (d <= bestDist) {
      bestDist = d
      best = p
    }
  }
  return best === null ? { time, snapped: null } : { time: best, snapped: best }
}
