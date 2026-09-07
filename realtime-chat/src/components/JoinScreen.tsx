import { useState, type FormEvent } from 'react'
import { AVATAR_COLORS } from '../../shared/protocol.ts'
import type { Profile } from '../lib/useChat.ts'
import { Avatar } from './Avatar.tsx'

interface JoinScreenProps {
  onJoin: (profile: Profile) => void
}

export function JoinScreen({ onJoin }: JoinScreenProps) {
  const [name, setName] = useState('')
  const [color, setColor] = useState<string>(AVATAR_COLORS[4])
  const trimmed = name.trim()

  const submit = (event: FormEvent) => {
    event.preventDefault()
    if (trimmed) onJoin({ id: crypto.randomUUID(), name: trimmed, color })
  }

  return (
    <main className="join">
      <form className="join-card" onSubmit={submit}>
        <div className="join-brand">
          <span className="join-logo">◉</span>
          <div>
            <h1>Relay</h1>
            <p>Realtime chat over a single WebSocket</p>
          </div>
        </div>

        <div className="join-preview">
          <Avatar name={trimmed || '?'} color={color} size={64} />
          <span className="join-preview-name">{trimmed || 'Your name'}</span>
        </div>

        <label className="field">
          <span>Display name</span>
          <input
            autoFocus
            maxLength={24}
            placeholder="e.g. Nader"
            value={name}
            onChange={(event) => setName(event.target.value)}
          />
        </label>

        <div className="field">
          <span>Avatar color</span>
          <div className="swatches" role="radiogroup" aria-label="Avatar color">
            {AVATAR_COLORS.map((swatch) => (
              <button
                key={swatch}
                type="button"
                role="radio"
                aria-checked={swatch === color}
                aria-label={swatch}
                className={`swatch${swatch === color ? ' selected' : ''}`}
                style={{ background: swatch }}
                onClick={() => setColor(swatch)}
              />
            ))}
          </div>
        </div>

        <button className="primary" type="submit" disabled={!trimmed}>
          Join the chat
        </button>
      </form>
    </main>
  )
}
