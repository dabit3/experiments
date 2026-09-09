import { useCallback, useEffect, useRef, useState } from 'react'
import type { ReactNode } from 'react'
import './App.css'
import { PATTERNS, TOTAL_STEPS } from './types'
import type { ScreenProps } from './types'
import { formatDuration } from './lib/format'
import { FakeClose } from './screens/FakeClose'
import { DodgingButton } from './screens/DodgingButton'
import { Confirmshaming } from './screens/Confirmshaming'
import { Countdown } from './screens/Countdown'
import { HiddenCheckbox } from './screens/HiddenCheckbox'
import { Survey } from './screens/Survey'
import { DisguisedAd } from './screens/DisguisedAd'
import { TermsScroll } from './screens/TermsScroll'
import { CaseTrap } from './screens/CaseTrap'
import { LookAlikes } from './screens/LookAlikes'
import { Success } from './screens/Success'

const SCREENS: Array<(props: ScreenProps) => ReactNode> = [
  FakeClose,
  DodgingButton,
  Confirmshaming,
  Countdown,
  HiddenCheckbox,
  Survey,
  DisguisedAd,
  TermsScroll,
  CaseTrap,
  LookAlikes,
]

interface Toast {
  id: number
  kind: 'defeat' | 'trap'
  text: string
}

export default function App() {
  const [run, setRun] = useState(0)
  const [step, setStep] = useState(1)
  const [startedAt, setStartedAt] = useState(() => Date.now())
  const [finishedAt, setFinishedAt] = useState<number | null>(null)
  const [traps, setTraps] = useState<string[]>([])
  const [toasts, setToasts] = useState<Toast[]>([])
  const [now, setNow] = useState(() => Date.now())
  const toastId = useRef(0)

  useEffect(() => {
    if (finishedAt !== null) return
    const t = window.setInterval(() => setNow(Date.now()), 500)
    return () => window.clearInterval(t)
  }, [finishedAt])

  const pushToast = useCallback((kind: Toast['kind'], text: string) => {
    const id = ++toastId.current
    setToasts((list) => [...list, { id, kind, text }])
    window.setTimeout(() => {
      setToasts((list) => list.filter((t) => t.id !== id))
    }, 2600)
  }, [])

  const onDefeat = useCallback(() => {
    const pattern = PATTERNS[step - 1]
    pushToast('defeat', `Defeated #${pattern.id}: ${pattern.name}`)
    if (step >= TOTAL_STEPS) {
      setFinishedAt(Date.now())
    }
    setStep((s) => s + 1)
    window.scrollTo({ top: 0 })
  }, [step, pushToast])

  const onTrap = useCallback(
    (label: string) => {
      setTraps((list) => [...list, label])
      pushToast('trap', label)
    },
    [pushToast],
  )

  const restart = () => {
    setRun((r) => r + 1)
    setStep(1)
    setStartedAt(Date.now())
    setFinishedAt(null)
    setTraps([])
    setToasts([])
    window.scrollTo({ top: 0 })
  }

  const finished = step > TOTAL_STEPS
  const elapsed = (finishedAt ?? now) - startedAt
  const Screen = finished ? null : SCREENS[step - 1]

  return (
    <div className="app">
      <header className="topbar">
        <div className="brand" aria-label="Streamly Plus">
          <span className="brand-mark" aria-hidden="true">
            <svg viewBox="0 0 24 24" width="22" height="22">
              <path d="M6 4.5v15l13-7.5z" fill="currentColor" />
            </svg>
          </span>
          <span className="brand-name">
            Streamly<span className="brand-plus">+</span>
          </span>
        </div>

        <div className="topbar-center">
          <span className="topbar-title">Manage subscription</span>
          <span className="topbar-sep" aria-hidden="true">
            /
          </span>
          <span className="topbar-step">
            {finished ? 'Cancelled' : `Step ${step} of ${TOTAL_STEPS}`}
          </span>
        </div>

        <div className="topbar-stats">
          <span className="stat" title="Traps triggered">
            <svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true">
              <path
                d="M12 3 2 21h20L12 3zm0 6 5.6 10H6.4L12 9zm-1 3v4h2v-4h-2zm0 5v2h2v-2h-2z"
                fill="currentColor"
              />
            </svg>
            {traps.length} {traps.length === 1 ? 'trap' : 'traps'}
          </span>
          <span className={`stat stat-timer ${finished ? 'stat-frozen' : ''}`} title="Elapsed time">
            <span className="stat-dot" aria-hidden="true" />
            <svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true">
              <path
                d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm0 2a8 8 0 1 1 0 16 8 8 0 0 1 0-16zm-1 3v6l4.5 2.7 1-1.7-3.5-2.1V7h-2z"
                fill="currentColor"
              />
            </svg>
            <span className="mono">{formatDuration(elapsed)}</span>
          </span>
        </div>
      </header>

      <div
        className="progress"
        role="progressbar"
        aria-valuemin={0}
        aria-valuemax={TOTAL_STEPS}
        aria-valuenow={step - 1}
        aria-label="Dark patterns defeated"
      >
        {PATTERNS.map((p) => (
          <span
            key={p.id}
            className={`progress-seg ${p.id < step ? 'done' : p.id === step ? 'active' : ''}`}
            title={p.id < step ? `${p.name} — defeated` : p.id === step ? 'In progress' : 'Locked'}
          />
        ))}
      </div>

      <div className="layout">
        <aside className="dossier" aria-label="Pattern dossier">
          <div className="dossier-head">
            <span className="dossier-kicker">Dossier</span>
            <span className="dossier-count mono">
              {Math.min(step - 1, TOTAL_STEPS)}/{TOTAL_STEPS}
            </span>
          </div>
          <ol className="dossier-list">
            {PATTERNS.map((p) => {
              const state = p.id < step ? 'done' : p.id === step ? 'active' : 'locked'
              return (
                <li key={p.id} className={`dossier-item ${state}`}>
                  <span className="dossier-pip" aria-hidden="true">
                    {state === 'done' ? (
                      <svg viewBox="0 0 24 24" width="12" height="12">
                        <path
                          d="M5 12.5l4.5 4.5L19 7.5"
                          stroke="currentColor"
                          strokeWidth="3.2"
                          fill="none"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                        />
                      </svg>
                    ) : (
                      p.id
                    )}
                  </span>
                  <span className="dossier-text">
                    <strong>{state === 'locked' ? 'Classified' : state === 'active' ? 'Pattern in play' : p.name}</strong>
                    <small>{state === 'done' ? p.trick : state === 'active' ? 'Spot the trick to reveal it.' : 'Unlocks after the previous screen.'}</small>
                  </span>
                </li>
              )
            })}
          </ol>
        </aside>

        <main className="stage">
          {Screen ? (
            <div className="card" key={`${run}-${step}`}>
              <Screen onDefeat={onDefeat} onTrap={onTrap} />
            </div>
          ) : (
            <Success key={`success-${run}`} elapsedMs={elapsed} traps={traps} onRestart={restart} />
          )}
        </main>
      </div>

      <div className="toasts" aria-live="polite">
        {toasts.map((t) => (
          <div key={t.id} className={`toast toast-${t.kind}`}>
            <span className="toast-icon" aria-hidden="true">
              {t.kind === 'defeat' ? '✓' : '!'}
            </span>
            <span className="toast-text">{t.text}</span>
          </div>
        ))}
      </div>
    </div>
  )
}
