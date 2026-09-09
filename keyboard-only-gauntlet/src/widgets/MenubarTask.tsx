import { useEffect, useRef, useState } from 'react'
import type { FocusEvent, KeyboardEvent } from 'react'
import { findTypeahead, isPrintableKey } from '../lib/keys'
import type { WidgetProps } from './types'

interface MenuItem {
  label: string
  shortcut?: string
}

interface MenuDef {
  label: string
  items: MenuItem[]
}

const MENUS: MenuDef[] = [
  {
    label: 'File',
    items: [
      { label: 'New File', shortcut: 'Ctrl+N' },
      { label: 'Open…', shortcut: 'Ctrl+O' },
      { label: 'Save', shortcut: 'Ctrl+S' },
      { label: 'Save As…', shortcut: 'Ctrl+Shift+S' },
      { label: 'Export' },
      { label: 'Close Window', shortcut: 'Ctrl+W' },
    ],
  },
  {
    label: 'Edit',
    items: [
      { label: 'Undo', shortcut: 'Ctrl+Z' },
      { label: 'Redo', shortcut: 'Ctrl+Y' },
      { label: 'Cut', shortcut: 'Ctrl+X' },
      { label: 'Copy', shortcut: 'Ctrl+C' },
      { label: 'Paste', shortcut: 'Ctrl+V' },
      { label: 'Find & Replace', shortcut: 'Ctrl+H' },
    ],
  },
  {
    label: 'View',
    items: [
      { label: 'Command Palette', shortcut: 'Ctrl+Shift+P' },
      { label: 'Appearance' },
      { label: 'Zoom In', shortcut: 'Ctrl+=' },
      { label: 'Zoom Out', shortcut: 'Ctrl+-' },
      { label: 'Zen Mode', shortcut: 'Ctrl+K Z' },
      { label: 'Word Wrap', shortcut: 'Alt+Z' },
    ],
  },
]

const MENUBAR_TARGET = { menu: 'View', item: 'Zen Mode' }

