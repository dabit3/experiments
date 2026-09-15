import { useEffect, useRef, type KeyboardEvent, type MouseEvent } from 'react'
import { cellKey, COLS, colName, inRange, ROWS, type Pos, type Range } from '../lib/cells'
import { formatValue, isError } from '../lib/formula'
import { getCell, type Cells, type Values } from '../lib/sheet'

export interface EditState {
  key: string
  value: string
  /** `replace` edits started by typing commit on arrow keys; `edit` (F2 / double-click) moves the caret instead. */
  mode: 'replace' | 'edit'
  source: 'cell' | 'bar'
}

interface Props {
  cells: Cells
  values: Values
  active: Pos
  selection: Range
  copied: Range | null
  edit: EditState | null
  onEditChange: (value: string) => void
  onEditKeyDown: (e: KeyboardEvent<HTMLInputElement>) => void
  onCellMouseDown: (pos: Pos, e: MouseEvent) => void
  onCellMouseEnter: (pos: Pos) => void
  onCellDoubleClick: (pos: Pos) => void
  onColumnClick: (col: number) => void
  onRowClick: (row: number) => void
}

const COLUMNS = Array.from({ length: COLS }, (_, c) => c)
const ROW_INDEXES = Array.from({ length: ROWS }, (_, r) => r)

function CellEditor({
  value,
  onChange,
  onKeyDown,
}: {
  value: string
  onChange: (value: string) => void
  onKeyDown: (e: KeyboardEvent<HTMLInputElement>) => void
}) {
  const ref = useRef<HTMLInputElement>(null)
  useEffect(() => {
    const el = ref.current
    if (!el) return
    el.focus()
    el.setSelectionRange(el.value.length, el.value.length)
  }, [])
  return (
    <input
      ref={ref}
      className="cell-editor"
      data-testid="cell-editor"
      value={value}
      onChange={(e) => onChange(e.target.value)}
      onKeyDown={onKeyDown}
      spellCheck={false}
    />
  )
}

export function Grid({
  cells,
  values,
  active,
  selection,
  copied,
  edit,
  onEditChange,
  onEditKeyDown,
  onCellMouseDown,
  onCellMouseEnter,
  onCellDoubleClick,
  onColumnClick,
  onRowClick,
}: Props) {
  return (
    <table className="sheet" role="grid" aria-label="Spreadsheet">
      <thead>
        <tr>
          <th className="corner" />
          {COLUMNS.map((col) => (
            <th
              key={col}
              className={col >= selection.c1 && col <= selection.c2 ? 'col-header hl' : 'col-header'}
              onClick={() => onColumnClick(col)}
            >
              {colName(col)}
            </th>
          ))}
        </tr>
      </thead>
      <tbody>
        {ROW_INDEXES.map((row) => (
          <tr key={row}>
            <th
              className={row >= selection.r1 && row <= selection.r2 ? 'row-header hl' : 'row-header'}
              onClick={() => onRowClick(row)}
            >
              {row + 1}
            </th>
            {COLUMNS.map((col) => {
              const pos = { row, col }
              const key = cellKey(pos)
              const cell = getCell(cells, key)
              const value = values[key] ?? null
              const isActive = active.row === row && active.col === col
              const isEditing = edit?.key === key
              const classes = ['cell']
              if (isActive) classes.push('active')
              if (inRange(pos, selection)) classes.push('selected')
              if (copied && inRange(pos, copied)) classes.push('copied')
              if (cell.bold) classes.push('bold')
              if (typeof value === 'number') classes.push('num')
              if (isError(value)) classes.push('err')
              if (isEditing) classes.push('editing')
              return (
                <td
                  key={key}
                  data-cell={key}
                  className={classes.join(' ')}
                  title={cell.raw.startsWith('=') ? cell.raw : undefined}
                  onMouseDown={(e) => onCellMouseDown(pos, e)}
                  onMouseEnter={() => onCellMouseEnter(pos)}
                  onDoubleClick={() => onCellDoubleClick(pos)}
                >
                  {isEditing && edit.source === 'cell' ? (
                    <CellEditor value={edit.value} onChange={onEditChange} onKeyDown={onEditKeyDown} />
                  ) : (
                    <span className="cell-text">{isEditing ? edit.value : formatValue(value)}</span>
                  )}
                </td>
              )
            })}
          </tr>
        ))}
      </tbody>
    </table>
  )
}
