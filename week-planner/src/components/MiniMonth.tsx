import { useState } from 'react'
import {
  addDays,
  addMonths,
  isSameDay,
  isSameMonth,
  monthGrid,
  monthName,
  startOfMonth,
} from '../dateUtils'

interface Props {
  weekStart: Date
  today: Date
  onSelectDate(date: Date): void
}

const WEEKDAY_LETTERS = ['S', 'M', 'T', 'W', 'T', 'F', 'S']

export function MiniMonth({ weekStart, today, onSelectDate }: Props) {
  // Browsing months is local UI state that resets whenever the selected week changes.
  const [browsed, setBrowsed] = useState<{ forWeek: number; month: Date } | null>(null)
  const month =
    browsed && browsed.forWeek === weekStart.getTime() ? browsed.month : startOfMonth(weekStart)
  const setMonth = (next: Date) => setBrowsed({ forWeek: weekStart.getTime(), month: next })

  const weekEnd = addDays(weekStart, 6)

  return (
    <div className="mini-month" aria-label="Month picker">
      <div className="mini-month-head">
        <span className="mini-month-title">
          {monthName(month)} {month.getFullYear()}
        </span>
        <div className="mini-month-nav">
          <button
            type="button"
            className="icon-btn small"
            aria-label="Previous month"
            onClick={() => setMonth(addMonths(month, -1))}
          >
            <Chevron direction="left" />
          </button>
          <button
            type="button"
            className="icon-btn small"
            aria-label="Next month"
            onClick={() => setMonth(addMonths(month, 1))}
          >
            <Chevron direction="right" />
          </button>
        </div>
      </div>
      <div className="mini-month-grid">
        {WEEKDAY_LETTERS.map((letter, i) => (
          <span key={i} className="mini-month-weekday">
            {letter}
          </span>
        ))}
        {monthGrid(month).map((date) => {
          const inWeek = date >= weekStart && date <= weekEnd
          const classes = [
            'mini-month-day',
            isSameMonth(date, month) ? '' : 'is-outside',
            isSameDay(date, today) ? 'is-today' : '',
            inWeek ? 'is-in-week' : '',
            inWeek && isSameDay(date, weekStart) ? 'is-week-start' : '',
            inWeek && isSameDay(date, weekEnd) ? 'is-week-end' : '',
          ].join(' ')
          return (
            <button
              key={date.toISOString()}
              type="button"
              className={classes}
              aria-label={date.toDateString()}
              onClick={() => onSelectDate(date)}
            >
              {date.getDate()}
            </button>
          )
        })}
      </div>
    </div>
  )
}

export function Chevron({ direction }: { direction: 'left' | 'right' }) {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path
        d={direction === 'left' ? 'M15 6l-6 6 6 6' : 'M9 6l6 6-6 6'}
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}
