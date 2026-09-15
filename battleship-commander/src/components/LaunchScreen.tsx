import { Logo } from './Logo'

interface LaunchScreenProps {
  seed: number
  onStart: () => void
}

export function LaunchScreen({ seed, onStart }: LaunchScreenProps) {
  return (
    <main className="launch">
      <div className="launch__art" aria-hidden="true" />
      <header className="launch__nav">
        <span className="arcade-label">
          <Logo size={32} /> COMMANDER ARCADE
        </span>
        <span className="launch__edition">
          TACTICAL NAVAL COMBAT <i /> VOL. 01
        </span>
      </header>
      <section className="launch__content">
        <p className="launch__eyebrow">
          <span /> THE OCEAN IS YOUR ARENA
        </p>
        <h1 className="launch__title">
          BATTLESHIP<span>COMMANDER</span>
        </h1>
        <p className="launch__tagline">
          Outsmart. Outmaneuver.
          <br />
          <strong>Send them under.</strong>
        </p>
        <p className="launch__description">
          Five ships. One ocean. No second chances.
          <br />
          Take on a cunning AI in a battle of instinct and strategy.
        </p>
        <button
          type="button"
          className="btn btn--primary launch__start"
          onClick={onStart}
        >
          Take command <span aria-hidden="true">→</span>
        </button>
        <p className="launch__meta">
          1 PLAYER <span>•</span> VS HUNT & TARGET AI <span>•</span> FREE PLAY
        </p>
      </section>
      <div className="launch__coordinates" aria-hidden="true">
        N 08° 24′
        <br />E 142° 18′<span>PACIFIC THEATER</span>
      </div>
      <footer className="launch__footer">
        <div>
          <b>01</b>
          <span>
            <strong>DEPLOY YOUR FLEET</strong>Drag, rotate, find your formation.
          </span>
        </div>
        <div>
          <b>02</b>
          <span>
            <strong>HUNT THE UNKNOWN</strong>Read the ocean. Trust your radar.
          </span>
        </div>
        <div>
          <b>03</b>
          <span>
            <strong>RULE THE WAVES</strong>Sink all five. Claim your victory.
          </span>
        </div>
        <p>
          REPLAYABLE MISSION <strong>#{String(seed).padStart(4, '0')}</strong>
        </p>
      </footer>
    </main>
  )
}
