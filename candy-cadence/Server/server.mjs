import { createServer } from "node:http";
import { readFileSync } from "node:fs";
import { randomBytes, randomUUID } from "node:crypto";
import { pathToFileURL } from "node:url";
import { WebSocketServer, WebSocket } from "ws";
import { advance, input, resetPlayer, snapshotPlayer } from "./engine.mjs";

const songs = JSON.parse(readFileSync(new URL("../Resources/songs.json", import.meta.url)));
const cleanName = value => String(value ?? "Guest").replace(/[^\p{L}\p{N} _-]/gu, "").trim().slice(0, 16) || "Guest";

export function createGameServer({ port = 0, host = "127.0.0.1", clock = Date.now, log = () => {} } = {}) {
  const rooms = new Map();
  const http = createServer((request, response) => {
    if (request.url !== "/health") {
      response.writeHead(404).end();
      return;
    }
    response.writeHead(200, { "Content-Type": "application/json" });
    response.end(JSON.stringify({ ok: true, service: "Candy Cadence", rooms: rooms.size }));
  });
  const wss = new WebSocketServer({ server: http, maxPayload: 4096 });
  const send = (ws, value) => {
    if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(value));
  };
  const state = room => ({
    type: "state", room: room.code, phase: room.phase, songID: room.songID,
    startAt: room.startAt, serverTime: clock(), match: room.match,
    hostID: room.players[0].id, players: room.players.map(snapshotPlayer),
  });
  const broadcast = room => room.players.forEach(player => send(player.socket, state(room)));
  const fail = (socket, error) => send(socket, { type: "error", error });
  wss.on("connection", socket => {
    let room;
    let player;
    let bucket = 0;
    let bucketAt = clock();
    socket.on("message", raw => {
      if (clock() - bucketAt >= 1000) { bucket = 0; bucketAt = clock(); }
      if (++bucket > 90) return fail(socket, "Too many messages");
      let message;
      try { message = JSON.parse(raw); } catch { return fail(socket, "Invalid JSON"); }
      if (!message || typeof message !== "object") return fail(socket, "Invalid message");
      if (message.type === "ping") return send(socket, { type: "pong", sent: message.sent, serverTime: clock() });
      if (message.type === "hello") {
        if (player) return fail(socket, "Already in a room");
        const code = String(message.room ?? "").trim().toUpperCase();
        if (message.create) {
          if (rooms.size >= 100) return fail(socket, "Room limit reached");
          let newCode;
          do { newCode = randomBytes(3).toString("hex").toUpperCase(); } while (rooms.has(newCode));
          room = { code: newCode, players: [], phase: "lobby", songID: songs[0].id, startAt: 0, match: 0, lastActive: clock() };
          rooms.set(newCode, room);
        } else {
          room = rooms.get(code);
          if (!room) return fail(socket, "Room not found. Check the six-character code.");
        }
        const existing = room.players.find(peer => peer.id === message.playerID);
        if (existing) {
          if (existing.token !== message.token) return fail(socket, "Invalid reconnect token");
          if (existing.connected) return fail(socket, "Player is already connected");
          player = existing;
          player.socket = socket;
          player.connected = true;
        } else {
          if (room.players.length >= 2) return fail(socket, "This room already has two players");
          if (room.phase !== "lobby") return fail(socket, "Wait for the next match");
          player = {
            id: randomUUID(), token: randomUUID(), name: cleanName(message.name),
            socket, connected: true, automated: message.automated === true,
          };
          resetPlayer(player);
          room.players.push(player);
        }
        room.lastActive = clock();
        send(socket, { type: "welcome", playerID: player.id, token: player.token, room: room.code });
        log({ event: "joined", room: room.code, id: player.id, name: player.name, automated: player.automated });
        broadcast(room);
        return;
      }
      if (!room || !player) return fail(socket, "Join a room first");
      if (message.type === "select") {
        if (room.phase !== "lobby" || player !== room.players[0]) return fail(socket, "Only the host selects in the lobby");
        if (!songs.some(song => song.id === message.songID)) return fail(socket, "Unknown song");
        room.songID = message.songID;
        room.players.forEach(peer => { peer.ready = false; });
      } else if (message.type === "ready") {
        if (room.phase !== "lobby") return;
        player.ready = !player.ready;
        if (room.players.length === 2 && room.players.every(peer => peer.ready && peer.connected)) {
          room.phase = "playing";
          room.startAt = clock() + 4000;
          room.match++;
          log({ event: "start", room: room.code, song: room.songID, startAt: room.startAt, match: room.match });
        }
      } else if (message.type === "hit") {
        if (room.phase !== "playing") return;
        const timestamp = message.time;
        if (!Number.isFinite(timestamp) || Math.abs(timestamp - clock()) > 220) return;
        const song = songs.find(item => item.id === room.songID);
        if (input(player, song, timestamp - room.startAt, message.lane, message.sequence)) {
          log({ event: "hit", room: room.code, match: room.match, id: player.id, lane: message.lane,
            verdict: player.verdict, score: Math.round(player.score), time: timestamp });
        }
      } else if (message.type === "rematch") {
        if (room.phase !== "results") return;
        room.phase = "lobby";
        room.startAt = 0;
        room.players.forEach(resetPlayer);
        log({ event: "rematch", room: room.code, match: room.match });
      } else {
        return fail(socket, "Unknown command");
      }
      broadcast(room);
    });
    socket.on("close", () => {
      if (!player) return;
      player.connected = false;
      player.ready = false;
      room.lastActive = clock();
      log({ event: "disconnected", room: room.code, id: player.id });
      broadcast(room);
    });
    socket.on("error", () => {});
  });
  const timer = setInterval(() => {
    for (const [code, room] of rooms) {
      if (room.players.every(player => !player.connected) && clock() - room.lastActive > 120_000) {
        rooms.delete(code);
        continue;
      }
      if (room.phase === "playing") {
        const song = songs.find(item => item.id === room.songID);
        room.players.forEach(player => advance(player, song, clock() - room.startAt));
        if (clock() > room.startAt + song.duration) {
          room.phase = "results";
          log({ event: "results", ...state(room) });
        }
        broadcast(room);
      }
    }
  }, 50);
  return {
    http, rooms,
    listen: () => new Promise(resolve => http.listen(port, host, () => resolve(http.address().port))),
    close: () => new Promise(resolve => {
      clearInterval(timer);
      wss.clients.forEach(client => client.terminate());
      wss.close(() => http.close(resolve));
    }),
  };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const server = createGameServer({
    port: Number(process.env.PORT || 8789), host: process.env.HOST || "0.0.0.0",
    log: value => console.log(JSON.stringify({ recordedAt: Date.now(), ...value })),
  });
  const port = await server.listen();
  console.log(JSON.stringify({ event: "listening", port }));
}
