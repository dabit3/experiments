import { useCallback, useEffect, useState } from 'react'
import type { CalendarEvent, ColorId, ViewMode } from './types'
import { addDays, atMinutes, formatWeekTitle, startOfDay, startOfWeek } from './dateUtils'
import { useEvents, type EventInput } from './useEvents'
import { WeekView } from './components/WeekView'
import { AgendaView } from './components/AgendaView'
import { MiniMonth, Chevron } from './components/MiniMonth'
import { CreatePopover } from './components/CreatePopover'
import { ContextMenu } from './components/ContextMenu'
import { EditModal } from './components/EditModal'

/** A not-yet-saved event produced by drag-selecting on the grid. */
export interface Draft {
  start: Date
  end: Date
  allDay: boolean
  anchor: { x: number; y: number }
}

interface MenuState {
  eventId: string
  x: number
  y: number
}

interface EditorState {
  event: CalendarEvent
  isNew: boolean
}

export default function App() {
  const { events, addEvent, updateEvent, deleteEvent, duplicateEvent } = useEvents()
  const [weekStart, setWeekStart] = useState(() => startOfWeek(new Date()))
  const [view, setView] = useState<ViewMode>('week')
  const [draft, setDraft] = useState<Draft | null>(null)
  const [menu, setMenu] = useState<MenuState | null>(null)
  const [editor, setEditor] = useState<EditorState | null>(null)
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const today = startOfDay(new Date())

  const findEvent = (id: string) => events.find((e) => e.id === id) ?? null

  const openEditor = useCallback(
    (id: string) => {
      const event = events.find((e) => e.id === id)
      if (event) setEditor({ event, isNew: false })
      setMenu(null)
    },
    [events],
  )

  const createBlank = () => {
    const base = weekStart <= today && today < addDays(weekStart, 7) ? today : weekStart
    setEditor({
      event: {
        id: 'new',
        title: '',
        description: '',
        start: atMinutes(base, 9 * 60).toISOString(),
        end: atMinutes(base, 10 * 60).toISOString(),
        allDay: false,
        color: 'peacock',
      },
      isNew: true,
    })
  }

  const saveDraft = (title: string, color: ColorId) => {
    if (!draft) return
    const created = addEvent({
      title,
      description: '',
      start: draft.start.toISOString(),
      end: draft.end.toISOString(),
      allDay: draft.allDay,
      color,
    })
    setSelectedId(created.id)
    setDraft(null)
  }

  const draftMoreOptions = (title: string, color: ColorId) => {
    if (!draft) return
    setEditor({
      event: {
        id: 'new',
        title,
        description: '',
        start: draft.start.toISOString(),
        end: draft.end.toISOString(),
        allDay: draft.allDay,
        color,
      },
      isNew: true,
    })
    setDraft(null)
  }

  const saveEditor = (patch: EventInput) => {
    if (!editor) return
    if (editor.isNew) {
      const created = addEvent(patch)
      setSelectedId(created.id)
    } else {
      updateEvent(editor.event.id, patch)
    }
    setEditor(null)
  }

  const removeEvent = (id: string) => {
    deleteEvent(id)
    setMenu(null)
    setEditor(null)
    if (selectedId === id) setSelectedId(null)
  }

  const handleReschedule = useCallback(
    (id: string, start: Date, end: Date) => {
      updateEvent(id, { start: start.toISOString(), end: end.toISOString() })
      setSelectedId(id)
    },
    [updateEvent],
  )

  const handleRequestCreate = useCallback((next: Draft) => {
    setMenu(null)
    setDraft(next)
  }, [])

  const handleContextMenu = useCallback((eventId: string, x: number, y: number) => {
    setDraft(null)
    setMenu({ eventId, x, y })
  }, [])

  const cancelDraft = useCallback(() => setDraft(null), [])
  const closeMenu = useCallback(() => setMenu(null), [])
  const closeEditor = useCallback(() => setEditor(null), [])

  useEffect(() => {
    const handleKey = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement
      const typing = ['INPUT', 'TEXTAREA', 'SELECT'].includes(target.tagName)
      if (typing || editor || draft) return
      if ((e.key === 'Delete' || e.key === 'Backspace') && selectedId) {
        e.preventDefault()
        removeEvent(selectedId)
      } else if (e.key === 't' || e.key === 'T') {
        setWeekStart(startOfWeek(new Date()))
      }
    }
    window.addEventListener('keydown', handleKey)
    return () => window.removeEventListener('keydown', handleKey)
  })

  const menuEvent = menu ? findEvent(menu.eventId) : null

  return (
    <div className="app">
      <header className="topbar">
        <div className="brand">
          <span className="brand-mark">{today.getDate()}</span>
          <span className="brand-name">Week Planner</span>
        </div>
        <div className="nav">
          <button type="button" className="btn" onClick={() => setWeekStart(startOfWeek(new Date()))}>
            Today
          </button>
          <button
            type="button"
            className="icon-btn"
            aria-label="Previous week"
            onClick={() => setWeekStart(addDays(weekStart, -7))}
          >
            <Chevron direction="left" />
          </button>
          <button
            type="button"
            className="icon-btn"
            aria-label="Next week"
            onClick={() => setWeekStart(addDays(weekStart, 7))}
          >
            <Chevron direction="right" />
          </button>
          <h1 className="week-title">{formatWeekTitle(weekStart)}</h1>
        </div>
        <div className="view-toggle" role="tablist" aria-label="View">
          <button
            type="button"
            role="tab"
            aria-selected={view === 'week'}
            className={view === 'week' ? 'is-active' : ''}
            onClick={() => setView('week')}
          >
            Week
          </button>
          <button
            type="button"
            role="tab"
            aria-selected={view === 'agenda'}
            className={view === 'agenda' ? 'is-active' : ''}
            onClick={() => setView('agenda')}
          >
            Agenda
          </button>
        </div>
      </header>

      <div className="layout">
        <aside className="sidebar">
          <button type="button" className="create-btn" onClick={createBlank}>
            <span className="create-plus">+</span> Create
          </button>
          <MiniMonth weekStart={weekStart} today={today} onSelectDate={(d) => setWeekStart(startOfWeek(d))} />
          <div className="tips">
            <div className="tips-title">Tips</div>
            <ul>
              <li>Drag on the grid to create an event</li>
              <li>Drag an event to move it, or its bottom edge to resize</li>
              <li>Right-click an event for more options</li>
              <li>Double-click an event to edit it</li>
            </ul>
          </div>
        </aside>

        <main className="main">
          {view === 'week' ? (
            <WeekView
              weekStart={weekStart}
              events={events}
              draft={draft}
              selectedId={selectedId}
              onRequestCreate={handleRequestCreate}
              onReschedule={handleReschedule}
              onSelect={setSelectedId}
              onOpenEdit={openEditor}
              onContextMenu={handleContextMenu}
            />
          ) : (
            <AgendaView
              weekStart={weekStart}
              events={events}
              today={today}
              onOpenEdit={openEditor}
              onContextMenu={handleContextMenu}
            />
          )}
        </main>
      </div>

      {draft && (
        <CreatePopover draft={draft} onSave={saveDraft} onMoreOptions={draftMoreOptions} onCancel={cancelDraft} />
      )}

      {menu && menuEvent && (
        <ContextMenu
          event={menuEvent}
          x={menu.x}
          y={menu.y}
          onEdit={() => openEditor(menuEvent.id)}
          onDuplicate={() => {
            duplicateEvent(menuEvent.id)
            setMenu(null)
          }}
          onChangeColor={(color) => {
            updateEvent(menuEvent.id, { color })
            setMenu(null)
          }}
          onDelete={() => removeEvent(menuEvent.id)}
          onClose={closeMenu}
        />
      )}

      {editor && (
        <EditModal
          key={editor.event.id}
          event={editor.event}
          isNew={editor.isNew}
          onSave={saveEditor}
          onDelete={() => removeEvent(editor.event.id)}
          onClose={closeEditor}
        />
      )}
    </div>
  )
}
