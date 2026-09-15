import { useEffect, useLayoutEffect, useRef, useState } from 'react'

export interface MenuItem {
  label: string
  shortcut?: string
  danger?: boolean
  disabled?: boolean
  onClick: () => void
}

interface Props {
  x: number
  y: number
  items: MenuItem[]
  onClose: () => void
}

export function ContextMenu({ x, y, items, onClose }: Props) {
  const ref = useRef<HTMLDivElement>(null)
  const [pos, setPos] = useState({ x, y })

  useLayoutEffect(() => {
    const el = ref.current
    if (!el) return
    const r = el.getBoundingClientRect()
    setPos({
      x: Math.min(x, window.innerWidth - r.width - 8),
      y: Math.min(y, window.innerHeight - r.height - 8),
    })
  }, [x, y])

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    const onDown = (e: PointerEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) onClose()
    }
    window.addEventListener('keydown', onKey)
    window.addEventListener('pointerdown', onDown)
    window.addEventListener('blur', onClose)
    return () => {
      window.removeEventListener('keydown', onKey)
      window.removeEventListener('pointerdown', onDown)
      window.removeEventListener('blur', onClose)
    }
  }, [onClose])

  return (
    <div ref={ref} className="context-menu" role="menu" style={{ left: pos.x, top: pos.y }} onContextMenu={(e) => e.preventDefault()}>
      {items.map((item) => (
        <button
          key={item.label}
          type="button"
          role="menuitem"
          className={`menu-item ${item.danger ? 'is-danger' : ''}`}
          disabled={item.disabled}
          onClick={() => {
            item.onClick()
            onClose()
          }}
        >
          <span>{item.label}</span>
          {item.shortcut && <kbd>{item.shortcut}</kbd>}
        </button>
      ))}
    </div>
  )
}
