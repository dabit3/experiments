import { useRef, useState, type ClipboardEvent, type KeyboardEvent } from 'react'
import {
  MANIFEST_COLUMNS,
  MANIFEST_EXPECTED_COLS,
  MANIFEST_EXPECTED_ROWS,
  MANIFEST_ROWS,
  manifestToTsv,
} from '../data'
import { selectNodeContents } from '../lib/clipboard'
import type { ClipboardApi } from '../types'
import './StageManifest.css'

interface Props {
  api: ClipboardApi
  completed: boolean
  onComplete: () => void
}

interface ParseResult {
  rows: string[][]
  colCounts: number[]
  tabbed: boolean
  uniform: boolean
  headerOk: boolean
}

function parseTsv(text: string): ParseResult {
  const lines = text
    .replace(/\r\n?/g, '\n')
    .split('\n')
    .filter((l) => l.trim().length > 0)
  const rows = lines.map((l) => l.split('\t').map((c) => c.trim()))
  const colCounts = rows.map((r) => r.length)
  const tabbed = text.includes('\t')
  const uniform = colCounts.every((c) => c === MANIFEST_EXPECTED_COLS)
  const headerOk = rows.length > 0 && rows[0].join('|') === MANIFEST_COLUMNS.join('|')
  return { rows, colCounts, tabbed, uniform, headerOk }
}

