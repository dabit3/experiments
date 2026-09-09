import { useMemo, useState } from 'react'
import type { FareClass, Flight, FlightSelection, Leg, SearchParams } from '../../types'
import { FARES, farePrice, flightsFor } from '../../data/flights'
import { AIRPORT_BY_CODE } from '../../data/airports'
import { formatDuration, formatLong, to12h } from '../../lib/date'
import { legTimes, money } from '../../lib/booking'

interface Props {
  search: SearchParams
  initial: Partial<Record<Leg, FlightSelection>>
  onChange: (sel: Partial<Record<Leg, FlightSelection>>) => void
  onDone: (sel: Partial<Record<Leg, FlightSelection>>) => void
  onBack: () => void
}

type SortKey = 'price' | 'duration' | 'departure'
type StopsFilter = 'any' | 0 | 1
type WindowFilter = 'any' | 'morning' | 'afternoon' | 'evening'

const WINDOWS: Record<Exclude<WindowFilter, 'any'>, [number, number]> = {
  morning: [5, 12],
  afternoon: [12, 18],
  evening: [18, 24],
}

export function ResultsStep({ search, initial, onChange, onDone, onBack }: Props) {
  const [leg, setLeg] = useState<Leg>(initial.outbound && search.roundTrip && !initial.return ? 'return' : 'outbound')
  const [selections, setSelections] = useState<Partial<Record<Leg, FlightSelection>>>(initial)
  const [sort, setSort] = useState<SortKey>('departure')
  const [stops, setStops] = useState<StopsFilter>('any')
  const [win, setWin] = useState<WindowFilter>('any')
  const [maxPrice, setMaxPrice] = useState<number | null>(null)
  const [expanded, setExpanded] = useState<string | null>(null)

  const from = leg === 'outbound' ? search.from! : search.to!
  const to = leg === 'outbound' ? search.to! : search.from!
  const date = leg === 'outbound' ? search.depart! : search.ret!
  const paxCount = search.adults + search.children

  const all = useMemo(() => flightsFor(from.code, to.code), [from.code, to.code])
  const priceBounds = useMemo(() => {
    const prices = all.map((f) => f.price)
    return { min: Math.min(...prices), max: Math.max(...prices) }
  }, [all])

  const visible = useMemo(() => {
    let list = all.filter((f) => {
      if (stops === 0 && f.stops !== 0) return false
      if (stops === 1 && f.stops > 1) return false
      if (win !== 'any') {
        const hour = Number(f.depart.split(':')[0])
        const [lo, hi] = WINDOWS[win]
        if (hour < lo || hour >= hi) return false
      }
      if (maxPrice !== null && f.price > maxPrice) return false
      return true
    })
    list = [...list].sort((x, y) => {
      if (sort === 'price') return x.price - y.price
      if (sort === 'duration') return x.durationMin - y.durationMin
      return x.depart.localeCompare(y.depart)
    })
    return list
  }, [all, stops, win, maxPrice, sort])

  const chooseFare = (flight: Flight, fare: FareClass) => {
    const next = { ...selections, [leg]: { flight, fare } }
    setSelections(next)
    onChange(next)
    setExpanded(null)
    if (leg === 'outbound' && search.roundTrip) {
      setLeg('return')
      setStops('any')
      setWin('any')
      setMaxPrice(null)
      window.scrollTo({ top: 0 })
      return
    }
    onDone(next)
  }

  const resetFilters = () => {
    setStops('any')
    setWin('any')
    setMaxPrice(null)
    setSort('departure')
  }

  const changeOutbound = () => {
    setLeg('outbound')
    setExpanded(null)
    window.scrollTo({ top: 0 })
  }

  const cheapest = visible.length ? Math.min(...visible.map((f) => f.price)) : null

  return (
    <div className="results">
      <div className="step-heading">
        <div>
          <p className="eyebrow">
            Step 2 · {search.roundTrip ? (leg === 'outbound' ? 'Outbound flight' : 'Return flight') : 'Your flight'}
          </p>
          <h2>
            {from.city} <span className="arrow">→</span> {to.city}
          </h2>
          <p className="muted">
            {formatLong(date)} · {paxCount} passenger{paxCount === 1 ? '' : 's'} · prices per passenger
          </p>
        </div>
        <button type="button" className="btn btn-ghost" onClick={onBack}>
          Edit search
        </button>
      </div>

      {leg === 'return' && selections.outbound && (
        <div className="selected-banner">
          <span className="selected-banner-tag">Outbound selected</span>
          <span>
            {selections.outbound.flight.airline.name} {selections.outbound.flight.number} · {to12h(selections.outbound.flight.depart)} · {FARES[selections.outbound.fare].label} ·{' '}
            {money(farePrice(selections.outbound.flight, selections.outbound.fare))}
          </span>
          <button type="button" className="link-btn" onClick={changeOutbound}>
            Change
          </button>
        </div>
      )}

      <div className="results-toolbar card">
        <div className="toolbar-group">
          <span className="toolbar-label">Sort by</span>
          <div className="segmented small" role="radiogroup" aria-label="Sort">
            {(['departure', 'price', 'duration'] as SortKey[]).map((k) => (
              <button key={k} type="button" role="radio" aria-checked={sort === k} className={sort === k ? 'active' : ''} onClick={() => setSort(k)}>
                {k === 'price' ? 'Price' : k === 'duration' ? 'Duration' : 'Departure'}
              </button>
            ))}
          </div>
        </div>
        <div className="toolbar-group">
          <span className="toolbar-label">Stops</span>
          <div className="chip-row">
            {(
              [
                ['any', 'Any'],
                [0, 'Nonstop'],
                [1, 'Up to 1 stop'],
              ] as [StopsFilter, string][]
            ).map(([v, label]) => (
              <button key={String(v)} type="button" className={`chip ${stops === v ? 'active' : ''}`} aria-pressed={stops === v} onClick={() => setStops(v)}>
                {label}
              </button>
            ))}
          </div>
        </div>
        <div className="toolbar-group">
          <span className="toolbar-label">Departure</span>
          <div className="chip-row">
            {(
              [
                ['any', 'Any time'],
                ['morning', 'Morning'],
                ['afternoon', 'Afternoon'],
                ['evening', 'Evening'],
              ] as [WindowFilter, string][]
            ).map(([v, label]) => (
              <button key={v} type="button" className={`chip ${win === v ? 'active' : ''}`} aria-pressed={win === v} onClick={() => setWin(v)}>
                {label}
              </button>
            ))}
          </div>
        </div>
        <div className="toolbar-group price-group">
          <label htmlFor="max-price" className="toolbar-label">
            Max price <strong>{money(maxPrice ?? priceBounds.max)}</strong>
          </label>
          <input
            id="max-price"
            type="range"
            min={priceBounds.min}
            max={priceBounds.max}
            step={1}
            value={maxPrice ?? priceBounds.max}
            onChange={(e) => setMaxPrice(Number(e.target.value))}
          />
        </div>
      </div>

      <p className="results-count muted">
        {visible.length} of {all.length} flights
        {(stops !== 'any' || win !== 'any' || maxPrice !== null) && (
          <>
            {' · '}
            <button type="button" className="link-btn" onClick={resetFilters}>
              Clear filters
            </button>
          </>
        )}
      </p>

      <ul className="flight-list">
        {visible.map((f) => {
          const times = legTimes(f, date)
          const isExpanded = expanded === f.id
          const isCheapest = f.price === cheapest
          return (
            <li key={f.id} className={`flight-card card ${isExpanded ? 'expanded' : ''}`}>
              <div className="flight-main">
                <div className="airline">
                  <span className="airline-logo" style={{ background: f.airline.color }}>
                    {f.airline.code}
                  </span>
                  <span className="airline-text">
                    <span className="airline-name">{f.airline.name}</span>
                    <span className="airline-meta">
                      {f.number} · {f.aircraft}
                    </span>
                  </span>
                </div>
                <div className="timeline">
                  <div className="time">
                    <strong>{to12h(f.depart)}</strong>
                    <span>{f.from}</span>
                  </div>
                  <div className="route">
                    <span className="route-duration">{formatDuration(f.durationMin)}</span>
                    <span className="route-line">
                      {f.via.map((v) => (
                        <span key={v} className="route-stop" title={`Stop in ${AIRPORT_BY_CODE[v]?.city ?? v}`} />
                      ))}
                    </span>
                    <span className={`route-stops ${f.stops === 0 ? 'nonstop' : ''}`}>
                      {f.stops === 0 ? 'Nonstop' : `${f.stops} stop${f.stops > 1 ? 's' : ''} · ${f.via.join(', ')}`}
                    </span>
                  </div>
                  <div className="time">
                    <strong>
                      {to12h(times.arriveLocal)}
                      {times.dayOffset > 0 && <sup className="next-day">+{times.dayOffset}</sup>}
                    </strong>
                    <span>{f.to}</span>
                  </div>
                </div>
                <div className="price-col">
                  {isCheapest && <span className="badge badge-green">Cheapest</span>}
                  <span className="price-from">from</span>
                  <strong className="price">{money(f.price)}</strong>
                  <button
                    type="button"
                    className={`btn ${isExpanded ? 'btn-ghost' : 'btn-primary'}`}
                    onClick={() => setExpanded(isExpanded ? null : f.id)}
                    aria-expanded={isExpanded}
                  >
                    {isExpanded ? 'Hide fares' : 'Select'}
                  </button>
                </div>
              </div>
              {isExpanded && (
                <div className="fare-grid">
                  {(Object.keys(FARES) as FareClass[]).map((fare) => (
                    <div key={fare} className={`fare-card fare-${fare}`}>
                      <div className="fare-head">
                        <span className="fare-name">{FARES[fare].label}</span>
                        <span className="fare-price">{money(farePrice(f, fare))}</span>
                      </div>
                      <ul className="fare-perks">
                        {FARES[fare].perks.map((p) => (
                          <li key={p}>{p}</li>
                        ))}
                      </ul>
                      <button type="button" className={`btn ${fare === 'standard' ? 'btn-primary' : 'btn-outline'} btn-block`} onClick={() => chooseFare(f, fare)}>
                        Choose {FARES[fare].label}
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </li>
          )
        })}
        {visible.length === 0 && (
          <li className="card empty-state">
            No flights match these filters.{' '}
            <button type="button" className="link-btn" onClick={resetFilters}>
              Clear filters
            </button>
          </li>
        )}
      </ul>
    </div>
  )
}
