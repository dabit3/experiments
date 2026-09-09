import { useState } from 'react'
import type { Stats } from '../lib/stats'
import { Modal } from './Modal'
import './StatsModal.css'

interface StatsModalProps {
  open: boolean
  onClose: () => void
  stats: Stats
  seed: number
  finished: boolean
  won: boolean
  answer: string
  shareText: string | null
  onShare: () => Promise<boolean>
  onPlaySeed: (seed: number) => void
}

export function StatsModal({
  open,
  onClose,
  stats,
  seed,
  finished,
  won,
  answer,
  shareText,
  onShare,
  onPlaySeed,
}: StatsModalProps) {
  const [copied, setCopied] = useState(false)
  const winPct = stats.gamesPlayed === 0 ? 0 : Math.round((stats.gamesWon / stats.gamesPlayed) * 100)
  const maxCount = Math.max(1, ...stats.guessDistribution)

  const handleShare = async () => {
    const ok = await onShare()
    setCopied(ok)
    if (ok) window.setTimeout(() => setCopied(false), 2000)
  }

  return (
    <Modal open={open} onClose={onClose} title="Statistics" testId="stats-modal">
      <div className="stats__grid">
        <Stat label="Played" value={stats.gamesPlayed} testId="stat-played" />
        <Stat label="Win %" value={winPct} testId="stat-winpct" />
        <Stat label="Current streak" value={stats.currentStreak} testId="stat-streak" />
        <Stat label="Max streak" value={stats.maxStreak} testId="stat-maxstreak" />
      </div>

      <h3 className="stats__subtitle">Guess distribution</h3>
      <ol className="dist">
        {stats.guessDistribution.map((count, i) => {
          const pct = Math.max(8, Math.round((count / maxCount) * 100))
          const highlight = finished && won && stats.lastGuessCount === i + 1
          return (
            <li className="dist__row" key={i}>
              <span className="dist__label">{i + 1}</span>
              <div className="dist__track">
                <div
                  className={`dist__bar ${highlight ? 'dist__bar--highlight' : ''} ${count === 0 ? 'dist__bar--empty' : ''}`}
                  style={{ width: count === 0 ? '8%' : `${pct}%` }}
                >
                  {count}
                </div>
              </div>
            </li>
          )
        })}
      </ol>

      {finished && (
        <div className="stats__result">
          <p className="stats__answer">
            {won ? 'You solved' : 'The answer was'} <strong>{answer.toUpperCase()}</strong>
            {' · '}seed <strong>#{seed}</strong>
          </p>
          {shareText && (
            <pre className="stats__share-preview" aria-label="Share preview">
              {shareText}
            </pre>
          )}
        </div>
      )}

      <div className="stats__actions">
        <button
          type="button"
          className="button button--secondary"
          onClick={() => onPlaySeed(seed + 1)}
        >
          Next seed
          <span className="button__hint">#{seed + 1}</span>
        </button>
        {finished && (
          <button
            type="button"
            className={`button button--primary ${copied ? 'button--copied' : ''}`}
            onClick={handleShare}
            data-testid="share-button"
          >
            {copied ? 'Copied!' : 'Share'}
            <ShareIcon />
          </button>
        )}
      </div>
    </Modal>
  )
}

function Stat({ label, value, testId }: { label: string; value: number; testId: string }) {
  return (
    <div className="stat">
      <div className="stat__value" data-testid={testId}>
        {value}
      </div>
      <div className="stat__label">{label}</div>
    </div>
  )
}

function ShareIcon() {
  return (
    <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true">
      <path
        fill="currentColor"
        d="M18 16.08c-.76 0-1.44.3-1.96.77L8.91 12.7c.05-.23.09-.46.09-.7s-.04-.47-.09-.7l7.05-4.11c.54.5 1.25.81 2.04.81 1.66 0 3-1.34 3-3s-1.34-3-3-3-3 1.34-3 3c0 .24.04.47.09.7L8.04 9.81C7.5 9.31 6.79 9 6 9c-1.66 0-3 1.34-3 3s1.34 3 3 3c.79 0 1.5-.31 2.04-.81l7.12 4.16c-.05.21-.08.43-.08.65 0 1.61 1.31 2.92 2.92 2.92s2.92-1.31 2.92-2.92-1.31-2.92-2.92-2.92z"
      />
    </svg>
  )
}
