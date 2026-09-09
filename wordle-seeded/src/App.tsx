import { useCallback, useEffect, useMemo, useState, type CSSProperties } from 'react'
import { Board } from './components/Board'
import { HelpModal } from './components/HelpModal'
import { Keyboard } from './components/Keyboard'
import { SeedDialog } from './components/SeedDialog'
import { StatsModal } from './components/StatsModal'
import { Toast } from './components/Toast'
import { REVEAL_TOTAL_MS, useGame } from './hooks/useGame'
import { keyboardStates } from './lib/evaluate'
import { buildShareText, copyToClipboard } from './lib/share'
import { loadHardMode, saveHardMode } from './lib/stats'
import { parseSeed, randomSeed } from './lib/words'
import './App.css'

function readUrl() {
  const params = new URLSearchParams(window.location.search)
  const seed = parseSeed(window.location.search)
  const hardParam = params.get('hard')
  return {
    seed,
    hard: hardParam === null ? null : hardParam === '1' || hardParam === 'true',
  }
}

export default function App() {
  const [seed, setSeed] = useState<number>(() => readUrl().seed ?? randomSeed())
  const [hardMode, setHardMode] = useState<boolean>(() => readUrl().hard ?? loadHardMode())

  // Keep the URL in sync so the current puzzle is always shareable / reloadable.
  useEffect(() => {
    const params = new URLSearchParams(window.location.search)
    if (params.get('seed') !== String(seed)) {
      params.set('seed', String(seed))
      window.history.replaceState(null, '', `?${params.toString()}`)
    }
  }, [seed])

  useEffect(() => {
    const onPopState = () => {
      const { seed: nextSeed, hard } = readUrl()
      if (nextSeed !== null) setSeed(nextSeed)
      if (hard !== null) setHardMode(hard)
    }
    window.addEventListener('popstate', onPopState)
    return () => window.removeEventListener('popstate', onPopState)
  }, [])

  const playSeed = useCallback((next: number) => {
    const params = new URLSearchParams(window.location.search)
    params.set('seed', String(next))
    window.history.pushState(null, '', `?${params.toString()}`)
    setSeed(next)
  }, [])

  const toggleHardMode = useCallback((enabled: boolean) => {
    setHardMode(enabled)
    saveHardMode(enabled)
  }, [])

  return (
    <Game
      key={seed}
      seed={seed}
      hardMode={hardMode}
      onToggleHardMode={toggleHardMode}
      onPlaySeed={playSeed}
    />
  )
}

interface GameProps {
  seed: number
  hardMode: boolean
  onToggleHardMode: (enabled: boolean) => void
  onPlaySeed: (seed: number) => void
}

