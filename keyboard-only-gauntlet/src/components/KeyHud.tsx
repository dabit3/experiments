import type { KeyChip } from '../hooks/useKeyLog'

interface Props {
  recent: KeyChip[]
  total: number
}

export function KeyHud({ recent, total }: Props) {
  return (
    <footer className="keyhud" aria-hidden="true">
      <span className="keyhud-label">Keys</span>
      <div className="keyhud-chips">
        {recent.length === 0 && <span className="keyhud-empty">waiting for input…</span>}
        {recent.map((chip, i) => (
          <kbd key={chip.id} className={`keychip${i === recent.length - 1 ? ' latest' : ''}`}>
            {chip.label}
          </kbd>
        ))}
      </div>
      <span className="keyhud-total">
        <strong>{total}</strong> keystrokes
      </span>
    </footer>
  )
}
