import { useEffect, useRef, useState, type FormEvent, type KeyboardEvent } from 'react'
import type { Room } from '../../shared/protocol.ts'

interface ComposerProps {
  room: Room
  typingNames: string[]
  disabled: boolean
  onSend: (text: string) => void
  onTyping: (isTyping: boolean) => void
}

const TYPING_IDLE_MS = 2000

export function Composer({ room, typingNames, disabled, onSend, onTyping }: ComposerProps) {
  const [text, setText] = useState('')
  const inputRef = useRef<HTMLTextAreaElement>(null)
  const typingRef = useRef(false)
  const idleTimer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined)

  const stopTyping = () => {
    clearTimeout(idleTimer.current)
    if (typingRef.current) {
      typingRef.current = false
      onTyping(false)
    }
  }

  useEffect(() => {
    if (!disabled) inputRef.current?.focus()
  }, [disabled])

  useEffect(() => {
    return () => {
      clearTimeout(idleTimer.current)
      if (typingRef.current) onTyping(false)
    }
  }, [onTyping])

  const handleChange = (value: string) => {
    setText(value)
    if (value.trim()) {
      if (!typingRef.current) {
        typingRef.current = true
        onTyping(true)
      }
      clearTimeout(idleTimer.current)
      idleTimer.current = setTimeout(stopTyping, TYPING_IDLE_MS)
    } else {
      stopTyping()
    }
  }

  const submit = (event?: FormEvent) => {
    event?.preventDefault()
    const value = text.trim()
    if (!value || disabled) return
    stopTyping()
    onSend(value)
    setText('')
    inputRef.current?.focus()
  }

  const onKeyDown = (event: KeyboardEvent<HTMLTextAreaElement>) => {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault()
      submit()
    }
  }

  return (
    <div className="composer-wrap">
      <div className={`typing${typingNames.length ? ' visible' : ''}`} aria-live="polite">
        {typingNames.length > 0 && (
          <>
            <span className="typing-dots">
              <i />
              <i />
              <i />
            </span>
            <span>{formatTyping(typingNames)}</span>
          </>
        )}
      </div>
      <form className="composer" onSubmit={submit}>
        <textarea
          ref={inputRef}
          rows={1}
          value={text}
          disabled={disabled}
          placeholder={`Message #${room}`}
          aria-label={`Message #${room}`}
          onChange={(event) => handleChange(event.target.value)}
          onKeyDown={onKeyDown}
        />
        <button type="submit" className="primary" disabled={disabled || !text.trim()}>
          Send
        </button>
      </form>
    </div>
  )
}

function formatTyping(names: string[]): string {
  if (names.length === 1) return `${names[0]} is typing…`
  if (names.length === 2) return `${names[0]} and ${names[1]} are typing…`
  return 'Several people are typing…'
}
