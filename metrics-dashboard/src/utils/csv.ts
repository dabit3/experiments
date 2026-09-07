import type { TableRow } from '../data/aggregate'

const HEADERS: Array<[keyof TableRow, string]> = [
  ['date', 'Date'],
  ['region', 'Region'],
  ['plan', 'Plan'],
  ['signups', 'Signups'],
  ['revenue', 'Revenue (USD)'],
  ['activeUsers', 'Active users'],
  ['churnRate', 'Churn rate'],
]

function escapeCell(value: string | number): string {
  const s = typeof value === 'number' ? String(value) : value
  return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s
}

export function rowsToCsv(rows: TableRow[]): string {
  const lines = [HEADERS.map(([, label]) => label).join(',')]
  for (const row of rows) {
    lines.push(
      HEADERS.map(([key]) => {
        const v = row[key]
        return escapeCell(key === 'churnRate' ? (Number(v) * 100).toFixed(2) + '%' : v)
      }).join(','),
    )
  }
  return lines.join('\n')
}

export function downloadCsv(filename: string, rows: TableRow[]): void {
  const blob = new Blob([rowsToCsv(rows)], { type: 'text/csv;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  document.body.appendChild(a)
  a.click()
  a.remove()
  URL.revokeObjectURL(url)
}
