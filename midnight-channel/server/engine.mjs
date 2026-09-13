export const RATE = 60;
const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v));
export const moves = {
  light: { startup: 5, active: 4, recovery: 12, reach: 122, damage: 64, stun: 17 },
  heavy: { startup: 13, active: 5, recovery: 21, reach: 165, damage: 108, stun: 26 },
  summon: { startup: 18, active: 9, recovery: 29, reach: 300, damage: 116, stun: 28 },
  super: { startup: 15, active: 14, recovery: 35, reach: 445, damage: 238, stun: 40 },
  burst: { startup: 0, active: 8, recovery: 17, reach: 200, damage: 24, stun: 32 }
};
export function fighter(id, name, slot) {
  return { id, name, slot, connected: true, ready: false, wins: 0, ...fresh(slot) };
}
function fresh(slot) {
  return { x: slot === 0 ? 295 : 705, y: 0, vy: 0, hp: 1000, meter: 0,
    cards: 4, breakTicks: 0, burst: 100, face: slot === 0 ? 1 : -1,
    move: '', frame: 0, hit: false, stun: 0, guard: false, axis: 0, companion: 0,
    combo: 0, awakened: false, invulnerable: 0, lastSeq: 0, queue: [], inputAge: 0 };
}
export function room(code) {
  return { code, tick: 0, phase: 'lobby', phaseTicks: 0, round: 1, time: 60,
    fighters: [], events: [], eventID: 0, winner: '', match: 1 };
}
export function event(r, kind, p, extra = {}) {
  r.events.push({ id: ++r.eventID, tick: r.tick, kind, player: p?.id ?? '', ...extra });
  r.events = r.events.slice(-18);
}
export function ready(r, p) {
  if (!['lobby', 'result'].includes(r.phase)) return;
  p.ready = true;
  if (r.fighters.length === 2 && r.fighters.every(f => f.ready && f.connected)) {
    if (r.phase === 'result') r.match++;
    r.round = 1;
    for (const f of r.fighters) f.wins = 0;
    resetRound(r);
  }
}
function resetRound(r) {
  for (const f of r.fighters) {
    const seq = f.lastSeq;
    Object.assign(f, fresh(f.slot));
    f.lastSeq = seq;
    f.ready = false;
  }
  r.time = 60;
  r.winner = '';
  r.phase = 'versus';
  r.phaseTicks = 180;
  event(r, 'round', null, { round: r.round });
}
export function input(r, p, msg) {
  if (!Number.isSafeInteger(msg.seq) || msg.seq <= p.lastSeq) return false;
  p.lastSeq = msg.seq;
  if (r.phase !== 'fight') return false;
  if (typeof msg.axis !== 'number' || !Number.isFinite(msg.axis)) return false;
  p.axis = clamp(msg.axis, -1, 1);
  p.guard = msg.guard === true;
  p.inputAge = 0;
  if (['jump', ...Object.keys(moves)].includes(msg.action) && p.queue.length < 3) {
    p.queue.push({ action: msg.action, ttl: 6 });
  }
  return true;
}
function attack(r, p, action) {
  if (action === 'burst') {
    if (p.burst < 100 || p.breakTicks > 0) return false;
    p.stun = 0;
    p.move = '';
    p.burst = 0;
    p.invulnerable = 24;
  } else if (p.stun || p.guard) return false;
  if (action === 'jump') {
    if (p.y !== 0 || p.move) return false;
    p.vy = 13.8;
    p.y = 0.1;
    event(r, 'jump', p);
    return true;
  }
  if (p.move) return false;
  if (['summon', 'super'].includes(action) && p.breakTicks > 0) return false;
  if (action === 'super') {
    if (p.meter < 50) return false;
    p.meter -= 50;
    p.invulnerable = 18;
  }
  p.move = action;
  p.frame = 0;
  p.hit = false;
  if (['summon', 'super'].includes(action)) p.companion = 62;
  event(r, action, p);
  return true;
}
function contact(r, a, b) {
  const m = moves[a.move];
  if (!m || a.hit || a.frame < m.startup || a.frame >= m.startup + m.active) return;
  if (Math.abs(a.x - b.x) > m.reach || Math.abs(a.y - b.y) > (a.move === 'super' ? 230 : 115)) return;
  if ((b.x - a.x) * a.face < -20 || b.invulnerable > 0) return;
  a.hit = true;
  const blocked = b.guard && b.y === 0 && !b.stun && !b.move && a.move !== 'burst';
  const damage = blocked ? Math.ceil(m.damage * 0.08) : Math.ceil(m.damage * Math.max(0.45, 1 - a.combo * 0.12));
  b.hp = Math.max(0, b.hp - damage);
  a.meter = clamp(a.meter + (blocked ? 5 : 11), 0, a.awakened ? 150 : 100);
  b.meter = clamp(b.meter + 7, 0, b.awakened ? 150 : 100);
  b.burst = clamp(b.burst + 4, 0, 100);
  b.x = clamp(b.x + a.face * (a.move === 'burst' ? 185 : blocked ? 16 : 33), 70, 930);
  if (!blocked) {
    a.combo++;
    b.stun = m.stun;
    b.move = '';
    b.combo = 0;
    if (b.companion > 0 && b.cards > 0) {
      b.cards--;
      event(r, 'card', b, { cards: b.cards });
      if (b.cards === 0) {
        b.breakTicks = 600;
        b.companion = 0;
        event(r, 'break', b);
      }
    }
  }
  if (!b.awakened && b.hp <= 350 && b.hp > 0) {
    b.awakened = true;
    b.meter = Math.min(150, b.meter + 50);
    event(r, 'awakening', b);
  }
  event(r, blocked ? 'block' : 'hit', a, { target: b.id, damage, x: b.x, y: b.y + 100, combo: a.combo });
}
function finishRound(r) {
  const [a, b] = r.fighters;
  const winner = a.hp === b.hp ? null : a.hp > b.hp ? a : b;
  if (winner) winner.wins++;
  r.winner = winner?.id ?? '';
  r.phase = 'roundEnd';
  r.phaseTicks = 180;
  event(r, 'ko', winner);
}
export function step(r) {
  if (r.fighters.length !== 2 || r.fighters.some(f => !f.connected)) return;
  r.tick++;
  if (r.phase === 'versus') {
    if (--r.phaseTicks <= 0) { r.phase = 'fight'; event(r, 'fight'); }
    return;
  }
  if (r.phase === 'roundEnd') {
    if (--r.phaseTicks <= 0) {
      if (r.fighters.some(f => f.wins === 2)) { r.phase = 'result'; event(r, 'result'); }
      else { r.round++; resetRound(r); }
    }
    return;
  }
  if (r.phase !== 'fight') return;
  r.time = Math.max(0, r.time - 1 / RATE);
  for (const p of r.fighters) {
    const other = r.fighters[1 - p.slot];
    if (!p.move) p.face = other.x >= p.x ? 1 : -1;
    p.burst = Math.min(100, p.burst + 100 / (45 * RATE));
    if (++p.inputAge > 30) { p.axis = 0; p.guard = false; }
    if (p.breakTicks > 0 && --p.breakTicks === 0) { p.cards = 4; event(r, 'restore', p); }
    if (p.companion > 0) p.companion--;
    if (p.invulnerable > 0) p.invulnerable--;
    if (p.stun > 0) p.stun--;
    else if (!other.move) p.combo = 0;
    if (p.queue.length) {
      const q = p.queue[0];
      if (attack(r, p, q.action) || --q.ttl <= 0) p.queue.shift();
    }
    if (!p.stun && !p.move && !p.guard) p.x = clamp(p.x + p.axis * 4.3, 70, 930);
    if (p.y > 0) {
      p.y = Math.max(0, p.y + p.vy);
      p.vy -= 0.62;
    }
    if (p.move) {
      p.frame++;
      const m = moves[p.move];
      if (p.frame >= m.startup + m.active + m.recovery) p.move = '';
    }
  }
  const [a, b] = r.fighters;
  if (Math.abs(a.x - b.x) < 64 && Math.abs(a.y - b.y) < 100) {
    const center = clamp((a.x + b.x) / 2, 102, 898);
    const side = a.x <= b.x ? -1 : 1;
    a.x = center + 32 * side; b.x = center - 32 * side;
  }
  contact(r, a, b);
  contact(r, b, a);
  if (r.time <= 0 || r.fighters.some(p => p.hp <= 0)) finishRound(r);
}
export function snapshot(r) {
  return { type: 'state', code: r.code, tick: r.tick, phase: r.phase, round: r.round,
    time: r.time, phaseTicks: r.phaseTicks, winner: r.winner, match: r.match,
    paused: r.fighters.some(f => !f.connected),
    fighters: r.fighters.map(({ queue, inputAge, hit, ...f }) => f), events: r.events };
}
