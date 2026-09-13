// Passive observer for a test-owned, otherwise unchanged real WebSocket server.
// No client is constructed here and no game message is injected.
import fs from 'node:fs';
import path from 'node:path';
import { WebSocket } from '../server/node_modules/ws/wrapper.mjs';
import { startServer } from '../server/server.mjs';

const output = process.argv[2];
const port = Number(process.argv[3] || 43116);
if (!output || !fs.statSync(output).isDirectory()) throw new Error('Output directory required');
const trace = fs.createWriteStream(path.join(output, 'wire.jsonl'), { flags: 'wx' });
const events = fs.createWriteStream(path.join(output, 'server.jsonl'), { flags: 'wx' });
const ids = new WeakMap();
let serial = 0;
function save(direction, socket, data) {
  const message = JSON.parse(data.toString());
  if (['ping', 'pong'].includes(message.type)) return;
  delete message.token;
  if (!ids.has(socket)) ids.set(socket, ++serial);
  trace.write(JSON.stringify({
    at: Date.now() / 1000, direction, socket: ids.get(socket), message,
  }) + '\n');
}
const send = WebSocket.prototype.send;
WebSocket.prototype.send = function(data, ...args) {
  save('server-to-client', this, data);
  return send.call(this, data, ...args);
};
const emit = WebSocket.prototype.emit;
WebSocket.prototype.emit = function(event, ...args) {
  if (event === 'message') save('client-to-server', this, args[0]);
  return emit.call(this, event, ...args);
};
const app = startServer({
  port,
  logger: line => { events.write(line + '\n'); console.log(line); },
});
process.on('SIGTERM', async () => {
  await app.close();
  trace.end();
  events.end();
});
