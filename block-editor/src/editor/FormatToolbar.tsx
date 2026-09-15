import type { InlineFormat } from './formatting'

interface Props {
  rect: DOMRect
  active: Record<InlineFormat, boolean>
  onFormat: (format: InlineFormat) => void
}

const BUTTONS: { format: InlineFormat; label: string; title: string; className?: string }[] = [
  { format: 'bold', label: 'B', title: 'Bold (Ctrl+B)', className: 'is-bold' },
  { format: 'italic', label: 'I', title: 'Italic (Ctrl+I)', className: 'is-italic' },
  { format: 'underline', label: 'U', title: 'Underline (Ctrl+U)', className: 'is-underline' },
  { format: 'code', label: '</>', title: 'Inline code (Ctrl+E)', className: 'is-mono' },
  { format: 'link', label: 'Link', title: 'Add link (Ctrl+K)' },
]

const TOOLBAR_HEIGHT = 40

export function FormatToolbar({ rect, active, onFormat }: Props) {
  const top = Math.max(8, rect.top - TOOLBAR_HEIGHT - 8)
  const left = Math.min(Math.max(120, rect.left + rect.width / 2), window.innerWidth - 120)

  return (
    <div className="format-toolbar" style={{ top, left }} data-testid="format-toolbar">
      {BUTTONS.map((button) => (
        <button
          key={button.format}
          type="button"
          title={button.title}
          aria-label={button.title}
          aria-pressed={active[button.format]}
          className={`format-button ${button.className ?? ''}${active[button.format] ? ' is-active' : ''}`}
          onMouseDown={(e) => e.preventDefault()}
          onClick={() => onFormat(button.format)}
        >
          {button.label}
        </button>
      ))}
    </div>
  )
}
