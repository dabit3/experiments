import { CATEGORIES, SORT_OPTIONS, type Category, type SortKey } from '../types'
import type { CatalogQuery } from '../lib/catalog'
import { plural } from '../lib/format'

interface Props {
  query: CatalogQuery
  resultCount: number
  onChange: (patch: Partial<CatalogQuery>) => void
}

export function Toolbar({ query, resultCount, onChange }: Props) {
  const categories: (Category | 'All')[] = ['All', ...CATEGORIES]
  return (
    <div className="toolbar">
      <div className="chips" role="group" aria-label="Category">
        {categories.map((c) => (
          <button
            type="button"
            key={c}
            className={`chip chip-btn ${query.category === c ? 'chip-active' : ''}`}
            aria-pressed={query.category === c}
            onClick={() => onChange({ category: c })}
          >
            {c}
          </button>
        ))}
        <button
          type="button"
          className={`chip chip-btn ${query.topRatedOnly ? 'chip-active' : ''}`}
          aria-pressed={query.topRatedOnly}
          onClick={() => onChange({ topRatedOnly: !query.topRatedOnly })}
        >
          ★ 4 &amp; up
        </button>
      </div>
      <div className="toolbar-right">
        <span className="muted">{plural(resultCount, 'product')}</span>
        <label className="select-wrap">
          <span className="muted">Sort</span>
          <select value={query.sort} onChange={(e) => onChange({ sort: e.target.value as SortKey })}>
            {SORT_OPTIONS.map((o) => (
              <option key={o.value} value={o.value}>
                {o.label}
              </option>
            ))}
          </select>
        </label>
      </div>
    </div>
  )
}
