import { useState, type FormEvent } from 'react'
import type { SearchParams } from '../../types'
import { AirportAutocomplete } from '../AirportAutocomplete'
import { DateRangePicker } from '../DateRangePicker'
import { CountStepper } from '../CountStepper'

interface Props {
  initial: SearchParams
  onSearch: (params: SearchParams) => void
}

interface SearchErrors {
  from?: string
  to?: string
  depart?: string
  ret?: string
}

export function SearchStep({ initial, onSearch }: Props) {
  const [params, setParams] = useState<SearchParams>(initial)
  const [errors, setErrors] = useState<SearchErrors>({})

  const update = (patch: Partial<SearchParams>) => {
    setParams((p) => ({ ...p, ...patch }))
    setErrors({})
  }

  const swap = () => update({ from: params.to, to: params.from })

  const submit = (e: FormEvent) => {
    e.preventDefault()
    const errs: SearchErrors = {}
    if (!params.from) errs.from = 'Choose a departure airport'
    if (!params.to) errs.to = 'Choose a destination airport'
    if (!params.depart) errs.depart = 'Choose a departure date'
    if (params.roundTrip && !params.ret) errs.ret = 'Choose a return date'
    setErrors(errs)
    if (Object.keys(errs).length === 0) onSearch(params)
  }

  const paxTotal = params.adults + params.children

  return (
    <div className="search-hero">
      <div className="hero-scene">
        <img
          className="hero-image"
          src={`${import.meta.env.BASE_URL}contrail-coast.webp`}
          alt="Sunlit cliffs meeting the Pacific along the California coast"
          width="1536"
          height="1024"
          fetchPriority="high"
        />
        <div className="hero-copy">
          <p className="eyebrow">The art of getting there</p>
          <h1>
            Where to <em>next?</em>
          </h1>
          <p className="lede">
            For the places you've dreamed of.
            <br />
            And the people you can't wait to see.
          </p>
        </div>
        <div className="hero-caption">
          <span>Find your perspective</span>
          <strong>The Pacific Coast, California</strong>
        </div>
      </div>

      <form className="card search-card" onSubmit={submit} noValidate>
        <div className="search-card-head">
          <div className="search-card-title">
            <svg
              width="22"
              height="22"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.5"
              aria-hidden
            >
              <path d="m3 17 18-7-2-2-6 1-4-5-2 1 2 6-4 2-3-2-1 1zM3 21h18" strokeLinejoin="round" />
            </svg>
            <h2>Book a flight</h2>
          </div>
          <div className="segmented" role="radiogroup" aria-label="Trip type">
            <button
              type="button"
              role="radio"
              aria-checked={params.roundTrip}
              className={params.roundTrip ? 'active' : ''}
              onClick={() => update({ roundTrip: true })}
            >
              Round trip
            </button>
            <button
              type="button"
              role="radio"
              aria-checked={!params.roundTrip}
              className={!params.roundTrip ? 'active' : ''}
              onClick={() => update({ roundTrip: false, ret: null })}
            >
              One way
            </button>
          </div>
        </div>

        <div className="search-row airports-row">
          <AirportAutocomplete
            id="from-airport"
            label="From"
            placeholder="City or airport code"
            value={params.from}
            exclude={params.to?.code}
            error={errors.from}
            onChange={(ap) => update({ from: ap })}
          />
          <button
            type="button"
            className="swap-btn"
            onClick={swap}
            aria-label="Swap origin and destination"
            title="Swap"
          >
            <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden>
              <path
                d="M7 7h11m0 0l-3-3m3 3l-3 3M17 17H6m0 0l3 3m-3-3l3-3"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </button>
          <AirportAutocomplete
            id="to-airport"
            label="To"
            placeholder="City or airport code"
            value={params.to}
            exclude={params.from?.code}
            error={errors.to}
            onChange={(ap) => update({ to: ap })}
          />
        </div>

        <div className="search-row dates-pax-row">
          <div className="field">
            <span className="field-label-static">Dates</span>
            <DateRangePicker
              depart={params.depart}
              ret={params.ret}
              roundTrip={params.roundTrip}
              departError={errors.depart}
              returnError={errors.ret}
              onChange={(depart, ret) => update({ depart, ret })}
            />
          </div>
          <div className="field">
            <span className="field-label-static">Passengers</span>
            <div className="pax-box">
              <CountStepper
                id="adults"
                label="Adults"
                sublabel="Age 12+"
                value={params.adults}
                min={1}
                max={6}
                onChange={(n) => update({ adults: n })}
              />
              <CountStepper
                id="children"
                label="Children"
                sublabel="Age 2–11"
                value={params.children}
                min={0}
                max={4}
                onChange={(n) => update({ children: n })}
              />
            </div>
          </div>
        </div>

        <div className="search-actions">
          <span className="search-recap">
            {paxTotal} passenger{paxTotal === 1 ? '' : 's'} · {params.roundTrip ? 'Round trip' : 'One way'} · Economy
          </span>
          <button type="submit" className="btn btn-primary btn-lg">
            Search flights
            <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden>
              <path
                d="M5 12h14m0 0l-6-6m6 6l-6 6"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </button>
        </div>
      </form>

      <div className="experience-heading">
        <span className="eyebrow">Considered, from the start</span>
        <h2>
          A journey that feels like <em>yours.</em>
        </h2>
      </div>
      <ul className="hero-perks">
        <li>
          <span className="perk-icon">
            <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden>
              <path
                d="M4 7h16v10H4zM4 11h16M8 15h3"
                fill="none"
                stroke="currentColor"
                strokeWidth="1.8"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </span>
          <span className="perk-text">
            <strong>A little more clarity</strong>
            <span>Compare fares with confidence. Every tax and fee, clearly shown before you pay.</span>
          </span>
        </li>
        <li>
          <span className="perk-icon">
            <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden>
              <path
                d="M7 4h10v9H7zM5 13h14v4H5zM8 17v3M16 17v3"
                fill="none"
                stroke="currentColor"
                strokeWidth="1.8"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </span>
          <span className="perk-text">
            <strong>Your favourite place on board</strong>
            <span>A window to the world or room to stretch. Choose your seat on every flight.</span>
          </span>
        </li>
        <li>
          <span className="perk-icon">
            <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden>
              <path
                d="M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h3v3h-3zM17 17h3v3h-3zM17 13h3M13 20h3"
                fill="none"
                stroke="currentColor"
                strokeWidth="1.8"
                strokeLinejoin="round"
              />
            </svg>
          </span>
          <span className="perk-text">
            <strong>Ready for what comes next</strong>
            <span>Your boarding passes and itinerary, together. One less thing to think about.</span>
          </span>
        </li>
      </ul>
    </div>
  )
}
