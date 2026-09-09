import { useEffect, useId, useRef, useState, type KeyboardEvent } from 'react'
import type { Airport } from '../types'
import { searchAirports } from '../data/airports'

interface Props {
  id: string
  label: string
  placeholder: string
  value: Airport | null
  exclude?: string | null
  error?: string
  onChange: (airport: Airport | null) => void
}

export function AirportAutocomplete({ id, label, placeholder, value, exclude, error, onChange }: Props) {
  const [query, setQuery] = useState('')
  const [open, setOpen] = useState(false)
  const [active, setActive] = useState(0)
  const wrapRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLInputElement>(null)
  const listId = useId()

  const results = open ? searchAirports(query, exclude) : []

  useEffect(() => {
    const onDocClick = (e: MouseEvent) => {
      if (!wrapRef.current?.contains(e.target as Node)) setOpen(false)
    }
    document.addEventListener('mousedown', onDocClick)
    return () => document.removeEventListener('mousedown', onDocClick)
  }, [])

  const select = (ap: Airport) => {
    onChange(ap)
    setQuery('')
    setOpen(false)
  }

  const onKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (!open || results.length === 0) {
      if (e.key === 'ArrowDown' && query) setOpen(true)
      return
    }
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      setActive((a) => (a + 1) % results.length)
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      setActive((a) => (a - 1 + results.length) % results.length)
    } else if (e.key === 'Enter') {
      e.preventDefault()
      select(results[active])
    } else if (e.key === 'Escape') {
      setOpen(false)
    }
  }

  return (
    <div className={`field airport-field ${error ? 'has-error' : ''}`} ref={wrapRef}>
      <label htmlFor={id}>{label}</label>
      {value ? (
        <div className="airport-chip-wrap">
          <button
            type="button"
            className="airport-chip"
            onClick={() => {
              onChange(null)
              setTimeout(() => inputRef.current?.focus(), 0)
            }}
            title="Change airport"
          >
            <span className="airport-chip-code">{value.code}</span>
            <span className="airport-chip-text">
              <span className="airport-chip-city">{value.city}</span>
              <span className="airport-chip-name">{value.name}</span>
            </span>
            <span className="airport-chip-x" aria-hidden>
              ×
            </span>
          </button>
        </div>
      ) : (
        <div className="airport-input-wrap">
          <svg className="airport-input-icon" viewBox="0 0 24 24" width="20" height="20" aria-hidden>
            <path
              d="M21 16v-2l-8-5V3.5a1.5 1.5 0 0 0-3 0V9l-8 5v2l8-2.5V19l-2 1.5V22l3.5-1 3.5 1v-1.5L13 19v-5.5z"
              fill="currentColor"
            />
          </svg>
          <input
            ref={inputRef}
            id={id}
            className="input"
            type="text"
            role="combobox"
            aria-expanded={open && results.length > 0}
            aria-controls={listId}
            aria-autocomplete="list"
            aria-invalid={error ? true : undefined}
            autoComplete="off"
            placeholder={placeholder}
            value={query}
            onChange={(e) => {
              setQuery(e.target.value)
              setOpen(true)
              setActive(0)
            }}
            onFocus={() => query && setOpen(true)}
            onKeyDown={onKeyDown}
          />
          {open && query && (
            <ul className="autocomplete-list" id={listId} role="listbox">
              {results.length === 0 && <li className="autocomplete-empty">No airports match “{query}”</li>}
              {results.map((ap, i) => (
                <li
                  key={ap.code}
                  role="option"
                  aria-selected={i === active}
                  className={`autocomplete-item ${i === active ? 'active' : ''}`}
                  onMouseEnter={() => setActive(i)}
                  onMouseDown={(e) => e.preventDefault()}
                  onClick={() => select(ap)}
                >
                  <span className="ac-code">{ap.code}</span>
                  <span className="ac-text">
                    <span className="ac-city">
                      {ap.city} <span className="ac-country">· {ap.country}</span>
                    </span>
                    <span className="ac-name">{ap.name}</span>
                  </span>
                </li>
              ))}
            </ul>
          )}
        </div>
      )}
      {error && (
        <p className="field-error" role="alert">
          {error}
        </p>
      )}
    </div>
  )
}
