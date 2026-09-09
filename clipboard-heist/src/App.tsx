import { useCallback, useMemo, useRef, useState } from 'react'
import { KEYS, OBJECTIVES, type VaultKey } from './data'
import { copyEntry } from './lib/clipboard'
import type { ClipboardApi, HistoryEntry, Stats } from './types'
import HistoryPanel from './components/HistoryPanel'
import KeyReveal from './components/KeyReveal'
import StageCallback from './components/StageCallback'
import StageDeadDrop from './components/StageDeadDrop'
import StageIntercept from './components/StageIntercept'
import StageManifest from './components/StageManifest'
import StageVault from './components/StageVault'
import VaultOpened from './components/VaultOpened'
import './App.css'

const STAGE_KEYS: Array<VaultKey | null> = [KEYS.alpha, KEYS.bravo, KEYS.charlie, null, null]

const STAGE_KEY_NOTES = [
  'Copy it now and keep moving — the vault will ask for it long after your clipboard has been overwritten.',
  'The roster is safe. Bank this key too.',
  'Last key. The vault wants all three in a specific order.',
]

function stamp(): string {
  const d = new Date()
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}:${String(d.getSeconds()).padStart(2, '0')}`
}

function formatElapsed(ms: number): string {
  const s = Math.round(ms / 1000)
  return `${Math.floor(s / 60)}m ${String(s % 60).padStart(2, '0')}s`
}

export default function App() {
  const [run, setRun] = useState(0)
  const [stage, setStage] = useState(0)
  const [done, setDone] = useState<boolean[]>(() => OBJECTIVES.map(() => false))
  const [startedAt, setStartedAt] = useState(() => Date.now())
  const [openedAt, setOpenedAt] = useState<number | null>(null)
  const [history, setHistory] = useState<HistoryEntry[]>([])
  const [currentId, setCurrentId] = useState<number | null>(null)
  const [stats, setStats] = useState<Stats>({ copies: 0, pastes: 0, rejected: 0 })
  const [toast, setToast] = useState<string | null>(null)
  const nextId = useRef(1)
  const toastTimer = useRef<number | null>(null)

  const showToast = useCallback((text: string) => {
    setToast(text)
    if (toastTimer.current) window.clearTimeout(toastTimer.current)
    toastTimer.current = window.setTimeout(() => setToast(null), 1800)
  }, [])

  const recordCopy = useCallback(
    async (label: string, text: string, html?: string) => {
      const outcome = await copyEntry(text, html)
      if (!outcome.ok) {
        showToast(`Copy failed: ${outcome.reason}`)
        return false
      }
      const entry: HistoryEntry = { id: nextId.current++, label, text, html, objective: stage + 1, at: stamp() }
      setHistory((h) => [...h, entry])
      setCurrentId(entry.id)
      setStats((s) => ({ ...s, copies: s.copies + 1 }))
      showToast(`Copied ${label} (${outcome.method})`)
      return true
    },
    [stage, showToast],
  )

  const notePaste = useCallback((accepted: boolean) => {
    setStats((s) => ({ ...s, pastes: s.pastes + 1, rejected: s.rejected + (accepted ? 0 : 1) }))
  }, [])

  const api = useMemo<ClipboardApi>(() => ({ recordCopy, notePaste }), [recordCopy, notePaste])

  async function recopy(entry: HistoryEntry): Promise<boolean> {
    const outcome = await copyEntry(entry.text, entry.html)
    if (!outcome.ok) {
      showToast(`Copy failed: ${outcome.reason}`)
      return false
    }
    setCurrentId(entry.id)
    setStats((s) => ({ ...s, copies: s.copies + 1 }))
    showToast(`Re-copied ${entry.label}`)
    return true
  }

  function completeStage(index: number) {
    setDone((d) => {
      if (d[index]) return d
      const next = d.slice()
      next[index] = true
      return next
    })
  }

  function reset() {
    setRun((r) => r + 1)
    setStage(0)
    setDone(OBJECTIVES.map(() => false))
    setOpenedAt(null)
    setHistory([])
    setCurrentId(null)
    setStats({ copies: 0, pastes: 0, rejected: 0 })
    setStartedAt(Date.now())
  }

  const lastCopied = history.length ? history[history.length - 1] : null
  const objective = OBJECTIVES[stage]
  const stageKey = STAGE_KEYS[stage]
  const completedCount = done.filter(Boolean).length

  return (
    <div className="app" key={run}>
      <header className="topbar">
        <div className="brand">
          <div className="brand__mark" aria-hidden="true">
            <svg viewBox="0 0 24 24" width="22" height="22">
              <rect x="8" y="3" width="8" height="4" rx="1.2" fill="none" stroke="currentColor" strokeWidth="1.8" />
              <path d="M8 5H6.5A1.5 1.5 0 0 0 5 6.5v13A1.5 1.5 0 0 0 6.5 21h11a1.5 1.5 0 0 0 1.5-1.5v-13A1.5 1.5 0 0 0 17.5 5H16" fill="none" stroke="currentColor" strokeWidth="1.8" />
              <path d="M9 13.5l2 2 4-4.5" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </div>
          <div>
            <h1>Clipboard Heist</h1>
            <p>A spy mission built on copy and paste</p>
          </div>
        </div>
        <ol className="stepper" aria-label="Objectives">
          {OBJECTIVES.map((o, i) => (
            <li
              key={o.code}
              className={`stepper__item ${i === stage ? 'is-active' : ''} ${done[i] ? 'is-done' : ''} ${i > stage ? 'is-locked' : ''}`}
              aria-current={i === stage ? 'step' : undefined}
            >
              <span className="stepper__num">{done[i] ? '✓' : i + 1}</span>
              <span className="stepper__title">{o.title}</span>
            </li>
          ))}
        </ol>
        <dl className="hud" aria-label="Clipboard statistics">
          <div>
            <dt>Copies</dt>
            <dd>{stats.copies}</dd>
          </div>
          <div>
            <dt>Pastes</dt>
            <dd>{stats.pastes}</dd>
          </div>
          <div>
            <dt>Rejected</dt>
            <dd className={stats.rejected ? 'is-danger' : undefined}>{stats.rejected}</dd>
          </div>
        </dl>
      </header>

      <main className="layout">
        <section className="mission">
          <div className="mission__head">
            <span className="mission__code">{objective.code}</span>
            <h2>{objective.title}</h2>
            <p>{objective.blurb}</p>
          </div>

          {stage === 0 && <StageIntercept api={api} completed={done[0]} onComplete={() => completeStage(0)} />}
          {stage === 1 && <StageManifest api={api} completed={done[1]} onComplete={() => completeStage(1)} />}
          {stage === 2 && <StageDeadDrop api={api} completed={done[2]} onComplete={() => completeStage(2)} />}
          {stage === 3 && (
            <StageCallback api={api} completed={done[3]} onComplete={() => completeStage(3)} lastCopied={lastCopied} />
          )}
          {stage === 4 && <StageVault api={api} onOpen={() => {
              completeStage(4)
              setOpenedAt(Date.now())
            }} />}

          {done[stage] && stage < OBJECTIVES.length - 1 && (
            <footer className="mission__foot">
              {stageKey && (
                <KeyReveal
                  vaultKey={stageKey}
                  note={STAGE_KEY_NOTES[stage]}
                  onCopy={(k) => recordCopy(`Vault key ${k.label}`, k.value)}
                />
              )}
              <button type="button" className="next-btn" onClick={() => setStage((s) => s + 1)}>
                Next objective
                <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true">
                  <path d="M5 12h13M13 6l6 6-6 6" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </button>
            </footer>
          )}
        </section>

        <HistoryPanel entries={history} currentId={currentId} onRecopy={recopy} />
      </main>

      <div className={`toast ${toast ? 'toast--show' : ''}`} role="status" aria-live="polite">
        {toast}
      </div>

      {openedAt !== null && (
        <VaultOpened
          stats={stats}
          historyCount={history.length}
          elapsed={formatElapsed(openedAt - startedAt)}
          onReset={reset}
        />
      )}

      <span className="sr-only">
        {completedCount} of {OBJECTIVES.length} objectives complete
      </span>
    </div>
  )
}
