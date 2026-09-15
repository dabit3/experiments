import { useEffect, useRef, useState } from 'react'
import type { MediaItem } from '../types'
import { MEDIA } from '../lib/media'
import { drawFrame } from '../lib/render'
import { timecode } from '../lib/time'
import { Icon } from './Icon'

interface Props {
  onAdd: (mediaId: string) => void
  usage: Record<string, number>
}

export function MediaBin({ onAdd, usage }: Props) {
  const [query, setQuery] = useState('')
  const [view, setView] = useState<'grid' | 'list'>('grid')
  const filtered = MEDIA.filter((media) => `${media.name} ${media.id}`.toLowerCase().includes(query.trim().toLowerCase()))
  return (
    <aside className="panel media-bin" aria-label="Media bin">
      <header className="panel-header">
        <h2>Project media</h2>
        <span className="panel-meta">{MEDIA.length} assets</span>
      </header>
      <div className="media-tools">
        <label className="media-search"><Icon name="search" size={15} /><input type="search" placeholder="Search media" aria-label="Search media" value={query} onChange={(e) => setQuery(e.target.value)} /></label>
        <div className="bin-breadcrumb"><span><Icon name="folder" size={14} /> Generated collection</span><span className="count-badge">06</span></div>
      </div>
      <ul className={`media-list ${view}`}>
        {filtered.map((m) => (
          <li key={m.id}>
            <MediaCard media={m} onAdd={() => onAdd(m.id)} used={usage[m.id] ?? 0} />
          </li>
        ))}
        {filtered.length === 0 && <li className="media-no-results">No clips match “{query}”.<button onClick={() => setQuery('')}>Clear search</button></li>}
      </ul>
      <footer className="media-footer">
        <div className="view-switch" role="group" aria-label="Media view">
          <button className={`icon-btn ${view === 'grid' ? 'active' : ''}`} onClick={() => setView('grid')} aria-label="Grid view" aria-pressed={view === 'grid'}><Icon name="grid" size={15} /></button>
          <button className={`icon-btn ${view === 'list' ? 'active' : ''}`} onClick={() => setView('list')} aria-label="List view" aria-pressed={view === 'list'}><Icon name="list" size={16} /></button>
        </div>
        <span>{filtered.length} clips<span className="footer-divider">/</span>Procedural media</span>
      </footer>
    </aside>
  )
}

function MediaCard({ media, onAdd, used }: { media: MediaItem; onAdd: () => void; used: number }) {
  return (
    <div className={`media-card ${used ? 'used' : ''}`} onDoubleClick={onAdd} data-media={media.id}>
      <div className="thumb-wrap">
        <Thumb media={media} />
        <span className="thumb-reel">{media.id}</span>
        <span className="thumb-duration">{timecode(media.duration)}</span>
        {used > 0 && <span className="media-used" title={`${used} uses on V1`}>V1 · {used}</span>}
      </div>
      <div className="media-info">
        <div className="media-name">
          {media.name}
        </div>
        <div className="media-sub">
          <span className="asset-dot" style={{ background: media.primary }} /> 1280 × 720 <span>30 fps</span>
        </div>
      </div>
      <button className="icon-btn add-btn" onClick={onAdd} onDoubleClick={(e) => e.stopPropagation()} title={`Add ${media.name} to timeline`} aria-label={`Add ${media.name} to timeline`}>
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
    drawFrame(ctx, media, 1.25, canvas.width, canvas.height, false)
  }, [media])
  return <canvas ref={ref} width={320} height={180} className="media-thumb" />
}
