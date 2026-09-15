import http from "node:http";
import { randomBytes, randomUUID } from "node:crypto";
import { pathToFileURL } from "node:url";
import { WebSocketServer, WebSocket } from "ws";
import { fighter, match, ready, input, step, snapshot } from "./combat.mjs";

export function startServer(port = Number(process.env.PORT || 8787), host = process.env.HOST || "0.0.0.0") {
  const rooms = new Map();
  const httpServer = http.createServer((request, response) => {
    response.setHeader("Content-Type", "application/json");
    if (request.url === "/health") {
      response.end(JSON.stringify({ ok: true, game: "Hollow Afterdark", rooms: rooms.size }));
    } else if (request.url === "/rooms") {
      response.end(JSON.stringify([...rooms].map(([code, room]) => ({ code, ...snapshot(room.game) }))));
    } else { response.writeHead(404); response.end('{"error":"not found"}'); }
  });
  const wss = new WebSocketServer({ server: httpServer, maxPayload: 4096 });
  const send = (ws, data) => { if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(data)); };
  wss.on("connection", (ws) => {
    let binding = null;
    let alive = true;
    let count = 0;
    let countSince = Date.now();
    ws.on("pong", () => { alive = true; });
    const heartbeat = setInterval(() => {
      if (!alive) return ws.terminate();
      alive = false;
      ws.ping();
    }, 10000);
    ws.on("message", (raw) => {
      if (Date.now() - countSince > 1000) { count = 0; countSince = Date.now(); }
      if (++count > 150) { ws.close(1008, "rate limit"); return; }
      let packet;
      try { packet = JSON.parse(raw.toString()); } catch { send(ws, { type: "error", message: "Invalid JSON" }); return; }
      if (!packet || typeof packet !== "object") return;
      if (packet.type === "join" && !binding) {
        const code = typeof packet.room === "string" ? packet.room.toUpperCase().trim() : "";
        if (!/^[A-Z0-9]{4,8}$/.test(code)) {
          send(ws, { type: "error", message: "Room code needs 4–8 letters or numbers." }); return;
        }
        if (!rooms.has(code)) {
          if (rooms.size >= 16) { send(ws, { type: "error", message: "Server room limit reached." }); return; }
          rooms.set(code, { game: match(), peers: new Map(), idleSince: Date.now() });
        }
        const room = rooms.get(code);
        let peer = [...room.peers.values()].find((p) => p.token === packet.token && p.id === packet.id);
        if (!peer) {
          if (room.peers.size >= 2) { send(ws, { type: "error", message: "This room already has two duelists." }); return; }
          const id = randomUUID();
          const name = (typeof packet.name === "string" ? packet.name.trim() : "").slice(0, 16) || "Guest";
          peer = { id, token: randomBytes(24).toString("hex"), ws: null, disconnectedAt: 0 };
          room.peers.set(id, peer);
          room.game.players.push(fighter(id, name, room.game.players.length));
        } else if (peer.ws && peer.ws !== ws) peer.ws.close(1000, "rejoined");
        peer.ws = ws;
        peer.disconnectedAt = 0;
        room.game.players.find((p) => p.id === peer.id).connected = true;
        binding = { room, code, peer };
        send(ws, { type: "welcome", id: peer.id, token: peer.token, room: code, seq: room.game.players.find((p) => p.id === peer.id).lastSeq });
        console.log(JSON.stringify({ event: "join", code, id: peer.id, peers: room.peers.size }));
      } else if (binding) {
        const { room, peer } = binding;
        if (packet.type === "ready") ready(room.game, peer.id);
        if (packet.type === "input") input(room.game, peer.id, packet);
        if (packet.type === "ping") send(ws, { type: "pong", time: packet.time });
      }
    });
    ws.on("error", () => {});
    ws.on("close", () => {
      clearInterval(heartbeat);
      if (!binding || binding.peer.ws !== ws) return;
      binding.peer.ws = null;
      binding.peer.disconnectedAt = Date.now();
      binding.room.game.players.find((p) => p.id === binding.peer.id).connected = false;
      console.log(JSON.stringify({ event: "disconnect", code: binding.code, id: binding.peer.id }));
    });
  });
  const tick = setInterval(() => {
    for (const [code, room] of rooms) {
      step(room.game);
      if (room.game.tick % 2 === 0) {
        const state = { ...snapshot(room.game), room: code };
        for (const peer of room.peers.values()) if (peer.ws) send(peer.ws, state);
      }
      if (room.game.eventID !== room.loggedEventID) {
        for (const event of room.game.events.filter((e) => e.id > (room.loggedEventID || 0))) {
          console.log(JSON.stringify({ code, ...event }));
        }
        room.loggedEventID = room.game.eventID;
      }
      const disconnected = [...room.peers.values()].filter((p) => !p.ws);
      if (disconnected.length === room.peers.size && disconnected.every((p) => Date.now() - p.disconnectedAt > 60000)) {
        rooms.delete(code);
      } else if (disconnected.some((p) => Date.now() - p.disconnectedAt > 60000) && !["lobby", "result"].includes(room.game.phase)) {
        const winner = room.game.players.find((p) => p.connected);
        room.game.phase = "result";
        room.game.winner = winner?.id ?? "";
        room.game.message = "DISCONNECT / FORFEIT";
        for (const p of room.game.players) p.ready = false;
      }
    }
  }, 1000 / 60);
  httpServer.listen(port, host);
  return {
    httpServer, rooms,
    close: async () => {
      clearInterval(tick);
      for (const ws of wss.clients) ws.terminate();
      await new Promise((resolve) => wss.close(resolve));
      await new Promise((resolve) => httpServer.close(resolve));
    },
  };
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const instance = startServer();
  instance.httpServer.on("listening", () => console.log(`Hollow Afterdark listening on ${JSON.stringify(instance.httpServer.address())}`));
}
