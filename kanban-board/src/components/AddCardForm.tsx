import { useState, type FormEvent } from 'react'

interface AddCardFormProps {
  columnTitle: string
  onAdd: (title: string) => void
}

export function AddCardForm({ columnTitle, onAdd }: AddCardFormProps) {
  const [title, setTitle] = useState('')

  function handleSubmit(event: FormEvent) {
    event.preventDefault()
    const trimmed = title.trim()
    if (!trimmed) return
    onAdd(trimmed)
    setTitle('')
  }

  return (
    <form className="add-card" onSubmit={handleSubmit}>
      <input
        className="add-card__input"
        type="text"
        value={title}
        onChange={(event) => setTitle(event.target.value)}
        placeholder="Add a card…"
        aria-label={`Add a card to ${columnTitle}`}
      />
      <button className="add-card__button" type="submit" disabled={!title.trim()} aria-label="Add card">
        +
      </button>
    </form>
  )
}
