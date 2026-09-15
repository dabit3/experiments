import { useEffect, useState, type FormEvent } from 'react'
import type { CalendarEvent, ColorId } from '../types'
import {
  addDays,
  fromDateTimeInputs,
  startOfDay,
  toDateInputValue,
  toTimeInputValue,
} from '../dateUtils'
import { ColorPicker } from './ColorPicker'
import type { EventInput } from '../useEvents'

interface Props {
  event: CalendarEvent
  isNew: boolean
  onSave(patch: EventInput): void
  onDelete(): void
  onClose(): void
}

export function EditModal({ event, isNew, onSave, onDelete, onClose }: Props) {
  const start = new Date(event.start)
  const end = new Date(event.end)
  const [title, setTitle] = useState(event.title)
  const [description, setDescription] = useState(event.description)
  const [color, setColor] = useState<ColorId>(event.color)
  const [allDay, setAllDay] = useState(event.allDay)
  const [date, setDate] = useState(toDateInputValue(start))
  const [startTime, setStartTime] = useState(event.allDay ? '09:00' : toTimeInputValue(start))
  const [endTime, setEndTime] = useState(
    event.allDay ? '10:00' : toTimeInputValue(end),
  )
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const handleKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', handleKey)
    return () => window.removeEventListener('keydown', handleKey)
  }, [onClose])

  const submit = (e: FormEvent) => {
    e.preventDefault()
    const day = fromDateTimeInputs(date, '00:00')
    if (!day) {
      setError('Please choose a valid date.')
      return
    }
    let nextStart: Date
    let nextEnd: Date
    if (allDay) {
      nextStart = startOfDay(day)
      nextEnd = addDays(nextStart, 1)
    } else {
      const s = fromDateTimeInputs(date, startTime)
      const en = fromDateTimeInputs(date, endTime)
      if (!s || !en) {
        setError('Please enter valid start and end times.')
        return
      }
      if (en <= s) {
        setError('End time must be after start time.')
        return
      }
      nextStart = s
      nextEnd = en
    }
    onSave({
      title: title.trim() || '(No title)',
      description: description.trim(),
      color,
      allDay,
      start: nextStart.toISOString(),
      end: nextEnd.toISOString(),
    })
  }

  return (
    <div className="modal-backdrop" onMouseDown={(e) => e.target === e.currentTarget && onClose()}>
      <form className="modal" role="dialog" aria-modal="true" aria-label={isNew ? 'New event' : 'Edit event'} onSubmit={submit}>
        <div className="modal-header">
          <h2>{isNew ? 'New event' : 'Edit event'}</h2>
          <button type="button" className="icon-btn" aria-label="Close" onClick={onClose}>
            ✕
          </button>
        </div>

        <label className="field">
          <span className="field-label">Title</span>
          <input
            className="input title-input"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Add title"
            autoFocus
          />
        </label>

        <label className="field">
          <span className="field-label">Description</span>
          <textarea
            className="input"
            rows={3}
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="Add notes, links, or an agenda"
          />
        </label>

        <div className="field-row">
          <label className="field">
            <span className="field-label">Date</span>
            <input className="input" type="date" value={date} onChange={(e) => setDate(e.target.value)} required />
          </label>
          <label className={`field ${allDay ? 'is-disabled' : ''}`}>
            <span className="field-label">Start</span>
            <input
              className="input"
              type="time"
              step={900}
              value={startTime}
              disabled={allDay}
              onChange={(e) => setStartTime(e.target.value)}
            />
          </label>
          <label className={`field ${allDay ? 'is-disabled' : ''}`}>
            <span className="field-label">End</span>
            <input
              className="input"
              type="time"
              step={900}
              value={endTime}
              disabled={allDay}
              onChange={(e) => setEndTime(e.target.value)}
            />
          </label>
        </div>

        <label className="switch-row">
          <span className="switch">
            <input
              type="checkbox"
              role="switch"
              checked={allDay}
              aria-label="All day"
              onChange={(e) => setAllDay(e.target.checked)}
            />
            <span className="switch-track" />
          </span>
          <span>All day</span>
        </label>

        <div className="field">
          <span className="field-label">Color</span>
          <ColorPicker value={color} onChange={setColor} />
        </div>

        {error && <div className="form-error" role="alert">{error}</div>}

        <div className="modal-actions">
          {!isNew && (
            <button type="button" className="btn danger-btn" onClick={onDelete}>
              Delete
            </button>
          )}
          <span className="spacer" />
          <button type="button" className="btn ghost-btn" onClick={onClose}>
            Cancel
          </button>
          <button type="submit" className="btn primary">
            Save
          </button>
        </div>
      </form>
    </div>
  )
}
