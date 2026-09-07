import type { CalendarEvent } from '../types'
import { colorById } from '../types'
import { dayName, formatTimeRange, isSameDay, monthName, weekDays } from '../dateUtils'

interface Props {
  weekStart: Date
  events: CalendarEvent[]
  today: Date
  onOpenEdit(id: string): void
  onContextMenu(id: string, x: number, y: number): void
}

export function AgendaView({ weekStart, events, today, onOpenEdit, onContextMenu }: Props) {
  const days = weekDays(weekStart)
  const total = events.filter((e) => days.some((d) => isSameDay(new Date(e.start), d))).length

  return (
    <div className="agenda-view">
      <div className="agenda-summary">
        {total === 0 ? 'No events this week' : `${total} event${total === 1 ? '' : 's'} this week`}
      </div>
      {days.map((day) => {
        const dayEvents = events
          .filter((e) => isSameDay(new Date(e.start), day))
          .sort((a, b) => Number(b.allDay) - Number(a.allDay) || a.start.localeCompare(b.start))
        return (
          <section key={day.toISOString()} className={`agenda-day ${isSameDay(day, today) ? 'is-today' : ''}`}>
            <div className="agenda-date">
              <span className="agenda-date-num">{day.getDate()}</span>
              <span className="agenda-date-text">
                {dayName(day)}, {monthName(day).slice(0, 3)}
              </span>
            </div>
            <div className="agenda-items">
              {dayEvents.length === 0 && <div className="agenda-empty">Nothing scheduled</div>}
              {dayEvents.map((event) => {
                const color = colorById(event.color)
                return (
                  <button
                    type="button"
                    key={event.id}
                    className="agenda-item"
                    data-event-id={event.id}
                    onClick={() => onOpenEdit(event.id)}
                    onContextMenu={(e) => {
                      e.preventDefault()
                      onContextMenu(event.id, e.clientX, e.clientY)
                    }}
                  >
                    <span className="agenda-dot" style={{ background: color.hex }} />
                    <span className="agenda-time">
                      {event.allDay
                        ? 'All day'
                        : formatTimeRange(new Date(event.start), new Date(event.end))}
                    </span>
                    <span className="agenda-text">
                      <span className="agenda-title">{event.title}</span>
                      {event.description && <span className="agenda-desc">{event.description}</span>}
                    </span>
                  </button>
                )
              })}
            </div>
          </section>
        )
      })}
    </div>
  )
}
