import { useEffect, useRef } from 'react'
import type { BlockType, BlockTypeMeta } from './model'

interface Props {
  items: BlockTypeMeta[]
  selectedIndex: number
  position: { top: number; left: number }
  onHover: (index: number) => void
  onSelect: (type: BlockType) => void
}

export function SlashMenu({ items, selectedIndex, position, onHover, onSelect }: Props) {
  const listRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    listRef.current
      ?.querySelector<HTMLElement>(`[data-index="${selectedIndex}"]`)
      ?.scrollIntoView({ block: 'nearest' })
  }, [selectedIndex])

  return (
    <div className="slash-menu" role="listbox" style={position} data-testid="slash-menu">
      <div className="slash-menu-heading">Basic blocks</div>
      <div ref={listRef} className="slash-menu-list">
        {items.map((meta, index) => (
          <div
            key={meta.type}
            role="option"
            aria-selected={index === selectedIndex}
            data-index={index}
            className={`slash-item${index === selectedIndex ? ' is-selected' : ''}`}
            onMouseEnter={() => onHover(index)}
            onMouseDown={(e) => e.preventDefault()}
            onClick={() => onSelect(meta.type)}
          >
            <span className="slash-item-icon">{meta.icon}</span>
            <span className="slash-item-text">
              <span className="slash-item-label">{meta.label}</span>
              <span className="slash-item-description">{meta.description}</span>
            </span>
          </div>
        ))}
      </div>
    </div>
  )
}
