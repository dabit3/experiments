// Test-only read-only observation. No game.input/ready/step/state assignments.
// The unchanged server owns its real WebSocket clients and its own tick loop.
import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';
import { createWriteStream } from 'node:fs';
const [repo, output, port = '8873'] = process.argv.slice(2);
if (!repo || !output) throw new Error('Usage: node observe-server.mjs REPO OUTPUT_JSONL [PORT]');
const { createServer } = await import(pathToFileURL(resolve(repo, 'Server/server.mjs')).href);
const stream = createWriteStream(output, { flags: 'wx' });
const service = createServer({ port: Number(port), host: '127.0.0.1', telemetry: true });
const observation = setInterval(() => {
  for (const game of service.rooms.values()) {
    stream.write(JSON.stringify({ wallUnix: Date.now() / 1000, state: game.snapshot() }) + '\n');
  }
}, 80);
console.log(JSON.stringify({ event: 'observerReady', port: Number(port), readOnly: true }));
let closing = false;
async function close() {
  if (closing) return;
  closing = true;
  clearInterval(observation);
  await service.close();
  stream.end(() => process.exit(0));
}
process.on('SIGINT', close);
process.on('SIGTERM', close);
