import { useEffect, useRef, useState } from 'react'
import type { Project } from '../types'
import { mediaById } from '../lib/media'
import { drawEmpty, drawFrame, drawTitleOverlay } from '../lib/render'
import { titleAt, videoAt } from '../lib/timeline'
import { timecode } from '../lib/time'
import { Transport, type TransportProps } from './Transport'
import { Icon } from './Icon'

interface Props extends TransportProps {
  project: Project
  time: number
  duration: number
}

const W = 1280
const H = 720

export function Preview({ project, time, duration, ...transport }: Props) {
  const ref = useRef<HTMLCanvasElement>(null)
  const [guides, setGuides] = useState(false)
  const { speed } = transport
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
        <h2>Program monitor</h2><span className="panel-subtitle">Sequence 01</span>
        {speed !== 0 && (
          <span className={`speed-badge ${speed < 0 ? 'rev' : ''}`}>
            {speed < 0 ? '◀' : '▶'} {Math.abs(speed)}×
          </span>
        )}
        <span className="panel-meta">
          <span className={`live-dot ${speed !== 0 ? 'on' : ''}`}>{speed !== 0 ? 'PLAYING' : 'PAUSED'}</span>
        </span>
      </header>
      <div className="monitor-info">
        <span><i className="status-dot" />1280 × 720 <span className="dim">/ 30 fps</span></span>
        <span>CANVAS · sRGB</span>
      </div>
      <div className="preview-stage">
        <div className="frame-container">
          <canvas ref={ref} width={W} height={H} className="preview-canvas" />
          {guides && <div className="safe-guides" aria-hidden="true"><span /></div>}
          {!hit && !title && <div className="monitor-empty"><Icon name="film" size={28} /><strong>{project.video.length ? 'End of sequence' : 'Your story starts here'}</strong><span>{project.video.length ? 'Scrub back to continue editing.' : 'Add a clip from Project media to begin.'}</span></div>}
        </div>
      </div>
      <div className="preview-footer">
        <span className="tc-big" data-testid="playhead-tc">{timecode(time)}</span>
        <span className="preview-clip">{media?.name ?? 'No active clip'}{title && <span className="title-chip">T1</span>}</span>
        <span className="duration-code mono">{timecode(duration)}</span>
      </div>
      <div className="monitor-controls">
        <span className="monitor-scale">Fit</span>
        <Transport {...transport} />
        <button className={`icon-btn ${guides ? 'active' : ''}`} onClick={() => setGuides(!guides)} aria-label="Toggle safe margins" aria-pressed={guides} title="Toggle safe margins"><Icon name="guides" size={18} /></button>
      </div>
      <footer className="monitor-status">
        <span><kbd>J</kbd><kbd>K</kbd><kbd>L</kbd> Shuttle playback</span>
        <span><kbd>Space</kbd> Play / pause</span>
      </footer>
    </section>
  )
}
