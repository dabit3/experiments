import { useCallback, useEffect, useMemo, useState } from 'react'
import Board from './Board'
import Confetti from './Confetti'
import { PUZZLES, type Difficulty, type Puzzle } from './puzzles'
import { PEERS, findConflicts, formatTime, isSolved, parseGrid, solve, type Grid } from './sudoku'

const DIFFICULTIES: Difficulty[] = ['easy', 'medium', 'hard']
const DEFAULT_PUZZLE = 'easy-1'
const NO_CELLS: Set<number> = new Set()

type Tone = 'info' | 'good' | 'bad'
interface Status {
  text: string
  tone: Tone
}

const readPuzzleId = (): string => {
  const id = new URLSearchParams(window.location.search).get('puzzle')
  return id && PUZZLES.some((p) => p.id === id) ? id : DEFAULT_PUZZLE
}

const findPuzzle = (id: string): Puzzle => PUZZLES.find((p) => p.id === id) ?? PUZZLES[0]

const solutionFor = (givens: Grid): Grid => {
  const s = solve(givens)
  if (!s) throw new Error('bundled puzzle has no solution')
  return s
}

export default function App() {
  const [puzzleId, setPuzzleId] = useState<string>(readPuzzleId)
  const puzzle = useMemo(() => findPuzzle(puzzleId), [puzzleId])
  const givens = useMemo(() => parseGrid(puzzle.givens), [puzzle])
  const solution = useMemo(() => solutionFor(givens), [givens])

  const [values, setValues] = useState<Grid>(givens)
  const [notes, setNotes] = useState<number[]>(() => new Array<number>(81).fill(0))
  const [selected, setSelected] = useState<number | null>(null)
  const [notesMode, setNotesMode] = useState(false)
  const [hinted, setHinted] = useState<Set<number>>(NO_CELLS)
  const [wrong, setWrong] = useState<Set<number>>(NO_CELLS)
  const [status, setStatus] = useState<Status | null>(null)
  const [seconds, setSeconds] = useState(0)
  const [overlayOpen, setOverlayOpen] = useState(true)

  const conflicts = useMemo(() => findConflicts(values), [values])
  const solved = useMemo(() => isSolved(values, solution), [values, solution])
  const filled = useMemo(() => values.filter((v) => v !== 0).length, [values])

  const resetBoard = useCallback(
    (g: Grid) => {
      setValues(g)
      setNotes(new Array<number>(81).fill(0))
      setSelected(null)
      setNotesMode(false)
      setHinted(NO_CELLS)
      setWrong(NO_CELLS)
      setStatus(null)
      setSeconds(0)
      setOverlayOpen(true)
    },
    [],
  )

  const loadPuzzle = useCallback(
    (id: string) => {
      setPuzzleId(id)
      resetBoard(parseGrid(findPuzzle(id).givens))
    },
    [resetBoard],
  )

  useEffect(() => {
    const onPop = () => loadPuzzle(readPuzzleId())
    window.addEventListener('popstate', onPop)
    return () => window.removeEventListener('popstate', onPop)
  }, [loadPuzzle])

  useEffect(() => {
    document.title = `Sudoku Dojo · ${puzzle.id}`
  }, [puzzle])

  useEffect(() => {
    if (solved) return
    const id = window.setInterval(() => setSeconds((s) => s + 1), 1000)
    return () => window.clearInterval(id)
  }, [solved])

  useEffect(() => {
    if (wrong.size === 0) return
    const id = window.setTimeout(() => setWrong(NO_CELLS), 1800)
    return () => window.clearTimeout(id)
  }, [wrong])

  const choosePuzzle = (id: string) => {
    const url = new URL(window.location.href)
    url.searchParams.set('puzzle', id)
    window.history.pushState(null, '', url)
    loadPuzzle(id)
  }

  const setCell = useCallback(
    (i: number, digit: number) => {
      if (givens[i] !== 0 || solved) return
      setWrong(NO_CELLS)
      if (notesMode && digit !== 0) {
        if (values[i] !== 0) return
        setNotes((prev) => {
          const next = prev.slice()
          next[i] ^= 1 << digit
          return next
        })
        return
      }
      setValues((prev) => {
        if (prev[i] === digit) return prev
        const next = prev.slice()
        next[i] = digit
        return next
      })
      if (digit !== 0) {
        setNotes((prev) => {
          const next = prev.slice()
          next[i] = 0
          for (const p of PEERS[i]) next[p] &= ~(1 << digit)
          return next
        })
      }
      setHinted((prev) => {
        if (!prev.has(i)) return prev
        const next = new Set(prev)
        next.delete(i)
        return next
      })
    },
    [givens, notesMode, solved, values],
  )

  const move = useCallback((dr: number, dc: number) => {
    setSelected((cur) => {
      if (cur === null) return 0
      const r = (Math.floor(cur / 9) + dr + 9) % 9
      const c = ((cur % 9) + dc + 9) % 9
      return r * 9 + c
    })
  }, [])

  const check = () => {
    const bad = new Set<number>()
    let entered = 0
    for (let i = 0; i < 81; i++) {
      if (givens[i] !== 0 || values[i] === 0) continue
      entered++
      if (values[i] !== solution[i]) bad.add(i)
    }
    setWrong(bad)
    if (entered === 0) {
      setStatus({ text: 'Nothing to check yet — fill in a few cells first.', tone: 'info' })
    } else if (bad.size === 0) {
      setStatus({
        text: `All ${entered} ${entered === 1 ? 'entry is' : 'entries are'} correct. ${81 - filled} to go.`,
        tone: 'good',
      })
    } else {
      setStatus({
        text: `${bad.size} ${bad.size === 1 ? 'cell is' : 'cells are'} wrong — they are flashing red.`,
        tone: 'bad',
      })
    }
  }

  const hint = () => {
    if (solved) return
    let target = -1
    if (selected !== null && givens[selected] === 0 && values[selected] !== solution[selected]) {
      target = selected
    } else {
      for (let i = 0; i < 81; i++) {
        if (givens[i] === 0 && values[i] !== solution[i]) {
          target = i
          break
        }
      }
    }
    if (target === -1) return
    const digit = solution[target]
    setValues((prev) => {
      const next = prev.slice()
      next[target] = digit
      return next
    })
    setNotes((prev) => {
      const next = prev.slice()
      next[target] = 0
      for (const p of PEERS[target]) next[p] &= ~(1 << digit)
      return next
    })
    setHinted((prev) => new Set(prev).add(target))
    setSelected(target)
    setWrong(NO_CELLS)
    setStatus({
      text: `Hint: row ${Math.floor(target / 9) + 1}, column ${(target % 9) + 1} is ${digit}.`,
      tone: 'info',
    })
  }

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement | null
      if (target && (target.tagName === 'SELECT' || target.tagName === 'INPUT')) return
      if (e.ctrlKey || e.metaKey || e.altKey) return

      switch (e.key) {
        case 'ArrowUp':
          e.preventDefault()
          move(-1, 0)
          return
        case 'ArrowDown':
          e.preventDefault()
          move(1, 0)
          return
        case 'ArrowLeft':
          e.preventDefault()
          move(0, -1)
          return
        case 'ArrowRight':
          e.preventDefault()
          move(0, 1)
          return
        case 'n':
        case 'N':
          e.preventDefault()
          setNotesMode((m) => !m)
          return
        case 'Escape':
          setSelected(null)
          return
        case 'Backspace':
        case 'Delete':
        case '0':
          e.preventDefault()
          if (selected !== null) {
            if (values[selected] !== 0) setCell(selected, 0)
            else setNotes((prev) => {
              const next = prev.slice()
              next[selected] = 0
              return next
            })
          }
          return
        default:
          break
      }
      if (e.key >= '1' && e.key <= '9' && selected !== null) {
        e.preventDefault()
        setCell(selected, Number(e.key))
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [move, selected, setCell, values])

  const remaining = 81 - filled
  const canEdit = selected !== null && givens[selected] === 0 && !solved

  return (
    <div className="app">
      <header className="topbar">
        <div className="brand">
          <span className="brand-mark" aria-hidden="true">
            <svg viewBox="0 0 24 24" width="26" height="26">
              <path
                d="M4 4h16v16H4zM9.33 4v16M14.67 4v16M4 9.33h16M4 14.67h16"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinejoin="round"
              />
            </svg>
          </span>
          <div>
            <h1>Sudoku Dojo</h1>
            <p className="tagline">Solve an 81-cell grid by hand</p>
          </div>
        </div>

        <div className="topbar-right">
          <label className="picker">
            <span>Puzzle</span>
            <select value={puzzleId} onChange={(e) => choosePuzzle(e.target.value)} aria-label="Choose puzzle">
              {DIFFICULTIES.map((d) => (
                <optgroup key={d} label={d[0].toUpperCase() + d.slice(1)}>
                  {PUZZLES.filter((p) => p.difficulty === d).map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.id}
                    </option>
                  ))}
                </optgroup>
              ))}
            </select>
          </label>
          <span className={`badge badge-${puzzle.difficulty}`}>{puzzle.difficulty}</span>
          <div className="timer" aria-label="Elapsed time" data-testid="timer">
            <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true">
              <circle cx="12" cy="13" r="8" fill="none" stroke="currentColor" strokeWidth="2" />
              <path d="M12 9v4l3 2M9 2h6" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
            </svg>
            <span className="timer-value">{formatTime(seconds)}</span>
          </div>
        </div>
      </header>

      <main className="layout">
        <Board
          givens={givens}
          values={values}
          notes={notes}
          selected={selected}
          conflicts={conflicts}
          wrong={wrong}
          hinted={hinted}
          solved={solved}
          onSelect={(i) => setSelected(i)}
        />

        <aside className="panel">
          <section className="panel-section">
            <div className="progress-row">
              <span className="progress-label">{remaining === 0 ? 'Grid complete' : `${remaining} cells left`}</span>
              <span className={`mode-pill${notesMode ? ' on' : ''}`} data-testid="mode-pill">
                {notesMode ? 'Notes mode' : 'Digit mode'}
              </span>
            </div>
            <div className="progress-bar" aria-hidden="true">
              <span style={{ width: `${(filled / 81) * 100}%` }} />
            </div>
          </section>

          <section className="panel-section">
            <div className="numpad" aria-label="Number pad">
              {[1, 2, 3, 4, 5, 6, 7, 8, 9].map((d) => {
                const count = values.filter((v) => v === d).length
                return (
                  <button
                    key={d}
                    type="button"
                    className={`num${count >= 9 ? ' done' : ''}`}
                    disabled={!canEdit}
                    onClick={() => selected !== null && setCell(selected, d)}
                    aria-label={`Enter ${d}`}
                  >
                    <span>{d}</span>
                    <small>{Math.max(0, 9 - count)}</small>
                  </button>
                )
              })}
              <button
                type="button"
                className="num erase"
                disabled={!canEdit}
                onClick={() => selected !== null && setCell(selected, 0)}
                aria-label="Erase cell"
              >
                <span>⌫</span>
                <small>erase</small>
              </button>
              <button
                type="button"
                className={`num toggle${notesMode ? ' active' : ''}`}
                onClick={() => setNotesMode((m) => !m)}
                aria-pressed={notesMode}
                aria-label="Toggle notes mode"
              >
                <span>✎</span>
                <small>notes · N</small>
              </button>
            </div>
          </section>

          <section className="panel-section actions">
            <button type="button" className="btn" onClick={check} disabled={solved}>
              Check
            </button>
            <button type="button" className="btn" onClick={hint} disabled={solved}>
              Hint
              {hinted.size > 0 && <span className="count">{hinted.size}</span>}
            </button>
            <button type="button" className="btn ghost" onClick={() => resetBoard(givens)}>
              Restart
            </button>
          </section>

          <section className={`status status-${status?.tone ?? 'idle'}`} role="status" aria-live="polite">
            {status
              ? status.text
              : conflicts.size > 0
                ? 'A digit repeats in a row, column or box — the clashing cells are red.'
                : 'Click a cell, then type a digit.'}
          </section>

          <section className="panel-section legend">
            <h2>Keyboard</h2>
            <dl>
              <dt>1–9</dt>
              <dd>Enter digit (or pencil mark in notes mode)</dd>
              <dt>Arrows</dt>
              <dd>Move selection</dd>
              <dt>N</dt>
              <dd>Toggle notes mode</dd>
              <dt>Backspace</dt>
              <dd>Clear cell</dd>
            </dl>
          </section>
        </aside>
      </main>

      {solved && overlayOpen && (
        <div className="overlay" role="dialog" aria-modal="true" aria-labelledby="solved-title">
          <Confetti />
          <div className="overlay-card">
            <div className="overlay-mark" aria-hidden="true">
              <svg viewBox="0 0 24 24" width="64" height="64">
                <circle cx="12" cy="12" r="10" fill="none" stroke="currentColor" strokeWidth="1.8" />
                <path d="M7 12.5l3.2 3.2L17 9" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </div>
            <h2 id="solved-title">Puzzle solved!</h2>
            <p className="overlay-sub">
              <strong>{puzzle.id}</strong> · {puzzle.difficulty}
            </p>
            <div className="overlay-stats">
              <div>
                <span className="stat-label">Time</span>
                <span className="stat-value" data-testid="final-time">
                  {formatTime(seconds)}
                </span>
              </div>
              <div>
                <span className="stat-label">Hints</span>
                <span className="stat-value">{hinted.size}</span>
              </div>
            </div>
            <div className="overlay-actions">
              <button type="button" className="btn" onClick={() => setOverlayOpen(false)}>
                View grid
              </button>
              <button
                type="button"
                className="btn primary"
                onClick={() => {
                  const idx = PUZZLES.findIndex((p) => p.id === puzzle.id)
                  choosePuzzle(PUZZLES[(idx + 1) % PUZZLES.length].id)
                }}
              >
                Next puzzle →
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
