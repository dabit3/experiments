export const FPS = 60;
export const CHARACTERS = {
  kai: { speed: 3.6, power: 1, reach: 1, color: 'cyan' },
  rhea: { speed: 3.15, power: 1.12, reach: 1.16, color: 'orange' },
};
export const MOVES = {
  light: { startup: 4, active: 4, recovery: 12, damage: 7, reach: 88, stun: 18, meter: 8 },
  heavy: { startup: 10, active: 5, recovery: 25, damage: 14, reach: 126, stun: 29, meter: 13 },
  fire: { startup: 18, active: 1, recovery: 29, damage: 12, reach: 0, stun: 22, meter: 12 },
  super: { startup: 10, active: 1, recovery: 45, damage: 10, reach: 0, stun: 24, meter: 0 },
};
export const neutral = () => ({ left: false, right: false, jump: false, crouch: false, guard: false });
export function fighter(id, name, character, slot) {
  return { id, name, character, slot, connected: true, ready: false, rematch: false,
    x: slot === 0 ? 270 : 690, y: 0, vy: 0, facing: slot === 0 ? 1 : -1,
    hp: 100, meter: 0, wins: 0, pose: 'idle', attack: null, stun: 0,
    input: neutral(), seq: -1, buffer: null, combo: 0, comboTicks: 0, hits: 0,
    blocks: 0, actions: 0, damageDealt: 0 };
}
export function makeMatch(code) {
  return { code, tick: 0, phase: 'waiting', phaseTicks: 0, remaining: 60 * FPS,
    round: 1, players: [], projectiles: [], effects: [], serial: 0,
    freeze: 0, winner: '', roundWinner: '', paused: false, match: 1 };
}
export function emit(m, kind, x, y, owner = '', text = '') {
  m.effects.push({ id: ++m.serial, kind, x, y, owner, text, life: 25 });
}
export function resetRound(m) {
  m.players.forEach((p, i) => {
    Object.assign(p, { x: i === 0 ? 270 : 690, y: 0, vy: 0, hp: 100, meter: 0,
      attack: null, stun: 0, pose: 'idle', input: neutral(), buffer: null, combo: 0, comboTicks: 0 });
  });
  m.projectiles = []; m.effects = []; m.freeze = 0;
  m.remaining = 60 * FPS; m.phase = 'countdown'; m.phaseTicks = 150;
}
export function input(m, p, message) {
  if (!Number.isSafeInteger(message.seq) || message.seq <= p.seq) return false;
  if (message.seq - p.seq > 10000) return false;
  p.seq = message.seq;
  if (!message.held || typeof message.held !== 'object') return false;
  for (const k of Object.keys(p.input)) p.input[k] = message.held[k] === true;
  if (Object.hasOwn(MOVES, message.action)) p.buffer = { move: message.action, expires: m.tick + 8 };
  return true;
}
function startMove(m, p, move) {
  if (move === 'super' && (p.meter < 100 || p.y > 0)) return;
  if (move === 'fire' && p.y > 0) return;
  p.attack = { move, frame: 0, hit: false, low: p.input.crouch && p.y === 0, air: p.y > 0 };
  p.pose = move; p.actions++;
  if (move === 'super') {
    p.meter = 0; m.freeze = 18; emit(m, 'super', p.x, p.y + 85, p.id, 'SUPER ART');
  }
  if (move === 'fire') p.meter = Math.min(100, p.meter + MOVES.fire.meter);
}
function hit(m, a, d, spec, projectile = false, low = false, air = false) {
  const back = d.facing === 1 ? d.input.left : d.input.right;
  const guarding = d.y === 0 && !d.attack && (d.input.guard || back)
    && (!low || d.input.crouch) && (!air || !d.input.crouch);
  const damage = guarding ? (projectile ? 2 : 0) : Math.round(spec.damage * CHARACTERS[a.character].power);
  d.hp = Math.max(0, d.hp - damage);
  d.stun = guarding ? 11 : spec.stun; d.attack = null; d.buffer = null;
  d.pose = guarding ? 'block' : 'hurt';
  d.x = Math.max(75, Math.min(885, d.x + a.facing * (guarding ? 8 : 20)));
  if (guarding) d.blocks++;
  else { a.hits++; a.combo = a.comboTicks > 0 ? a.combo + 1 : 1; a.comboTicks = spec.stun + 28; }
  a.damageDealt += damage;
  a.meter = Math.min(100, a.meter + spec.meter);
  d.meter = Math.min(100, d.meter + (guarding ? 3 : 7));
  m.freeze = guarding ? 4 : (spec.damage >= 14 ? 9 : 6);
  emit(m, guarding ? 'block' : 'hit', d.x - a.facing * 24, d.y + (low ? 30 : 80),
    a.id, guarding ? 'GUARD' : a.combo > 1 ? `${a.combo} HIT` : '');
}
function advanceFighter(m, p, d) {
  const stats = CHARACTERS[p.character];
  if (!p.attack) p.facing = p.x <= d.x ? 1 : -1;
  if (p.comboTicks > 0) p.comboTicks--;
  if (p.y > 0 || p.vy > 0) {
    p.y += p.vy; p.vy -= 0.72;
    if (p.y <= 0) { p.y = 0; p.vy = 0; }
  }
  if (p.stun > 0) { p.stun--; return; }
  if (p.buffer && p.buffer.expires < m.tick) p.buffer = null;
  if (!p.attack) {
    if (p.input.jump && p.y === 0) { p.vy = 13; p.y = 1; }
    const walk = Number(p.input.right) - Number(p.input.left);
    if ((!p.input.crouch && !p.input.guard) || p.y > 0) p.x += walk * stats.speed;
    p.x = Math.max(75, Math.min(885, p.x));
    p.pose = p.y > 0 ? 'jump' : p.input.crouch ? 'crouch' : p.input.guard ? 'block' : walk ? 'walk' : 'idle';
    if (p.buffer) { startMove(m, p, p.buffer.move); p.buffer = null; }
  }
  if (!p.attack) return;
  const a = p.attack, spec = MOVES[a.move];
  a.frame++;
  if (a.frame === spec.startup && (a.move === 'fire' || a.move === 'super')) {
    const count = a.move === 'super' ? 4 : 1;
    for (let i = 0; i < count; i++) {
      m.projectiles.push({ id: ++m.serial, owner: p.id, x: p.x + p.facing * 65 - p.facing * i * 60,
        y: 65, vx: p.facing * (a.move === 'super' ? 11 : 7), super: a.move === 'super', life: 150 });
    }
    emit(m, 'fire', p.x + p.facing * 60, 65, p.id);
  }
  if ((a.move === 'light' || a.move === 'heavy') && !a.hit &&
      a.frame >= spec.startup && a.frame < spec.startup + spec.active) {
    const dx = (d.x - p.x) * p.facing;
    const height = Math.abs((p.y + (a.low ? 32 : 80)) - (d.y + (d.input.crouch ? 38 : 65)));
    if (dx > -20 && dx < spec.reach * stats.reach && height < 66) {
      a.hit = true; hit(m, p, d, spec, false, a.low, a.air);
    }
  }
  if (a.frame >= spec.startup + spec.active + spec.recovery) p.attack = null;
}
function finishRound(m) {
  const [a, b] = m.players;
  const winner = a.hp === b.hp ? null : a.hp > b.hp ? a : b;
  if (winner) winner.wins++;
  m.roundWinner = winner?.id ?? '';
  m.winner = winner?.wins === 2 ? winner.id : '';
  m.phase = m.winner ? 'matchOver' : 'roundOver';
  m.phaseTicks = 180; m.projectiles = [];
  for (const p of m.players) {
    p.pose = p.hp === 0 ? 'ko' : winner?.id === p.id ? 'win' : 'idle';
    p.attack = null; p.input = neutral(); p.buffer = null;
  }
  emit(m, 'ko', 480, 230, winner?.id ?? '', m.remaining <= 0 ? 'TIME UP' : 'K.O.');
}
export function step(m) {
  m.tick++;
  m.paused = m.players.some(p => !p.connected);
  if (m.paused || m.players.length !== 2) return;
  m.effects.forEach(e => e.life--); m.effects = m.effects.filter(e => e.life > 0);
  if (m.phase === 'waiting' && m.players.every(p => p.ready)) resetRound(m);
  else if (m.phase === 'countdown' && --m.phaseTicks <= 0) m.phase = 'fight';
  else if (m.phase === 'roundOver' && --m.phaseTicks <= 0) { m.round++; resetRound(m); }
  else if (m.phase === 'matchOver' && m.players.every(p => p.rematch)) {
    m.players.forEach(p => { p.wins = 0; p.rematch = false; p.hits = 0; p.actions = 0; p.damageDealt = 0; p.blocks = 0; });
    m.round = 1; m.match++; m.winner = ''; resetRound(m);
  }
  if (m.phase !== 'fight') return;
  if (m.freeze > 0) { m.freeze--; return; }
  m.remaining--;
  const [a, b] = m.players;
  // Alternate evaluation priority to avoid a permanent player-one trade advantage.
  const order = m.tick % 2 ? [a, b] : [b, a];
  for (const p of order) advanceFighter(m, p, p === a ? b : a);
  if (Math.abs(a.x - b.x) < 60 && Math.abs(a.y - b.y) < 95) {
    const middle = (a.x + b.x) / 2, side = a.x <= b.x ? 1 : -1;
    a.x = Math.max(75, Math.min(885, middle - 30 * side));
    b.x = Math.max(75, Math.min(885, middle + 30 * side));
  }
  for (const shot of m.projectiles) {
    shot.x += shot.vx; shot.life--;
    const owner = m.players.find(p => p.id === shot.owner), target = owner === a ? b : a;
    const targetTop = target.y + (target.input.crouch ? 74 : 122);
    if (Math.abs(target.x - shot.x) < 34 && target.y + 12 < shot.y + 16 &&
        targetTop > shot.y - 16 && shot.life > 0) {
      hit(m, owner, target, MOVES[shot.super ? 'super' : 'fire'], true); shot.life = 0;
    }
  }
  // Opposing waves cancel each other; a super wave consumes one normal wave.
  for (let i = 0; i < m.projectiles.length; i++) for (let j = i + 1; j < m.projectiles.length; j++) {
    const x = m.projectiles[i], y = m.projectiles[j];
    if (x.life > 0 && y.life > 0 && x.owner !== y.owner && Math.abs(x.x - y.x) < 35) {
      x.life = 0; y.life = 0; emit(m, 'block', (x.x + y.x) / 2, 65);
    }
  }
  m.projectiles = m.projectiles.filter(s => s.life > 0 && s.x > -80 && s.x < 1040);
  if (a.hp <= 0 || b.hp <= 0 || m.remaining <= 0) finishRound(m);
}
export function snapshot(m) {
  return { type: 'state', code: m.code, tick: m.tick, phase: m.phase, phaseTicks: m.phaseTicks,
    remaining: m.remaining, round: m.round, match: m.match, winner: m.winner,
    roundWinner: m.roundWinner, paused: m.paused, freeze: m.freeze, effects: m.effects,
    projectiles: m.projectiles, players: m.players.map(({ buffer, input: held, ...p }) => p) };
}
