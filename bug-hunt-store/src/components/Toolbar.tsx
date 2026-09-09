import { SORT_OPTIONS, type SortKey } from '../types'
import type { CatalogQuery } from '../lib/catalog'
import { plural } from '../lib/format'

interface Props {
  query: CatalogQuery
  resultCount: number
  onChange: (patch: Partial<CatalogQuery>) => void
}

const HEADLINES: Record<CatalogQuery['category'], string> = {
  All: 'Everything',
  Audio: 'Audio',
  Wearables: 'Wearables',
  Home: 'Home',
  Outdoor: 'Outdoor',
}

export function Toolbar({ query, resultCount, onChange }: Props) {
  return (
    <div className="page-head">
      <div className="page-title">
        <h1>{query.search ? `“${query.search}”` : HEADLINES[query.category]}</h1>
        <span className="page-count">{plural(resultCount, 'item')}</span>
      </div>
      <div className="toolbar" role="group" aria-label="Refine">
        <button
          type="button"
          className={`toggle ${query.topRatedOnly ? 'toggle-on' : ''}`}
          aria-pressed={query.topRatedOnly}
          onClick={() => onChange({ topRatedOnly: !query.topRatedOnly })}
        >
          <span className="toggle-box" aria-hidden="true" />
          Rated 4 &amp; up
        </button>
        <label className="sort">
          <span>Sort by</span>
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
