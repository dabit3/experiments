import { ROOMS, type Room } from '../../shared/protocol.ts'
import type { ConnectionStatus, Profile } from '../lib/useChat.ts'
import { Avatar } from './Avatar.tsx'

interface SidebarProps {
  activeRoom: Room
  unread: Record<Room, number>
  profile: Profile
  status: ConnectionStatus
  onSelectRoom: (room: Room) => void
}

export function Sidebar({ activeRoom, unread, profile, status, onSelectRoom }: SidebarProps) {
  return (
    <aside className="sidebar">
      <div className="sidebar-brand">
        <span className="join-logo small">◉</span>
        <span>Relay</span>
      </div>

      <div className="sidebar-section">Rooms</div>
      <nav className="rooms" aria-label="Rooms">
        {ROOMS.map((room) => {
          const count = unread[room]
          return (
            <button
              key={room}
              type="button"
              className={`room${room === activeRoom ? ' active' : ''}${count ? ' has-unread' : ''}`}
              aria-current={room === activeRoom ? 'page' : undefined}
              onClick={() => onSelectRoom(room)}
            >
              <span className="room-hash">#</span>
              <span className="room-name">{room}</span>
              {count > 0 && (
                <span className="badge" aria-label={`${count} unread`}>
                  {count > 99 ? '99+' : count}
                </span>
              )}
            </button>
          )
        })}
      </nav>

      <div className="sidebar-self">
        <Avatar name={profile.name} color={profile.color} size={32} />
        <div className="self-meta">
          <span className="self-name">{profile.name}</span>
          <span className={`self-status ${status}`}>
            <i />
            {status === 'online' ? 'Connected' : status === 'connecting' ? 'Connecting…' : 'Reconnecting…'}
          </span>
        </div>
      </div>
    </aside>
  )
}
