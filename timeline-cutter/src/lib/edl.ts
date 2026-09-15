import { FPS, type Project } from '../types'
import { mediaById } from './media'
import { placeVideo, sequenceDuration } from './timeline'
import { round3, timecode } from './time'

export interface EdlEvent {
  event: number
  track: 'V1' | 'T1'
  reel: string
  name: string
  sourceIn: number
  sourceOut: number
  recordIn: number
  recordOut: number
  duration: number
  sourceInTC: string
  sourceOutTC: string
  recordInTC: string
  recordOutTC: string
}

export interface Edl {
  title: string
  fps: number
  generatedBy: string
  sequenceDuration: number
  sequenceDurationTC: string
  events: EdlEvent[]
}

export function buildEdl(project: Project, title = 'Timeline Cutter Sequence'): Edl {
  const events: EdlEvent[] = []
  let n = 1
  for (const p of placeVideo(project.video)) {
    const m = mediaById(p.clip.mediaId)
    events.push({
      event: n++,
      track: 'V1',
      reel: m.id,
      name: m.name,
      sourceIn: round3(p.clip.in),
      sourceOut: round3(p.clip.out),
      recordIn: round3(p.start),
      recordOut: round3(p.end),
      duration: round3(p.end - p.start),
      sourceInTC: timecode(p.clip.in),
      sourceOutTC: timecode(p.clip.out),
      recordInTC: timecode(p.start),
      recordOutTC: timecode(p.end),
    })
  }
  for (const t of [...project.titles].sort((a, b) => a.start - b.start)) {
    events.push({
      event: n++,
      track: 'T1',
      reel: 'TITLE',
      name: t.text,
      sourceIn: 0,
      sourceOut: round3(t.duration),
      recordIn: round3(t.start),
      recordOut: round3(t.start + t.duration),
      duration: round3(t.duration),
      sourceInTC: timecode(0),
      sourceOutTC: timecode(t.duration),
      recordInTC: timecode(t.start),
      recordOutTC: timecode(t.start + t.duration),
    })
  }
  const dur = sequenceDuration(project)
  return {
    title,
    fps: FPS,
    generatedBy: 'timeline-cutter',
    sequenceDuration: round3(dur),
    sequenceDurationTC: timecode(dur),
    events,
  }
}

export function edlToJson(edl: Edl): string {
  return JSON.stringify(edl, null, 2)
}

export function edlToCsv(edl: Edl): string {
  const header = ['event', 'track', 'reel', 'name', 'source_in', 'source_out', 'record_in', 'record_out', 'duration', 'source_in_tc', 'source_out_tc', 'record_in_tc', 'record_out_tc']
  const esc = (v: string | number) => {
    const s = String(v)
    return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s
  }
  const rows = edl.events.map((e) =>
    [e.event, e.track, e.reel, e.name, e.sourceIn, e.sourceOut, e.recordIn, e.recordOut, e.duration, e.sourceInTC, e.sourceOutTC, e.recordInTC, e.recordOutTC].map(esc).join(','),
  )
  return [header.join(','), ...rows].join('\n') + '\n'
}

export function downloadText(filename: string, text: string, mime: string) {
  const blob = new Blob([text], { type: mime })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  document.body.appendChild(a)
  a.click()
  a.remove()
  setTimeout(() => URL.revokeObjectURL(url), 1000)
}
