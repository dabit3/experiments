import { useCallback, useEffect, useState } from 'react'
import type { CalendarEvent, ColorId } from './types'
import { addDays, atMinutes, startOfDay, startOfWeek } from './dateUtils'

const STORAGE_KEY = 'week-planner:events'

function newId(): string {
  return crypto.randomUUID()
}

function seedEvents(): CalendarEvent[] {
  const week = startOfWeek(new Date())
  const timed = (
    dayOffset: number,
    startMin: number,
    endMin: number,
    title: string,
    color: ColorId,
    description = '',
  ): CalendarEvent => ({
    id: newId(),
    title,
    description,
    start: atMinutes(addDays(week, dayOffset), startMin).toISOString(),
    end: atMinutes(addDays(week, dayOffset), endMin).toISOString(),
    allDay: false,
    color,
  })
  const saturday = addDays(week, 6)
  return [
    timed(1, 9 * 60, 9 * 60 + 30, 'Team standup', 'peacock', 'Daily sync in the main room.'),
    timed(1, 12 * 60, 13 * 60, 'Lunch with Sam', 'sage'),
    timed(3, 14 * 60, 15 * 60 + 30, 'Design review', 'grape', 'Walk through the new onboarding flow.'),
    timed(5, 16 * 60, 17 * 60, 'Sprint retro', 'tangerine'),
    {
      id: newId(),
      title: 'Farmers market',
      description: '',
      start: startOfDay(saturday).toISOString(),
      end: addDays(startOfDay(saturday), 1).toISOString(),
      allDay: true,
      color: 'banana',
    },
  ]
}

function loadEvents(): CalendarEvent[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (raw) {
      const parsed: unknown = JSON.parse(raw)
      if (Array.isArray(parsed)) return parsed as CalendarEvent[]
    }
  } catch {
    // fall through to seed data
  }
  return seedEvents()
}

export type EventInput = Omit<CalendarEvent, 'id'>

export function useEvents() {
  const [events, setEvents] = useState<CalendarEvent[]>(loadEvents)

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(events))
  }, [events])

  const addEvent = useCallback((input: EventInput): CalendarEvent => {
    const event: CalendarEvent = { ...input, id: newId() }
    setEvents((prev) => [...prev, event])
    return event
  }, [])

  const updateEvent = useCallback((id: string, patch: Partial<EventInput>) => {
    setEvents((prev) => prev.map((e) => (e.id === id ? { ...e, ...patch } : e)))
  }, [])

  const deleteEvent = useCallback((id: string) => {
    setEvents((prev) => prev.filter((e) => e.id !== id))
  }, [])

  /** Copies an event into the slot immediately after it (next day for all-day events). */
  const duplicateEvent = useCallback((id: string) => {
    setEvents((prev) => {
      const source = prev.find((e) => e.id === id)
      if (!source) return prev
      const start = new Date(source.start)
      const end = new Date(source.end)
      const duration = end.getTime() - start.getTime()
      const copy: CalendarEvent = {
        ...source,
        id: newId(),
        title: `${source.title} (copy)`,
        start: end.toISOString(),
        end: new Date(end.getTime() + duration).toISOString(),
      }
      return [...prev, copy]
    })
  }, [])

  return { events, addEvent, updateEvent, deleteEvent, duplicateEvent }
}
