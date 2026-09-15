import type { KeyboardEvent } from 'react'

interface Props {
  label: string
  value: string
  onChange: (value: string) => void
  onKeyDown: (e: KeyboardEvent<HTMLInputElement>) => void
}

export function FormulaBar({ label, value, onChange, onKeyDown }: Props) {
  return (
    <div className="formula-bar">
      <div className="cell-ref" data-testid="active-ref">
        {label}
      </div>
      <div className="fx">fx</div>
      <input
        className="formula-input"
        data-testid="formula-input"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        onKeyDown={onKeyDown}
        spellCheck={false}
        placeholder="Type a value or a formula such as =SUM(B2:B6)"
      />
    </div>
  )
}
