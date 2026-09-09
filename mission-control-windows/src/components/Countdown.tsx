interface CountdownProps {
  value: number
  onAbort: () => void
  compact?: boolean
}

export function Countdown({ value, onAbort, compact }: CountdownProps) {
  return (
    <div className={`countdown${compact ? ' countdown--compact' : ''}`} role="alert">
      <span className="caption countdown__caption">Terminal count</span>
      <div className="countdown__ring" key={value}>
        <span className="countdown__digit mono">{value}</span>
      </div>
      <p className="countdown__hint">Do not press abort.</p>
      <button type="button" className="btn btn--red btn--lg countdown__abort" onClick={onAbort}>
        Abort
      </button>
    </div>
  )
}
