import { Logo } from './Logo'
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
      <div className="topbar-left">
        <Logo />
        <span className="topbar-divider" aria-hidden="true" />
        <div className="location">
          <span className="location-name">Mercer Street</span>
          <span className="location-meta">New York · Dining room</span>
        </div>
      </div>

      <nav className="segmented nav" aria-label="Views">
        <button type="button" className={view === 'floor' ? 'active' : ''} onClick={() => onNavigate('floor')}>
          <svg viewBox="0 0 16 16" width="15" height="15" aria-hidden="true">
            <rect x="1.5" y="1.5" width="5" height="5" rx="1.2" fill="none" stroke="currentColor" strokeWidth="1.5" />
            <rect x="9.5" y="1.5" width="5" height="5" rx="1.2" fill="none" stroke="currentColor" strokeWidth="1.5" />
            <rect x="1.5" y="9.5" width="5" height="5" rx="1.2" fill="none" stroke="currentColor" strokeWidth="1.5" />
            <rect x="9.5" y="9.5" width="5" height="5" rx="1.2" fill="none" stroke="currentColor" strokeWidth="1.5" />
          </svg>
          Floor plan
        </button>
        <button type="button" className={view === 'kitchen' ? 'active' : ''} onClick={() => onNavigate('kitchen')}>
          <svg viewBox="0 0 16 16" width="15" height="15" aria-hidden="true">
            <path
              d="M3 2.5h10a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1v-9a1 1 0 0 1 1-1Z"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.5"
            />
            <path d="M5 6h6M5 9h4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
          </svg>
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
        <span className="topbar-divider" aria-hidden="true" />
        <div className="server">
          <span className="server-avatar">JM</span>
          <span className="server-text">
            <strong>Jordan Miles</strong>
            <span className="muted">Dining room captain</span>
          </span>
        </div>
      </div>
    </header>
  )
}
