export const SLIDE_W = 960
export const SLIDE_H = 540

export type TextAlign = 'left' | 'center' | 'right'

interface BaseElement {
  id: string
  x: number
  y: number
  w: number
  h: number
  rotation: number
}

export interface TextElement extends BaseElement {
  kind: 'text'
  text: string
  placeholder?: string
  fontSize: number
  align: TextAlign
  bold: boolean
  bullets: boolean
  color?: string
  fill?: string
}

export interface ShapeElement extends BaseElement {
  kind: 'rect' | 'ellipse' | 'arrow'
  fill: string
  label: string
  fontSize: number
}

export interface StickerElement extends BaseElement {
  kind: 'sticker'
  emoji: string
}

export type SlideElement = TextElement | ShapeElement | StickerElement
export type ElementKind = SlideElement['kind']

export interface Slide {
  id: string
  elements: SlideElement[]
  notes: string
}

export type ThemeId = 'midnight' | 'paper' | 'coral' | 'forest' | 'slate' | 'terminal'

export interface Deck {
  title: string
  themeId: ThemeId
  slides: Slide[]
}

export interface Theme {
  id: ThemeId
  name: string
  background: string
  text: string
  muted: string
  accent: string
  headingFont: string
  bodyFont: string
  palette: string[]
}

export type SlideLayout = 'title' | 'bullets' | 'blank'
