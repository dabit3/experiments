import { useEffect, useRef } from 'react'
import type { ChatMessage, Room, User } from '../../shared/protocol.ts'
import { MessageItem } from './MessageItem.tsx'

interface MessageListProps {
  room: Room
  messages: ChatMessage[]
  selfId: string | null
  users: User[]
  onReact: (messageId: string, emoji: string) => void
  onEdit: (messageId: string, text: string) => void
  onDelete: (messageId: string) => void
}

export function MessageList({ room, messages, selfId, users, onReact, onEdit, onDelete }: MessageListProps) {
  const endRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    endRef.current?.scrollIntoView({ block: 'end' })
  }, [messages.length, room])

  return (
    <div className="message-scroll">
      {messages.length === 0 && (
        <div className="empty-room">
          <span className="empty-hash">#</span>
          <h3>Welcome to #{room}</h3>
          <p>This is the very beginning of the room. Say hello!</p>
        </div>
      )}
      <ul className="messages" aria-live="polite">
        {messages.map((message) => (
          <MessageItem
            key={message.id}
            message={message}
            isOwn={message.userId === selfId}
            selfId={selfId}
            users={users}
            onReact={(emoji) => onReact(message.id, emoji)}
            onEdit={(text) => onEdit(message.id, text)}
            onDelete={() => onDelete(message.id)}
          />
        ))}
      </ul>
      <div ref={endRef} />
    </div>
  )
}
