import { useMemo, useState } from 'react'
import type { TableRow } from '../data/aggregate'
import { downloadCsv } from '../utils/csv'
import { formatLongDate, formatMetric } from '../utils/format'

interface Props {
  rows: TableRow[]
}

type SortKey = keyof Omit<TableRow, 'id'>
type SortDir = 'asc' | 'desc'

const COLUMNS: Array<{ key: SortKey; label: string; numeric?: boolean }> = [
  { key: 'date', label: 'Date' },
  { key: 'region', label: 'Region' },
  { key: 'plan', label: 'Plan' },
  { key: 'signups', label: 'Signups', numeric: true },
  { key: 'revenue', label: 'Revenue', numeric: true },
  { key: 'activeUsers', label: 'Active users', numeric: true },
  { key: 'churnRate', label: 'Churn', numeric: true },
]

const PAGE_SIZE = 10

export function DataTable({ rows }: Props) {
  const [sortKey, setSortKey] = useState<SortKey>('date')
  const [sortDir, setSortDir] = useState<SortDir>('desc')
  const [query, setQuery] = useState('')
  const [requestedPage, setPage] = useState(1)

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase()
    const matched = q
      ? rows.filter(
          (r) =>
            r.date.includes(q) ||
            r.region.toLowerCase().includes(q) ||
            r.plan.toLowerCase().includes(q) ||
            formatLongDate(r.date).toLowerCase().includes(q),
        )
      : rows
    const dir = sortDir === 'asc' ? 1 : -1
    return [...matched].sort((a, b) => {
      const av = a[sortKey]
      const bv = b[sortKey]
      const cmp = typeof av === 'number' && typeof bv === 'number' ? av - bv : String(av).localeCompare(String(bv))
      return cmp * dir || a.id.localeCompare(b.id)
    })
  }, [rows, query, sortKey, sortDir])

  const pageCount = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE))
  const page = Math.min(requestedPage, pageCount)

  const pageRows = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE)

  const sortBy = (key: SortKey) => {
    if (key === sortKey) {
      setSortDir((d) => (d === 'asc' ? 'desc' : 'asc'))
    } else {
      setSortKey(key)
      setSortDir('asc')
    }
    setPage(1)
  }

  return (
    <section className="panel" data-testid="table-panel">
      <header className="panel__head">
        <div>
          <h2 className="panel__title">Daily breakdown</h2>
          <p className="panel__subtitle" data-testid="table-summary">
            {filtered.length.toLocaleString()} rows · sorted by {COLUMNS.find((c) => c.key === sortKey)?.label}{' '}
            {sortDir === 'asc' ? '↑' : '↓'}
          </p>
        </div>
        <div className="panel__actions">
          <input
            type="search"
            className="input"
            placeholder="Search date, region, plan…"
            value={query}
            onChange={(e) => {
              setQuery(e.target.value)
              setPage(1)
            }}
            data-testid="table-search"
          />
          <button
            type="button"
            className="btn btn--primary"
            onClick={() => downloadCsv(`metrics-${new Date().toISOString().slice(0, 10)}.csv`, filtered)}
            data-testid="export-csv"
          >
            Export CSV
          </button>
        </div>
      </header>

      <div className="table-wrap">
        <table className="table" data-testid="data-table">
          <thead>
            <tr>
              {COLUMNS.map((col) => {
                const active = col.key === sortKey
                return (
                  <th
                    key={col.key}
                    className={`${col.numeric ? 'num' : ''}${active ? ' sorted' : ''}`}
                    aria-sort={active ? (sortDir === 'asc' ? 'ascending' : 'descending') : 'none'}
                  >
                    <button type="button" className="th-button" onClick={() => sortBy(col.key)} data-testid={`sort-${col.key}`}>
                      {col.label}
                      <span className="sort-icon" aria-hidden="true">
                        {active ? (sortDir === 'asc' ? '↑' : '↓') : '↕'}
                      </span>
                    </button>
                  </th>
                )
              })}
            </tr>
          </thead>
          <tbody>
            {pageRows.map((row) => (
              <tr key={row.id}>
                <td>{formatLongDate(row.date)}</td>
                <td>{row.region}</td>
                <td>
                  <span className="chip">{row.plan}</span>
                </td>
                <td className="num">{formatMetric('signups', row.signups)}</td>
                <td className="num">{formatMetric('revenue', row.revenue)}</td>
                <td className="num">{formatMetric('activeUsers', row.activeUsers)}</td>
                <td className="num">{formatMetric('churnRate', row.churnRate)}</td>
              </tr>
            ))}
            {pageRows.length === 0 && (
              <tr>
                <td colSpan={COLUMNS.length} className="empty">
                  No rows match “{query}”.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <footer className="pagination">
        <span data-testid="page-info">
          Page {page} of {pageCount}
        </span>
        <div className="pagination__buttons">
          <button type="button" className="btn" disabled={page === 1} onClick={() => setPage(1)}>
            «
          </button>
          <button type="button" className="btn" disabled={page === 1} onClick={() => setPage((p) => p - 1)} data-testid="prev-page">
            Prev
          </button>
          <button
            type="button"
            className="btn"
            disabled={page === pageCount}
            onClick={() => setPage((p) => p + 1)}
            data-testid="next-page"
          >
            Next
          </button>
          <button type="button" className="btn" disabled={page === pageCount} onClick={() => setPage(pageCount)}>
            »
          </button>
        </div>
      </footer>
    </section>
  )
}
