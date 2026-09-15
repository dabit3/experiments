import { useCallback, useEffect, useMemo, useRef, useState, type KeyboardEvent } from 'react'
import { countNodes, displayPath, HOST, USER } from '../shell/filesystem'
import { span, type Line } from '../shell/output'
import { Shell, TOTAL_CLUES } from '../shell/shell'
import { Fireworks } from './Fireworks'
import { OutputLines } from './OutputLines'

type Entry =
  | { id: number; kind: 'boot' }
  | { id: number; kind: 'command'; prompt: string; text: string }
  | { id: number; kind: 'output'; lines: Line[] }
  | { id: number; kind: 'fireworks'; commands: number }

const QUICK_COMMANDS = ['cat README.txt', 'ls -la', 'help', 'clear']

let nextId = 1
const entry = <T extends Omit<Entry, 'id'>>(e: T): T & { id: number } => ({ ...e, id: nextId++ })

export function Terminal() {
  const [shell] = useState(() => new Shell())

  const [entries, setEntries] = useState<Entry[]>(() => [entry({ kind: 'boot' })])
  const [input, setInput] = useState('')
  const [caret, setCaret] = useState(0)
  const [focused, setFocused] = useState(true)
  const [historyIndex, setHistoryIndex] = useState<number | null>(null)
  const draftRef = useRef('')
  const inputRef = useRef<HTMLInputElement>(null)
  const bodyRef = useRef<HTMLDivElement>(null)
  const [, bump] = useState(0)

  const fileCount = useMemo(() => countNodes(shell.root), [shell])

  const focusInput = useCallback(() => inputRef.current?.focus(), [])

  const scrollToBottom = useCallback(() => {
    const el = bodyRef.current
    if (el) el.scrollTop = el.scrollHeight
  }, [])

  useEffect(() => {
    scrollToBottom()
  }, [entries, scrollToBottom])

  useEffect(() => {
    focusInput()
  }, [focusInput])

  const syncCaret = () => {
    const el = inputRef.current
    if (el) setCaret(el.selectionStart ?? el.value.length)
  }

  const setLine = (value: string) => {
    setInput(value)
    setCaret(value.length)
    requestAnimationFrame(() => {
      const el = inputRef.current
      if (el) el.setSelectionRange(value.length, value.length)
    })
  }

  const runCommand = (raw: string) => {
    const prompt = shell.prompt
    const result = shell.execute(raw)
    const additions: Entry[] = []
    if (!result.clear) additions.push(entry({ kind: 'command', prompt, text: raw }))
    if (result.lines.length) additions.push(entry({ kind: 'output', lines: result.lines }))
    if (result.fireworks) additions.push(entry({ kind: 'fireworks', commands: shell.history.length }))
    setEntries((prev) => (result.clear ? additions : [...prev, ...additions]))
    setHistoryIndex(null)
    draftRef.current = ''
    setLine('')
  }

  const onKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    const history = shell.history
    if (e.key === 'Enter') {
      e.preventDefault()
      runCommand(input)
      return
    }
    if (e.key === 'Tab') {
      e.preventDefault()
      const completion = shell.complete(input)
      if (completion.kind === 'single') setLine(completion.value)
      else if (completion.kind === 'multiple') {
        setLine(completion.value)
        setEntries((prev) => [
          ...prev,
          entry({ kind: 'command', prompt: shell.prompt, text: input }),
          entry({ kind: 'output', lines: [completion.candidates.map((c) => span(c.padEnd(Math.max(...completion.candidates.map((x) => x.length)) + 2), c.endsWith('/') ? 'dir' : undefined))] }),
        ])
      }
      return
    }
    if (e.key === 'ArrowUp') {
      e.preventDefault()
      if (history.length === 0) return
      const idx = historyIndex === null ? history.length - 1 : Math.max(0, historyIndex - 1)
      if (historyIndex === null) draftRef.current = input
      setHistoryIndex(idx)
      setLine(history[idx])
      return
    }
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      if (historyIndex === null) return
      const idx = historyIndex + 1
      if (idx >= history.length) {
        setHistoryIndex(null)
        setLine(draftRef.current)
      } else {
        setHistoryIndex(idx)
        setLine(history[idx])
      }
      return
    }
    if (e.ctrlKey && (e.key === 'l' || e.key === 'L')) {
      e.preventDefault()
      setEntries([])
      return
    }
    if (e.ctrlKey && (e.key === 'c' || e.key === 'C')) {
      e.preventDefault()
      setEntries((prev) => [...prev, entry({ kind: 'command', prompt: shell.prompt, text: input + '^C' })])
      setHistoryIndex(null)
      setLine('')
      return
    }
    if (e.ctrlKey && (e.key === 'u' || e.key === 'U')) {
      e.preventDefault()
      setLine('')
      return
    }
    if (e.ctrlKey && (e.key === 'a' || e.key === 'A')) {
      e.preventDefault()
      inputRef.current?.setSelectionRange(0, 0)
      setCaret(0)
      return
    }
    if (e.ctrlKey && (e.key === 'e' || e.key === 'E')) {
      e.preventDefault()
      inputRef.current?.setSelectionRange(input.length, input.length)
      setCaret(input.length)
    }
  }

  const onSettled = useCallback(() => {
    bump((n) => n + 1)
    scrollToBottom()
  }, [scrollToBottom])

  const cluesFound = shell.clues.size
  const solved = shell.solved
  const cwdLabel = displayPath(shell.cwd)

  return (
    <div className="terminal-window" onMouseUp={() => window.getSelection()?.toString() === '' && focusInput()}>
      <header className="titlebar">
        <div className="traffic-lights" aria-hidden="true">
          <span className="light red" />
          <span className="light yellow" />
          <span className="light green" />
        </div>
        <div className="titlebar-title">
          <span className="titlebar-icon" aria-hidden="true">
            ▣
          </span>
          {USER}@{HOST}: {cwdLabel}
        </div>
        <div className={`progress ${solved ? 'progress-solved' : ''}`} title={`${cluesFound} of ${TOTAL_CLUES} clues found`}>
          <span className="progress-label">{solved ? 'SOLVED' : `Clues ${cluesFound}/${TOTAL_CLUES}`}</span>
          <div className="pips" aria-label={`${cluesFound} of ${TOTAL_CLUES} clues found`}>
            {Array.from({ length: TOTAL_CLUES }, (_, i) => (
              <span className={`pip ${i < cluesFound ? 'pip-on' : ''}`} key={i} />
            ))}
            <span className={`pip pip-flag ${solved ? 'pip-on' : ''}`} title="flag submitted">
              ⚑
            </span>
          </div>
        </div>
      </header>

      <div className="terminal-body" ref={bodyRef} data-testid="terminal-output">
        {entries.map((en) => {
          switch (en.kind) {
            case 'boot':
              return <BootBanner key={en.id} fileCount={fileCount} />
            case 'command':
              return (
                <div className="line command-line" key={en.id}>
                  <Prompt text={en.prompt} />
                  <span className="command-text">{en.text}</span>
                </div>
              )
            case 'output':
              return (
                <div className="output" key={en.id}>
                  <OutputLines lines={en.lines} />
                </div>
              )
            case 'fireworks':
              return <Fireworks key={en.id} commands={en.commands} onSettled={onSettled} />
          }
        })}

        <div className="line input-line" onClick={focusInput}>
          <Prompt text={shell.prompt} />
          <span className="input-render">
            <span>{input.slice(0, caret)}</span>
            <span className={`cursor ${focused ? 'cursor-focused' : ''}`}>{input[caret] ?? '\u00a0'}</span>
            <span>{input.slice(caret + 1)}</span>
          </span>
          <input
            ref={inputRef}
            className="hidden-input"
            type="text"
            value={input}
            onChange={(e) => {
              setInput(e.target.value)
              setCaret(e.target.selectionStart ?? e.target.value.length)
            }}
            onKeyDown={onKeyDown}
            onKeyUp={syncCaret}
            onSelect={syncCaret}
            onFocus={() => setFocused(true)}
            onBlur={() => setFocused(false)}
            autoComplete="off"
            autoCapitalize="off"
            autoCorrect="off"
            spellCheck={false}
            aria-label="Terminal command input"
            data-testid="terminal-input"
          />
        </div>
      </div>

      <footer className="statusbar">
        <div className="status-left">
          <span className="status-chip status-cwd" title="current directory">
            {shell.cwd}
          </span>
          <span className="status-hint">
            <kbd>Tab</kbd> complete · <kbd>↑</kbd>
            <kbd>↓</kbd> history · <kbd>Ctrl</kbd>+<kbd>L</kbd> clear
          </span>
        </div>
        <div className="quick-commands" aria-label="Quick commands">
          {QUICK_COMMANDS.map((cmd) => (
            <button
              type="button"
              className="quick-command"
              key={cmd}
              onClick={() => {
                setLine(cmd)
                focusInput()
              }}
            >
              {cmd}
            </button>
          ))}
        </div>
      </footer>
    </div>
  )
}

function Prompt({ text }: { text: string }) {
  const at = text.indexOf(':')
  const dollar = text.lastIndexOf('$')
  return (
    <span className="prompt">
      <span className="prompt-user">{text.slice(0, at)}</span>
      <span className="prompt-sep">:</span>
      <span className="prompt-path">{text.slice(at + 1, dollar)}</span>
      <span className="prompt-sep">$ </span>
    </span>
  )
}

function BootBanner({ fileCount }: { fileCount: number }) {
  return (
    <div className="boot">
      <pre className="boot-logo">{`  ████████╗████████╗██╗  ██╗
  ╚══██╔══╝╚══██╔══╝██║  ██║
     ██║      ██║   ███████║
     ██║      ██║   ██╔══██║
     ██║      ██║   ██║  ██║
     ╚═╝      ╚═╝   ╚═╝  ╚═╝`}</pre>
      <div className="boot-title">Terminal Treasure Hunt</div>
      <div className="boot-sub">
        a fake shell with a hidden flag · {fileCount} files and directories · 1 flag · 0 real shells involved
      </div>
      <div className="boot-start">
        Start with <code>cat README.txt</code>. Type <code>help</code> for the list of commands.
      </div>
    </div>
  )
}
