export type Tool =
  | 'brush'
  | 'eraser'
  | 'line'
  | 'rect'
  | 'circle'
  | 'fill'
  | 'freeform'
  | 'eyedropper'

export interface Point {
  x: number
  y: number
}

export const CANVAS_WIDTH = 1040
export const CANVAS_HEIGHT = 680
export const CANVAS_BACKGROUND = '#ffffff'

export const MIN_BRUSH_SIZE = 1
export const MAX_BRUSH_SIZE = 120

export const PALETTE = [
  '#17191c',
  '#63666d',
  '#d9dadd',
  '#ffffff',
  '#f36b56',
  '#ffa940',
  '#f6d365',
  '#cce0a1',
  '#498b73',
  '#629bed',
  '#6871c5',
  '#a78bcc',
  '#e39db8',
  '#d88927',
  '#f2e4cd',
  '#9dd8d2',
]

export const TOOLS: { id: Tool; label: string; hotkey: string }[] = [
  { id: 'brush', label: 'Brush', hotkey: 'B' },
  { id: 'eraser', label: 'Eraser', hotkey: 'E' },
  { id: 'line', label: 'Line', hotkey: 'L' },
  { id: 'rect', label: 'Rectangle', hotkey: 'R' },
  { id: 'circle', label: 'Ellipse', hotkey: 'C' },
  { id: 'freeform', label: 'Freeform fill', hotkey: 'P' },
  { id: 'fill', label: 'Paint bucket', hotkey: 'F' },
  { id: 'eyedropper', label: 'Eyedropper', hotkey: 'I' },
]
