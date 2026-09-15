import { useEffect, useMemo, useRef, useState, type MouseEvent as ReactMouseEvent } from 'react'
import type { CalendarEvent } from '../types'
import { colorById } from '../types'
import {
  MINUTES_PER_DAY,
  SLOT_MINUTES,
  addDays,
  atMinutes,
  clamp,
  dayName,
  formatHourLabel,
  formatTimeRange,
  isSameDay,
  minutesSinceMidnight,
  snapToSlot,
  weekDays,
} from '../dateUtils'
import { layoutDay } from '../layout'
import type { Draft } from '../App'

export const HOUR_HEIGHT = 48
const GRID_HEIGHT = HOUR_HEIGHT * 24
const DRAG_THRESHOLD_PX = 4
const INITIAL_SCROLL_HOUR = 7.5

type Interaction =
  | { kind: 'create'; day: number; anchorMin: number; currentMin: number }
  | {
      kind: 'move'
      id: string
      day: number
      startMin: number
      durationMin: number
      grabOffsetMin: number
      originX: number
      originY: number
      moved: boolean
    }
  | { kind: 'resize'; id: string; day: number; startMin: number; endMin: number }

interface Props {
  weekStart: Date
  events: CalendarEvent[]
  draft: Draft | null
  selectedId: string | null
  onRequestCreate(draft: Draft): void
  onReschedule(id: string, start: Date, end: Date): void
  onSelect(id: string | null): void
  onOpenEdit(id: string): void
  onContextMenu(id: string, x: number, y: number): void
}

function minutesToPx(minutes: number): number {
  return (minutes / 60) * HOUR_HEIGHT
}

