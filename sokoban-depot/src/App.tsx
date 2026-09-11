import { useCallback, useLayoutEffect, useRef, useState } from 'react'
import './App.css'
import { LevelSelect } from './components/LevelSelect'
import { PlayScreen } from './components/PlayScreen'
import { Logo } from './components/Logo'
import { LEVELS } from './game/levels'
import { useProgress } from './game/progress'

type Screen = { kind: 'select' } | { kind: 'play'; levelId: number; run: number }

export default function App() {
  const { progress, record, reset } = useProgress()
  const [screen, setScreen] = useState<Screen>({ kind: 'select' })
  const helpDialog = useRef<HTMLDialogElement>(null)

  useLayoutEffect(() => {
    window.scrollTo(0, 0)
  }, [screen])

  const play = useCallback((levelId: number) => {
    setScreen((s) => ({ kind: 'play', levelId, run: s.kind === 'play' ? s.run + 1 : 0 }))
  }, [])

  const exit = useCallback(() => setScreen({ kind: 'select' }), [])

  const next = useCallback(() => {
    setScreen((s) => {
      if (s.kind !== 'play') return s
      const nextId = Math.min(LEVELS.length, s.levelId + 1)
      return { kind: 'play', levelId: nextId, run: s.run + 1 }
    })
  }, [])

  const level = screen.kind === 'play' ? LEVELS.find((l) => l.id === screen.levelId) : undefined

  return (
    <div className="app">
      <header className="topbar">
        <button className="brand" onClick={exit} aria-label="Sokoban Depot – back to level select">
          <Logo />
        </button>
        <span className="topbar-tag">THE DAILY DOSE OF “NAILED IT.”</span>
        {level && (
          <nav className="crumbs" aria-label="Breadcrumb">
            <button className="crumb-link" onClick={exit}>
              Levels
            </button>
            <span className="crumb-sep">/</span>
            <span className="crumb-current">
              <span className="crumb-num">{String(level.id).padStart(2, '0')}</span>
              {level.name}
            </span>
          </nav>
        )}
        <button className="help-button" onClick={() => helpDialog.current?.showModal()}>
          <span aria-hidden="true">?</span> How to play
        </button>
      </header>

      <dialog
        ref={helpDialog}
        className="instructions-dialog"
        aria-labelledby="help-title"
        onKeyDown={(event) => event.stopPropagation()}
      >
        <p className="eyebrow">WELCOME TO THE DEPOT</p>
        <h2 id="help-title">A push in the right direction.</h2>
        <p>
          Push every wooden crate onto a marked target. You can push one crate at a time, but you can’t pull it back.
        </p>
        <dl className="help-controls">
          <div>
            <dt>Move & push</dt>
            <dd>↑ ↓ ← → or W A S D</dd>
          </div>
          <div>
            <dt>Undo a move</dt>
            <dd>Z / Backspace</dd>
          </div>
          <div>
            <dt>Restart the shift</dt>
            <dd>R</dd>
          </div>
          <div>
            <dt>Back to stages</dt>
            <dd>Esc / L</dd>
          </div>
        </dl>
        <p>
          Hit par for three stars. Finish within 1.5× par for two. Every finish earns a star. There’s no timer, and undo
          is unlimited.
        </p>
        <form method="dialog">
          <button className="btn btn-primary">
            Got it. Let’s move! <span aria-hidden="true">↗</span>
          </button>
        </form>
      </dialog>
      <main>
        {level && screen.kind === 'play' ? (
          <PlayScreen
            key={`${level.id}-${screen.run}`}
            level={level}
            best={progress[level.id]}
            onSolved={record}
            onNext={next}
            onExit={exit}
          />
        ) : (
          <LevelSelect progress={progress} onPlay={play} onReset={reset} />
        )}
      </main>
    </div>
  )
}
