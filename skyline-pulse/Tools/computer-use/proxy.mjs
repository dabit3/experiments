// Passive forwarding only: never creates gameplay inputs.
import { createRequire } from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
const require = createRequire(path.resolve(process.argv[2], 'Server/package.json'));
const {WebSocketServer, WebSocket} = require('ws');
const out = fs.createWriteStream(process.argv[3]);
let counter = 0;
function log(peer, direction, raw) {
  let message; try { message = JSON.parse(raw.toString()); } catch { return; }
  if(message.token) message.token = '[redacted]';
  out.write(JSON.stringify({at:Date.now(),peer,direction,message})+'\n');
}
new WebSocketServer({port:8770,host:'127.0.0.1'}).on('connection', client => {
  const peer=++counter, upstream=new WebSocket('ws://127.0.0.1:8769'), pending=[];
  client.on('message',raw=>{
    log(peer,'client',raw);
    if(upstream.readyState===WebSocket.OPEN) upstream.send(raw.toString());
    else pending.push(raw.toString());
  });
  upstream.on('open',()=>pending.forEach(raw=>upstream.send(raw)));
  upstream.on('message',raw=>{
    log(peer,'server',raw);
    if(client.readyState===WebSocket.OPEN)client.send(raw.toString());
  });
  client.on('close',()=>upstream.close());
  upstream.on('close',()=>client.close());
  upstream.on('error',()=>client.close());
});
console.log('Passive evidence forwarding 8770 -> 8769');
