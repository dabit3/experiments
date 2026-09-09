import { useEffect, useRef } from 'react'
import type { MediaItem } from '../types'
import { MEDIA } from '../lib/media'
import { drawFrame } from '../lib/render'
import { fmtSeconds, timecode } from '../lib/time'
import { Icon } from './Icon'

interface Props {
  onAdd: (mediaId: string) => void
  usage: Record<string, number>
}

export function MediaBin({ onAdd, usage }: Props) {
  return (
    <aside className="panel media-bin" aria-label="Media bin">
      <header className="panel-header">
        <Icon name="film" size={16} />
        <h2>Media bin</h2>
        <span className="panel-meta">{MEDIA.length} clips</span>
      </header>
      <ul className="media-list">
        {MEDIA.map((m) => (
          <li key={m.id}>
            <MediaCard media={m} onAdd={() => onAdd(m.id)} used={usage[m.id] ?? 0} />
          </li>
        ))}
      </ul>
      <p className="panel-hint">
        <strong>Add</strong> or double-click a clip to append it to V1. Procedurally rendered — no media files.
      </p>
    </aside>
  )
}

function MediaCard({ media, onAdd, used }: { media: MediaItem; onAdd: () => void; used: number }) {
  return (
    <div className="media-card" onDoubleClick={onAdd} data-media={media.id}>
      <Thumb media={media} />
      <div className="media-info">
        <div className="media-name">
          <span className="media-reel" style={{ background: media.primary }}>{media.id}</span>
          {media.name}
        </div>
        <div className="media-sub">
          {fmtSeconds(media.duration)} · {timecode(media.duration)}
          {used > 0 && <span className="media-used"> · ×{used} on V1</span>}
        </div>
      </div>
      <button className="icon-btn add-btn" onClick={onAdd} title={`Add ${media.name} to timeline`} aria-label={`Add ${media.name} to timeline`}>
        <Icon name="plus" size={18} />
      </button>
    </div>
  )
}

function Thumb({ media }: { media: MediaItem }) {
  const ref = useRef<HTMLCanvasElement>(null)
  useEffect(() => {
    const canvas = ref.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return
    drawFrame(ctx, media, 1.25, canvas.width, canvas.height)
  }, [media])
  return <canvas ref={ref} width={160} height={90} className="media-thumb" />
}
