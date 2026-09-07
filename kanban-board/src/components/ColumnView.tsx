import type { CSSProperties } from 'react'
import { useDroppable } from '@dnd-kit/core'
import { SortableContext, verticalListSortingStrategy } from '@dnd-kit/sortable'
import type { Card, Column } from '../types'
import { AddCardForm } from './AddCardForm'
import { SortableCard } from './SortableCard'

interface ColumnViewProps {
  column: Column
  cards: Card[]
  isDropTarget: boolean
  onAddCard: (title: string) => void
  onOpenCard: (cardId: string) => void
}

export function ColumnView({ column, cards, isDropTarget, onAddCard, onOpenCard }: ColumnViewProps) {
  const { setNodeRef } = useDroppable({ id: column.id, data: { type: 'column' } })

  return (
    <section
      className={`column${isDropTarget ? ' column--drop-target' : ''}`}
      data-column-id={column.id}
      style={{ '--column-accent': column.accent } as CSSProperties}
      aria-label={`${column.title} column`}
    >
      <header className="column__header">
        <span className="column__dot" />
        <h2 className="column__title">{column.title}</h2>
        <span className="column__count" data-testid={`count-${column.id}`}>
          {cards.length}
        </span>
      </header>

      <SortableContext id={column.id} items={column.cardIds} strategy={verticalListSortingStrategy}>
        <div ref={setNodeRef} className="column__cards">
          {cards.map((card) => (
            <SortableCard key={card.id} card={card} onOpen={onOpenCard} />
          ))}
          {cards.length === 0 && <div className="column__empty">Drop cards here</div>}
        </div>
      </SortableContext>

      <AddCardForm columnTitle={column.title} onAdd={onAddCard} />
    </section>
  )
}
