import { pageRange } from '../lib/catalog'

interface Props {
  page: number
  pages: number
  total: number
  onChange: (page: number) => void
}

export function Pagination({ page, pages, total, onChange }: Props) {
  const { from, to } = pageRange(page, total)
  return (
    <nav className="pagination" aria-label="Pagination">
      <span className="pagination-summary">
        Showing {from}–{to} of {total}
      </span>
      <div className="pagination-controls">
        <button type="button" className="btn btn-ghost" disabled={page <= 1} onClick={() => onChange(page - 1)}>
          ← Previous
        </button>
        {Array.from({ length: pages }, (_, i) => i + 1).map((n) => (
          <button
            type="button"
            key={n}
            className={`btn page-btn ${n === page ? 'page-btn-active' : ''}`}
            aria-current={n === page ? 'page' : undefined}
            onClick={() => onChange(n)}
          >
            {n}
          </button>
        ))}
        <button type="button" className="btn btn-ghost" disabled={page >= pages} onClick={() => onChange(page + 1)}>
          Next →
        </button>
      </div>
    </nav>
  )
}