export default function StageManifest({ api, completed, onComplete }: Props) {
  const tableRef = useRef<HTMLTableElement>(null)
  const [selectedRows, setSelectedRows] = useState<number | null>(null)
  const [copiedRows, setCopiedRows] = useState<number | null>(null)
  const [dropText, setDropText] = useState(completed ? manifestToTsv([[...MANIFEST_COLUMNS], ...MANIFEST_ROWS]) : '')
  const [result, setResult] = useState<ParseResult | null>(completed ? parseTsv(dropText) : null)

  const allRows: string[][] = [[...MANIFEST_COLUMNS], ...MANIFEST_ROWS]

  function handleRegionKeyDown(e: KeyboardEvent<HTMLDivElement>) {
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'a' && tableRef.current) {
      e.preventDefault()
      selectNodeContents(tableRef.current)
      setSelectedRows(allRows.length)
    }
  }

  function handleCopy(e: ClipboardEvent<HTMLDivElement>) {
    const table = tableRef.current
    const sel = window.getSelection()
    if (!table || !sel || sel.rangeCount === 0) return
    const rowEls = Array.from(table.querySelectorAll('tr'))
    const picked = rowEls
      .map((tr, i) => (sel.containsNode(tr, true) ? allRows[i] : null))
      .filter((r): r is string[] => r !== null)
    if (picked.length === 0) return
    e.preventDefault()
    const tsv = manifestToTsv(picked)
    e.clipboardData.setData('text/plain', tsv)
    setCopiedRows(picked.length)
    void api.recordCopy(`Agent manifest · ${picked.length} rows (TSV)`, tsv)
  }

  function evaluate(text: string) {
    const parsed = parseTsv(text)
    setResult(parsed)
    const ok =
      parsed.tabbed && parsed.uniform && parsed.headerOk && parsed.rows.length === MANIFEST_EXPECTED_ROWS
    api.notePaste(ok)
    if (ok && !completed) onComplete()
  }

  function handleDropPaste(e: ClipboardEvent<HTMLTextAreaElement>) {
    e.preventDefault()
    const text = e.clipboardData.getData('text/plain')
    setDropText(text)
    evaluate(text)
  }

  const success = result !== null && result.tabbed && result.uniform && result.headerOk && result.rows.length === MANIFEST_EXPECTED_ROWS

  return (
    <div className="stage stage-manifest">
      <div className="stage__grid stage__grid--manifest">
        <section className="panel">
          <header className="panel__head">
            <h3>Agent manifest</h3>
            <span className="pill">
              {selectedRows !== null ? `${selectedRows} rows selected` : `${allRows.length} rows · ${MANIFEST_EXPECTED_COLS} columns`}
            </span>
          </header>
          <div
            className={`table-region ${selectedRows !== null ? 'table-region--selected' : ''}`}
            tabIndex={0}
            role="group"
            aria-label="Agent manifest table. Press Ctrl+A to select every row, then Ctrl+C."
            onKeyDown={handleRegionKeyDown}
            onCopy={handleCopy}
            onBlur={() => setSelectedRows(null)}
          >
            <table ref={tableRef} className="manifest">
              <thead>
                <tr>
                  {MANIFEST_COLUMNS.map((c) => (
                    <th key={c}>{c}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {MANIFEST_ROWS.map((row) => (
                  <tr key={row[0]}>
                    {row.map((cell, i) => (
                      <td key={i} className={i === 4 ? `cell-status cell-status--${cell.toLowerCase()}` : undefined}>
                        {cell}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
            <div className="table-region__focus-hint">
              {selectedRows !== null
                ? `Whole manifest selected — press Ctrl+C`
                : `Click inside, then Ctrl+A to select the whole table`}
            </div>
          </div>
          <p className="hint">
            {copiedRows !== null ? (
              <>
                Copied <strong>{copiedRows} rows</strong> as tab-separated text. Now paste into the exfil buffer.
              </>
            ) : (
              <>
                Click anywhere inside the manifest, press <kbd>Ctrl</kbd>+<kbd>A</kbd> to select every row, then{' '}
                <kbd>Ctrl</kbd>+<kbd>C</kbd>.
              </>
            )}
          </p>
        </section>

        <section className="panel">
          <header className="panel__head">
            <h3>Exfil buffer</h3>
            <span className={`pill ${success ? 'pill--accent' : ''}`}>
              {success ? 'COMPLETE' : 'TSV PARSER'}
            </span>
          </header>
          <textarea
            className={`drop-zone ${success ? 'drop-zone--ok' : result ? 'drop-zone--error' : ''}`}
            value={dropText}
            placeholder="Paste the whole manifest here (Ctrl+V)"
            spellCheck={false}
            readOnly={completed}
            onChange={(e) => {
              setDropText(e.target.value)
              if (e.target.value.length === 0) setResult(null)
            }}
            onPaste={handleDropPaste}
            aria-label="Exfil buffer, accepts tab-separated values"
          />
          {result && (
            <div className={`parse-report ${success ? 'parse-report--ok' : 'parse-report--error'}`} role="status">
              <div className="parse-report__row">
                <span className="parse-report__stat">
                  <strong>{result.rows.length}</strong> rows arrived
                </span>
                <span className="parse-report__stat">
                  <strong>{result.uniform ? MANIFEST_EXPECTED_COLS : result.colCounts.join('/')}</strong> columns
                </span>
                <span className="parse-report__stat">{result.tabbed ? 'tab-separated' : 'no tabs found'}</span>
              </div>
              <div className="parse-report__verdict">
                {success
                  ? `Manifest intact: 1 header + ${MANIFEST_ROWS.length} agents parsed.`
                  : !result.tabbed
                    ? 'No tab characters — copy the table itself, not a screenshot or a single cell.'
                    : !result.headerOk
                      ? 'Header row missing — select the whole table including the column names.'
                      : result.rows.length !== MANIFEST_EXPECTED_ROWS
                        ? `Expected ${MANIFEST_EXPECTED_ROWS} rows, got ${result.rows.length}.`
                        : `Ragged columns — every row must have ${MANIFEST_EXPECTED_COLS} cells.`}
              </div>
            </div>
          )}
          {result && result.rows.length > 0 && (
            <div className="parsed-preview" aria-label="Parsed rows">
              {result.rows.map((r, i) => (
                <div key={i} className={`parsed-preview__row ${i === 0 ? 'parsed-preview__row--head' : ''}`}>
                  <span className="parsed-preview__num">{i === 0 ? 'H' : i}</span>
                  {r.map((c, j) => (
                    <span key={j} className="parsed-preview__cell">
                      {c}
                    </span>
                  ))}
                </div>
              ))}
            </div>
          )}
        </section>
      </div>
    </div>
  )
}
