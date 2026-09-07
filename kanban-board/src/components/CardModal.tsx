import { useEffect, useState, type CSSProperties } from 'react'
import { ASSIGNEES, LABELS, LABEL_ORDER } from '../data'
import type { Card, LabelId } from '../types'
import { Avatar } from './Avatar'

interface CardModalProps {
  card: Card
  columnTitle: string
  onSave: (patch: Partial<Omit<Card, 'id'>>) => void
  onDelete: () => void
  onClose: () => void
}

export function CardModal({ card, columnTitle, onSave, onDelete, onClose }: CardModalProps) {
  const [title, setTitle] = useState(card.title)
  const [description, setDescription] = useState(card.description)
  const [labels, setLabels] = useState<LabelId[]>(card.labels)
  const [assigneeId, setAssigneeId] = useState<string | null>(card.assigneeId)

  useEffect(() => {
    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape') onClose()
    }
    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [onClose])

  function toggleLabel(labelId: LabelId) {
    setLabels((current) =>
      current.includes(labelId)
        ? current.filter((id) => id !== labelId)
        : LABEL_ORDER.filter((id) => id === labelId || current.includes(id)),
    )
  }

  function handleSave() {
    const trimmed = title.trim()
    if (!trimmed) return
    onSave({ title: trimmed, description: description.trim(), labels, assigneeId })
    onClose()
  }

  return (
    <div className="modal-backdrop" onMouseDown={onClose} role="presentation">
      <div
        className="modal"
        role="dialog"
        aria-modal="true"
        aria-labelledby="modal-title"
        onMouseDown={(event) => event.stopPropagation()}
      >
        <header className="modal__header">
          <div>
            <span className="modal__eyebrow">
              {card.id} · in <strong>{columnTitle}</strong>
            </span>
            <label htmlFor="modal-title" className="visually-hidden">
              Title
            </label>
            <input
              id="modal-title"
              className="modal__title-input"
              value={title}
              onChange={(event) => setTitle(event.target.value)}
              autoFocus
            />
          </div>
          <button className="icon-button" onClick={onClose} aria-label="Close">
            ×
          </button>
        </header>

        <div className="modal__body">
          <section className="modal__section">
            <h4>Labels</h4>
            <div className="label-picker">
              {LABEL_ORDER.map((labelId) => {
                const label = LABELS[labelId]
                const active = labels.includes(labelId)
                return (
                  <button
                    key={labelId}
                    type="button"
                    className={`label-chip${active ? ' label-chip--active' : ''}`}
                    style={{ '--chip-color': label.color } as CSSProperties}
                    aria-pressed={active}
                    onClick={() => toggleLabel(labelId)}
                  >
                    {label.name}
                  </button>
                )
              })}
            </div>
          </section>

          <section className="modal__section">
            <h4>Assignee</h4>
            <div className="assignee-picker">
              <button
                type="button"
                className={`assignee-option${assigneeId === null ? ' assignee-option--active' : ''}`}
                onClick={() => setAssigneeId(null)}
                aria-pressed={assigneeId === null}
              >
                <Avatar assigneeId={null} size="md" />
              </button>
              {Object.values(ASSIGNEES).map((assignee) => (
                <button
                  key={assignee.id}
                  type="button"
                  className={`assignee-option${assigneeId === assignee.id ? ' assignee-option--active' : ''}`}
                  onClick={() => setAssigneeId(assignee.id)}
                  aria-pressed={assigneeId === assignee.id}
                  title={assignee.name}
                >
                  <Avatar assigneeId={assignee.id} size="md" />
                </button>
              ))}
            </div>
          </section>

          <section className="modal__section">
            <h4>
              <label htmlFor="modal-description">Description</label>
            </h4>
            <textarea
              id="modal-description"
              className="modal__description"
              rows={5}
              value={description}
              onChange={(event) => setDescription(event.target.value)}
              placeholder="Add a more detailed description…"
            />
          </section>
        </div>

        <footer className="modal__footer">
          <button className="button button--danger" type="button" onClick={onDelete}>
            Delete
          </button>
          <div className="modal__actions">
            <button className="button button--ghost" type="button" onClick={onClose}>
              Cancel
            </button>
            <button className="button button--primary" type="button" onClick={handleSave} disabled={!title.trim()}>
              Save
            </button>
          </div>
        </footer>
      </div>
    </div>
  )
}
