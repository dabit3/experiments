import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import type { Deck, ElementKind, SlideElement, SlideLayout, ThemeId } from './types'
import { useHistory } from './hooks/useHistory'
import { cloneSlide, createElement, createSlide, deckFileName, loadDeck, saveDeck, uid } from './lib/deck'
import { getTheme } from './lib/themes'
import { ContextMenu, type MenuItem } from './components/ContextMenu'
import { EditorCanvas } from './components/EditorCanvas'
import { NotesPanel } from './components/NotesPanel'
import { Presenter } from './components/Presenter'
import { PrintView } from './components/PrintView'
import { PropertiesPanel } from './components/PropertiesPanel'
import { SlideRail } from './components/SlideRail'
import { TopBar } from './components/TopBar'
import './App.css'

interface Menu {
  slideId: string
  x: number
  y: number
}

function isEditableTarget(target: EventTarget | null): boolean {
  if (!(target instanceof HTMLElement)) return false
  return target.isContentEditable || target.tagName === 'INPUT' || target.tagName === 'TEXTAREA'
}

export default function App() {
  const history = useHistory<Deck>(loadDeck)
  const deck = history.state
  const { update, checkpoint, undo, redo } = history

  const [currentId, setCurrentId] = useState(() => deck.slides[0].id)
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [menu, setMenu] = useState<Menu | null>(null)
  const [presenting, setPresenting] = useState(false)
  const [savedAt, setSavedAt] = useState<number | null>(() => Date.now())
  const typingRef = useRef<{ field: string; at: number } | null>(null)

  /** Consecutive keystrokes into the same field within 1.5s collapse into one undo step. */
  const shouldRecordTyping = (field: string) => {
    const now = Date.now()
    const last = typingRef.current
    typingRef.current = { field, at: now }
    return !(last && last.field === field && now - last.at < 1500)
  }

  const theme = useMemo(() => getTheme(deck.themeId), [deck.themeId])
  const currentIndex = Math.max(0, deck.slides.findIndex((s) => s.id === currentId))
  const slide = deck.slides[currentIndex]
  const selected = slide.elements.find((e) => e.id === selectedId) ?? null

  // Keep the current slide id valid after undo/redo/delete.
  useEffect(() => {
    if (!deck.slides.some((s) => s.id === currentId)) setCurrentId(deck.slides[0].id)
  }, [deck.slides, currentId])

  // Autosave (debounced) to localStorage.
  useEffect(() => {
    setSavedAt(null)
    const id = window.setTimeout(() => {
      saveDeck(deck)
      setSavedAt(Date.now())
    }, 400)
    return () => window.clearTimeout(id)
  }, [deck])

  const updateSlide = useCallback(
    (slideId: string, fn: (s: Deck['slides'][number]) => Deck['slides'][number], record = true) => {
      update((d) => ({ ...d, slides: d.slides.map((s) => (s.id === slideId ? fn(s) : s)) }), record)
    },
    [update],
  )

  const patchElement = useCallback(
    (id: string, patch: Partial<SlideElement>, record = true) => {
      updateSlide(
        currentId,
        (s) => ({ ...s, elements: s.elements.map((el) => (el.id === id ? ({ ...el, ...patch } as SlideElement) : el)) }),
        record,
      )
    },
    [currentId, updateSlide],
  )

  const commitText = useCallback(
    (id: string, value: string, contentHeight: number) => {
      setEditingId(null)
      updateSlide(currentId, (s) => ({
        ...s,
        elements: s.elements.map((el) => {
          if (el.id !== id) return el
          if (el.kind === 'text') {
            const h = Math.max(el.h, Math.ceil(contentHeight))
            return el.text === value && h === el.h ? el : { ...el, text: value, h }
          }
          if (el.kind === 'rect' || el.kind === 'ellipse') return el.label === value ? el : { ...el, label: value }
          return el
        }),
      }))
    },
    [currentId, updateSlide],
  )

  const insertElement = (kind: ElementKind, emoji?: string) => {
    const el = createElement(kind, deck.themeId, emoji, slide.elements.length)
    updateSlide(currentId, (s) => ({ ...s, elements: [...s.elements, el] }))
    setSelectedId(el.id)
    setEditingId(null)
  }

  const addSlide = (layout: SlideLayout, afterIndex = currentIndex) => {
    const s = createSlide(layout)
    update((d) => {
      const slides = [...d.slides]
      slides.splice(afterIndex + 1, 0, s)
      return { ...d, slides }
    })
    setCurrentId(s.id)
    setSelectedId(null)
  }

  const duplicateSlide = (slideId: string) => {
    const i = deck.slides.findIndex((s) => s.id === slideId)
    if (i < 0) return
    const copy = cloneSlide(deck.slides[i])
    update((d) => {
      const slides = [...d.slides]
      slides.splice(i + 1, 0, copy)
      return { ...d, slides }
    })
    setCurrentId(copy.id)
    setSelectedId(null)
  }

  const deleteSlide = (slideId: string) => {
    if (deck.slides.length <= 1) return
    const i = deck.slides.findIndex((s) => s.id === slideId)
    update((d) => ({ ...d, slides: d.slides.filter((s) => s.id !== slideId) }))
    if (slideId === currentId) {
      const fallback = deck.slides[i + 1] ?? deck.slides[i - 1]
      setCurrentId(fallback.id)
    }
    setSelectedId(null)
  }

  const moveSlide = (from: number, to: number) => {
    if (from === to || to < 0 || to >= deck.slides.length) return
    update((d) => {
      const slides = [...d.slides]
      const [s] = slides.splice(from, 1)
      slides.splice(to, 0, s)
      return { ...d, slides }
    })
  }

  const deleteElement = () => {
    if (!selectedId) return
    updateSlide(currentId, (s) => ({ ...s, elements: s.elements.filter((e) => e.id !== selectedId) }))
    setSelectedId(null)
  }

  const duplicateElement = () => {
    if (!selected) return
    const copy = { ...selected, id: uid('el'), x: selected.x + 24, y: selected.y + 24 }
    updateSlide(currentId, (s) => ({ ...s, elements: [...s.elements, copy] }))
    setSelectedId(copy.id)
  }

  const reorderElement = (dir: 1 | -1) => {
    if (!selectedId) return
    updateSlide(currentId, (s) => {
      const i = s.elements.findIndex((e) => e.id === selectedId)
      const j = i + dir
      if (i < 0 || j < 0 || j >= s.elements.length) return s
      const elements = [...s.elements]
      ;[elements[i], elements[j]] = [elements[j], elements[i]]
      return { ...s, elements }
    })
  }

  const setTheme = (themeId: ThemeId) => update((d) => (d.themeId === themeId ? d : { ...d, themeId }))
  const setTitle = (title: string) => update((d) => ({ ...d, title }), shouldRecordTyping('title'))
  const setNotes = (notes: string) => updateSlide(currentId, (s) => ({ ...s, notes }), shouldRecordTyping(`notes:${currentId}`))

  const startPresenting = () => {
    setEditingId(null)
    setSelectedId(null)
    setPresenting(true)
    const root = document.documentElement
    if (!document.fullscreenElement && root.requestFullscreen) {
      root.requestFullscreen().catch(() => undefined)
    }
  }

  const stopPresenting = useCallback(() => {
    setPresenting(false)
    if (document.fullscreenElement) document.exitFullscreen().catch(() => undefined)
  }, [])

  useEffect(() => {
    if (!presenting) return
    const onChange = () => {
      if (!document.fullscreenElement) setPresenting(false)
    }
    document.addEventListener('fullscreenchange', onChange)
    return () => document.removeEventListener('fullscreenchange', onChange)
  }, [presenting])

  const exportPdf = () => {
    setEditingId(null)
    setSelectedId(null)
    const previous = document.title
    document.title = deckFileName(deck.title)
    const restore = () => {
      document.title = previous
      window.removeEventListener('afterprint', restore)
    }
    window.addEventListener('afterprint', restore)
    window.setTimeout(() => window.print(), 50)
  }

  // Global keyboard shortcuts for the editor.
  useEffect(() => {
    if (presenting) return
    const onKey = (e: KeyboardEvent) => {
      const mod = e.ctrlKey || e.metaKey
      if (mod && e.key.toLowerCase() === 'z') {
        if (isEditableTarget(e.target)) return
        e.preventDefault()
        if (e.shiftKey) redo()
        else undo()
        return
      }
      if (mod && e.key.toLowerCase() === 'y') {
        if (isEditableTarget(e.target)) return
        e.preventDefault()
        redo()
        return
      }
      if (e.key === 'F5') {
        e.preventDefault()
        startPresenting()
        return
      }
      if (isEditableTarget(e.target) || editingId) return
      if (mod && e.key.toLowerCase() === 'd') {
        e.preventDefault()
        duplicateElement()
        return
      }
      if ((e.key === 'Delete' || e.key === 'Backspace') && selectedId) {
        e.preventDefault()
        deleteElement()
        return
      }
      if (e.key === 'Escape') {
        setSelectedId(null)
        return
      }
      if (selected && ['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown'].includes(e.key)) {
        e.preventDefault()
        const step = e.shiftKey ? 10 : 1
        const dx = e.key === 'ArrowLeft' ? -step : e.key === 'ArrowRight' ? step : 0
        const dy = e.key === 'ArrowUp' ? -step : e.key === 'ArrowDown' ? step : 0
        patchElement(selected.id, { x: selected.x + dx, y: selected.y + dy })
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  })

  const menuItems: MenuItem[] = menu
    ? (() => {
        const i = deck.slides.findIndex((s) => s.id === menu.slideId)
        return [
          { label: 'Duplicate slide', shortcut: 'Ctrl+D', onClick: () => duplicateSlide(menu.slideId) },
          { label: 'New slide below', onClick: () => addSlide('bullets', i) },
          { label: 'Move up', disabled: i <= 0, onClick: () => moveSlide(i, i - 1) },
          { label: 'Move down', disabled: i >= deck.slides.length - 1, onClick: () => moveSlide(i, i + 1) },
          { label: 'Delete slide', shortcut: 'Del', danger: true, disabled: deck.slides.length <= 1, onClick: () => deleteSlide(menu.slideId) },
        ]
      })()
    : []

  return (
    <>
      <div className="app">
        <TopBar
          title={deck.title}
          onTitleChange={setTitle}
          canUndo={history.canUndo}
          canRedo={history.canRedo}
          onUndo={undo}
          onRedo={redo}
          onInsert={insertElement}
          onAddSlide={(layout) => addSlide(layout)}
          onPresent={startPresenting}
          onExportPdf={exportPdf}
          savedAt={savedAt}
        />
        <div className="workspace">
          <SlideRail
            slides={deck.slides}
            theme={theme}
            currentId={slide.id}
            onSelect={(id) => {
              if (id !== currentId) {
                setCurrentId(id)
                setSelectedId(null)
                setEditingId(null)
              }
            }}
            onReorder={moveSlide}
            onContextMenu={(slideId, x, y) => setMenu({ slideId, x, y })}
            onAddSlide={() => addSlide('bullets')}
          />
          <main className="stage">
            <EditorCanvas
              slide={slide}
              theme={theme}
              selectedId={selectedId}
              editingId={editingId}
              onSelect={setSelectedId}
              onStartEdit={(id) => {
                setSelectedId(id)
                setEditingId(id)
              }}
              onStopEdit={() => setEditingId(null)}
              onCheckpoint={checkpoint}
              onPatch={patchElement}
              onCommitText={commitText}
            />
            <NotesPanel notes={slide.notes} slideNumber={currentIndex + 1} slideCount={deck.slides.length} onChange={setNotes} />
          </main>
          <PropertiesPanel
            element={selected}
            theme={theme}
            onThemeChange={setTheme}
            onPatch={(patch) => selected && patchElement(selected.id, patch)}
            onDelete={deleteElement}
            onDuplicate={duplicateElement}
            onBringForward={() => reorderElement(1)}
            onSendBackward={() => reorderElement(-1)}
          />
        </div>
      </div>
      {menu && <ContextMenu x={menu.x} y={menu.y} items={menuItems} onClose={() => setMenu(null)} />}
      {presenting && <Presenter deck={deck} theme={theme} startIndex={currentIndex} onExit={stopPresenting} />}
      <PrintView deck={deck} theme={theme} />
    </>
  )
}
