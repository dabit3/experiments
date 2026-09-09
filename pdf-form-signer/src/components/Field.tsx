import type { ChangeEvent, ReactNode } from 'react'

interface FieldShellProps {
  id: string
  label: string
  required?: boolean
  error?: string
  hint?: string
  valid?: boolean
  className?: string
  children: ReactNode
  shaking?: boolean
}

export function FieldShell({ id, label, required, error, hint, valid, className = '', children, shaking }: FieldShellProps) {
  return (
    <div
      className={`field ${className} ${error ? 'is-invalid' : ''} ${valid ? 'is-valid' : ''} ${shaking ? 'is-shaking' : ''}`}
      data-field={id}
    >
      <label className="field__label" htmlFor={id}>
        {label}
        {required ? (
          <span className="req" aria-hidden="true">
            *
          </span>
        ) : (
          <span className="opt">optional</span>
        )}
      </label>
      {children}
      {error ? (
        <div className="field__error" id={`${id}-error`} role="alert">
          <ErrorIcon />
          {error}
        </div>
      ) : hint ? (
        <div className="field__hint">{hint}</div>
      ) : null}
    </div>
  )
}

interface TextFieldProps {
  id: string
  label: string
  value: string
  onChange: (v: string) => void
  onCommit?: () => void
  type?: 'text' | 'email' | 'tel' | 'date' | 'number'
  placeholder?: string
  required?: boolean
  error?: string
  hint?: string
  valid?: boolean
  className?: string
  prefix?: string
  min?: string
  max?: string
  autoComplete?: string
  inputMode?: 'text' | 'numeric' | 'decimal' | 'email' | 'tel'
  shaking?: boolean
  multiline?: boolean
}

export function TextField(p: TextFieldProps) {
  const common = {
    id: p.id,
    name: p.id,
    value: p.value,
    placeholder: p.placeholder,
    'aria-invalid': !!p.error,
    'aria-describedby': p.error ? `${p.id}-error` : undefined,
    onChange: (e: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => p.onChange(e.target.value),
    onBlur: () => p.onCommit?.(),
  }
  return (
    <FieldShell
      id={p.id}
      label={p.label}
      required={p.required}
      error={p.error}
      hint={p.hint}
      valid={p.valid}
      className={p.className}
      shaking={p.shaking}
    >
      <div className="field__control">
        {p.prefix && <span className="field__prefix">{p.prefix}</span>}
        {p.multiline ? (
          <textarea {...common} className="field__input" rows={3} />
        ) : (
          <input
            {...common}
            className={`field__input ${p.prefix ? 'field__input--prefix' : ''}`}
            type={p.type ?? 'text'}
            min={p.min}
            max={p.max}
            autoComplete={p.autoComplete ?? 'off'}
            inputMode={p.inputMode}
          />
        )}
        {p.valid && !p.multiline && <CheckIcon className="field__valid-mark" />}
      </div>
    </FieldShell>
  )
}

interface SelectFieldProps {
  id: string
  label: string
  value: string
  onChange: (v: string) => void
  options: { value: string; label: string }[]
  placeholder?: string
  required?: boolean
  error?: string
  hint?: string
  valid?: boolean
  className?: string
  shaking?: boolean
}

export function SelectField(p: SelectFieldProps) {
  return (
    <FieldShell
      id={p.id}
      label={p.label}
      required={p.required}
      error={p.error}
      hint={p.hint}
      valid={p.valid}
      className={p.className}
      shaking={p.shaking}
    >
      <div className="field__control">
        <select
          id={p.id}
          name={p.id}
          className="field__input field__input--select"
          value={p.value}
          required
          aria-invalid={!!p.error}
          onChange={(e) => p.onChange(e.target.value)}
        >
          <option value="" disabled>
            {p.placeholder ?? 'Select…'}
          </option>
          {p.options.map((o) => (
            <option key={o.value} value={o.value}>
              {o.label}
            </option>
          ))}
        </select>
      </div>
    </FieldShell>
  )
}

interface RadioGroupProps<T extends string> {
  id: string
  label: string
  value: T | ''
  onChange: (v: T) => void
  options: { value: T; label: string; hint?: string }[]
  required?: boolean
  error?: string
  hint?: string
  className?: string
  row?: boolean
  shaking?: boolean
}

export function RadioGroup<T extends string>(p: RadioGroupProps<T>) {
  return (
    <FieldShell
      id={p.id}
      label={p.label}
      required={p.required}
      error={p.error}
      hint={p.hint}
      className={p.className}
      shaking={p.shaking}
    >
      <div className={`choice-group ${p.row ? 'choice-group--row' : ''}`} role="radiogroup" aria-labelledby={`${p.id}-label`}>
        {p.options.map((o, i) => {
          const checked = p.value === o.value
          return (
            <label key={o.value} className={`choice ${checked ? 'is-checked' : ''}`} htmlFor={i === 0 ? p.id : `${p.id}-${o.value}`}>
              <input
                type="radio"
                id={i === 0 ? p.id : `${p.id}-${o.value}`}
                name={p.id}
                value={o.value}
                checked={checked}
                onChange={() => p.onChange(o.value)}
              />
              <span className="choice__control choice__control--radio" aria-hidden="true" />
              <span className="choice__text">
                <span className="choice__label">{o.label}</span>
                {o.hint && <span className="choice__hint">{o.hint}</span>}
              </span>
            </label>
          )
        })}
      </div>
    </FieldShell>
  )
}

interface CheckboxProps {
  id: string
  label: string
  hint?: string
  checked: boolean
  onChange: (v: boolean) => void
  error?: string
}

export function Checkbox(p: CheckboxProps) {
  return (
    <div className={`field ${p.error ? 'is-invalid' : ''}`} data-field={p.id}>
      <label className={`choice ${p.checked ? 'is-checked' : ''}`} htmlFor={p.id}>
        <input type="checkbox" id={p.id} name={p.id} checked={p.checked} onChange={(e) => p.onChange(e.target.checked)} />
        <span className="choice__control choice__control--checkbox" aria-hidden="true">
          <CheckIcon stroke="#fff" />
        </span>
        <span className="choice__text">
          <span className="choice__label">{p.label}</span>
          {p.hint && <span className="choice__hint">{p.hint}</span>}
        </span>
      </label>
      {p.error && (
        <div className="field__error" role="alert">
          <ErrorIcon />
          {p.error}
        </div>
      )}
    </div>
  )
}

export function CheckIcon({ className, stroke = 'currentColor' }: { className?: string; stroke?: string }) {
  return (
    <svg
      className={className}
      width="16"
      height="16"
      viewBox="0 0 24 24"
      fill="none"
      stroke={stroke}
      strokeWidth="3"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M5 12.5l4.5 4.5L19 7.5" />
    </svg>
  )
}

export function ErrorIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm-1 5h2v7h-2V7zm0 9h2v2h-2v-2z" />
    </svg>
  )
}
