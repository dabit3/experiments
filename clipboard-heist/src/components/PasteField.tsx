import { useState, type ClipboardEvent, type KeyboardEvent } from 'react'
import './PasteField.css'

interface Props {
  id: string
  value: string
  placeholder: string
  maxLength?: number
  disabled?: boolean
  locked?: boolean
  state?: 'idle' | 'ok' | 'error'
  onPaste: (text: string) => void
  onClear?: () => void
  autoFocus?: boolean
}

const PASSTHROUGH_KEYS = new Set(['Tab', 'Escape', 'Enter', 'ArrowLeft', 'ArrowRight', 'Home', 'End'])

export default function PasteField({
  id,
  value,
  placeholder,
  maxLength,
  disabled,
  locked,
  state = 'idle',
  onPaste,
  onClear,
  autoFocus,
}: Props) {
  const [typedWarning, setTypedWarning] = useState(false)

  function handleKeyDown(e: KeyboardEvent<HTMLInputElement>) {
    if (e.ctrlKey || e.metaKey || PASSTHROUGH_KEYS.has(e.key)) return
    if (e.key === 'Backspace' || e.key === 'Delete') {
      e.preventDefault()
      onClear?.()
      return
    }
    if (e.key.length === 1) {
      e.preventDefault()
      setTypedWarning(true)
      window.setTimeout(() => setTypedWarning(false), 1400)
    }
  }

  function handlePaste(e: ClipboardEvent<HTMLInputElement>) {
    e.preventDefault()
    const text = e.clipboardData.getData('text/plain').trim()
    onPaste(text)
  }

  return (
    <div className={`paste-field paste-field--${state} ${locked ? 'paste-field--locked' : ''}`}>
      <input
        id={id}
        className="paste-field__input"
        value={value}
        placeholder={placeholder}
        maxLength={maxLength}
        disabled={disabled || locked}
        autoComplete="off"
        spellCheck={false}
        onChange={() => undefined}
        onKeyDown={handleKeyDown}
        onPaste={handlePaste}
        autoFocus={autoFocus}
      />
      <span className="paste-field__badge" aria-hidden="true">
        {locked ? 'LOCKED' : 'PASTE ONLY · Ctrl+V'}
      </span>
      {typedWarning && (
        <div className="paste-field__warning" role="status">
          Keypad ignores typed characters — paste it with Ctrl+V.
        </div>
      )}
    </div>
  )
}
