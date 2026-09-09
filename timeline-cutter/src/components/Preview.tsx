import { useEffect, useRef } from 'react'
import type { Project } from '../types'
import { mediaById } from '../lib/media'
import { drawEmpty, drawFrame, drawTitleOverlay } from '../lib/render'
import { titleAt, videoAt } from '../lib/timeline'
import { timecode } from '../lib/time'

interface Props {
  project: Project
  time: number
  speed: number
}

const W = 1280
const H = 720

export function Preview({ project, time, speed }: Props) {
  const ref = useRef<HTMLCanvasElement>(null)
  const hit = videoAt(project, time)
  const title = titleAt(project, time)

  useEffect(() => {
    const canvas = ref.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return
    if (hit) {
      const media = mediaById(hit.clip.mediaId)
      drawFrame(ctx, media, hit.clip.in + (time - hit.start), W, H)
    } else {
      drawEmpty(ctx, W, H)
    }
    if (title) {
      drawTitleOverlay(ctx, title.text, (time - title.start) / title.duration, title.duration, W, H)
    }
  }, [hit, title, time])

  const media = hit ? mediaById(hit.clip.mediaId) : null

  return (
    <section className="panel preview" aria-label="Program monitor">
      <header className="panel-header">
        <h2>Program</h2>
        <span className="panel-meta">1280×720 · 30 fps</span>
        {speed !== 0 && (
          <span className={`speed-badge ${speed < 0 ? 'rev' : ''}`}>
            {speed < 0 ? '◀' : '▶'} {Math.abs(speed)}×
          </span>
        )}
      </header>
      <div className="preview-stage">
        <canvas ref={ref} width={W} height={H} className="preview-canvas" />
      </div>
      <footer className="preview-footer">
        <span className="tc-big" data-testid="playhead-tc">{timecode(time)}</span>
        <span className="preview-clip">
          {media ? (
            <>
              <span className="media-reel" style={{ background: media.primary }}>{media.id}</span>
              {media.name}
              <span className="dim"> · src {timecode(hit!.clip.in + (time - hit!.start))}</span>
            </>
          ) : (
            <span className="dim">—</span>
          )}
          {title && <span className="title-chip">T · {title.text}</span>}
        </span>
      </footer>
    </section>
  )
}
