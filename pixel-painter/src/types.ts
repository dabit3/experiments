export type Tool = 'brush' | 'eraser' | 'line' | 'rect' | 'circle' | 'fill'

export interface Point {
  x: number
  y: number
}

export const CANVAS_WIDTH = 1040
export const CANVAS_HEIGHT = 680
export const CANVAS_BACKGROUND = '#ffffff'

export const MIN_BRUSH_SIZE = 1
export const MAX_BRUSH_SIZE = 60

export const PALETTE = [
  '#000000',
  '#4a4a4a',
  '#9e9e9e',
  '#ffffff',
  '#e53935',
  '#fb8c00',
  '#fdd835',
  '#7cb342',
  '#00897b',
  '#1e88e5',
  '#3949ab',
  '#8e24aa',
  '#d81b60',
  '#8d6e63',
  '#ffcc80',
  '#80deea',
]

export const TOOLS: { id: Tool; label: string; hotkey: string }[] = [
  { id: 'brush', label: 'Brush', hotkey: 'B' },
  { id: 'eraser', label: 'Eraser', hotkey: 'E' },
  { id: 'line', label: 'Line', hotkey: 'L' },
  { id: 'rect', label: 'Rect', hotkey: 'R' },
  { id: 'circle', label: 'Circle', hotkey: 'C' },
  { id: 'fill', label: 'Fill', hotkey: 'F' },
]
