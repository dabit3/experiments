import type { CSSProperties, ReactNode } from 'react'
import type { Slide, Theme } from '../types'
import { SLIDE_H, SLIDE_W } from '../types'
import { ElementBody } from './ElementBody'

export function themeVars(theme: Theme): CSSProperties {
  return {
    '--slide-bg': theme.background,
    '--slide-text': theme.text,
    '--slide-muted': theme.muted,
    '--slide-accent': theme.accent,
    '--slide-heading-font': theme.headingFont,
    '--slide-body-font': theme.bodyFont,
  } as CSSProperties
}

export function elementStyle(el: { x: number; y: number; w: number; h: number; rotation: number }): CSSProperties {
  return {
    left: el.x,
    top: el.y,
    width: el.w,
    height: el.h,
    transform: el.rotation ? `rotate(${el.rotation}deg)` : undefined,
  }
}

interface Props {
  slide: Slide
  theme: Theme
  /** Rendered width in CSS px; the 960×540 slide is scaled to fit. */
  width: number
  className?: string
  /** Show editor placeholders for empty text boxes (thumbnails only). */
  placeholders?: boolean
  children?: ReactNode
}

/** Static, non-interactive rendering of a slide (thumbnails, presenter, print). */
export function SlideView({ slide, theme, width, className, placeholders = false, children }: Props) {
  const scale = width / SLIDE_W
  return (
    <div className={`slide-frame ${className ?? ''}`} style={{ width, height: width * (SLIDE_H / SLIDE_W) }}>
      <div className="slide-surface" style={{ ...themeVars(theme), transform: `scale(${scale})` }}>
        {slide.elements.map((el) => (
          <div key={el.id} className={`slide-el kind-${el.kind}`} style={elementStyle(el)}>
            <ElementBody el={el} placeholders={placeholders} />
          </div>
        ))}
        {children}
      </div>
    </div>
  )
}
