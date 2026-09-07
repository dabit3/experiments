// Protocol smoke test: two clients talk through the Vite proxy (or the server directly).
// Usage: node scripts/smoke.mjs [ws://localhost:5173/ws]
import { WebSocket } from 'ws'

const url = process.argv[2] ?? 'ws://localhost:5173/ws'

function connect(name, color) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(url)
    const inbox = []
    const waiters = []
    ws.on('message', (raw) => {
      const event = JSON.parse(raw.toString())
      const idx = waiters.findIndex((w) => w.match(event))
      if (idx >= 0) waiters.splice(idx, 1)[0].resolve(event)
      else inbox.push(event)
    })
    ws.on('error', reject)
    ws.on('open', () => {
      ws.send(JSON.stringify({ type: 'join', name, color }))
      resolve({
        ws,
        send: (event) => ws.send(JSON.stringify(event)),
        next(match, label) {
          const buffered = inbox.findIndex(match)
          if (buffered >= 0) return Promise.resolve(inbox.splice(buffered, 1)[0])
          return new Promise((res, rej) => {
            const timer = setTimeout(() => rej(new Error(`timeout waiting for ${label}`)), 3000)
            waiters.push({ match, resolve: (e) => (clearTimeout(timer), res(e)) })
          })
        },
      })
    })
  })
}

function assert(cond, label) {
  if (!cond) throw new Error(`assertion failed: ${label}`)
  console.log(`ok - ${label}`)
}

const nader = await connect('Nader', '#f97316')
await nader.next((e) => e.type === 'welcome', 'nader welcome')
const devin = await connect('Devin', '#6366f1')
const welcome = await devin.next((e) => e.type === 'welcome', 'devin welcome')
const names = (users) => users.map((u) => u.name)
assert(names(welcome.users).includes('Nader') && names(welcome.users).includes('Devin'), 'both users online')
await nader.next((e) => e.type === 'presence' && names(e.users).includes('Devin'), 'nader sees presence')

nader.send({ type: 'typing', room: 'general', isTyping: true })
const typing = await devin.next((e) => e.type === 'typing' && e.isTyping, 'typing indicator')
assert(typing.name === 'Nader', 'devin sees Nader typing')

nader.send({ type: 'message', room: 'general', text: 'hello from Nader' })
const msg = await devin.next((e) => e.type === 'message' && e.message.kind === 'chat', 'chat message')
assert(msg.message.text === 'hello from Nader', 'devin receives message')

devin.send({ type: 'react', messageId: msg.message.id, emoji: '🎉' })
const reacted = await nader.next((e) => e.type === 'message_updated', 'reaction')
assert(reacted.message.reactions['🎉'].length === 1, 'nader sees reaction')

nader.send({ type: 'edit', messageId: msg.message.id, text: 'hello from Nader (edited)' })
const edited = await devin.next((e) => e.type === 'message_updated' && e.message.editedAt, 'edit')
assert(edited.message.text === 'hello from Nader (edited)', 'devin sees edit')

devin.send({ type: 'edit', messageId: msg.message.id, text: 'hijack' })
nader.send({ type: 'delete', messageId: msg.message.id })
const deleted = await devin.next((e) => e.type === 'message_deleted', 'delete')
assert(deleted.messageId === msg.message.id, 'devin sees delete (and could not edit foreign message)')

devin.send({ type: 'switch_room', room: 'random' })
devin.send({ type: 'message', room: 'random', text: 'random thoughts' })
const randomMsg = await nader.next((e) => e.type === 'message' && e.message.room === 'random' && e.message.kind === 'chat', 'random room message')
assert(randomMsg.message.text === 'random thoughts', 'nader receives #random message')

devin.ws.close()
const left = await nader.next((e) => e.type === 'message' && e.message.kind === 'system' && /left/.test(e.message.text), 'leave message')
assert(left.message.text === 'Devin left the chat', 'nader sees Devin left')
const presence = await nader.next((e) => e.type === 'presence' && !names(e.users).includes('Devin'), 'presence after leave')
assert(names(presence.users).includes('Nader'), 'online list updated')

nader.ws.close()
console.log('all good')
