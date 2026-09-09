import { useState } from 'react'
import './CopyButton.css'

interface Props {
  label: string
  onCopy: () => Promise<boolean>
  variant?: 'primary' | 'ghost'
  size?: 'md' | 'sm'
  copiedLabel?: string
}

export default function CopyButton({
  label,
  onCopy,
  variant = 'primary',
  size = 'md',
  copiedLabel = 'Copied',
}: Props) {
  const [status, setStatus] = useState<'idle' | 'done' | 'failed'>('idle')

  async function handleClick() {
    const ok = await onCopy()
    setStatus(ok ? 'done' : 'failed')
    window.setTimeout(() => setStatus('idle'), 1500)
  }

  return (
    <button
      type="button"
      className={`copy-btn copy-btn--${variant} copy-btn--${size} copy-btn--${status}`}
      onClick={handleClick}
    >
      <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true">
        {status === 'done' ? (
          <path d="M5 12.5l4.5 4.5L19 7.5" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" />
        ) : (
          <>
            <rect x="8" y="3" width="8" height="4" rx="1.2" fill="none" stroke="currentColor" strokeWidth="1.8" />
            <path d="M8 5H6.5A1.5 1.5 0 0 0 5 6.5v13A1.5 1.5 0 0 0 6.5 21h11a1.5 1.5 0 0 0 1.5-1.5v-13A1.5 1.5 0 0 0 17.5 5H16" fill="none" stroke="currentColor" strokeWidth="1.8" />
          </>
        )}
      </svg>
      <span>{status === 'done' ? copiedLabel : status === 'failed' ? 'Copy blocked' : label}</span>
    </button>
  )
}
