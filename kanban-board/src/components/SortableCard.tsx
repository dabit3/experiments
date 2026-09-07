import { useSortable } from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'
import type { Card } from '../types'
import { CardView } from './CardView'

interface SortableCardProps {
  card: Card
  onOpen: (cardId: string) => void
}

export function SortableCard({ card, onOpen }: SortableCardProps) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({
    id: card.id,
    data: { type: 'card' },
  })

  return (
    <CardView
      ref={setNodeRef}
      card={card}
      dragging={isDragging}
      style={{ transform: CSS.Translate.toString(transform), transition }}
      onClick={() => onOpen(card.id)}
      onKeyDown={(event) => {
        if (event.key === 'Enter') onOpen(card.id)
      }}
      {...attributes}
      {...listeners}
    />
  )
}
