import { Icon } from './Icon'

export interface TransportProps {
  speed: number
  isPlaying: boolean
  onTogglePlay: () => void
  onShuttle: (dir: 1 | -1) => void
  onPause: () => void
  onGoStart: () => void
  onGoEnd: () => void
  onStep: (dir: 1 | -1) => void
}

export function Transport(p: TransportProps) {
  return (
    <div className="transport" role="group" aria-label="Transport">
      <button className="icon-btn" onClick={p.onGoStart} title="Go to start (Home)" aria-label="Go to start"><Icon name="skip-start" size={16} /></button>
      <button className={`icon-btn ${p.speed < 0 ? 'active' : ''}`} onClick={() => p.onShuttle(-1)} title="Shuttle backwards (J)" aria-label="Shuttle backwards"><Icon name="rewind" size={18} /></button>
      <button className="icon-btn" onClick={() => p.onStep(-1)} title="Previous frame (←)" aria-label="Previous frame"><Icon name="step-back" size={18} /></button>
      <button className={`play-btn ${p.isPlaying ? 'playing' : ''}`} onClick={p.onTogglePlay} title="Play / pause (Space)" aria-label={p.isPlaying ? 'Pause' : 'Play'}><Icon name={p.isPlaying ? 'pause' : 'play'} size={20} /></button>
      <button className="icon-btn" onClick={() => p.onStep(1)} title="Next frame (→)" aria-label="Next frame"><Icon name="step-forward" size={18} /></button>
      <button className={`icon-btn ${p.speed > 0 ? 'active' : ''}`} onClick={() => p.onShuttle(1)} title="Shuttle forwards (L)" aria-label="Shuttle forwards"><Icon name="forward" size={18} /></button>
      <button className="icon-btn" onClick={p.onGoEnd} title="Go to end (End)" aria-label="Go to end"><Icon name="skip-end" size={16} /></button>
      <button className="icon-btn transport-stop" onClick={p.onPause} title="Stop (K)" aria-label="Stop"><Icon name="stop" size={14} /></button>
    </div>
  )
}
