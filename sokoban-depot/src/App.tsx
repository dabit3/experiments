import { useCallback, useState } from 'react'
import './App.css'
import { LevelSelect } from './components/LevelSelect'
import { PlayScreen } from './components/PlayScreen'
import { CrateIcon } from './components/Sprites'
import { LEVELS } from './game/levels'
import { useProgress } from './game/progress'

type Screen = { kind: 'select' } | { kind: 'play'; levelId: number; run: number }

export default function App() {
  const { progress, record, reset } = useProgress()
  const [screen, setScreen] = useState<Screen>({ kind: 'select' })

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
          <CrateIcon className="brand-icon" />
          <span>
            <span className="brand-name">Sokoban Depot</span>
            <span className="brand-tag">push crates onto targets</span>
          </span>
        </button>
        {level && (
          <nav className="crumbs" aria-label="Breadcrumb">
            <button className="crumb-link" onClick={exit}>
              Levels
            </button>
            <span className="crumb-sep">/</span>
            <span className="crumb-current">
              {String(level.id).padStart(2, '0')} · {level.name}
            </span>
          </nav>
        )}
      </header>

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