export function MenubarTask({ onComplete }: WidgetProps) {
  const [barIndex, setBarIndex] = useState(0)
  const [open, setOpen] = useState<number | null>(null)
  const [itemIndex, setItemIndex] = useState(0)
  const [lastActivated, setLastActivated] = useState<string | null>(null)
  const [zen, setZen] = useState(false)
  const rootRef = useRef<HTMLDivElement>(null)
  const barRefs = useRef<(HTMLButtonElement | null)[]>([])
  const itemRefs = useRef<(HTMLButtonElement | null)[][]>([])

  useEffect(() => {
    if (open === null) return
    itemRefs.current[open]?.[itemIndex]?.focus()
  }, [open, itemIndex])

  const focusBar = (i: number) => {
    setBarIndex(i)
    barRefs.current[i]?.focus()
  }

  const openMenu = (i: number, item = 0) => {
    setBarIndex(i)
    setOpen(i)
    setItemIndex(item)
  }

  const closeMenu = (i: number) => {
    setOpen(null)
    barRefs.current[i]?.focus()
  }

  const activate = (menu: number, item: number) => {
    const menuLabel = MENUS[menu].label
    const itemLabel = MENUS[menu].items[item].label
    setLastActivated(`${menuLabel} › ${itemLabel}`)
    if (itemLabel === 'Zen Mode') setZen((z) => !z)
    closeMenu(menu)
    if (menuLabel === MENUBAR_TARGET.menu && itemLabel === MENUBAR_TARGET.item) onComplete()
  }

  const onBarKeyDown = (e: KeyboardEvent<HTMLButtonElement>, i: number) => {
    const n = MENUS.length
    switch (e.key) {
      case 'ArrowRight':
        if (open !== null) openMenu((i + 1) % n)
        else focusBar((i + 1) % n)
        break
      case 'ArrowLeft':
        if (open !== null) openMenu((i - 1 + n) % n)
        else focusBar((i - 1 + n) % n)
        break
      case 'ArrowDown':
      case 'Enter':
      case ' ':
        openMenu(i, 0)
        break
      case 'ArrowUp':
        openMenu(i, MENUS[i].items.length - 1)
        break
      case 'Home':
        focusBar(0)
        break
      case 'End':
        focusBar(n - 1)
        break
      case 'Escape':
        if (open === null) return
        closeMenu(i)
        break
      default: {
        if (!isPrintableKey(e)) return
        const j = findTypeahead(MENUS.map((m) => m.label), i, e.key)
        if (j === -1) return
        focusBar(j)
      }
    }
    e.preventDefault()
  }

  const onItemKeyDown = (e: KeyboardEvent<HTMLButtonElement>, menu: number, i: number) => {
    const items = MENUS[menu].items
    const n = MENUS.length
    switch (e.key) {
      case 'ArrowDown':
        setItemIndex((i + 1) % items.length)
        break
      case 'ArrowUp':
        setItemIndex((i - 1 + items.length) % items.length)
        break
      case 'Home':
        setItemIndex(0)
        break
      case 'End':
        setItemIndex(items.length - 1)
        break
      case 'ArrowRight':
        openMenu((menu + 1) % n)
        break
      case 'ArrowLeft':
        openMenu((menu - 1 + n) % n)
        break
      case 'Enter':
      case ' ':
        activate(menu, i)
        break
      case 'Escape':
        closeMenu(menu)
        break
      case 'Tab':
        setOpen(null)
        return
      default: {
        if (!isPrintableKey(e)) return
        const j = findTypeahead(items.map((it) => it.label), i, e.key)
        if (j === -1) return
        setItemIndex(j)
      }
    }
    e.preventDefault()
  }

  const onBlur = (e: FocusEvent<HTMLDivElement>) => {
    if (!rootRef.current?.contains(e.relatedTarget)) setOpen(null)
  }

  return (
    <div className={`editor-shell${zen ? ' zen' : ''}`} ref={rootRef} onBlur={onBlur}>
      <ul role="menubar" aria-label="Editor" className="menubar">
        {MENUS.map((menu, i) => (
          <li key={menu.label} role="none" className="menubar-item">
            <button
              type="button"
              role="menuitem"
              aria-haspopup="true"
              aria-expanded={open === i}
              tabIndex={barIndex === i ? 0 : -1}
              className={`menubar-trigger${open === i ? ' open' : ''}`}
              ref={(el) => {
                barRefs.current[i] = el
              }}
              onKeyDown={(e) => onBarKeyDown(e, i)}
              onFocus={() => setBarIndex(i)}
            >
              {menu.label}
            </button>
            {open === i && (
              <ul role="menu" aria-label={menu.label} className="menu">
                {menu.items.map((item, j) => (
                  <li key={item.label} role="none">
                    <button
                      type="button"
                      role="menuitem"
                      tabIndex={-1}
                      className={`menu-item${j === itemIndex ? ' active' : ''}${
                        item.label === 'Zen Mode' && zen ? ' checked' : ''
                      }`}
                      ref={(el) => {
                        ;(itemRefs.current[i] ??= [])[j] = el
                      }}
                      onKeyDown={(e) => onItemKeyDown(e, i, j)}
                    >
                      <span className="menu-item-label">{item.label}</span>
                      {item.shortcut && <kbd className="menu-shortcut">{item.shortcut}</kbd>}
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </li>
        ))}
      </ul>
      <div className="editor-body" aria-hidden="true">
        <div className="editor-gutter">
          {Array.from({ length: 7 }, (_, i) => (
            <span key={i}>{i + 1}</span>
          ))}
        </div>
        <pre className="editor-code">
          <span className="tok-kw">export function</span> <span className="tok-fn">focusNext</span>(items) {'{'}
          {'\n'}  <span className="tok-kw">const</span> i = items.indexOf(document.activeElement)
          {'\n'}  <span className="tok-kw">return</span> items[(i + <span className="tok-num">1</span>) % items.length]
          {'\n'}
          {'}'}
          {'\n\n'}
          <span className="tok-cm">// keyboard first, always</span>
        </pre>
        {zen && <div className="zen-badge">Zen Mode</div>}
      </div>
      <p className="widget-status" aria-live="polite">
        {lastActivated ? (
          <>
            Activated <strong>{lastActivated}</strong>
            {lastActivated !== `${MENUBAR_TARGET.menu} › ${MENUBAR_TARGET.item}` && (
              <span className="status-hint"> — not the target, try View › Zen Mode</span>
            )}
          </>
        ) : (
          'Nothing activated yet'
        )}
      </p>
    </div>
  )
}