function Game({ seed, hardMode, onToggleHardMode, onPlaySeed }: GameProps) {
  const game = useGame({ seed, hardMode })
  const [helpOpen, setHelpOpen] = useState(false)
  const [seedOpen, setSeedOpen] = useState(false)
  const anyModalOpen = helpOpen || seedOpen || game.statsOpen

  const revealedCount = game.revealing ? game.guesses.length - 1 : game.guesses.length
  const keyStates = useMemo(
    () => keyboardStates(game.guesses.slice(0, revealedCount), game.evaluations.slice(0, revealedCount)),
    [game.guesses, game.evaluations, revealedCount],
  )

  const finished = game.status !== 'playing'
  const shareText = finished
    ? buildShareText(seed, game.evaluations, game.status === 'won', hardMode)
    : null

  const { handleKey } = game
  useEffect(() => {
    if (anyModalOpen) return
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.ctrlKey || e.metaKey || e.altKey) return
      const target = e.target
      if (target instanceof HTMLTextAreaElement) return
      if (target instanceof HTMLInputElement && target.type !== 'checkbox') return
      if (e.key === 'Enter' || e.key === 'Backspace' || /^[a-zA-Z]$/.test(e.key)) {
        e.preventDefault()
        handleKey(e.key)
      }
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [anyModalOpen, handleKey])

  const handleHardToggle = () => {
    if (game.guesses.length > 0 && !finished) {
      game.showToast('Hard mode can only be changed before the first guess', 'error', 2400)
      return
    }
    const next = !hardMode
    onToggleHardMode(next)
    game.showToast(next ? 'Hard mode on: revealed hints must be reused' : 'Hard mode off', 'info', 2000)
  }

  const handleShare = async () => {
    if (!shareText) return false
    const ok = await copyToClipboard(shareText)
    game.showToast(ok ? 'Copied results to clipboard' : 'Could not copy to clipboard', ok ? 'success' : 'error')
    return ok
  }

  return (
    <div className="app" style={{ '--reveal-total-ms': `${REVEAL_TOTAL_MS}ms` } as CSSProperties}>
      <header className="topbar">
        <div className="topbar__left">
          <button
            type="button"
            className="icon-button"
            aria-label="How to play"
            onClick={() => setHelpOpen(true)}
          >
            <svg viewBox="0 0 24 24" width="24" height="24" aria-hidden="true">
              <path
                fill="currentColor"
                d="M11 18h2v-2h-2v2zm1-16C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm0-14c-2.21 0-4 1.79-4 4h2c0-1.1.9-2 2-2s2 .9 2 2c0 2-3 1.75-3 5h2c0-2.25 3-2.5 3-5 0-2.21-1.79-4-4-4z"
              />
            </svg>
          </button>
          <button
            type="button"
            className="seed-badge"
            onClick={() => setSeedOpen(true)}
            aria-label={`Current seed ${seed}. Change seed`}
            data-testid="seed-badge"
          >
            <span className="seed-badge__label">Seed</span>
            <span className="seed-badge__value">#{seed}</span>
          </button>
        </div>

        <h1 className="logo">
          Wordle<span className="logo__accent">Seeded</span>
        </h1>

        <div className="topbar__right">
          <label className="switch" title="Hard mode: revealed hints must be reused">
            <input
              type="checkbox"
              role="switch"
              checked={hardMode}
              onChange={handleHardToggle}
              aria-label="Hard mode"
              data-testid="hard-mode-toggle"
            />
            <span className="switch__track" aria-hidden="true">
              <span className="switch__thumb" />
            </span>
            <span className="switch__label">Hard mode</span>
          </label>
          <button
            type="button"
            className="icon-button"
            aria-label="Statistics"
            onClick={() => game.setStatsOpen(true)}
            data-testid="stats-button"
          >
            <svg viewBox="0 0 24 24" width="24" height="24" aria-hidden="true">
              <path fill="currentColor" d="M4 9h4v11H4zM10 4h4v16h-4zM16 13h4v7h-4z" />
            </svg>
          </button>
        </div>
      </header>

      <main className="stage">
        <Board
          guesses={game.guesses}
          evaluations={game.evaluations}
          current={game.current}
          shakeKey={game.shakeKey}
          won={game.status === 'won'}
        />
        {hardMode && (
          <div className="hard-pill" data-testid="hard-pill">
            <span className="hard-pill__dot" />
            Hard mode
          </div>
        )}
      </main>

      <footer className="dock">
        <Keyboard states={keyStates} onKey={game.handleKey} disabled={finished || game.revealing} />
      </footer>

      <Toast toast={game.toast} />

      <StatsModal
        open={game.statsOpen}
        onClose={() => game.setStatsOpen(false)}
        stats={game.stats}
        seed={seed}
        finished={finished}
        won={game.status === 'won'}
        answer={game.answer}
        shareText={shareText}
        onShare={handleShare}
        onPlaySeed={onPlaySeed}
      />
      <HelpModal open={helpOpen} onClose={() => setHelpOpen(false)} />
      <SeedDialog
        open={seedOpen}
        seed={seed}
        onClose={() => setSeedOpen(false)}
        onPlaySeed={onPlaySeed}
      />
    </div>
  )
}
