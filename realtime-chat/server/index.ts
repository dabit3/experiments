import { randomUUID } from 'node:crypto'
import { createServer } from 'node:http'
import { WebSocketServer, type WebSocket } from 'ws'
import {
  AVATAR_COLORS,
  REACTION_EMOJIS,
  ROOMS,
  isRoom,
  type ChatMessage,
  type ClientEvent,
  type Room,
  type ServerEvent,
  type User,
} from '../shared/protocol.ts'

const PORT = Number(process.env.PORT ?? 3001)
const HOST = process.env.HOST ?? '127.0.0.1'
const HISTORY_LIMIT = 200
const MAX_TEXT_LENGTH = 2000
const CLIENT_ID_PATTERN = /^[a-zA-Z0-9-]{8,64}$/

const users = new Map<WebSocket, User>()
const history: Record<Room, ChatMessage[]> = { general: [], random: [], devin: [] }

function send(socket: WebSocket, event: ServerEvent) {
  if (socket.readyState === socket.OPEN) socket.send(JSON.stringify(event))
}

function broadcast(event: ServerEvent, except?: WebSocket) {
  const payload = JSON.stringify(event)
  for (const socket of users.keys()) {
    if (socket !== except && socket.readyState === socket.OPEN) socket.send(payload)
  }
}

function onlineUsers(): User[] {
  return [...users.values()].sort((a, b) => a.name.localeCompare(b.name))
}

function storeMessage(message: ChatMessage) {
  const list = history[message.room]
  list.push(message)
  if (list.length > HISTORY_LIMIT) list.splice(0, list.length - HISTORY_LIMIT)
}

function findMessage(id: string): ChatMessage | undefined {
  for (const room of ROOMS) {
    const found = history[room].find((m) => m.id === id)
    if (found) return found
  }
  return undefined
}

function postSystemMessage(room: Room, text: string) {
  const message: ChatMessage = {
    id: randomUUID(),
    room,
    kind: 'system',
    userId: 'system',
    name: 'system',
    color: '#94a3b8',
    text,
    ts: Date.now(),
    reactions: {},
  }
  storeMessage(message)
  broadcast({ type: 'message', message })
}

function cleanText(value: unknown): string {
  return typeof value === 'string' ? value.trim().slice(0, MAX_TEXT_LENGTH) : ''
}

function handleJoin(socket: WebSocket, event: Extract<ClientEvent, { type: 'join' }>) {
  const name = cleanText(event.name).slice(0, 24)
  if (!name) return send(socket, { type: 'error', message: 'A display name is required.' })

  const color = (AVATAR_COLORS as readonly string[]).includes(event.color)
    ? event.color
    : AVATAR_COLORS[0]
  const requestedId =
    typeof event.id === 'string' && CLIENT_ID_PATTERN.test(event.id) ? event.id : null
  const idInUse = [...users.values()].some((u) => u.id === requestedId)
  const id = requestedId && !idInUse ? requestedId : randomUUID()
  const user: User = { id, name, color, room: 'general' }
  users.set(socket, user)

  send(socket, { type: 'welcome', selfId: user.id, users: onlineUsers(), history })
  broadcast({ type: 'presence', users: onlineUsers() })
  for (const room of ROOMS) postSystemMessage(room, `${name} joined the chat`)
}

function handleEvent(socket: WebSocket, event: ClientEvent) {
  if (event.type === 'join') return handleJoin(socket, event)

  const user = users.get(socket)
  if (!user) return send(socket, { type: 'error', message: 'Join before sending events.' })

  switch (event.type) {
    case 'switch_room': {
      if (!isRoom(event.room)) return
      broadcast({ type: 'typing', room: user.room, userId: user.id, name: user.name, isTyping: false })
      user.room = event.room
      broadcast({ type: 'presence', users: onlineUsers() })
      return
    }
    case 'message': {
      const text = cleanText(event.text)
      if (!isRoom(event.room) || !text) return
      const message: ChatMessage = {
        id: randomUUID(),
        room: event.room,
        kind: 'chat',
        userId: user.id,
        name: user.name,
        color: user.color,
        text,
        ts: Date.now(),
        reactions: {},
      }
      storeMessage(message)
      broadcast({ type: 'message', message })
      broadcast({ type: 'typing', room: event.room, userId: user.id, name: user.name, isTyping: false })
      return
    }
    case 'typing': {
      if (!isRoom(event.room)) return
      broadcast(
        { type: 'typing', room: event.room, userId: user.id, name: user.name, isTyping: Boolean(event.isTyping) },
        socket,
      )
      return
    }
    case 'react': {
      const message = findMessage(event.messageId)
      if (!message || message.kind !== 'chat') return
      if (!(REACTION_EMOJIS as readonly string[]).includes(event.emoji)) return
      const reactors = message.reactions[event.emoji] ?? []
      const next = reactors.includes(user.id)
        ? reactors.filter((id) => id !== user.id)
        : [...reactors, user.id]
      if (next.length) message.reactions[event.emoji] = next
      else delete message.reactions[event.emoji]
      broadcast({ type: 'message_updated', message })
      return
    }
    case 'edit': {
      const message = findMessage(event.messageId)
      const text = cleanText(event.text)
      if (!message || message.userId !== user.id || !text) return
      message.text = text
      message.editedAt = Date.now()
      broadcast({ type: 'message_updated', message })
      return
    }
    case 'delete': {
      const message = findMessage(event.messageId)
      if (!message || message.userId !== user.id) return
      const list = history[message.room]
      list.splice(list.indexOf(message), 1)
      broadcast({ type: 'message_deleted', room: message.room, messageId: message.id })
      return
    }
  }
}

function handleClose(socket: WebSocket) {
  const user = users.get(socket)
  if (!user) return
  users.delete(socket)
  broadcast({ type: 'typing', room: user.room, userId: user.id, name: user.name, isTyping: false })
  broadcast({ type: 'presence', users: onlineUsers() })
  for (const room of ROOMS) postSystemMessage(room, `${user.name} left the chat`)
}

const httpServer = createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'content-type': 'application/json' })
    res.end(JSON.stringify({ ok: true, online: users.size }))
    return
  }
  res.writeHead(404)
  res.end()
})

const wss = new WebSocketServer({ server: httpServer, path: '/ws' })

wss.on('connection', (socket) => {
  socket.on('message', (raw) => {
    let event: ClientEvent
    try {
      event = JSON.parse(raw.toString()) as ClientEvent
    } catch {
      return send(socket, { type: 'error', message: 'Malformed event.' })
    }
    handleEvent(socket, event)
  })
  socket.on('close', () => handleClose(socket))
  socket.on('error', () => socket.terminate())
})

httpServer.listen(PORT, HOST, () => {
  console.log(`[chat-server] listening on ws://${HOST}:${PORT}/ws`)
})

for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.on(signal, () => {
    wss.close()
    httpServer.close(() => process.exit(0))
  })
}
