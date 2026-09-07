import { useCallback, useEffect, useReducer, useRef } from 'react'
import {
  ROOMS,
  type ChatMessage,
  type ClientEvent,
  type Room,
  type ServerEvent,
  type User,
} from '../../shared/protocol.ts'

export type ConnectionStatus = 'connecting' | 'online' | 'offline'

export interface Profile {
  /** Stable per-tab id so a reload keeps ownership of earlier messages. */
  id: string
  name: string
  color: string
}

export interface ChatState {
  status: ConnectionStatus
  selfId: string | null
  users: User[]
  activeRoom: Room
  messages: Record<Room, ChatMessage[]>
  unread: Record<Room, number>
  /** room -> userId -> display name of people currently typing */
  typing: Record<Room, Record<string, string>>
  error: string | null
}

type Action =
  | { type: 'status'; status: ConnectionStatus }
  | { type: 'server'; event: ServerEvent }
  | { type: 'set_room'; room: Room }

function emptyRoomRecord<T>(make: () => T): Record<Room, T> {
  return Object.fromEntries(ROOMS.map((room) => [room, make()])) as Record<Room, T>
}

const initialState: ChatState = {
  status: 'connecting',
  selfId: null,
  users: [],
  activeRoom: 'general',
  messages: emptyRoomRecord(() => []),
  unread: emptyRoomRecord(() => 0),
  typing: emptyRoomRecord(() => ({})),
  error: null,
}

function reducer(state: ChatState, action: Action): ChatState {
  switch (action.type) {
    case 'status':
      return { ...state, status: action.status }
    case 'set_room':
      return {
        ...state,
        activeRoom: action.room,
        unread: { ...state.unread, [action.room]: 0 },
      }
    case 'server':
      return applyServerEvent(state, action.event)
  }
}

function applyServerEvent(state: ChatState, event: ServerEvent): ChatState {
  switch (event.type) {
    case 'welcome':
      return {
        ...state,
        status: 'online',
        selfId: event.selfId,
        users: event.users,
        messages: event.history,
        unread: emptyRoomRecord(() => 0),
        typing: emptyRoomRecord(() => ({})),
        error: null,
      }
    case 'presence':
      return { ...state, users: event.users }
    case 'message': {
      const { message } = event
      const room = message.room
      const isForeignChat =
        message.kind === 'chat' && room !== state.activeRoom && message.userId !== state.selfId
      return {
        ...state,
        messages: { ...state.messages, [room]: [...state.messages[room], message] },
        unread: isForeignChat ? { ...state.unread, [room]: state.unread[room] + 1 } : state.unread,
      }
    }
    case 'message_updated': {
      const { message } = event
      const list = state.messages[message.room].map((m) => (m.id === message.id ? message : m))
      return { ...state, messages: { ...state.messages, [message.room]: list } }
    }
    case 'message_deleted': {
      const list = state.messages[event.room].filter((m) => m.id !== event.messageId)
      return { ...state, messages: { ...state.messages, [event.room]: list } }
    }
    case 'typing': {
      if (event.userId === state.selfId) return state
      const roomTyping = { ...state.typing[event.room] }
      if (event.isTyping) roomTyping[event.userId] = event.name
      else delete roomTyping[event.userId]
      return { ...state, typing: { ...state.typing, [event.room]: roomTyping } }
    }
    case 'error':
      return { ...state, error: event.message }
  }
}

function socketUrl(): string {
  const override = import.meta.env.VITE_WS_URL as string | undefined
  if (override) return override
  const scheme = location.protocol === 'https:' ? 'wss' : 'ws'
  return `${scheme}://${location.host}/ws`
}

export function useChat(profile: Profile) {
  const [state, dispatch] = useReducer(reducer, initialState)
  const socketRef = useRef<WebSocket | null>(null)
  const activeRoomRef = useRef<Room>(initialState.activeRoom)

  const sendEvent = useCallback((event: ClientEvent) => {
    const socket = socketRef.current
    if (socket?.readyState === WebSocket.OPEN) socket.send(JSON.stringify(event))
  }, [])

  useEffect(() => {
    let disposed = false
    let retryTimer: ReturnType<typeof setTimeout> | undefined
    let attempt = 0

    const connect = () => {
      dispatch({ type: 'status', status: 'connecting' })
      const socket = new WebSocket(socketUrl())
      socketRef.current = socket

      socket.onopen = () => {
        attempt = 0
        const join: ClientEvent = { type: 'join', id: profile.id, name: profile.name, color: profile.color }
        socket.send(JSON.stringify(join))
        if (activeRoomRef.current !== 'general') {
          socket.send(JSON.stringify({ type: 'switch_room', room: activeRoomRef.current }))
        }
      }
      socket.onmessage = (raw) => {
        const event = JSON.parse(String(raw.data)) as ServerEvent
        dispatch({ type: 'server', event })
      }
      socket.onclose = () => {
        if (disposed) return
        dispatch({ type: 'status', status: 'offline' })
        const delay = Math.min(1000 * 2 ** attempt++, 8000)
        retryTimer = setTimeout(connect, delay)
      }
    }

    connect()
    return () => {
      disposed = true
      clearTimeout(retryTimer)
      socketRef.current?.close()
      socketRef.current = null
    }
  }, [profile.id, profile.name, profile.color])

  const switchRoom = useCallback(
    (room: Room) => {
      activeRoomRef.current = room
      dispatch({ type: 'set_room', room })
      sendEvent({ type: 'switch_room', room })
    },
    [sendEvent],
  )

  const sendMessage = useCallback(
    (text: string) => sendEvent({ type: 'message', room: activeRoomRef.current, text }),
    [sendEvent],
  )

  const setTyping = useCallback(
    (isTyping: boolean) => sendEvent({ type: 'typing', room: activeRoomRef.current, isTyping }),
    [sendEvent],
  )

  const react = useCallback(
    (messageId: string, emoji: string) => sendEvent({ type: 'react', messageId, emoji }),
    [sendEvent],
  )

  const editMessage = useCallback(
    (messageId: string, text: string) => sendEvent({ type: 'edit', messageId, text }),
    [sendEvent],
  )

  const deleteMessage = useCallback(
    (messageId: string) => sendEvent({ type: 'delete', messageId }),
    [sendEvent],
  )

  return { state, switchRoom, sendMessage, setTyping, react, editMessage, deleteMessage }
}
