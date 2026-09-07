export const MINUTES_PER_DAY = 24 * 60
export const SLOT_MINUTES = 30

const DAY_NAMES = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
const MONTH_NAMES = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
]

export function startOfDay(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate())
}

export function addDays(d: Date, n: number): Date {
  const next = new Date(d)
  next.setDate(next.getDate() + n)
  return next
}

export function addMonths(d: Date, n: number): Date {
  return new Date(d.getFullYear(), d.getMonth() + n, 1)
}

export function startOfWeek(d: Date): Date {
  return addDays(startOfDay(d), -d.getDay())
}

export function startOfMonth(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth(), 1)
}

export function isSameDay(a: Date, b: Date): boolean {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  )
}

export function isSameMonth(a: Date, b: Date): boolean {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth()
}

export function minutesSinceMidnight(d: Date): number {
  return d.getHours() * 60 + d.getMinutes()
}

/** Returns local midnight of `day` plus `minutes`. */
export function atMinutes(day: Date, minutes: number): Date {
  const result = startOfDay(day)
  result.setMinutes(minutes)
  return result
}

export function snapToSlot(minutes: number): number {
  return Math.round(minutes / SLOT_MINUTES) * SLOT_MINUTES
}

export function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value))
}

export function dayName(d: Date): string {
  return DAY_NAMES[d.getDay()]
}

export function monthName(d: Date): string {
  return MONTH_NAMES[d.getMonth()]
}

export function formatTime(d: Date): string {
  const hours = d.getHours()
  const period = hours < 12 ? 'AM' : 'PM'
  const h12 = hours % 12 === 0 ? 12 : hours % 12
  const minutes = String(d.getMinutes()).padStart(2, '0')
  return `${h12}:${minutes} ${period}`
}

export function formatHourLabel(hour: number): string {
  if (hour === 0) return ''
  const period = hour < 12 ? 'AM' : 'PM'
  const h12 = hour % 12 === 0 ? 12 : hour % 12
  return `${h12} ${period}`
}

/** "10:00 – 11:30 AM" or "11:00 AM – 1:00 PM" */
export function formatTimeRange(start: Date, end: Date): string {
  const startLabel = formatTime(start)
  const endLabel = formatTime(end)
  const samePeriod = startLabel.slice(-2) === endLabel.slice(-2)
  return samePeriod
    ? `${startLabel.slice(0, -3)} – ${endLabel}`
    : `${startLabel} – ${endLabel}`
}

/** "Sep 6 – 12, 2026", "Sep 27 – Oct 3, 2026" or "Dec 27, 2026 – Jan 2, 2027" */
export function formatWeekTitle(weekStart: Date): string {
  const weekEnd = addDays(weekStart, 6)
  const startMonth = monthName(weekStart).slice(0, 3)
  const endMonth = monthName(weekEnd).slice(0, 3)
  if (isSameMonth(weekStart, weekEnd)) {
    return `${startMonth} ${weekStart.getDate()} – ${weekEnd.getDate()}, ${weekEnd.getFullYear()}`
  }
  if (weekStart.getFullYear() === weekEnd.getFullYear()) {
    return `${startMonth} ${weekStart.getDate()} – ${endMonth} ${weekEnd.getDate()}, ${weekEnd.getFullYear()}`
  }
  return `${startMonth} ${weekStart.getDate()}, ${weekStart.getFullYear()} – ${endMonth} ${weekEnd.getDate()}, ${weekEnd.getFullYear()}`
}

export function formatLongDate(d: Date): string {
  return `${dayName(d)}, ${monthName(d)} ${d.getDate()}`
}

export function toDateInputValue(d: Date): string {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

export function toTimeInputValue(d: Date): string {
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
}

export function fromDateTimeInputs(date: string, time: string): Date | null {
  const dateMatch = /^(\d{4})-(\d{2})-(\d{2})$/.exec(date)
  const timeMatch = /^(\d{2}):(\d{2})$/.exec(time)
  if (!dateMatch || !timeMatch) return null
  return new Date(
    Number(dateMatch[1]),
    Number(dateMatch[2]) - 1,
    Number(dateMatch[3]),
    Number(timeMatch[1]),
    Number(timeMatch[2]),
  )
}

/** Six rows of seven days covering the month, starting on Sunday. */
export function monthGrid(month: Date): Date[] {
  const first = startOfWeek(startOfMonth(month))
  return Array.from({ length: 42 }, (_, i) => addDays(first, i))
}

export function weekDays(weekStart: Date): Date[] {
  return Array.from({ length: 7 }, (_, i) => addDays(weekStart, i))
}
