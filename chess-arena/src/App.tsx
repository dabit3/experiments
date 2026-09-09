import { useCallback, useEffect, useState, type FormEvent } from 'react'
import type { PieceSymbol, Square } from 'chess.js'
import { Board } from './components/Board'
import { CapturedPieces } from './components/CapturedPieces'
import { MoveList } from './components/MoveList'
import { PromotionPicker } from './components/PromotionPicker'
import { ResultBanner } from './components/ResultBanner'
import { describeResult } from './lib/result'
import { useGame } from './lib/useGame'
import './App.css'

interface PendingPromotion {
  from: Square
  to: Square
}

async function copyText(text: string): Promise<boolean> {
  try {
    await navigator.clipboard.writeText(text)
    return true
  } catch {
    const ta = document.createElement('textarea')
    ta.value = text
    ta.setAttribute('readonly', '')
    ta.style.position = 'fixed'
    ta.style.opacity = '0'
    document.body.appendChild(ta)
    ta.select()
    const ok = document.execCommand('copy')
    ta.remove()
    return ok
  }
}

export default function App() {
  const game = useGame()
  const [flipped, setFlipped] = useState(false)
  const [promotion, setPromotion] = useState<PendingPromotion | null>(null)
  const [bannerDismissedFor, setBannerDismissedFor] = useState<number | null>(null)
  const [toast, setToast] = useState<string | null>(null)

  useEffect(() => {
    if (!toast) return
    const t = window.setTimeout(() => setToast(null), 2200)
    return () => window.clearTimeout(t)
  }, [toast])

  const handleMove = useCallback(
    (from: Square, to: Square): boolean => {
      const outcome = game.playMove(from, to)
      if (outcome === 'promotion') {
        setPromotion({ from, to })
        return true
      }
      return outcome === 'moved'
    },
    [game],
  )

  const handlePromote = (piece: PieceSymbol) => {
    if (promotion) game.playMove(promotion.from, promotion.to, piece)
    setPromotion(null)
  }

  const handleNewGame = (seed?: number) => {
    setPromotion(null)
    setBannerDismissedFor(null)
    game.newGame(seed)
  }

  const handleSeedSubmit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    const raw = new FormData(e.currentTarget).get('seed')
    const n = typeof raw === 'string' ? Number.parseInt(raw, 10) : NaN
    if (Number.isFinite(n) && n >= 0) handleNewGame(n)
    else e.currentTarget.reset()
  }

  const handleCopyPgn = async () => {
    const ok = await copyText(game.pgn())
    setToast(ok ? 'PGN copied to clipboard' : 'Could not copy PGN')
  }

  const kingSquare = (): Square | null => {
    for (const row of game.chess.board()) {
      for (const cell of row) {
        if (cell && cell.type === 'k' && cell.color === game.turn) return cell.square
      }
    }
    return null
  }
  const checkSquare = game.inCheck ? kingSquare() : null

  const showBanner = game.result !== null && bannerDismissedFor !== game.sans.length
  const resultText = game.result ? describeResult(game.result) : null

  let status: string
  let statusTone = 'neutral'
  if (game.result && resultText) {
    status = `${resultText.title} — ${resultText.subtitle}`
    statusTone = resultText.tone
  } else if (game.engineThinking) {
    status = 'Engine is thinking…'
    statusTone = 'thinking'
  } else if (game.inCheck) {
    status = 'Check! White to move'
    statusTone = 'check'
  } else {
    status = 'White to move'
  }

  const topCaptured = flipped ? 'w' : 'b'
  const bottomCaptured = flipped ? 'b' : 'w'

  return (
    <div className="app">
      <header className="topbar">
        <div className="brand">
          <span className="brand-mark" aria-hidden="true">
            ♞
          </span>
          <div>
            <h1>Chess Arena</h1>
            <p>Checkmate a built-in engine</p>
          </div>
        </div>
        <form className="seed-form" onSubmit={handleSeedSubmit} key={game.seed}>
          <label htmlFor="seed">Engine seed</label>
          <input
            id="seed"
            name="seed"
            type="number"
            min={0}
            inputMode="numeric"
            defaultValue={game.seed}
          />
          <button type="submit" className="btn ghost small">
            Apply
          </button>
        </form>
      </header>

      <main className="layout">
        <section className="board-column">
          <CapturedPieces
            by={topCaptured}
            pieces={game.captured[topCaptured]}
            advantage={topCaptured === 'w' ? game.materialBalance : -game.materialBalance}
          />
          <div className="board-stage">
            <Board
              pieces={game.pieces}
              turn={game.turn}
              flipped={flipped}
              interactive={game.playerToMove && promotion === null}
              lastMove={game.lastMove}
              checkSquare={checkSquare}
              legalMovesFrom={game.legalMovesFrom}
              onMove={handleMove}
            />
            {promotion && (
              <PromotionPicker
                color="w"
                to={promotion.to}
                onPick={handlePromote}
                onCancel={() => setPromotion(null)}
              />
            )}
            {showBanner && game.result && (
              <ResultBanner
                result={game.result}
                moveCount={game.sans.length}
                onNewGame={() => handleNewGame()}
                onDismiss={() => setBannerDismissedFor(game.sans.length)}
              />
            )}
          </div>
          <CapturedPieces
            by={bottomCaptured}
            pieces={game.captured[bottomCaptured]}
            advantage={bottomCaptured === 'w' ? game.materialBalance : -game.materialBalance}
          />
        </section>

        <aside className="sidebar">
          <div className={`status ${statusTone}`} role="status" data-testid="status">
            <span className="status-dot" aria-hidden="true" />
            <span>{status}</span>
          </div>

          <div className="players">
            <div className="player">
              <span className="swatch black" />
              <span>Engine · greedy 1-ply · seed {game.seed}</span>
            </div>
            <div className="player">
              <span className="swatch white" />
              <span>You · White</span>
            </div>
          </div>

          <MoveList history={game.history} />

          <div className="controls">
            <button type="button" className="btn primary" onClick={() => handleNewGame()} data-testid="new-game">
              New game
            </button>
            <button
              type="button"
              className="btn"
              onClick={game.undo}
              disabled={game.sans.length === 0}
              data-testid="undo"
            >
              Undo
            </button>
            <button type="button" className="btn" onClick={() => setFlipped((f) => !f)} data-testid="flip">
              Flip board
            </button>
            <button
              type="button"
              className="btn"
              onClick={handleCopyPgn}
              disabled={game.sans.length === 0}
              data-testid="copy-pgn"
            >
              Copy PGN
            </button>
          </div>
        </aside>
      </main>

      <div className={`toast${toast ? ' show' : ''}`} role="status" aria-live="polite">
        {toast}
      </div>
    </div>
  )
}
