import { CATEGORIES, TOTAL_BUGS, type Category } from '../types'
import { Wordmark } from './Wordmark'

interface Props {
  search: string
  category: Category | 'All'
  cartCount: number
  bugsFound: number
  onCategory: (category: Category | 'All') => void
  onSearch: (value: string) => void
  onOpenCart: () => void
  onOpenScoreboard: () => void
}

export function Header({
  search,
  category,
  cartCount,
  bugsFound,
  onCategory,
  onSearch,
  onOpenCart,
  onOpenScoreboard,
}: Props) {
  const categories: (Category | 'All')[] = ['All', ...CATEGORIES]
  return (
    <header className="header">
      <nav className="nav" aria-label="Departments">
        {categories.map((c) => (
          <button
            type="button"
            key={c}
            className={`nav-link ${category === c ? 'nav-link-active' : ''}`}
            aria-pressed={category === c}
            onClick={() => onCategory(c)}
          >
            {c === 'All' ? 'Everything' : c}
          </button>
        ))}
      </nav>

      <a className="brand" href="#" onClick={(e) => e.preventDefault()} aria-label="Kestrel home">
        <Wordmark />
      </a>

      <div className="header-actions">
        <label className="search">
          <svg viewBox="0 0 24 24" aria-hidden="true">
            <circle cx="10.5" cy="10.5" r="6.5" fill="none" stroke="currentColor" strokeWidth="1.6" />
            <path d="m15.5 15.5 5 5" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
          </svg>
          <input
            type="search"
            placeholder="Search"
            value={search}
            onChange={(e) => onSearch(e.target.value)}
            aria-label="Search products"
          />
        </label>

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

        <button type="button" className="cart-link" onClick={onOpenCart} aria-label={`Open shopping bag, ${cartCount} items`}>
          Bag
          <span className="cart-count">({cartCount})</span>
        </button>
      </div>
    </header>
  )
}
