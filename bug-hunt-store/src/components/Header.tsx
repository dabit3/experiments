import { TOTAL_BUGS } from '../types'

interface Props {
  search: string
  cartCount: number
  bugsFound: number
  onSearch: (value: string) => void
  onOpenCart: () => void
  onOpenScoreboard: () => void
}

export function Header({ search, cartCount, bugsFound, onSearch, onOpenCart, onOpenScoreboard }: Props) {
  return (
    <header className="header">
      <a className="brand" href="#" onClick={(e) => e.preventDefault()}>
        <span className="brand-mark" aria-hidden="true" />
        Kestrel Supply
      </a>
      <div className="search">
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path
            d="M10.5 3a7.5 7.5 0 0 1 5.96 12.05l4.25 4.24-1.42 1.42-4.24-4.25A7.5 7.5 0 1 1 10.5 3Zm0 2a5.5 5.5 0 1 0 0 11 5.5 5.5 0 0 0 0-11Z"
            fill="currentColor"
          />
        </svg>
        <input
          type="search"
          placeholder="Search products"
          value={search}
          onChange={(e) => onSearch(e.target.value)}
          aria-label="Search products"
        />
      </div>
      <div className="header-actions">
        <button type="button" className="scoreboard" onClick={onOpenScoreboard} aria-label="Open bug scoreboard">
          <span className="scoreboard-label">Bugs found</span>
          <span className="scoreboard-count">
            {bugsFound}/{TOTAL_BUGS}
          </span>
          <span className="pips" aria-hidden="true">
            {Array.from({ length: TOTAL_BUGS }, (_, i) => (
              <span key={i} className={`pip ${i < bugsFound ? 'pip-on' : ''}`} />
            ))}
          </span>
        </button>
        <button type="button" className="btn btn-cart" onClick={onOpenCart} aria-label={`Open cart, ${cartCount} items`}>
          <svg viewBox="0 0 24 24" aria-hidden="true">
            <path
              d="M3 3h2.4l.6 3H21l-2.2 8H7.6l.4 2h10v2H6.4L4 5H3V3Zm5.2 10h9.1l1.1-4H7.4l.8 4ZM8 19a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3Zm9 0a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3Z"
              fill="currentColor"
            />
          </svg>
          Cart
          {cartCount > 0 && <span className="badge">{cartCount}</span>}
        </button>
      </div>
    </header>
  )
}
