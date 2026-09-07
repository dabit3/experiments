import { useEffect, useRef, useState } from 'react'
import { ALL_REGIONS } from '../data/aggregate'
import type { Region } from '../data/dataset'

interface Props {
  selected: Region[]
  onChange: (regions: Region[]) => void
  colors: string[]
}

export function RegionMultiSelect({ selected, onChange, colors }: Props) {
  const [open, setOpen] = useState(false)
  const ref = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!open) return
    const onDocClick = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false)
    }
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setOpen(false)
    }
    document.addEventListener('mousedown', onDocClick)
    document.addEventListener('keydown', onKey)
    return () => {
      document.removeEventListener('mousedown', onDocClick)
      document.removeEventListener('keydown', onKey)
    }
  }, [open])

  const toggle = (region: Region) => {
    if (selected.includes(region)) {
      if (selected.length === 1) return // keep at least one region
      onChange(selected.filter((r) => r !== region))
    } else {
      onChange(ALL_REGIONS.filter((r) => r === region || selected.includes(r)))
    }
  }

  const summary =
    selected.length === ALL_REGIONS.length
      ? 'All regions'
      : selected.length === 1
        ? selected[0]
        : `${selected.length} regions`

  return (
    <div className={`multiselect${open ? ' multiselect--open' : ''}`} ref={ref}>
      <button
        type="button"
        className="btn btn--field"
        onClick={() => setOpen((o) => !o)}
        aria-haspopup="listbox"
        aria-expanded={open}
        data-testid="region-toggle"
      >
        <span className="btn__label">Region</span>
        <span className="btn__value">{summary}</span>
        <span className="btn__chevron" aria-hidden="true">
          ▾
        </span>
      </button>
      {open && (
        <ul className="multiselect__menu" role="listbox" aria-multiselectable="true" data-testid="region-menu">
          {ALL_REGIONS.map((region, i) => {
            const checked = selected.includes(region)
            return (
              <li key={region}>
                <label className="multiselect__option">
                  <input
                    type="checkbox"
                    checked={checked}
                    onChange={() => toggle(region)}
                    data-testid={`region-option-${region}`}
                  />
                  <span className="swatch" style={{ background: colors[i % colors.length] }} />
                  {region}
                </label>
              </li>
            )
          })}
          <li className="multiselect__footer">
            <button type="button" className="link" onClick={() => onChange(ALL_REGIONS)}>
              Select all
            </button>
          </li>
        </ul>
      )}
    </div>
  )
}
