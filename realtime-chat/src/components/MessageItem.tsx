import { useEffect, useRef, useState, type KeyboardEvent } from 'react'
import { REACTION_EMOJIS, type ChatMessage, type User } from '../../shared/protocol.ts'
import { Avatar } from './Avatar.tsx'
import { Emoji } from './Emoji.tsx'
import { PencilIcon, SmileIcon, TrashIcon } from './icons.tsx'

interface MessageItemProps {
  message: ChatMessage
  isOwn: boolean
  selfId: string | null
  users: User[]
  onReact: (emoji: string) => void
  onEdit: (text: string) => void
  onDelete: () => void
}

const timeFormat = new Intl.DateTimeFormat(undefined, { hour: 'numeric', minute: '2-digit' })

export function MessageItem({ message, isOwn, selfId, users, onReact, onEdit, onDelete }: MessageItemProps) {
  const [pickerOpen, setPickerOpen] = useState(false)
  const [editing, setEditing] = useState(false)
  const [draft, setDraft] = useState(message.text)
  const editRef = useRef<HTMLTextAreaElement>(null)

  useEffect(() => {
    if (editing) {
      const el = editRef.current
      el?.focus()
      el?.setSelectionRange(el.value.length, el.value.length)
    }
  }, [editing])

  if (message.kind === 'system') {
    return (
      <li className="system-message" data-message-id={message.id}>
        <span>{message.text}</span>
        <time dateTime={new Date(message.ts).toISOString()}>{timeFormat.format(message.ts)}</time>
      </li>
    )
  }

  const startEditing = () => {
    setDraft(message.text)
    setEditing(true)
    setPickerOpen(false)
  }

  const commitEdit = () => {
    const text = draft.trim()
    if (text && text !== message.text) onEdit(text)
    setEditing(false)
  }

  const onEditKeyDown = (event: KeyboardEvent<HTMLTextAreaElement>) => {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault()
      commitEdit()
    } else if (event.key === 'Escape') {
      setEditing(false)
    }
  }

  const reactions = Object.entries(message.reactions)
  const nameOf = (id: string) => users.find((u) => u.id === id)?.name ?? 'someone'

  return (
    <li
      className={`message${isOwn ? ' own' : ''}${editing ? ' editing' : ''}`}
      data-message-id={message.id}
      onMouseLeave={() => setPickerOpen(false)}
    >
      <Avatar name={message.name} color={message.color} />
      <div className="message-body">
        <div className="message-head">
          <span className="message-author" style={{ color: message.color }}>
            {message.name}
          </span>
          <time dateTime={new Date(message.ts).toISOString()}>{timeFormat.format(message.ts)}</time>
          {message.editedAt && <span className="edited">(edited)</span>}
        </div>

        {editing ? (
          <div className="edit-box">
            <textarea
              ref={editRef}
              rows={1}
              value={draft}
              onChange={(event) => setDraft(event.target.value)}
              onKeyDown={onEditKeyDown}
              aria-label="Edit message"
            />
            <div className="edit-actions">
              <span>
                <kbd>Enter</kbd> to save · <kbd>Esc</kbd> to cancel
              </span>
              <button type="button" className="ghost" onClick={() => setEditing(false)}>
                Cancel
              </button>
              <button type="button" className="primary small" onClick={commitEdit}>
                Save
              </button>
            </div>
          </div>
        ) : (
          <p className="message-text">{message.text}</p>
        )}

        {reactions.length > 0 && (
          <div className="reactions">
            {reactions.map(([emoji, ids]) => (
              <button
                key={emoji}
                type="button"
                className={`reaction${selfId && ids.includes(selfId) ? ' mine' : ''}`}
                title={ids.map(nameOf).join(', ')}
                onClick={() => onReact(emoji)}
              >
                <Emoji emoji={emoji} size={16} />
                <span className="reaction-count">{ids.length}</span>
              </button>
            ))}
          </div>
        )}
      </div>

      {!editing && (
        <div className="message-tools">
          <div className="toolbar" role="toolbar" aria-label="Message actions">
            <button
              type="button"
              title="Add reaction"
              aria-label="Add reaction"
              aria-expanded={pickerOpen}
              onClick={() => setPickerOpen((open) => !open)}
            >
              <SmileIcon />
            </button>
            {isOwn && (
              <>
                <button type="button" title="Edit" aria-label="Edit message" onClick={startEditing}>
                  <PencilIcon />
                </button>
                <button
                  type="button"
                  title="Delete"
                  aria-label="Delete message"
                  className="danger"
                  onClick={onDelete}
                >
                  <TrashIcon />
                </button>
              </>
            )}
          </div>
          {pickerOpen && (
            <div className="emoji-picker" role="menu">
              {REACTION_EMOJIS.map((emoji) => (
                <button
                  key={emoji}
                  type="button"
                  role="menuitem"
                  aria-label={`React with ${emoji}`}
                  onClick={() => {
                    onReact(emoji)
                    setPickerOpen(false)
                  }}
                >
                  <Emoji emoji={emoji} size={22} />
                </button>
              ))}
            </div>
          )}
        </div>
      )}
    </li>
  )
}
