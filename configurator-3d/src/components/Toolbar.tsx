import { VIEWS, VIEW_LABELS, type ViewId } from '../config'

interface Props {
  view: ViewId | null
  spin: boolean
  onView: (view: ViewId) => void
  onToggleSpin: () => void
}

export function Toolbar({ view, spin, onView, onToggleSpin }: Props) {
  return (
    <div className="toolbar" role="toolbar" aria-label="Camera">
      <div className="segmented" role="group" aria-label="Camera presets">
        {VIEWS.map((id, i) => (
          <button
            key={id}
            type="button"
            className={`seg ${view === id ? 'is-active' : ''}`}
            aria-pressed={view === id}
            onClick={() => onView(id)}
            title={`${VIEW_LABELS[id]} view (shortcut ${i + 1})`}
            data-testid={`view-${id}`}
          >
            {VIEW_LABELS[id]}
          </button>
        ))}
      </div>
      <button
        type="button"
        className={`toggle ${spin ? 'is-on' : ''}`}
        aria-pressed={spin}
        onClick={onToggleSpin}
        title="Toggle auto-rotate (Space)"
        data-testid="autorotate"
      >
        <span className="toggle-track" aria-hidden="true">
          <span className="toggle-knob" />
        </span>
        Auto-rotate
      </button>
    </div>
  )
}
