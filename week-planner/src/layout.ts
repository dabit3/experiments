import type { CalendarEvent } from './types'
import { MINUTES_PER_DAY, clamp, isSameDay, minutesSinceMidnight } from './dateUtils'

export interface PositionedEvent {
  event: CalendarEvent
  startMin: number
  endMin: number
  /** Column index inside its overlap cluster. */
  column: number
  /** Total columns in the overlap cluster. */
  columns: number
}

/**
 * Lays out the timed events of a single day so overlapping events sit side by side.
 * Events are grouped into clusters of transitively-overlapping events; within a
 * cluster each event takes the first column whose previous event has ended.
 */
export function layoutDay(events: CalendarEvent[], day: Date): PositionedEvent[] {
  const items = events
    .filter((e) => !e.allDay && isSameDay(new Date(e.start), day))
    .map((event) => {
      const start = new Date(event.start)
      const end = new Date(event.end)
      const startMin = minutesSinceMidnight(start)
      const rawEnd = isSameDay(start, end) ? minutesSinceMidnight(end) : MINUTES_PER_DAY
      const endMin = clamp(Math.max(rawEnd, startMin + 15), 0, MINUTES_PER_DAY)
      return { event, startMin, endMin, column: 0, columns: 1 }
    })
    .sort((a, b) => a.startMin - b.startMin || b.endMin - a.endMin)

  let cluster: PositionedEvent[] = []
  let columnEnds: number[] = []
  let clusterEnd = -1

  const flush = () => {
    for (const item of cluster) item.columns = columnEnds.length
    cluster = []
    columnEnds = []
  }

  for (const item of items) {
    if (item.startMin >= clusterEnd) flush()
    let column = columnEnds.findIndex((end) => end <= item.startMin)
    if (column === -1) {
      column = columnEnds.length
      columnEnds.push(item.endMin)
    } else {
      columnEnds[column] = item.endMin
    }
    item.column = column
    cluster.push(item)
    clusterEnd = Math.max(clusterEnd, item.endMin)
  }
  flush()

  return items
}
