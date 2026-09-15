export const DT = 1 / 30;
export const LAPS = 2;
export const WIDTH = 9;
export const COUNT = 240;
const TAU = Math.PI * 2;
const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
export const angle = x => Math.atan2(Math.sin(x), Math.cos(x));

export function trackPoint(track, index) {
  const t = index / COUNT * TAU;
  const r = track === 1 ? 61 + 12 * Math.sin(3 * t) : 68 + 8 * Math.sin(3 * t);
  return { x: Math.sin(t) * r * 1.14, z: Math.cos(t) * r };
}

export function tangent(track, index) {
  const a = trackPoint(track, index), b = trackPoint(track, index + 0.2);
  return Math.atan2(b.x - a.x, b.z - a.z);
}

export function nearest(track, x, z) {
  let best = 0, distance = Infinity;
  for (let i = 0; i < COUNT; i++) {
    const p = trackPoint(track, i), d = Math.hypot(x - p.x, z - p.z);
    if (d < distance) { best = i; distance = d; }
  }
  return { index: best, distance };
}

export function createPlayer(id, name, racer, token) {
  return {
    id, name, racer, token, connected: true, ready: false, x: 0, z: 0,
    heading: 0, speed: 0, index: 0, progress: 0, gate: 1, lap: 1,
    finish: 0, rank: 1, item: "", roulette: 0, boost: 0, stun: 0, shield: 0,
    charge: 0, drifting: false, seq: -1, lastInput: 0,
    input: { steer: 0, throttle: 0, brake: false, drift: false },
    pickups: 0, shots: 0, hits: 0, drifts: 0, distance: 0, disconnectAt: 0,
    nextItem: 0, lastBox: -100
  };
}

export function resetRace(room, now) {
  room.phase = "countdown"; room.startAt = now + 3500; room.finishAt = 0;
  room.race++; room.events = []; room.hazards = [];
  [...room.players.values()].forEach((p, n) => {
    const at = trackPoint(room.track, 0), h = tangent(room.track, 0);
    Object.assign(p, {
      x: at.x + Math.cos(h) * (n === 0 ? -2.8 : 2.8), z: at.z - Math.sin(h) * (n === 0 ? -2.8 : 2.8),
      heading: h, speed: 0, index: 0, progress: 0, gate: 1, lap: 1, finish: 0,
      item: "", roulette: 0, boost: 0, stun: 0, shield: 0, charge: 0, drifting: false,
      pickups: 0, shots: 0, hits: 0, drifts: 0, distance: 0, nextItem: 0, lastBox: -100,
      input: { steer: 0, throttle: 0, brake: false, drift: false }
    });
  });
}

function event(room, kind, player, extra = {}) {
  room.eventID++;
  room.events.push({ id: room.eventID, kind, player: player.id, ...extra });
  room.events = room.events.slice(-16);
}

export function inputPlayer(p, msg, now) {
  if (!Number.isSafeInteger(msg.seq) || msg.seq <= p.seq) return false;
  if (!Number.isFinite(msg.steer) || !Number.isFinite(msg.throttle)) return false;
  p.seq = msg.seq; p.lastInput = now;
  p.input = {
    steer: clamp(msg.steer, -1, 1), throttle: clamp(msg.throttle, 0, 1),
    brake: msg.brake === true, drift: msg.drift === true
  };
  return true;
}

export function useItem(room, p) {
  if (room.phase !== "racing" || p.finish || !p.item || p.roulette > 0) return;
  const item = p.item;
  p.item = ""; p.shots++;
  event(room, "item", p, { item });
  if (item === "comet") p.boost = 2.3;
  if (item === "bubble") p.shield = 5;
  if (item === "gum") room.hazards.push({ x: p.x - Math.sin(p.heading) * 5, z: p.z - Math.cos(p.heading) * 5, owner: p.id, ttl: 18 });
  if (item === "zap") {
    const targets = [...room.players.values()].filter(other => other.id !== p.id && other.connected && !other.finish);
    targets.sort((a, b) => Math.hypot(a.x - p.x, a.z - p.z) - Math.hypot(b.x - p.x, b.z - p.z));
    const target = targets[0];
    if (target && Math.hypot(target.x - p.x, target.z - p.z) < 110) {
      if (target.shield > 0) target.shield = 0;
      else { target.stun = 1.3; target.speed *= 0.4; p.hits++; }
      event(room, "zap", p, { target: target.id });
    }
  }
}

