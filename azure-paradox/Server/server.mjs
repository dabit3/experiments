import http from "node:http";
import crypto from "node:crypto";
import { pathToFileURL } from "node:url";
import { WebSocketServer, WebSocket } from "ws";
import { room, fighter, step, snapshot, acceptInput, startRound, event } from "./combat.mjs";

export function createServer({ port = 8787, host = "0.0.0.0", logging = true } = {}) {
  const rooms = new Map();
  const bindings = new Map();
  const resumes = new Map();
  const log = data => { if (logging) console.log(JSON.stringify({ time: new Date().toISOString(), ...data })); };
  const server = http.createServer((req, res) => {
    res.setHeader("Content-Type", "application/json");
    if (req.url === "/health") res.end(JSON.stringify({ game: "Azure Paradox", rooms: rooms.size, protocol: 1 }));
    else { res.statusCode = 404; res.end('{"error":"not found"}'); }
  });
  const wss = new WebSocketServer({ server, maxPayload: 4096 });
  const send = (ws, value) => {
    if (ws.readyState === WebSocket.OPEN && ws.bufferedAmount < 128 * 1024) ws.send(JSON.stringify(value));
  };
  wss.on("connection", ws => {
    let budget = 0;
    const rate = setInterval(() => { budget = 0; }, 1000);
    ws.on("error", error => log({ type: "socket-error", message: error.message }));
    ws.on("message", data => {
      if (++budget > 120) { ws.close(1008, "rate limit"); return; }
      let msg;
      try { msg = JSON.parse(data.toString()); } catch { send(ws, { type: "error", message: "Invalid JSON" }); return; }
      if (!msg || typeof msg !== "object" || Array.isArray(msg)) return;
      let binding = bindings.get(ws);
      if (msg.type === "join" && !binding) {
        if (msg.version !== 1) { send(ws, { type: "error", message: "Protocol version 1 required" }); return; }
        const code = typeof msg.room === "string" ? msg.room.trim().toUpperCase() : "";
        if (!/^[A-Z0-9]{4,8}$/.test(code)) { send(ws, { type: "error", message: "Use a 4–8 letter/number room code" }); return; }
        let r = rooms.get(code);
        if (!r && msg.create === true && rooms.size < 64) { r = room(code); rooms.set(code, r); }
        if (!r) { send(ws, { type: "error", message: "Room not found. Host a room first." }); return; }
        let p;
        const resume = typeof msg.token === "string" ? resumes.get(msg.token) : null;
        if (resume && resume.code === code) {
          p = r.players.find(candidate => candidate.id === resume.id);
          if (p?.connected) { send(ws, { type: "error", message: "That guest is already connected" }); return; }
        }
        if (!p) {
          if (r.players.length >= 2) { send(ws, { type: "error", message: "This duel already has two players" }); return; }
          const name = typeof msg.name === "string" ? msg.name.trim().slice(0, 16) : "";
          if (!name) { send(ws, { type: "error", message: "Enter a guest name" }); return; }
          p = fighter(crypto.randomUUID(), name, msg.character === "lyra" ? "lyra" : "seraph", r.players.length);
          r.players.push(p);
        }
        const token = resume ? msg.token : crypto.randomBytes(24).toString("hex");
        resumes.set(token, { code, id: p.id });
        p.connected = true;
        p.lastSeq = -1;
        p.input = { axis: 0, guard: false };
        p.actions = [];
        binding = { r, p };
        bindings.set(ws, binding);
        event(r, "join", `${p.name} CONNECTED`, p);
        send(ws, { type: "welcome", id: p.id, token, room: code, slot: p.slot });
        log({ type: resume ? "rejoin" : "join", room: code, id: p.id, name: p.name, character: p.character });
      } else if (binding) {
        const { r, p } = binding;
        if (msg.type === "input") {
          if (acceptInput(r, p, msg) && msg.action) log({ type: "input", room: r.code, id: p.id, seq: msg.seq, action: msg.action, tick: r.tick });
        } else if (msg.type === "select" && r.phase === "lobby" && ["seraph", "lyra"].includes(msg.character)) {
          p.character = msg.character;
          p.ready = false;
        } else if (msg.type === "ready" && r.phase === "lobby") {
          p.ready = msg.ready === true;
          if (r.players.length === 2 && r.players.every(peer => peer.ready && peer.connected)) startRound(r);
        } else if (msg.type === "rematch" && r.phase === "result") {
          p.rematch = true;
          if (r.players.every(peer => peer.rematch && peer.connected)) {
            r.players.forEach(peer => { peer.wins = 0; peer.rematch = false; });
            r.round = 1;
            r.match++;
            r.winner = "";
            startRound(r);
          }
        } else if (msg.type === "ping") send(ws, { type: "pong", timestamp: msg.timestamp });
      }
    });
    ws.on("close", () => {
      clearInterval(rate);
      const binding = bindings.get(ws);
      if (binding) {
        binding.p.connected = false;
        binding.p.input = { axis: 0, guard: false };
        binding.p.actions = [];
        binding.p.ready = false;
        event(binding.r, "disconnect", "PEER LOST · REJOIN WITHIN 30s", binding.p);
        log({ type: "disconnect", room: binding.r.code, id: binding.p.id });
        bindings.delete(ws);
      }
    });
  });
  let frame = 0;
  const interval = setInterval(() => {
    for (const r of rooms.values()) {
      const before = r.eventID;
      step(r);
      for (const e of r.events.filter(e => e.id > before)) {
        if (["hit", "result", "roundEnd", "start", "super"].includes(e.kind)) log({ type: e.kind, room: r.code, ...e });
      }
      if (r.players.every(p => !p.connected)) {
        r.emptyTicks = (r.emptyTicks ?? 0) + 1;
        if (r.emptyTicks > 60 * 120) {
          rooms.delete(r.code);
          for (const [token, resume] of resumes) if (resume.code === r.code) resumes.delete(token);
        }
      } else r.emptyTicks = 0;
    }
    if (++frame % 2 === 0)
      for (const [ws, { r }] of bindings) send(ws, snapshot(r));
  }, 1000 / 60);
  server.listen(port, host, () => log({ type: "listening", port: server.address().port }));
  return { server, rooms, close: async () => {
    clearInterval(interval);
    for (const ws of wss.clients) ws.terminate();
    await new Promise(resolve => wss.close(resolve));
    await new Promise(resolve => server.close(resolve));
  } };
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  createServer({ port: Number(process.env.PORT ?? 8787) });
}
