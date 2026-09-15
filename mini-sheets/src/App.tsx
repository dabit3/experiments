import { useEffect, useMemo, useRef, useState, type KeyboardEvent, type MouseEvent } from 'react'
import { FormulaBar } from './components/FormulaBar'
import { Grid, type EditState } from './components/Grid'
import { StatusBar } from './components/StatusBar'
import { cellKey, clampPos, COLS, normalizeRange, rangeSize, ROWS, type Pos, type Range } from './lib/cells'
import {
  clearRange,
  computeValues,
  copyRange,
  fillDown,
  getCell,
  paste,
  rangeToTsv,
  setCellRaw,
  toggleBold,
  type Cells,
  type Clipboard,
} from './lib/sheet'
import { loadCells, saveCells } from './lib/storage'

const ORIGIN: Pos = { row: 0, col: 0 }
const HISTORY_LIMIT = 100

const ARROWS: Record<string, Pos> = {
  ArrowUp: { row: -1, col: 0 },
  ArrowDown: { row: 1, col: 0 },
  ArrowLeft: { row: 0, col: -1 },
  ArrowRight: { row: 0, col: 1 },
}

export default function App() {
  const [cells, setCells] = useState<Cells>(loadCells)
  const [active, setActive] = useState<Pos>(ORIGIN)
  const [selEnd, setSelEnd] = useState<Pos>(ORIGIN)
  const [edit, setEdit] = useState<EditState | null>(null)
  const [clipboard, setClipboard] = useState<Clipboard | null>(null)
  const [copied, setCopied] = useState<Range | null>(null)

  const gridRef = useRef<HTMLDivElement>(null)
  const history = useRef<{ undo: Cells[]; redo: Cells[] }>({ undo: [], redo: [] })
  const dragging = useRef(false)
  /** Column to return to on Enter after a run of Tab presses, like Excel. */
  const tabStartCol = useRef<number | null>(null)

  const values = useMemo(() => computeValues(cells), [cells])
  const selection = useMemo(() => normalizeRange(active, selEnd), [active, selEnd])
  const activeKey = cellKey(active)

  useEffect(() => saveCells(cells), [cells])

  useEffect(() => {
    gridRef.current?.focus()
    const stop = () => {
      dragging.current = false
    }
    window.addEventListener('mouseup', stop)
    return () => window.removeEventListener('mouseup', stop)
  }, [])

  const focusGrid = () => gridRef.current?.focus()

  /** Applies a change to the sheet and records the previous state for undo. */
  const updateCells = (next: Cells) => {
    if (next === cells) return
    history.current.undo = [...history.current.undo.slice(-HISTORY_LIMIT + 1), cells]
    history.current.redo = []
    setCells(next)
  }

  const undo = () => {
    const prev = history.current.undo.pop()
    if (!prev) return
    history.current.redo.push(cells)
    setCells(prev)
  }

  const redo = () => {
    const next = history.current.redo.pop()
    if (!next) return
    history.current.undo.push(cells)
    setCells(next)
  }

  // ------------------------------------------------------------------ selection

  const select = (pos: Pos, extend = false) => {
    const clamped = clampPos(pos)
    if (extend) {
      setSelEnd(clamped)
    } else {
      setActive(clamped)
      setSelEnd(clamped)
    }
  }

  const moveBy = (delta: Pos, extend = false) => {
    const base = extend ? selEnd : active
    select({ row: base.row + delta.row, col: base.col + delta.col }, extend)
  }

  /** Enter after Tab, Tab, Tab jumps back to the column where the Tab run started. */
  const moveAfterEnter = (shift: boolean) => {
    const col = tabStartCol.current ?? active.col
    tabStartCol.current = null
    select({ row: active.row + (shift ? -1 : 1), col })
  }

  const moveAfterTab = (shift: boolean) => {
    tabStartCol.current ??= active.col
    select({ row: active.row, col: active.col + (shift ? -1 : 1) })
  }

  // ------------------------------------------------------------------ editing

  const startEdit = (value: string, mode: EditState['mode'], source: EditState['source'] = 'cell') => {
    setEdit({ key: activeKey, value, mode, source })
  }

  const commitEdit = () => {
    if (!edit) return
    updateCells(setCellRaw(cells, edit.key, edit.value.trim()))
    setEdit(null)
  }

  const cancelEdit = () => setEdit(null)

  const handleEditKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (!edit) return
    const arrow = ARROWS[e.key]
    if (e.key === 'Enter') {
      e.preventDefault()
      commitEdit()
      moveAfterEnter(e.shiftKey)
      focusGrid()
    } else if (e.key === 'Tab') {
      e.preventDefault()
      commitEdit()
      moveAfterTab(e.shiftKey)
      focusGrid()
    } else if (e.key === 'Escape') {
      e.preventDefault()
      cancelEdit()
      focusGrid()
    } else if (arrow && edit.mode === 'replace' && edit.source === 'cell') {
      e.preventDefault()
      commitEdit()
      tabStartCol.current = null
      moveBy(arrow)
      focusGrid()
    }
  }

  const handleFormulaBarChange = (value: string) => {
    setEdit({ key: activeKey, value, mode: 'edit', source: 'bar' })
  }

  // ------------------------------------------------------------------ clipboard & commands

  const copySelection = () => {
    setClipboard(copyRange(cells, selection))
    setCopied(selection)
    navigator.clipboard?.writeText(rangeToTsv(values, selection)).catch(() => {})
  }

  const pasteClipboard = () => {
    if (!clipboard) return
    const result = paste(cells, clipboard, active)
    updateCells(result.cells)
    setSelEnd({ row: result.range.r2, col: result.range.c2 })
  }

  const handleGridKeyDown = (e: KeyboardEvent<HTMLDivElement>) => {
    if (edit) return
    const ctrl = e.ctrlKey || e.metaKey
    const arrow = ARROWS[e.key]

    if (arrow) {
      e.preventDefault()
      tabStartCol.current = null
      if (ctrl) {
        const target = { ...(e.shiftKey ? selEnd : active) }
        if (arrow.row) target.row = arrow.row < 0 ? 0 : ROWS - 1
        if (arrow.col) target.col = arrow.col < 0 ? 0 : COLS - 1
        select(target, e.shiftKey)
      } else {
        moveBy(arrow, e.shiftKey)
      }
      return
    }

    if (ctrl) {
      const handled = handleShortcut(e.key.toLowerCase(), e.shiftKey)
      if (handled) e.preventDefault()
      return
    }

    switch (e.key) {
      case 'Enter':
        e.preventDefault()
        moveAfterEnter(e.shiftKey)
        break
      case 'Tab':
        e.preventDefault()
        moveAfterTab(e.shiftKey)
        break
      case 'F2':
        e.preventDefault()
        startEdit(getCell(cells, activeKey).raw, 'edit')
        break
      case 'Delete':
        e.preventDefault()
        updateCells(clearRange(cells, selection))
        break
      case 'Backspace':
        e.preventDefault()
        startEdit('', 'replace')
        break
      case 'Escape':
        e.preventDefault()
        setCopied(null)
        setSelEnd(active)
        break
      case 'Home':
        e.preventDefault()
        select({ row: active.row, col: 0 }, e.shiftKey)
        break
      case 'End':
        e.preventDefault()
        select({ row: active.row, col: COLS - 1 }, e.shiftKey)
        break
      default:
        if (e.key.length === 1 && !e.altKey) {
          e.preventDefault()
          startEdit(e.key, 'replace')
        }
    }
  }

  const handleShortcut = (key: string, shift: boolean): boolean => {
    switch (key) {
      case 'c':
        copySelection()
        return true
      case 'x':
        copySelection()
        updateCells(clearRange(cells, selection))
        return true
      case 'v':
        pasteClipboard()
        return true
      case 'b':
        updateCells(toggleBold(cells, selection))
        return true
      case 'd':
        updateCells(fillDown(cells, selection))
        return true
      case 'z':
        if (shift) redo()
        else undo()
        return true
      case 'y':
        redo()
        return true
      case 'a':
        setActive(ORIGIN)
        setSelEnd({ row: ROWS - 1, col: COLS - 1 })
        return true
      default:
        return false
    }
  }

  // ------------------------------------------------------------------ mouse

  const handleCellMouseDown = (pos: Pos, e: MouseEvent) => {
    if (e.button !== 0) return
    if (edit?.key === cellKey(pos) && edit.source === 'cell') return
    if (edit) commitEdit()
    tabStartCol.current = null
    dragging.current = true
    select(pos, e.shiftKey)
  }

  const handleCellMouseEnter = (pos: Pos) => {
    if (dragging.current) setSelEnd(pos)
  }

  const handleCellDoubleClick = (pos: Pos) => {
    select(pos)
    setEdit({ key: cellKey(pos), value: getCell(cells, cellKey(pos)).raw, mode: 'edit', source: 'cell' })
  }

  const handleFormulaBarKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' || e.key === 'Tab') {
      e.preventDefault()
      commitEdit()
      if (e.key === 'Enter') moveAfterEnter(e.shiftKey)
      else moveAfterTab(e.shiftKey)
      focusGrid()
    } else if (e.key === 'Escape') {
      e.preventDefault()
      cancelEdit()
      focusGrid()
    }
  }

  const clearSheet = () => {
    if (Object.keys(cells).length === 0) return
    if (window.confirm('Clear every cell in this sheet?')) updateCells({})
  }

  const formulaValue = edit ? edit.value : getCell(cells, activeKey).raw
  const filledCount = Object.values(cells).filter((c) => c.raw !== '').length

  return (
    <div className="app">
      <header className="app-header">
        <div className="brand">
          <div className="logo">Σ</div>
          <div>
            <h1>Mini Sheets</h1>
            <p className="subtitle">
              {ROWS} × {COLS} grid · {filledCount} filled {filledCount === 1 ? 'cell' : 'cells'} · saved locally
            </p>
          </div>
        </div>
        <div className="header-actions">
          {rangeSize(selection) > 1 && <span className="pill">{rangeSize(selection)} cells selected</span>}
          <button type="button" className="ghost" onClick={clearSheet}>
            Clear sheet
          </button>
        </div>
      </header>

      <FormulaBar
        label={activeKey}
        value={formulaValue}
        onChange={handleFormulaBarChange}
        onKeyDown={handleFormulaBarKeyDown}
      />

      <div
        className="grid-scroller"
        ref={gridRef}
        tabIndex={0}
        onKeyDown={handleGridKeyDown}
        data-testid="grid"
      >
        <Grid
          cells={cells}
          values={values}
          active={active}
          selection={selection}
          copied={copied}
          edit={edit}
          onEditChange={(value) => edit && setEdit({ ...edit, value })}
          onEditKeyDown={handleEditKeyDown}
          onCellMouseDown={handleCellMouseDown}
          onCellMouseEnter={handleCellMouseEnter}
          onCellDoubleClick={handleCellDoubleClick}
          onColumnClick={(col) => {
            setActive({ row: 0, col })
            setSelEnd({ row: ROWS - 1, col })
          }}
          onRowClick={(row) => {
            setActive({ row, col: 0 })
            setSelEnd({ row, col: COLS - 1 })
          }}
        />
      </div>

      <StatusBar range={selection} values={values} />
    </div>
  )
}
