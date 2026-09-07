import { useCallback, useEffect, useReducer, useState } from 'react'
import {
  DndContext,
  DragOverlay,
  KeyboardSensor,
  MeasuringStrategy,
  PointerSensor,
  closestCorners,
  pointerWithin,
  useSensor,
  useSensors,
  type CollisionDetection,
  type DragEndEvent,
  type DragOverEvent,
  type DragStartEvent,
  type UniqueIdentifier,
} from '@dnd-kit/core'
import { sortableKeyboardCoordinates } from '@dnd-kit/sortable'
import { boardReducer, findColumnOfCard } from './boardReducer'
import { createSeedBoard } from './data'
import { loadBoard, saveBoard } from './storage'
import type { ColumnId } from './types'
import { CardModal } from './components/CardModal'
import { CardView } from './components/CardView'
import { ColumnView } from './components/ColumnView'

/** Prefer whatever card is directly under the pointer, then its column, then nearest corners. */
const collisionDetection: CollisionDetection = (args) => {
  const within = pointerWithin(args)
  const cardHits = within.filter((hit) => hit.data?.droppableContainer?.data.current?.type === 'card')
  if (cardHits.length > 0) return cardHits
  if (within.length > 0) return within
  return closestCorners(args)
}

export default function App() {
  const [board, dispatch] = useReducer(boardReducer, undefined, () => loadBoard() ?? createSeedBoard())
  const [activeCardId, setActiveCardId] = useState<string | null>(null)
  const [overColumnId, setOverColumnId] = useState<ColumnId | null>(null)
  const [openCardId, setOpenCardId] = useState<string | null>(null)

  useEffect(() => {
    saveBoard(board)
  }, [board])

  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 6 } }),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates }),
  )

  const resolveColumn = useCallback(
    (id: UniqueIdentifier): ColumnId | undefined => {
      const asColumn = board.columns.find((column) => column.id === id)
      return asColumn ? asColumn.id : findColumnOfCard(board, String(id))
    },
    [board],
  )

  function handleDragStart({ active }: DragStartEvent) {
    setActiveCardId(String(active.id))
    setOverColumnId(resolveColumn(active.id) ?? null)
  }

  function handleDragOver({ active, over }: DragOverEvent) {
    if (!over) return
    const fromColumn = resolveColumn(active.id)
    const toColumn = resolveColumn(over.id)
    if (!fromColumn || !toColumn) return
    setOverColumnId(toColumn)
    if (fromColumn === toColumn) return

    const target = board.columns.find((column) => column.id === toColumn)
    if (!target) return

    let toIndex = target.cardIds.length
    if (over.id !== toColumn) {
      const overIndex = target.cardIds.indexOf(String(over.id))
      const translated = active.rect.current.translated
      const isBelowOver = translated ? translated.top + translated.height / 2 > over.rect.top + over.rect.height / 2 : false
      toIndex = overIndex + (isBelowOver ? 1 : 0)
    }
    dispatch({ type: 'move-card', cardId: String(active.id), toColumn, toIndex })
  }

  function handleDragEnd({ active, over }: DragEndEvent) {
    setActiveCardId(null)
    setOverColumnId(null)
    if (!over) return
    const fromColumn = resolveColumn(active.id)
    const toColumn = resolveColumn(over.id)
    if (!fromColumn || !toColumn || fromColumn !== toColumn) return

    const column = board.columns.find((entry) => entry.id === fromColumn)
    if (!column) return
    const fromIndex = column.cardIds.indexOf(String(active.id))
    const toIndex = over.id === toColumn ? column.cardIds.length - 1 : column.cardIds.indexOf(String(over.id))
    if (fromIndex !== -1 && toIndex !== -1 && fromIndex !== toIndex) {
      dispatch({ type: 'reorder-card', columnId: fromColumn, fromIndex, toIndex })
    }
  }

  function handleDragCancel() {
    setActiveCardId(null)
    setOverColumnId(null)
  }

  const closeModal = useCallback(() => setOpenCardId(null), [])

  const activeCard = activeCardId ? board.cards[activeCardId] : undefined
  const openCard = openCardId ? board.cards[openCardId] : undefined
  const openCardColumn = openCardId ? board.columns.find((column) => column.cardIds.includes(openCardId)) : undefined
  const totalCards = Object.keys(board.cards).length
  const doneCount = board.columns.find((column) => column.id === 'done')?.cardIds.length ?? 0

  return (
    <div className="app">
      <header className="topbar">
        <div className="topbar__brand">
          <span className="topbar__logo" aria-hidden="true" />
          <div>
            <h1 className="topbar__title">Kanban Board</h1>
            <p className="topbar__subtitle">Sprint 42 · Product Launch</p>
          </div>
        </div>
        <div className="topbar__meta">
          <span className="topbar__stat">
            <strong>{totalCards}</strong> cards
          </span>
          <span className="topbar__stat">
            <strong>{doneCount}</strong> done
          </span>
          <button className="button button--ghost button--small" type="button" onClick={() => dispatch({ type: 'reset' })}>
            Reset board
          </button>
        </div>
      </header>

      <DndContext
        sensors={sensors}
        collisionDetection={collisionDetection}
        measuring={{ droppable: { strategy: MeasuringStrategy.Always } }}
        onDragStart={handleDragStart}
        onDragOver={handleDragOver}
        onDragEnd={handleDragEnd}
        onDragCancel={handleDragCancel}
      >
        <main className="board">
          {board.columns.map((column) => (
            <ColumnView
              key={column.id}
              column={column}
              cards={column.cardIds.map((id) => board.cards[id]).filter((card) => card !== undefined)}
              isDropTarget={activeCardId !== null && overColumnId === column.id}
              onAddCard={(title) => dispatch({ type: 'add-card', columnId: column.id, title })}
              onOpenCard={setOpenCardId}
            />
          ))}
        </main>

        <DragOverlay dropAnimation={{ duration: 180, easing: 'cubic-bezier(0.2, 0, 0, 1)' }}>
          {activeCard ? <CardView card={activeCard} overlay /> : null}
        </DragOverlay>
      </DndContext>

      {openCard && (
        <CardModal
          key={openCard.id}
          card={openCard}
          columnTitle={openCardColumn?.title ?? ''}
          onSave={(patch) => dispatch({ type: 'update-card', cardId: openCard.id, patch })}
          onDelete={() => {
            dispatch({ type: 'delete-card', cardId: openCard.id })
            closeModal()
          }}
          onClose={closeModal}
        />
      )}
    </div>
  )
}
