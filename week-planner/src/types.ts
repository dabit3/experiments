export type ColorId =
  | 'tomato'
  | 'tangerine'
  | 'banana'
  | 'sage'
  | 'peacock'
  | 'blueberry'
  | 'grape'

export interface EventColor {
  id: ColorId
  name: string
  hex: string
  /** Text color that reads well on top of `hex`. */
  ink: string
}

export const COLORS: EventColor[] = [
  { id: 'tomato', name: 'Tomato', hex: '#d93025', ink: '#fff' },
  { id: 'tangerine', name: 'Tangerine', hex: '#f4511e', ink: '#fff' },
  { id: 'banana', name: 'Banana', hex: '#f6bf26', ink: '#3c2f00' },
  { id: 'sage', name: 'Sage', hex: '#33b679', ink: '#fff' },
  { id: 'peacock', name: 'Peacock', hex: '#039be5', ink: '#fff' },
  { id: 'blueberry', name: 'Blueberry', hex: '#3f51b5', ink: '#fff' },
  { id: 'grape', name: 'Grape', hex: '#8e24aa', ink: '#fff' },
]

export function colorById(id: ColorId): EventColor {
  return COLORS.find((c) => c.id === id) ?? COLORS[4]
}

export interface CalendarEvent {
  id: string
  title: string
  description: string
  /** ISO timestamp. For all-day events this is local midnight of the day. */
  start: string
  /** ISO timestamp, exclusive. For all-day events this is midnight of the next day. */
  end: string
  allDay: boolean
  color: ColorId
}

export type ViewMode = 'week' | 'agenda'
