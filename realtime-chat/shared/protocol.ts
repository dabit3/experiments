export const ROOMS = ['general', 'random', 'devin'] as const
export type Room = (typeof ROOMS)[number]

export const ROOM_TOPICS: Record<Room, string> = {
  general: 'Team-wide announcements and chatter',
  random: 'Off-topic, memes, and weekend plans',
  devin: 'Watching Devin drive the browser',
}

export const REACTION_EMOJIS = ['👍', '❤️', '😂', '🎉', '🚀', '👀'] as const

export const AVATAR_COLORS = [
  '#f97316',
  '#ef4444',
  '#ec4899',
  '#a855f7',
  '#6366f1',
  '#0ea5e9',
  '#14b8a6',
  '#22c55e',
] as const

export interface User {
  id: string
  name: string
  color: string
  room: Room
}

export interface ChatMessage {
  id: string
  room: Room
  kind: 'chat' | 'system'
  userId: string
  name: string
  color: string
  text: string
  ts: number
  editedAt?: number
  /** emoji -> ids of users who reacted */
  reactions: Record<string, string[]>
}

export type ClientEvent =
  | { type: 'join'; name: string; color: string; id?: string }
  | { type: 'switch_room'; room: Room }
  | { type: 'message'; room: Room; text: string }
  | { type: 'typing'; room: Room; isTyping: boolean }
  | { type: 'react'; messageId: string; emoji: string }
  | { type: 'edit'; messageId: string; text: string }
  | { type: 'delete'; messageId: string }

export type ServerEvent =
  | {
      type: 'welcome'
      selfId: string
      users: User[]
      history: Record<Room, ChatMessage[]>
    }
  | { type: 'presence'; users: User[] }
  | { type: 'message'; message: ChatMessage }
  | { type: 'message_updated'; message: ChatMessage }
  | { type: 'message_deleted'; room: Room; messageId: string }
  | { type: 'typing'; room: Room; userId: string; name: string; isTyping: boolean }
  | { type: 'error'; message: string }

export function isRoom(value: unknown): value is Room {
  return typeof value === 'string' && (ROOMS as readonly string[]).includes(value)
}
