import { useEffect, useState } from 'react'
import type { CalendarEvent, ColorId } from '../types'
import { useClampedPosition } from '../useClampedPosition'
import { ColorPicker } from './ColorPicker'

interface Props {
  event: CalendarEvent
  x: number
  y: number
  onEdit(): void
  onDuplicate(): void
  onChangeColor(color: ColorId): void
  onDelete(): void
  onClose(): void
}

export function ContextMenu({ event, x, y, onEdit, onDuplicate, onChangeColor, onDelete, onClose }: Props) {
  const { ref, style } = useClampedPosition(x, y)
  const [showColors, setShowColors] = useState(false)

  useEffect(() => {
    const handleMouseDown = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) onClose()
    }
    const handleKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    window.addEventListener('mousedown', handleMouseDown)
    window.addEventListener('keydown', handleKey)
    return () => {
      window.removeEventListener('mousedown', handleMouseDown)
      window.removeEventListener('keydown', handleKey)
    }
  }, [onClose, ref])

  return (
    <div ref={ref} className="context-menu" style={style} role="menu" aria-label={`Options for ${event.title}`}>
      <div className="context-menu-header">{event.title}</div>
      <button type="button" role="menuitem" className="menu-item" onClick={onEdit}>
        <PencilIcon /> Edit
      </button>
      <button type="button" role="menuitem" className="menu-item" onClick={onDuplicate}>
        <CopyIcon /> Duplicate
      </button>
      <button
        type="button"
        role="menuitem"
        className={`menu-item ${showColors ? 'is-open' : ''}`}
        aria-expanded={showColors}
        onClick={() => setShowColors((v) => !v)}
      >
        <PaletteIcon /> Change color
        <span className="menu-caret">{showColors ? '▾' : '▸'}</span>
      </button>
      {showColors && (
        <div className="menu-colors">
          <ColorPicker value={event.color} onChange={onChangeColor} />
        </div>
      )}
      <div className="menu-divider" />
      <button type="button" role="menuitem" className="menu-item danger" onClick={onDelete}>
        <TrashIcon /> Delete
      </button>
    </div>
  )
}

const iconProps = {
  width: 16,
  height: 16,
  viewBox: '0 0 24 24',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: 1.8,
  strokeLinecap: 'round',
  strokeLinejoin: 'round',
  'aria-hidden': true,
} as const

function PencilIcon() {
  return (
    <svg {...iconProps}>
      <path d="M4 20h4l10.5-10.5a2.1 2.1 0 0 0-3-3L5 17v3zM13.5 6.5l3 3" />
    </svg>
  )
}

function CopyIcon() {
  return (
    <svg {...iconProps}>
      <rect x="9" y="9" width="11" height="11" rx="2" />
      <path d="M5 15V6a2 2 0 0 1 2-2h9" />
    </svg>
  )
}

function PaletteIcon() {
  return (
    <svg {...iconProps}>
      <path d="M12 3a9 9 0 1 0 0 18h1a2 2 0 0 0 1.5-3.4 2 2 0 0 1 1.5-3.3H18a3 3 0 0 0 3-3 8.7 8.7 0 0 0-9-8.3z" />
      <circle cx="7.5" cy="11.5" r="1" fill="currentColor" />
      <circle cx="10.5" cy="7.5" r="1" fill="currentColor" />
      <circle cx="15" cy="7.5" r="1" fill="currentColor" />
    </svg>
  )
}

function TrashIcon() {
  return (
    <svg {...iconProps}>
      <path d="M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13M10 11v6M14 11v6" />
    </svg>
  )
}
