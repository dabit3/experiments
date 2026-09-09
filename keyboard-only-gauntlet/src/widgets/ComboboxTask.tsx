import { useEffect, useMemo, useRef, useState } from 'react'
import type { ChangeEvent, KeyboardEvent } from 'react'
import type { WidgetProps } from './types'

export const COMBOBOX_TARGET = 'Kazakhstan'

const COUNTRIES = [
  'Afghanistan', 'Albania', 'Algeria', 'Argentina', 'Armenia', 'Australia', 'Austria', 'Azerbaijan',
  'Bahrain', 'Bangladesh', 'Belgium', 'Bolivia', 'Brazil', 'Bulgaria',
  'Cambodia', 'Cameroon', 'Canada', 'Chile', 'China', 'Colombia', 'Croatia', 'Cuba', 'Czechia',
  'Denmark', 'Ecuador', 'Egypt', 'Estonia', 'Ethiopia', 'Finland', 'France',
  'Georgia', 'Germany', 'Ghana', 'Greece', 'Guatemala', 'Hungary', 'Iceland', 'India', 'Indonesia',
  'Iran', 'Iraq', 'Ireland', 'Israel', 'Italy', 'Jamaica', 'Japan', 'Jordan',
  'Kazakhstan', 'Kenya', 'Kiribati', 'Kosovo', 'Kuwait', 'Kyrgyzstan',
  'Laos', 'Latvia', 'Lebanon', 'Lithuania', 'Luxembourg', 'Madagascar', 'Malaysia', 'Mexico',
  'Mongolia', 'Morocco', 'Nepal', 'Netherlands', 'New Zealand', 'Nigeria', 'Norway',
  'Pakistan', 'Peru', 'Philippines', 'Poland', 'Portugal', 'Qatar', 'Romania',
  'Saudi Arabia', 'Senegal', 'Serbia', 'Singapore', 'Slovakia', 'Slovenia', 'South Africa',
  'South Korea', 'Spain', 'Sri Lanka', 'Sweden', 'Switzerland', 'Taiwan', 'Tajikistan', 'Tanzania',
  'Thailand', 'Tunisia', 'Turkey', 'Turkmenistan', 'Uganda', 'Ukraine', 'United Arab Emirates',
  'United Kingdom', 'United States', 'Uruguay', 'Uzbekistan', 'Venezuela', 'Vietnam', 'Zambia', 'Zimbabwe',
]

function filterCountries(query: string): string[] {
  const q = query.trim().toLowerCase()
  if (!q) return COUNTRIES
  const starts = COUNTRIES.filter((c) => c.toLowerCase().startsWith(q))
  const contains = COUNTRIES.filter((c) => !c.toLowerCase().startsWith(q) && c.toLowerCase().includes(q))
  return [...starts, ...contains]
}

function Highlight({ text, query }: { text: string; query: string }) {
  const q = query.trim().toLowerCase()
  const at = q ? text.toLowerCase().indexOf(q) : -1
  if (at === -1) return <>{text}</>
  return (
    <>
      {text.slice(0, at)}
      <mark>{text.slice(at, at + q.length)}</mark>
      {text.slice(at + q.length)}
    </>
  )
}

export function ComboboxTask({ onComplete }: WidgetProps) {
  const [query, setQuery] = useState('')
  const [open, setOpen] = useState(false)
  const [active, setActive] = useState(-1)
  const [selected, setSelected] = useState<string | null>(null)
  const listRef = useRef<HTMLUListElement>(null)
  const options = useMemo(() => filterCountries(query), [query])

  useEffect(() => {
    if (!open || active < 0) return
    listRef.current?.children[active]?.scrollIntoView({ block: 'nearest' })
  }, [open, active])

  const select = (name: string) => {
    setSelected(name)
    setQuery(name)
    setOpen(false)
    setActive(-1)
    if (name === COMBOBOX_TARGET) onComplete()
  }

  const onChange = (e: ChangeEvent<HTMLInputElement>) => {
    setQuery(e.target.value)
    setSelected(null)
    setOpen(true)
    setActive(-1)
  }

  const onKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    switch (e.key) {
      case 'ArrowDown':
        if (!open) {
          setOpen(true)
          setActive(e.altKey || options.length === 0 ? -1 : 0)
        } else if (options.length > 0) {
          setActive((a) => (a + 1) % options.length)
        }
        break
      case 'ArrowUp':
        if (!open) {
          setOpen(true)
          setActive(options.length - 1)
        } else if (options.length > 0) {
          setActive((a) => (a <= 0 ? options.length - 1 : a - 1))
        }
        break
      case 'Enter':
        if (!open || active < 0) return
        select(options[active])
        break
      case 'Escape':
        if (open) {
          setOpen(false)
          setActive(-1)
        } else {
          setQuery('')
          setSelected(null)
        }
        break
      case 'Tab':
        setOpen(false)
        return
      default:
        return
    }
    e.preventDefault()
  }

  const activeId = open && active >= 0 ? `country-option-${active}` : undefined

  return (
    <div className="combobox-shell">
      <label className="field-label" htmlFor="country-input">
        Shipping country
      </label>
      <div className={`combobox${open ? ' open' : ''}`}>
        <input
          id="country-input"
          className="combobox-input"
          type="text"
          role="combobox"
          aria-autocomplete="list"
          aria-expanded={open}
          aria-controls="country-listbox"
          aria-activedescendant={activeId}
          autoComplete="off"
          spellCheck={false}
          placeholder="Start typing a country…"
          value={query}
          onChange={onChange}
          onKeyDown={onKeyDown}
          onBlur={() => setOpen(false)}
        />
        <span className="combobox-chevron" aria-hidden="true">
          ▾
        </span>
        <ul
          id="country-listbox"
          role="listbox"
          aria-label="Countries"
          className="listbox"
          ref={listRef}
          hidden={!open}
        >
          {options.map((name, i) => (
            <li
              key={name}
              id={`country-option-${i}`}
              role="option"
              aria-selected={i === active}
              className={`option${i === active ? ' active' : ''}`}
            >
              <Highlight text={name} query={query} />
            </li>
          ))}
          {options.length === 0 && (
            <li className="option empty" role="presentation">
              No matches
            </li>
          )}
        </ul>
      </div>
      <p className="widget-status" aria-live="polite">
        {selected ? (
          <>
            Selected <strong>{selected}</strong>
            {selected !== COMBOBOX_TARGET && <span className="status-hint"> — not the target, pick Kazakhstan</span>}
          </>
        ) : open ? (
          `${options.length} match${options.length === 1 ? '' : 'es'} · ↓ to highlight, Enter to select`
        ) : (
          'No country selected'
        )}
      </p>
    </div>
  )
}
