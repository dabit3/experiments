import type { Deck, Theme } from '../types'
import { SlideView } from './SlideView'

/** One 13.333in × 7.5in page per slide; only visible under @media print. */
export function PrintView({ deck, theme }: { deck: Deck; theme: Theme }) {
  return (
    <div className="print-root" aria-hidden="true">
      {deck.slides.map((slide) => (
        <div key={slide.id} className="print-page">
          <SlideView slide={slide} theme={theme} width={1280} className="print-slide" />
        </div>
      ))}
    </div>
  )
}
