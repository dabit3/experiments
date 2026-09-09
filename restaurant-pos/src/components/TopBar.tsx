import './TopBar.css'

export type NavView = 'floor' | 'kitchen'

interface Props {
  view: NavView
  onNavigate: (view: NavView) => void
  openTickets: number
  editLayout: boolean
  onToggleEdit: () => void
  onReset: () => void
  showEdit: boolean
}

export function TopBar({ view, onNavigate, openTickets, editLayout, onToggleEdit, onReset, showEdit }: Props) {
  return (
    <header className="topbar">
      <div className="brand">
        <span className="brand-mark" aria-hidden="true">
          <svg viewBox="0 0 24 24" width="22" height="22">
            <path
              d="M12 2c1.5 3.2 4.5 5 4.5 9.2A4.5 4.5 0 0 1 12 15.7a4.5 4.5 0 0 1-4.5-4.5C7.5 8.4 9 6.6 9.6 4.6 10.5 6 11.2 6.7 12 7c0-1.7 0-3.3 0-5Z"
              fill="currentColor"
            />
            <path d="M5 19h14M7 22h10" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
          </svg>
        </span>
        <span className="brand-name">Ember</span>
        <span className="brand-sub">POS</span>
      </div>

      <nav className="segmented nav" aria-label="Views">
        <button type="button" className={view === 'floor' ? 'active' : ''} onClick={() => onNavigate('floor')}>
          Floor plan
        </button>
        <button type="button" className={view === 'kitchen' ? 'active' : ''} onClick={() => onNavigate('kitchen')}>
          Kitchen
          {openTickets > 0 && <span className="nav-badge">{openTickets}</span>}
        </button>
      </nav>

      <div className="topbar-right">
        {showEdit && (
          <button type="button" className={editLayout ? 'btn-primary' : 'btn-ghost'} onClick={onToggleEdit}>
            {editLayout ? 'Done editing' : 'Edit layout'}
          </button>
        )}
        <button type="button" className="btn-ghost" onClick={onReset}>
          Reset demo
        </button>
        <div className="server">
          <span className="server-avatar">JM</span>
          <span>
            <strong>Jordan M.</strong>
            <br />
            <span className="muted">Dinner · Section A</span>
          </span>
        </div>
      </div>
    </header>
  )
}
