import type {
  Deck,
  ElementKind,
  ShapeElement,
  Slide,
  SlideElement,
  SlideLayout,
  StickerElement,
  TextElement,
  ThemeId,
} from '../types'
import { SLIDE_H, SLIDE_W } from '../types'
import { getTheme } from './themes'

let counter = 0
export function uid(prefix: string): string {
  counter += 1
  return `${prefix}-${Date.now().toString(36)}-${counter.toString(36)}`
}

export const STICKERS = [
  '🚀', '✅', '🔥', '💡', '🎯', '🤖', '🧪', '🐛',
  '⚡', '🏆', '📈', '🛠️', '🔒', '🎉', '👀', '❤️',
  '⭐', '☁️', '🧠', '📦', '⏱️', '💬', '🧭', '🍕',
]

function textEl(partial: Partial<TextElement> & Pick<TextElement, 'x' | 'y' | 'w' | 'h'>): TextElement {
  return {
    id: uid('el'),
    kind: 'text',
    rotation: 0,
    text: '',
    fontSize: 28,
    align: 'left',
    bold: false,
    bullets: false,
    ...partial,
  }
}

export function createSlide(layout: SlideLayout): Slide {
  const elements: SlideElement[] = []
  if (layout === 'title') {
    elements.push(
      textEl({ x: 60, y: 130, w: 840, h: 160, fontSize: 56, bold: true, align: 'center', placeholder: 'Presentation title' }),
      textEl({ x: 140, y: 320, w: 680, h: 70, fontSize: 28, align: 'center', placeholder: 'Subtitle or presenter name' }),
    )
  } else if (layout === 'bullets') {
    elements.push(
      textEl({ x: 60, y: 44, w: 840, h: 84, fontSize: 44, bold: true, placeholder: 'Slide title' }),
      textEl({ x: 60, y: 150, w: 840, h: 340, fontSize: 28, bullets: true, placeholder: 'Add your bullet points' }),
    )
  }
  return { id: uid('slide'), elements, notes: '' }
}

/** Fills cycle through the theme accent followed by its palette so consecutive shapes are distinguishable. */
function nthFill(themeId: ThemeId, n: number): string {
  const theme = getTheme(themeId)
  const fills = [theme.accent, ...theme.palette.filter((c) => c !== theme.accent)]
  return fills[n % fills.length]
}

/**
 * New elements are centred, then cascaded by `ordinal` (the number of elements already on the slide)
 * so repeated inserts don't stack exactly on top of each other.
 */
export function createElement(kind: ElementKind, themeId: ThemeId, emoji = '🚀', ordinal = 0): SlideElement {
  const fill = nthFill(themeId, ordinal)
  const dx = (ordinal % 5) * 36 - 72
  const dy = (ordinal % 4) * 30 - 45
  const cx = SLIDE_W / 2 + dx
  const cy = SLIDE_H / 2 + dy
  switch (kind) {
    case 'text':
      return textEl({ x: cx - 240, y: cy - 40, w: 480, h: 80, placeholder: 'Type something' })
    case 'rect': {
      const el: ShapeElement = { id: uid('el'), kind, x: cx - 110, y: cy - 60, w: 220, h: 120, rotation: 0, fill, label: '', fontSize: 24 }
      return el
    }
    case 'ellipse': {
      const el: ShapeElement = { id: uid('el'), kind, x: cx - 100, y: cy - 70, w: 200, h: 140, rotation: 0, fill, label: '', fontSize: 24 }
      return el
    }
    case 'arrow': {
      const el: ShapeElement = { id: uid('el'), kind, x: cx - 120, y: cy - 24, w: 240, h: 48, rotation: 0, fill, label: '', fontSize: 24 }
      return el
    }
    case 'sticker': {
      const el: StickerElement = { id: uid('el'), kind, x: cx - 60, y: cy - 60, w: 120, h: 120, rotation: 0, emoji }
      return el
    }
  }
}

export function cloneSlide(slide: Slide): Slide {
  return {
    ...slide,
    id: uid('slide'),
    elements: slide.elements.map((el) => ({ ...el, id: uid('el') })),
  }
}

export function createDeck(): Deck {
  return { title: 'Untitled deck', themeId: 'midnight', slides: [createSlide('title')] }
}

export const STORAGE_KEY = 'slide-forge:deck'

const THEME_IDS: ThemeId[] = ['midnight', 'paper', 'coral', 'forest', 'slate', 'terminal']

export function loadDeck(): Deck {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return createDeck()
    const parsed: unknown = JSON.parse(raw)
    if (
      typeof parsed === 'object' &&
      parsed !== null &&
      'slides' in parsed &&
      Array.isArray(parsed.slides) &&
      parsed.slides.length > 0 &&
      'title' in parsed &&
      typeof parsed.title === 'string' &&
      'themeId' in parsed &&
      typeof parsed.themeId === 'string' &&
      THEME_IDS.includes(parsed.themeId as ThemeId)
    ) {
      return parsed as Deck
    }
  } catch {
    // fall through to a fresh deck
  }
  return createDeck()
}

export function saveDeck(deck: Deck): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(deck))
}

export function deckFileName(title: string): string {
  const slug = title.trim().toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '')
  return slug || 'deck'
}
