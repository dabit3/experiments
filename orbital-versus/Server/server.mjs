import http from "node:http";
import { randomBytes, randomUUID } from "node:crypto";
import { pathToFileURL } from "node:url";
import { performance } from "node:perf_hooks";
import { WebSocketServer, WebSocket } from "ws";
import { Arena } from "./game.mjs";

export function createServer({ port = 8787, host = "0.0.0.0", duration = 90 } = {}) {
  const rooms = new Map();
  const peers = new Map();
  const server = http.createServer((request, response) => {
    response.setHeader("Content-Type", "application/json");
    if (request.url === "/health") response.end(JSON.stringify({ ok: true, rooms: rooms.size, game: "Orbital Versus" }));
    else { response.statusCode = 404; response.end('{"error":"Not found"}'); }
  });
  const wss = new WebSocketServer({ server, maxPayload: 4096 });
  const send = (socket, payload) => {
    if (socket.readyState === WebSocket.OPEN && socket.bufferedAmount < 256000) socket.send(JSON.stringify(payload));
  };
  wss.on("connection", socket => {
    let peer;
    let messages = 0;
    const limiter = setInterval(() => { messages = 0; }, 1000);
    socket.on("message", raw => {
      if (++messages > 90) return socket.close(1008, "Input rate exceeded");
      try {
        const msg = JSON.parse(raw.toString());
        if (!msg || typeof msg !== "object") return;
        if (msg.type === "join" && !peer) {
          const name = String(msg.name || "Pilot").trim().slice(0, 16) || "Pilot";
          const code = String(msg.code || "").trim().toUpperCase();
          if (msg.token && peers.has(msg.token)) {
            const existing = peers.get(msg.token);
            if (existing.room.code !== code) throw new Error("Rejoin room does not match");
            if (existing.socket?.readyState === WebSocket.OPEN) throw new Error("Pilot is already connected");
            peer = existing; peer.socket = socket; peer.disconnected = 0;
            const unit = peer.room.units.find(unit => unit.id === peer.id);
            unit.connected = true; unit.seq = -1;
          } else {
            if (code && !/^[A-Z0-9]{4,8}$/.test(code)) throw new Error("Use a 4–8 character room code");
            let room = rooms.get(code);
            if (!room) {
              if (rooms.size >= 100) throw new Error("Server room limit reached");
              const newCode = code || randomBytes(3).toString("hex").toUpperCase();
              room = new Arena(newCode, duration); rooms.set(newCode, room);
            }
            if (room.phase !== "lobby") throw new Error("Match already started");
            const id = randomUUID();
            room.add(id, name);
            peer = { id, token: randomBytes(24).toString("hex"), room, socket, disconnected: 0 };
            peers.set(peer.token, peer);
          }
          send(socket, { type: "welcome", id: peer.id, token: peer.token, code: peer.room.code });
          console.log(JSON.stringify({ event: "join", id: peer.id, name, room: peer.room.code }));
        } else if (peer) {
          if (msg.type === "input") peer.room.input(peer.id, msg);
          if (msg.type === "ready") peer.room.vote(peer.id);
          if (msg.type === "rematch") peer.room.vote(peer.id, true);
          if (msg.type === "ping") send(socket, { type: "pong", sent: msg.sent });
        }
      } catch (error) { send(socket, { type: "error", message: error.message }); }
    });
    socket.on("close", () => {
      clearInterval(limiter);
      if (peer && peer.socket === socket) {
        peer.room.disconnect(peer.id); peer.disconnected = Date.now();
      }
    });
    socket.on("error", () => {});
  });
  let lastClock = performance.now();
  let accumulated = 0;
  const clock = setInterval(() => {
    const now = performance.now();
    accumulated += Math.min(250, now - lastClock);
    lastClock = now;
    const steps = Math.floor(accumulated / (1000 / 30));
    accumulated -= steps * (1000 / 30);
    for (const room of rooms.values()) {
      for (let index = 0; index < steps; index++) {
        const before = room.phase;
        room.step();
        if (before !== room.phase) console.log(JSON.stringify({ event: "phase", room: room.code, ...room.snapshot() }));
      }
      if (steps > 0 && (room.tick % 2 === 0 || steps > 1)) {
        const snapshot = room.snapshot();
        for (const peer of peers.values()) if (peer.room === room) send(peer.socket, snapshot);
      }
    }
    for (const [token, peer] of peers) {
      if (peer.disconnected && Date.now() - peer.disconnected > 60000) {
        const room = peer.room;
        if (room.phase === "playing" || room.phase === "countdown") {
          const unit = room.units.find(unit => unit.id === peer.id);
          room.finish(1 - unit.team, "OPPONENT DISCONNECTED");
        }
        const connected = [...peers.values()].some(other => other.room === room && !other.disconnected);
        if (!connected) {
          rooms.delete(room.code);
          for (const [key, value] of peers) if (value.room === room) peers.delete(key);
        } else if (room.phase === "lobby") {
          // Rebuild an abandoned lobby instead of leaving an occupied ghost seat.
          for (const other of peers.values()) if (other.room === room) other.socket.close(1001, "Lobby expired; create a new room");
          rooms.delete(room.code);
          for (const [key, value] of peers) if (value.room === room) peers.delete(key);
        } else peers.delete(token);
      }
    }
  }, 1000 / 30);
  server.listen(port, host);
  return { server, rooms, close: async () => {
    clearInterval(clock);
    for (const socket of wss.clients) socket.terminate();
    await new Promise(resolve => wss.close(resolve));
    await new Promise(resolve => server.close(resolve));
  } };
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  createServer({ port: Number(process.env.PORT || 8787) });
  console.log("Orbital Versus authoritative server on :8787");
}
