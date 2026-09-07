import type { User } from '../../shared/protocol.ts'
import { Avatar } from './Avatar.tsx'

interface OnlineListProps {
  users: User[]
  selfId: string | null
}

export function OnlineList({ users, selfId }: OnlineListProps) {
  return (
    <aside className="online">
      <div className="sidebar-section">
        Online <span className="count">{users.length}</span>
      </div>
      <ul className="online-list" aria-label="Who's online">
        {users.map((user) => (
          <li key={user.id} className="online-user">
            <span className="online-avatar">
              <Avatar name={user.name} color={user.color} size={30} />
              <i className="online-dot" />
            </span>
            <span className="online-meta">
              <span className="online-name">
                {user.name}
                {user.id === selfId && <em> (you)</em>}
              </span>
              <span className="online-room">in #{user.room}</span>
            </span>
          </li>
        ))}
      </ul>
    </aside>
  )
}
