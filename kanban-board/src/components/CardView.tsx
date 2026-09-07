import type { HTMLAttributes, Ref } from 'react'
import type { Card } from '../types'
import { Avatar } from './Avatar'
import { LabelPill } from './LabelPill'

interface CardViewProps extends HTMLAttributes<HTMLElement> {
  card: Card
  ref?: Ref<HTMLElement>
  dragging?: boolean
  overlay?: boolean
}

export function CardView({ card, ref, dragging = false, overlay = false, className = '', ...rest }: CardViewProps) {
  const classes = ['card', dragging && 'card--placeholder', overlay && 'card--overlay', className]
    .filter(Boolean)
    .join(' ')

  return (
    <article ref={ref} className={classes} data-card-id={card.id} {...rest}>
      {card.labels.length > 0 && (
        <div className="card__labels">
          {card.labels.map((labelId) => (
            <LabelPill key={labelId} labelId={labelId} />
          ))}
        </div>
      )}
      <h3 className="card__title">{card.title}</h3>
      <div className="card__footer">
        <span className="card__id">{card.id}</span>
        {card.description && (
          <span className="card__has-description" title="Has description" aria-label="Has description">
            ≡
          </span>
        )}
        <Avatar assigneeId={card.assigneeId} />
      </div>
    </article>
  )
}