export function tick(room, now, dt = DT) {
  if (room.phase === "countdown" && now >= room.startAt) room.phase = "racing";
  if (room.phase !== "racing") return;
  for (const p of room.players.values()) {
    if (!p.connected || p.finish) continue;
    const input = now - p.lastInput < 600 ? p.input : { steer: 0, throttle: 0, brake: true, drift: false };
    for (const timer of ["boost", "stun", "shield", "roulette"]) p[timer] = Math.max(0, p[timer] - dt);
    const drifting = input.drift && Math.abs(input.steer) > 0.12 && p.speed > 10 && p.stun === 0;
    if (drifting) p.charge = Math.min(2.3, p.charge + dt);
    if (p.drifting && !drifting) {
      if (p.charge > 0.65) { p.boost = p.charge > 1.5 ? 1.9 : 1; p.drifts++; event(room, "drift", p); }
      p.charge = 0;
    }
    p.drifting = drifting;
    const near = nearest(room.track, p.x, p.z);
    const offroad = near.distance > WIDTH;
    const maxSpeed = p.stun > 0 ? 11 : offroad ? 15 : p.boost > 0 ? 53 : 37;
    p.speed = clamp(p.speed + (input.throttle * 23 - 5 - (input.brake ? 45 : 0)) * dt, 0, maxSpeed);
    const turning = (drifting ? 1.85 : 1.55) * Math.min(1, p.speed / 8);
    p.heading = angle(p.heading + input.steer * turning * dt);
    const dx = Math.sin(p.heading) * p.speed * dt, dz = Math.cos(p.heading) * p.speed * dt;
    p.x += dx; p.z += dz; p.distance += Math.hypot(dx, dz);
    const n = nearest(room.track, p.x, p.z);
    if (n.distance > WIDTH + 6) {
      const center = trackPoint(room.track, n.index);
      const scale = (WIDTH + 5.5) / n.distance;
      p.x = center.x + (p.x - center.x) * scale; p.z = center.z + (p.z - center.z) * scale;
      p.speed *= 0.94;
    }
    let delta = n.index - p.index;
    if (delta < -COUNT / 2) delta += COUNT;
    if (delta > COUNT / 2) delta -= COUNT;
    if (Math.abs(delta) <= 8 && n.distance < WIDTH + 4) {
      p.progress = Math.max(0, p.progress + delta);
      const crossed = Math.floor(p.progress / 30);
      while (p.gate <= crossed && p.gate <= LAPS * 8) {
        event(room, "checkpoint", p, { gate: p.gate });
        p.gate++;
      }
      p.lap = Math.min(LAPS, Math.floor(p.progress / COUNT) + 1);
      if (p.progress >= COUNT * LAPS && p.gate > LAPS * 8) {
        p.finish = now - room.startAt;
        p.speed = 0;
        event(room, "finish", p, { time: p.finish });
        if (!room.finishAt) room.finishAt = now;
      }
    }
    p.index = n.index;
    const box = [24, 84, 144, 204].find(i => Math.abs(n.index - i) <= 2);
    if (box !== undefined && !p.item && now > p.nextItem && n.distance < WIDTH - 1 && p.lastBox !== p.lap * COUNT + box) {
      p.item = ["zap", "comet", "gum", "bubble"][(p.pickups + (room.race - 1)) % 4];
      p.roulette = 1.1; p.pickups++; p.nextItem = now + 2800; p.lastBox = p.lap * COUNT + box;
      event(room, "pickup", p, { item: p.item });
    }
    for (const hazard of room.hazards) {
      if (hazard.owner !== p.id && hazard.ttl > 0 && Math.hypot(p.x - hazard.x, p.z - hazard.z) < 3) {
        if (p.shield > 0) p.shield = 0;
        else { p.stun = 1.2; p.speed *= 0.35; }
        hazard.ttl = 0; event(room, "gumHit", p);
      }
    }
  }
  const players = [...room.players.values()];
  if (players.length === 2 && players.every(p => !p.finish && p.connected)) {
    const [a, b] = players, dist = Math.hypot(a.x - b.x, a.z - b.z);
    if (dist < 2.8 && dist > 0.001) {
      const push = (2.8 - dist) / 2, x = (a.x - b.x) / dist, z = (a.z - b.z) / dist;
      a.x += x * push; a.z += z * push; b.x -= x * push; b.z -= z * push;
    }
  }
  room.hazards.forEach(h => { h.ttl -= dt; });
  room.hazards = room.hazards.filter(h => h.ttl > 0);
  players.sort((a, b) => a.finish && b.finish ? a.finish - b.finish : a.finish ? -1 : b.finish ? 1 : b.progress - a.progress);
  players.forEach((p, n) => { p.rank = n + 1; });
  if (players.every(p => p.finish || !p.connected) || (room.finishAt && now - room.finishAt > 20000) || now - room.startAt > 180000) {
    room.phase = "results"; event(room, "results", players[0]);
  }
}

export function snapshot(room, now) {
  return {
    type: "state", code: room.code, phase: room.phase, track: room.track, race: room.race,
    now, startAt: room.startAt, laps: LAPS, events: room.events, hazards: room.hazards,
    players: [...room.players.values()].map(({ token, input, lastInput, disconnectAt, nextItem, lastBox, ...p }) => p)
  };
}

export function driver(track, p, now) {
  const target = trackPoint(track, p.index + 9);
  const error = angle(Math.atan2(target.x - p.x, target.z - p.z) - p.heading);
  return {
    steer: clamp(error * 2.7, -1, 1), throttle: 1, brake: false,
    drift: Math.abs(error) > 0.12 && Math.floor(now / 1400) % 3 !== 0
  };
}
