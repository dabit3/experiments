import { useEffect, useState } from 'react'
import { ROOM_TOPICS } from '../shared/protocol.ts'
import { Composer } from './components/Composer.tsx'
import { JoinScreen } from './components/JoinScreen.tsx'
import { MessageList } from './components/MessageList.tsx'
import { OnlineList } from './components/OnlineList.tsx'
import { Sidebar } from './components/Sidebar.tsx'
import { useChat, type Profile } from './lib/useChat.ts'

const PROFILE_KEY = 'relay.profile'

function loadProfile(): Profile | null {
  try {
    const raw = sessionStorage.getItem(PROFILE_KEY)
    if (!raw) return null
    const parsed = JSON.parse(raw) as Partial<Profile>
    return parsed.id && parsed.name && parsed.color
      ? { id: parsed.id, name: parsed.name, color: parsed.color }
      : null
  } catch {
    return null
  }
}

export default function App() {
  const [profile, setProfile] = useState<Profile | null>(loadProfile)

  const join = (next: Profile) => {
    sessionStorage.setItem(PROFILE_KEY, JSON.stringify(next))
    setProfile(next)
  }

  if (!profile) return <JoinScreen onJoin={join} />
  return <ChatShell profile={profile} />
}

function ChatShell({ profile }: { profile: Profile }) {
  const { state, switchRoom, sendMessage, setTyping, react, editMessage, deleteMessage } =
    useChat(profile)
  const { activeRoom, messages, unread, users, selfId, status, typing } = state

  useEffect(() => {
    const total = Object.values(unread).reduce((sum, n) => sum + n, 0)
    document.title = total ? `(${total}) #${activeRoom} · Relay` : `#${activeRoom} · Relay`
  }, [unread, activeRoom])

  return (
    <div className="app">
      <Sidebar
        activeRoom={activeRoom}
        unread={unread}
        profile={profile}
        status={status}
        onSelectRoom={switchRoom}
      />

      <main className="chat">
        <header className="chat-header">
          <h2>
            <span className="room-hash">#</span>
            {activeRoom}
          </h2>
          <p className="topic">{ROOM_TOPICS[activeRoom]}</p>
        </header>

        {state.error && <div className="banner error">{state.error}</div>}
        {status !== 'online' && (
          <div className="banner">
            {status === 'connecting' ? 'Connecting to the chat server…' : 'Connection lost — reconnecting…'}
          </div>
        )}

        <MessageList
          room={activeRoom}
          messages={messages[activeRoom]}
          selfId={selfId}
          users={users}
          onReact={react}
          onEdit={editMessage}
          onDelete={deleteMessage}
        />

        <Composer
          key={activeRoom}
          room={activeRoom}
          typingNames={Object.values(typing[activeRoom])}
          disabled={status !== 'online'}
          onSend={sendMessage}
          onTyping={setTyping}
        />
      </main>

      <OnlineList users={users} selfId={selfId} />
    </div>
  )
}
