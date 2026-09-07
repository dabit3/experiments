import type { ReactNode } from 'react'

interface Props {
  id: string
  label: string
  error?: string
  hint?: string
  optional?: boolean
  children: ReactNode
}

/** Form field wrapper: label, control, and inline error wired up with aria attributes. */
export function Field({ id, label, error, hint, optional, children }: Props) {
  return (
    <div className={`field${error ? ' field--invalid' : ''}`}>
      <label htmlFor={id} className="field__label">
        {label}
        {optional && <span className="field__optional">Optional</span>}
      </label>
      {children}
      {error ? (
        <p className="field__error" id={`${id}-error`} role="alert">
          {error}
        </p>
      ) : hint ? (
        <p className="field__hint">{hint}</p>
      ) : null}
    </div>
  )
}
