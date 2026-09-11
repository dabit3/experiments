import type { ReactNode } from 'react'

interface Props {
  id: string
  label: string
  error?: string
  hint?: string
  children: ReactNode
  className?: string
}

export function Field({ id, label, error, hint, children, className = '' }: Props) {
  return (
    <div className={`field ${error ? 'has-error' : ''} ${className}`}>
      <label htmlFor={id}>{label}</label>
      {children}
      {error ? (
        <p className="field-error" id={`${id}-error`} role="alert">
          <svg viewBox="0 0 16 16" width="14" height="14" aria-hidden>
            <circle cx="8" cy="8" r="7" fill="currentColor" opacity=".18" />
            <path d="M8 4.5v4M8 11.2v.3" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
          </svg>
          {error}
        </p>
      ) : hint ? (
        <p className="field-hint">{hint}</p>
      ) : null}
    </div>
  )
}
