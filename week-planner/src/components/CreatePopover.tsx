import { useEffect, useState, type FormEvent } from 'react'
import type { ColorId } from '../types'
import { formatLongDate, formatTimeRange } from '../dateUtils'
import { useClampedPosition } from '../useClampedPosition'
import { ColorPicker } from './ColorPicker'
import type { Draft } from '../App'

interface Props {
  draft: Draft
  onSave(title: string, color: ColorId): void
  onMoreOptions(title: string, color: ColorId): void
  onCancel(): void
}

export function CreatePopover({ draft, onSave, onMoreOptions, onCancel }: Props) {
  const [title, setTitle] = useState('')
  const [color, setColor] = useState<ColorId>('peacock')
  const { ref, style } = useClampedPosition<HTMLFormElement>(draft.anchor.x, draft.anchor.y)

  useEffect(() => {
    const handleMouseDown = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) onCancel()
    }
    const handleKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onCancel()
    }
    window.addEventListener('mousedown', handleMouseDown)
    window.addEventListener('keydown', handleKey)
    return () => {
      window.removeEventListener('mousedown', handleMouseDown)
      window.removeEventListener('keydown', handleKey)
    }
  }, [onCancel, ref])

  const submit = (e: FormEvent) => {
    e.preventDefault()
    onSave(title.trim() || '(No title)', color)
  }

  return (
    <form
      ref={ref}
      className="popover create-popover"
      style={style}
      onSubmit={submit}
      role="dialog"
      aria-label="New event"
    >
      <input
        className="popover-title"
        placeholder="Add title"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        autoFocus
        aria-label="Event title"
      />
      <div className="popover-when">
        <CalendarIcon />
        <span>
          {formatLongDate(draft.start)}
          {draft.allDay ? ' · All day' : ` · ${formatTimeRange(draft.start, draft.end)}`}
        </span>
      </div>
      <ColorPicker value={color} onChange={setColor} />
      <div className="popover-actions">
        <button
          type="button"
          className="btn ghost-btn"
          onClick={() => onMoreOptions(title.trim() || '(No title)', color)}
        >
          More options
        </button>
        <button type="submit" className="btn primary">
          Save
        </button>
      </div>
    </form>
  )
}

function CalendarIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <rect x="3" y="5" width="18" height="16" rx="2" stroke="currentColor" strokeWidth="1.8" />
      <path d="M3 10h18M8 3v4M16 3v4" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
    </svg>
  )
}