export function WeekView({
  weekStart,
  events,
  draft,
  selectedId,
  onRequestCreate,
  onReschedule,
  onSelect,
  onOpenEdit,
  onContextMenu,
}: Props) {
  const days = useMemo(() => weekDays(weekStart), [weekStart])
  const scrollRef = useRef<HTMLDivElement>(null)
  const daysRef = useRef<HTMLDivElement>(null)
  const interactionRef = useRef<Interaction | null>(null)
  const [interaction, setInteractionState] = useState<Interaction | null>(null)
  const [now, setNow] = useState(() => new Date())

  const setInteraction = (next: Interaction | null) => {
    interactionRef.current = next
    setInteractionState(next)
  }

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: INITIAL_SCROLL_HOUR * HOUR_HEIGHT })
  }, [])

  useEffect(() => {
    const timer = window.setInterval(() => setNow(new Date()), 60_000)
    return () => window.clearInterval(timer)
  }, [])

  /** Converts a pointer position to a day index and a minute-of-day. */
  const locate = (clientX: number, clientY: number) => {
    const rect = daysRef.current!.getBoundingClientRect()
    const day = clamp(Math.floor(((clientX - rect.left) / rect.width) * 7), 0, 6)
    const rawMin = clamp(((clientY - rect.top) / HOUR_HEIGHT) * 60, 0, MINUTES_PER_DAY)
    const slotMin = clamp(
      Math.floor(rawMin / SLOT_MINUTES) * SLOT_MINUTES,
      0,
      MINUTES_PER_DAY - SLOT_MINUTES,
    )
    return { day, rawMin, slotMin }
  }

  const isInteracting = interaction !== null

  useEffect(() => {
    if (!isInteracting) return

    const handleMove = (e: MouseEvent) => {
      const current = interactionRef.current
      if (!current) return
      const { day, rawMin, slotMin } = locate(e.clientX, e.clientY)
      switch (current.kind) {
        case 'create':
          setInteraction({ ...current, currentMin: slotMin })
          break
        case 'move': {
          if (
            !current.moved &&
            Math.hypot(e.clientX - current.originX, e.clientY - current.originY) < DRAG_THRESHOLD_PX
          ) {
            return
          }
          const startMin = clamp(
            snapToSlot(rawMin - current.grabOffsetMin),
            0,
            MINUTES_PER_DAY - current.durationMin,
          )
          setInteraction({ ...current, day, startMin, moved: true })
          break
        }
        case 'resize': {
          const endMin = clamp(snapToSlot(rawMin), current.startMin + SLOT_MINUTES, MINUTES_PER_DAY)
          setInteraction({ ...current, endMin })
          break
        }
      }
    }

    const handleUp = (e: MouseEvent) => {
      const current = interactionRef.current
      setInteraction(null)
      if (!current) return
      const day = addDays(weekStart, current.day)
      switch (current.kind) {
        case 'create': {
          const startMin = Math.min(current.anchorMin, current.currentMin)
          const endMin = Math.max(current.anchorMin, current.currentMin) + SLOT_MINUTES
          onRequestCreate({
            start: atMinutes(day, startMin),
            end: atMinutes(day, endMin),
            allDay: false,
            anchor: { x: e.clientX + 12, y: e.clientY - 24 },
          })
          break
        }
        case 'move':
          if (current.moved) {
            onReschedule(
              current.id,
              atMinutes(day, current.startMin),
              atMinutes(day, current.startMin + current.durationMin),
            )
          } else {
            onSelect(current.id)
          }
          break
        case 'resize':
          onReschedule(current.id, atMinutes(day, current.startMin), atMinutes(day, current.endMin))
          break
      }
    }

    window.addEventListener('mousemove', handleMove)
    window.addEventListener('mouseup', handleUp)
    return () => {
      window.removeEventListener('mousemove', handleMove)
      window.removeEventListener('mouseup', handleUp)
    }
  }, [isInteracting, weekStart, onRequestCreate, onReschedule, onSelect])

  const handleGridMouseDown = (e: ReactMouseEvent<HTMLDivElement>) => {
    if (e.button !== 0) return
    if ((e.target as HTMLElement).closest('.event')) return
    e.preventDefault()
    onSelect(null)
    const { day, slotMin } = locate(e.clientX, e.clientY)
    setInteraction({ kind: 'create', day, anchorMin: slotMin, currentMin: slotMin })
  }

  const handleEventMouseDown = (e: ReactMouseEvent<HTMLDivElement>, event: CalendarEvent) => {
    e.stopPropagation()
    if (e.button !== 0) return
    e.preventDefault()
    const start = new Date(event.start)
    const end = new Date(event.end)
    const { day, rawMin } = locate(e.clientX, e.clientY)
    const startMin = minutesSinceMidnight(start)
    const durationMin = Math.max(SLOT_MINUTES, Math.round((end.getTime() - start.getTime()) / 60_000))
    setInteraction({
      kind: 'move',
      id: event.id,
      day,
      startMin,
      durationMin,
      grabOffsetMin: rawMin - startMin,
      originX: e.clientX,
      originY: e.clientY,
      moved: false,
    })
  }

  const handleResizeMouseDown = (e: ReactMouseEvent<HTMLDivElement>, event: CalendarEvent) => {
    e.stopPropagation()
    if (e.button !== 0) return
    e.preventDefault()
    const start = new Date(event.start)
    const { day } = locate(e.clientX, e.clientY)
    onSelect(event.id)
    setInteraction({
      kind: 'resize',
      id: event.id,
      day,
      startMin: minutesSinceMidnight(start),
      endMin: minutesSinceMidnight(new Date(event.end)),
    })
  }

  /** Events with the in-progress move/resize applied so the grid previews the result live. */
  const displayEvents = useMemo(() => {
    if (!interaction || interaction.kind === 'create') return events
    return events.map((event) => {
      if (event.id !== interaction.id) return event
      const day = addDays(weekStart, interaction.day)
      if (interaction.kind === 'move') {
        return {
          ...event,
          start: atMinutes(day, interaction.startMin).toISOString(),
          end: atMinutes(day, interaction.startMin + interaction.durationMin).toISOString(),
        }
      }
      return { ...event, end: atMinutes(day, interaction.endMin).toISOString() }
    })
  }, [events, interaction, weekStart])

  const ghost = useMemo(() => {
    if (interaction?.kind === 'create') {
      const startMin = Math.min(interaction.anchorMin, interaction.currentMin)
      const endMin = Math.max(interaction.anchorMin, interaction.currentMin) + SLOT_MINUTES
      return { day: interaction.day, startMin, endMin }
    }
    if (draft && !draft.allDay) {
      const day = days.findIndex((d) => isSameDay(d, draft.start))
      if (day === -1) return null
      return {
        day,
        startMin: minutesSinceMidnight(draft.start),
        endMin: isSameDay(draft.start, draft.end) ? minutesSinceMidnight(draft.end) : MINUTES_PER_DAY,
      }
    }
    return null
  }, [interaction, draft, days])

  const draggingId = interaction && interaction.kind !== 'create' ? interaction.id : null
  const todayIndex = days.findIndex((d) => isSameDay(d, now))
  const cursorClass =
    interaction?.kind === 'move' && interaction.moved
      ? 'is-moving'
      : interaction?.kind === 'resize'
        ? 'is-resizing'
        : interaction?.kind === 'create'
          ? 'is-creating'
          : ''

  return (
    <div className={`week-view ${cursorClass}`} ref={scrollRef}>
      <div className="week-head">
        <div className="gutter gutter-head" />
        <div className="head-days">
          {days.map((day, i) => (
            <div key={i} className={`day-head ${i === todayIndex ? 'is-today' : ''}`}>
              <span className="day-head-name">{dayName(day)}</span>
              <span className="day-head-num">{day.getDate()}</span>
            </div>
          ))}
        </div>
        <div className="gutter allday-label">all-day</div>
        <div className="allday-strip">
          {days.map((day, i) => {
            const allDayEvents = displayEvents.filter(
              (e) => e.allDay && isSameDay(new Date(e.start), day),
            )
            return (
              <div
                key={i}
                className="allday-cell"
                onClick={(e) => {
                  if ((e.target as HTMLElement).closest('.event')) return
                  onSelect(null)
                  onRequestCreate({
                    start: day,
                    end: addDays(day, 1),
                    allDay: true,
                    anchor: { x: e.clientX + 12, y: e.clientY + 12 },
                  })
                }}
              >
                {allDayEvents.map((event) => (
                  <AllDayChip
                    key={event.id}
                    event={event}
                    selected={event.id === selectedId}
                    onSelect={onSelect}
                    onOpenEdit={onOpenEdit}
                    onContextMenu={onContextMenu}
                  />
                ))}
              </div>
            )
          })}
        </div>
      </div>

      <div className="week-body">
        <div className="gutter" style={{ height: GRID_HEIGHT }}>
          {Array.from({ length: 24 }, (_, hour) => (
            <span key={hour} className="hour-label" style={{ top: hour * HOUR_HEIGHT }}>
              {formatHourLabel(hour)}
            </span>
          ))}
        </div>
        <div
          className="days"
          ref={daysRef}
          style={{ height: GRID_HEIGHT }}
          onMouseDown={handleGridMouseDown}
        >
          {days.map((day, dayIndex) => {
            const positioned = layoutDay(displayEvents, day)
            return (
              <div key={dayIndex} className={`day-col ${dayIndex === todayIndex ? 'is-today' : ''}`}>
                {positioned.map(({ event, startMin, endMin, column, columns }) => {
                  const color = colorById(event.color)
                  const widthPct = 100 / columns
                  return (
                    <div
                      key={event.id}
                      className={[
                        'event',
                        event.id === selectedId ? 'is-selected' : '',
                        event.id === draggingId ? 'is-dragging' : '',
                        endMin - startMin < 45 ? 'is-short' : '',
                      ].join(' ')}
                      style={{
                        top: minutesToPx(startMin),
                        height: minutesToPx(endMin - startMin),
                        left: `calc(${column * widthPct}% + 1px)`,
                        width: `calc(${widthPct}% - 4px)`,
                        background: color.hex,
                        color: color.ink,
                      }}
                      data-event-id={event.id}
                      title={event.title}
                      onMouseDown={(e) => handleEventMouseDown(e, event)}
                      onDoubleClick={(e) => {
                        e.stopPropagation()
                        onOpenEdit(event.id)
                      }}
                      onContextMenu={(e) => {
                        e.preventDefault()
                        e.stopPropagation()
                        onSelect(event.id)
                        onContextMenu(event.id, e.clientX, e.clientY)
                      }}
                    >
                      <div className="event-title">{event.title}</div>
                      <div className="event-time">
                        {formatTimeRange(atMinutes(day, startMin), atMinutes(day, endMin))}
                      </div>
                      <div
                        className="event-resize"
                        onMouseDown={(e) => handleResizeMouseDown(e, event)}
                      />
                    </div>
                  )
                })}

                {ghost && ghost.day === dayIndex && (
                  <div
                    className="event ghost"
                    style={{
                      top: minutesToPx(ghost.startMin),
                      height: minutesToPx(ghost.endMin - ghost.startMin),
                    }}
                  >
                    <div className="event-title">(No title)</div>
                    <div className="event-time">
                      {formatTimeRange(atMinutes(day, ghost.startMin), atMinutes(day, ghost.endMin))}
                    </div>
                  </div>
                )}

                {dayIndex === todayIndex && (
                  <div className="now-line" style={{ top: minutesToPx(minutesSinceMidnight(now)) }} />
                )}
              </div>
            )
          })}
        </div>
      </div>
    </div>
  )
}

interface ChipProps {
  event: CalendarEvent
  selected: boolean
  onSelect(id: string): void
  onOpenEdit(id: string): void
  onContextMenu(id: string, x: number, y: number): void
}

function AllDayChip({ event, selected, onSelect, onOpenEdit, onContextMenu }: ChipProps) {
  const color = colorById(event.color)
  return (
    <div
      className={`event allday-chip ${selected ? 'is-selected' : ''}`}
      style={{ background: color.hex, color: color.ink }}
      data-event-id={event.id}
      title={event.title}
      onClick={(e) => {
        e.stopPropagation()
        onSelect(event.id)
      }}
      onDoubleClick={(e) => {
        e.stopPropagation()
        onOpenEdit(event.id)
      }}
      onContextMenu={(e) => {
        e.preventDefault()
        e.stopPropagation()
        onSelect(event.id)
        onContextMenu(event.id, e.clientX, e.clientY)
      }}
    >
      {event.title}
    </div>
  )
}
