import type { Project, Selection } from '../types'
import { mediaById } from '../lib/media'
import { placeVideo } from '../lib/timeline'
import { fmtSeconds, timecode } from '../lib/time'
import { Icon } from './Icon'

interface Props {
  project: Project
  selection: Selection
  playhead: number
  onSplit: () => void
  onRippleDelete: () => void
  onAddTitle: () => void
  onTitleText: (id: string, text: string) => void
}

export function Inspector({ project, selection, playhead, onSplit, onRippleDelete, onAddTitle, onTitleText }: Props) {
  const placed = placeVideo(project.video)
  const video = selection?.kind === 'video' ? placed.find((p) => p.clip.id === selection.id) : undefined
  const title = selection?.kind === 'title' ? project.titles.find((t) => t.id === selection.id) : undefined
  const videoAtHead = placed.find((p) => playhead >= p.start && playhead < p.end)

  return (
    <aside className="panel inspector" aria-label="Inspector">
      <header className="panel-header">
        <h2>Inspector</h2>
      </header>

      <div className="inspector-body">
        {video && (
          <>
            <div className="insp-title">
              <span className="media-reel" style={{ background: mediaById(video.clip.mediaId).primary }}>{mediaById(video.clip.mediaId).id}</span>
              {mediaById(video.clip.mediaId).name}
            </div>
            <dl className="insp-grid">
              <dt>Position</dt><dd>#{video.index + 1} on V1</dd>
              <dt>Duration</dt><dd>{fmtSeconds(video.end - video.start)}</dd>
              <dt>Record in</dt><dd className="mono">{timecode(video.start)}</dd>
              <dt>Record out</dt><dd className="mono">{timecode(video.end)}</dd>
              <dt>Source in</dt><dd className="mono">{timecode(video.clip.in)}</dd>
              <dt>Source out</dt><dd className="mono">{timecode(video.clip.out)}</dd>
            </dl>
          </>
        )}
        {title && (
          <>
            <div className="insp-title"><span className="title-chip">T1</span>Title</div>
            <label className="field">
              <span>Text</span>
              <input value={title.text} onChange={(e) => onTitleText(title.id, e.target.value)} data-testid="title-text" />
            </label>
            <dl className="insp-grid">
              <dt>Start</dt><dd className="mono">{timecode(title.start)}</dd>
              <dt>Duration</dt><dd>{fmtSeconds(title.duration)}</dd>
            </dl>
          </>
        )}
        {!video && !title && (
          <p className="insp-empty">
            <strong>Nothing selected.</strong> Click a clip on the timeline to inspect it. Drag the handles at either end of a clip to trim, or drag the clip body to reorder it.
          </p>
        )}
      </div>

      <div className="insp-actions">
        <button className="btn" onClick={onSplit} disabled={!videoAtHead} title="Split the clip under the playhead (S)">
          <Icon name="split" size={16} /> Split at playhead <kbd>S</kbd>
        </button>
        <button className="btn danger" onClick={onRippleDelete} disabled={!selection} title="Ripple delete the selected clip (Delete)">
          <Icon name="trash" size={16} /> Ripple delete <kbd>⌫</kbd>
        </button>
        <button className="btn" onClick={onAddTitle} title="Add a title at the playhead (T)">
          <Icon name="title" size={16} /> Add title at playhead <kbd>T</kbd>
        </button>
      </div>

      <div className="shortcuts">
        <h3>Shortcuts</h3>
        <ul>
          <li><span className="keys"><kbd>Space</kbd></span><span>Play / pause</span></li>
          <li><span className="keys"><kbd>J</kbd><kbd>K</kbd><kbd>L</kbd></span><span>Shuttle back / stop / forward</span></li>
          <li><span className="keys"><kbd>←</kbd><kbd>→</kbd></span><span>Step one frame</span></li>
          <li><span className="keys"><kbd>V</kbd><kbd>B</kbd></span><span>Select tool / razor tool</span></li>
          <li><span className="keys"><kbd>N</kbd></span><span>Toggle snapping</span></li>
          <li><span className="keys"><kbd>Ctrl</kbd><kbd>Z</kbd></span><span>Undo · add <kbd>⇧</kbd> to redo</span></li>
        </ul>
      </div>
    </aside>
  )
}
