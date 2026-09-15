import assert from 'node:assert/strict';
import { once } from 'node:events';
import { createServer, connect } from 'node:net';
import { spawn } from 'node:child_process';
import { startServer } from '../server/server.mjs';

const service = startServer(0, '127.0.0.1');
await once(service.server, 'listening');
const port = service.server.address().port;
const sockets = new Set();
const proxy = createServer(front => {
  const back = connect(port, '127.0.0.1');
  sockets.add(front);
  sockets.add(back);
  front.pipe(back);
  back.on('data', data => setTimeout(() => {
    if (!front.destroyed) front.write(data);
  }, 300));
  back.on('end', () => setTimeout(() => front.end(), 300));
  front.on('error', () => back.destroy());
  back.on('error', () => front.destroy());
  front.on('close', () => { sockets.delete(front); back.destroy(); });
  back.on('close', () => { sockets.delete(back); });
});
proxy.listen(0, '127.0.0.1');
await once(proxy, 'listening');
try {
  const child = spawn(process.argv[2], [
    `ws://127.0.0.1:${proxy.address().port}`,
    `ws://127.0.0.1:${port}`,
    `http://127.0.0.1:${port}/health`
  ], { stdio: 'inherit', timeout: 20000 });
  const [code] = await once(child, 'exit');
  assert.equal(code, 0, 'Native connection regression suite failed');
  assert.equal(service.rooms.size, 1);
  assert.equal([...service.rooms.values()][0].fighters.length, 2);
} finally {
  for (const socket of sockets) socket.destroy();
  await new Promise(resolve => proxy.close(resolve));
  await service.close();
}
