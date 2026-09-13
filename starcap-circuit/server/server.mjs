import http from "node:http";
import { randomUUID } from "node:crypto";
import { WebSocketServer, WebSocket } from "ws";
import { createPlayer, inputPlayer, resetRace, snapshot, tick, useItem } from "./game.mjs";

export function startServer(port = Number(process.env.PORT || 8791)) {
  const rooms = new Map();
  const server = http.createServer((req, res) => {
    if (req.url === "/health") {
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ game: "Starcap Circuit", rooms: rooms.size, ok: true }));
    } else if (req.method === "GET" && /^\/rooms\/[A-Z0-9]{4,8}$/.test(req.url)) {
      const room = rooms.get(req.url.split("/")[2]);
      res.writeHead(room ? 200 : 404, { "Content-Type": "application/json" });
      res.end(JSON.stringify(room ? snapshot(room, Date.now()) : { error: "Room not found" }));
    } else { res.writeHead(404); res.end(); }
  });
  const wss = new WebSocketServer({ server, maxPayload: 2048 });
  const log = (kind, data) => console.log(JSON.stringify({ at: Date.now(), kind, ...data }));
  const send = (ws, value) => { if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(value)); };
  wss.on("connection", ws => {
    let joined, player, count = 0, windowAt = Date.now();
    ws.on("message", raw => {
      const now = Date.now();
      if (now - windowAt > 1000) { count = 0; windowAt = now; }
      if (++count > 90) return ws.close(1008, "Rate limit");
      let msg;
      try { msg = JSON.parse(raw.toString()); } catch { return send(ws, { type: "error", message: "Invalid JSON" }); }
      if (!msg || typeof msg !== "object") return;
      if (msg.type === "join" && !joined) {
        const code = String(msg.code || "").trim().toUpperCase();
        if (!/^[A-Z0-9]{4,8}$/.test(code)) return send(ws, { type: "error", message: "Room code needs 4–8 letters or numbers." });
        if (!rooms.has(code)) {
          if (rooms.size >= 32) return send(ws, { type: "error", message: "Server full." });
          rooms.set(code, { code, phase: "lobby", track: msg.track === 1 ? 1 : 0, race: 0, players: new Map(), sockets: new Map(), startAt: 0, events: [], eventID: 0, hazards: [], emptyAt: 0 });
        }
        const room = rooms.get(code);
        let p = [...room.players.values()].find(p => p.token === msg.token && typeof msg.token === "string");
        if (!p && room.phase !== "lobby") return send(ws, { type: "error", message: "Race underway. Choose a different room." });
        if (!p && room.players.size >= 2) return send(ws, { type: "error", message: "Room full — two racers maximum." });
        if (!p) { p = createPlayer(randomUUID(), String(msg.name || "Guest").slice(0, 16), Math.max(0, Math.min(2, Math.floor(Number(msg.racer) || 0))), randomUUID()); room.players.set(p.id, p); }
        const old = room.sockets.get(p.id);
        if (old && old !== ws) old.close(4000, "Reconnected elsewhere");
        joined = room; player = p; p.connected = true; p.disconnectAt = 0; room.emptyAt = 0;
        room.sockets.set(p.id, ws);
        send(ws, { type: "welcome", id: p.id, token: p.token, code });
        send(ws, snapshot(room, now));
        log("join", { code, id: p.id, name: p.name, race: room.race });
      }
      if (!joined || !player || joined.sockets.get(player.id) !== ws) return;
      if (msg.type === "input") {
        if (inputPlayer(player, msg, now) && msg.use === true) useItem(joined, player);
      }
      if (msg.type === "ready" && joined.phase === "lobby") {
        player.ready = true;
        if (joined.players.size === 2 && [...joined.players.values()].every(p => p.ready && p.connected)) {
          resetRace(joined, now); log("start", { code: joined.code, race: joined.race, track: joined.track });
        }
      }
      if (msg.type === "rematch" && joined.phase === "results") {
        joined.phase = "lobby";
        joined.players.forEach(p => { p.ready = false; });
        joined.track = joined.track === 0 ? 1 : 0;
        log("rematch", { code: joined.code, track: joined.track });
      }
      if (msg.type === "ping") send(ws, { type: "pong", sent: msg.sent, now });
    });
    ws.on("error", () => {});
    ws.on("close", () => {
      if (joined && player && joined.sockets.get(player.id) === ws) {
        player.connected = false; player.ready = false; player.disconnectAt = Date.now();
        joined.sockets.delete(player.id);
        log("disconnect", { code: joined.code, id: player.id });
      }
    });
  });
  let frame = 0;
  const timer = setInterval(() => {
    const now = Date.now();
    for (const [code, room] of rooms) {
      const before = room.eventID;
      tick(room, now);
      for (const evt of room.events.filter(e => e.id > before)) log(evt.kind, { code, race: room.race, ...evt });
      if (room.phase === "lobby") {
        for (const [id, p] of room.players) if (!p.connected && now - p.disconnectAt > 30000) room.players.delete(id);
      }
      if (!room.sockets.size) {
        if (!room.emptyAt) room.emptyAt = now;
        if (now - room.emptyAt > 60000) { rooms.delete(code); continue; }
      }
      if (frame % 2 === 0) {
        const state = snapshot(room, now);
        room.sockets.forEach(ws => send(ws, state));
      }
    }
    frame++;
  }, 1000 / 30);
  server.listen(port, "0.0.0.0", () => log("listening", { port: server.address().port }));
  return { server, wss, rooms, close: async () => { clearInterval(timer); wss.clients.forEach(ws => ws.terminate()); await new Promise(resolve => wss.close(resolve)); await new Promise(resolve => server.close(resolve)); } };
}

if (process.argv[1]?.endsWith("server.mjs")) startServer();
