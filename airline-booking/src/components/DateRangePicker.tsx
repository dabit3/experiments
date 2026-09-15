import { useEffect, useRef, useState } from 'react'
import { addDays, addMonths, formatMedium, isSameDay, parseISODate, toISODate, today } from '../lib/date'

interface Props {
  depart: string | null
  ret: string | null
  roundTrip: boolean
  departError?: string
  returnError?: string
  onChange: (depart: string | null, ret: string | null) => void
}

const WEEKDAYS = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']

export function DateRangePicker({ depart, ret, roundTrip, departError, returnError, onChange }: Props) {
  const [open, setOpen] = useState<null | 'depart' | 'return'>(null)
  const [viewMonth, setViewMonth] = useState(() => {
    const base = depart ? parseISODate(depart) ?? today() : today()
    return new Date(base.getFullYear(), base.getMonth(), 1)
  })
  const [hover, setHover] = useState<Date | null>(null)
  const wrapRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const onDocClick = (e: MouseEvent) => {
      if (!wrapRef.current?.contains(e.target as Node)) setOpen(null)
    }
    document.addEventListener('mousedown', onDocClick)
    return () => document.removeEventListener('mousedown', onDocClick)
  }, [])

  const departDate = depart ? parseISODate(depart) : null
  const returnDate = ret ? parseISODate(ret) : null
  const minDate = today()

  const pick = (d: Date) => {
    const iso = toISODate(d)
    if (!roundTrip) {
      onChange(iso, null)
      setOpen(null)
      return
    }
    if (open === 'depart' || !departDate || (departDate && returnDate)) {
      onChange(iso, returnDate && returnDate > d ? toISODate(returnDate) : null)
      setOpen('return')
      return
    }
    // picking the return date
    if (d < departDate) {
      onChange(iso, null)
      setOpen('return')
      return
    }
    onChange(toISODate(departDate), iso)
    setOpen(null)
  }

  const months = [viewMonth, addMonths(viewMonth, 1)]
  const canGoBack = viewMonth > new Date(minDate.getFullYear(), minDate.getMonth(), 1)

  const rangeEnd = returnDate ?? (open === 'return' && hover && departDate && hover > departDate ? hover : null)

  return (
    <div className="date-range" ref={wrapRef}>
      <div className="date-range-fields">
        <button
          type="button"
          id="depart-date"
          className={`date-field ${open === 'depart' ? 'open' : ''} ${departError ? 'has-error' : ''}`}
          onClick={() => setOpen(open === 'depart' ? null : 'depart')}
          aria-haspopup="dialog"
          aria-expanded={open === 'depart'}
        >
          <span className="date-field-label">Depart</span>
          <span className={`date-field-value ${depart ? '' : 'placeholder'}`}>
            {depart ? formatMedium(depart) : 'Add date'}
          </span>
        </button>
        {roundTrip && (
          <button
            type="button"
            id="return-date"
            className={`date-field ${open === 'return' ? 'open' : ''} ${returnError ? 'has-error' : ''}`}
            onClick={() => setOpen(open === 'return' ? null : 'return')}
            aria-haspopup="dialog"
            aria-expanded={open === 'return'}
          >
            <span className="date-field-label">Return</span>
            <span className={`date-field-value ${ret ? '' : 'placeholder'}`}>{ret ? formatMedium(ret) : 'Add date'}</span>
          </button>
        )}
      </div>
      {(departError || returnError) && (
        <p className="field-error" role="alert">
          {departError ?? returnError}
        </p>
      )}

      {open && (
        <div className="calendar-popover" role="dialog" aria-label="Choose travel dates">
          <div className="calendar-head">
            <button type="button" className="cal-nav" disabled={!canGoBack} onClick={() => setViewMonth(addMonths(viewMonth, -1))} aria-label="Previous month">
              ‹
            </button>
            <span className="calendar-hint">
              {roundTrip
                ? open === 'depart' || !departDate
                  ? 'Select your departure date'
                  : 'Now select your return date'
                : 'Select your departure date'}
            </span>
            <button type="button" className="cal-nav" onClick={() => setViewMonth(addMonths(viewMonth, 1))} aria-label="Next month">
              ›
            </button>
          </div>
          <div className="calendar-months">
            {months.map((m) => (
              <Month
                key={m.toISOString()}
                month={m}
                minDate={minDate}
                start={departDate}
                end={rangeEnd}
                roundTrip={roundTrip}
                onPick={pick}
                onHover={setHover}
              />
            ))}
          </div>
          <div className="calendar-foot">
            <span className="muted">Past dates are unavailable</span>
            <button type="button" className="btn btn-ghost btn-sm" onClick={() => setOpen(null)}>
              Done
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

interface MonthProps {
  month: Date
  minDate: Date
  start: Date | null
  end: Date | null
  roundTrip: boolean
  onPick: (d: Date) => void
  onHover: (d: Date | null) => void
}

function Month({ month, minDate, start, end, roundTrip, onPick, onHover }: MonthProps) {
  const first = new Date(month.getFullYear(), month.getMonth(), 1)
  const daysInMonth = new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate()
  const cells: (Date | null)[] = Array.from({ length: first.getDay() }, () => null)
  for (let d = 0; d < daysInMonth; d++) cells.push(addDays(first, d))

  return (
    <div className="calendar-month">
      <div className="calendar-month-title">
        {month.toLocaleDateString('en-US', { month: 'long', year: 'numeric' })}
      </div>
      <div className="calendar-grid">
        {WEEKDAYS.map((w) => (
          <span key={w} className="calendar-weekday">
            {w}
          </span>
        ))}
        {cells.map((d, i) => {
          if (!d) return <span key={`e${i}`} />
          const disabled = d < minDate
          const isStart = start ? isSameDay(d, start) : false
          const isEnd = end ? isSameDay(d, end) : false
          const inRange = roundTrip && start && end && d > start && d < end
          const isToday = isSameDay(d, today())
          return (
            <button
              key={d.toISOString()}
              type="button"
              className={[
                'cal-day',
                disabled ? 'disabled' : '',
                isStart ? 'start' : '',
                isEnd ? 'end' : '',
                inRange ? 'in-range' : '',
                isToday ? 'today' : '',
              ].join(' ')}
              disabled={disabled}
              onClick={() => onPick(d)}
              onMouseEnter={() => onHover(d)}
              onMouseLeave={() => onHover(null)}
              aria-label={d.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' })}
              aria-pressed={isStart || isEnd}
            >
              {d.getDate()}
            </button>
          )
        })}
      </div>
    </div>
  )
}
