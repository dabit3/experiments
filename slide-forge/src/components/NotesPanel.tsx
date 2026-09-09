import { Icon } from './Icons'

interface Props {
  notes: string
  slideNumber: number
  slideCount: number
  onChange: (notes: string) => void
}

export function NotesPanel({ notes, slideNumber, slideCount, onChange }: Props) {
  return (
    <section className="notes" aria-label="Speaker notes">
      <div className="notes-head">
        <Icon name="notes" size={16} />
        <span>Speaker notes</span>
        <span className="notes-count">
          Slide {slideNumber} of {slideCount}
        </span>
      </div>
      <textarea
        className="notes-input"
        value={notes}
        placeholder="Click to add speaker notes — they show up in presenter view (press P while presenting)."
        onChange={(e) => onChange(e.target.value)}
        spellCheck={false}
      />
    </section>
  )
}
