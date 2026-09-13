export const DT = 1 / 60;
export const attacks = {
  slash: { startup: 6, active: 5, recovery: 15, range: 150, damage: 9, stun: 19 },
  heavy: { startup: 15, active: 7, recovery: 25, range: 210, damage: 18, stun: 30 },
  special: { startup: 19, active: 1, recovery: 30, range: 0, damage: 13, stun: 24 }
};

export function fighter(id, name, style, slot) {
  return {
    id, name, style, slot, connected: true, ready: false, wins: 0, hp: 100,
    x: slot ? 800 : 300, y: 0, vx: 0, vy: 0, facing: slot ? -1 : 1,
    meter: 25, pose: 'idle', attack: '', frame: 0, stun: 0,
    dash: 0, airDash: false, slow: 0, combo: 0, comboUntil: 0,
    hit: false, seq: -1, move: 0, guard: false, queue: [], rematch: false
  };
}

export function room(code) {
  return {
    code, tick: 0, phase: 'lobby', round: 1, seconds: 60, countdown: 0,
    players: [], projectiles: [], events: [], eventID: 0, winner: '',
    paused: false, roundWinner: '', matches: 0
  };
}

function event(r, type, p, extra = {}) {
  r.events.push({ id: ++r.eventID, tick: r.tick, type, player: p.id, x: p.x, y: p.y, ...extra });
  r.events = r.events.slice(-20);
}

export function resetRound(r) {
  for (const p of r.players) {
    const fresh = fighter(p.id, p.name, p.style, p.slot);
    Object.assign(p, fresh, { wins: p.wins, seq: p.seq });
  }
  r.phase = 'countdown';
  r.countdown = 150;
  r.seconds = 60;
  r.projectiles = [];
  r.roundWinner = '';
  event(r, 'round', r.players[0]);
}

export function input(r, p, message) {
  if (!Number.isSafeInteger(message.seq) || message.seq <= p.seq) return false;
  p.seq = message.seq;
  if (r.phase !== 'fight' || r.paused) return false;
  if (message.action === 'move') {
    p.move = [-1, 0, 1].includes(message.value) ? message.value : 0;
  } else if (message.action === 'guard') {
    p.guard = message.value === 1;
  } else if (['jump', 'dash', 'slash', 'heavy', 'special', 'cancel'].includes(message.action)) {
    if (p.queue.length < 8) p.queue.push(message.action);
  }
  return true;
}

function act(r, p, opponent, action) {
  if (p.stun > 0) return;
  if (action === 'cancel') {
    const cost = p.attack ? 50 : 25;
    if (p.meter < cost || p.pose === 'cancel') return;
    const color = p.attack ? (p.hit ? 'RED' : 'PURPLE') : 'YELLOW';
    p.meter -= cost;
    p.attack = '';
    p.frame = 0;
    p.dash = 0;
    p.vy = Math.max(0, p.vy);
    opponent.slow = cost === 50 ? 45 : 25;
    event(r, 'cancel', p, { text: `${color} REQUIEM`, color });
    return;
  }
  if (p.attack || p.dash > 0 || p.guard) return;
  if (action === 'jump' && p.y === 0) {
    p.vy = 800;
    event(r, 'jump', p);
  } else if (action === 'dash' && (p.y === 0 || !p.airDash)) {
    p.dash = p.y > 0 ? 16 : 12;
    p.vx = (p.move || p.facing) * 780;
    if (p.y > 0) { p.airDash = true; p.vy = 0; }
    event(r, p.y > 0 ? 'airdash' : 'dash', p);
  } else if (attacks[action]) {
    p.attack = action;
    p.frame = 0;
    p.hit = false;
    p.facing = p.x <= opponent.x ? 1 : -1;
    event(r, 'attack', p, { attack: action });
  }
}

function damage(r, p, target, attack, projectile = false) {
  const guarding = target.guard && !target.attack && target.stun === 0
    && Math.sign(p.x - target.x) === target.facing;
  const counter = !!target.attack && !guarding;
  const amount = guarding ? 2 : Math.round(attack.damage * (counter ? 1.2 : 1));
  target.hp = Math.max(0, target.hp - amount);
  target.stun = guarding ? 10 : attack.stun;
  target.attack = '';
  target.dash = 0;
  target.vx = p.facing * (guarding ? 160 : 260);
  if (!guarding && (p.attack === 'heavy' || target.y > 0)) target.vy = 240;
  p.meter = Math.min(100, p.meter + (guarding ? 4 : 13));
  target.meter = Math.min(100, target.meter + 6);
  p.combo = r.tick < p.comboUntil ? p.combo + 1 : 1;
  p.comboUntil = r.tick + attack.stun + 25;
  p.hit = true;
  event(r, guarding ? 'block' : 'hit', target, {
    attacker: p.id, amount, combo: guarding ? 0 : p.combo, counter,
    projectile, text: guarding ? 'GUARD' : counter ? 'COUNTER' : p.combo > 1 ? `${p.combo} BEAT` : 'SLASH'
  });
}

function updateFighter(r, p, opponent) {
  if (p.slow > 0 && --p.slow % 2 === 0) return;
  if (p.queue.length) act(r, p, opponent, p.queue.shift());
  if (!p.attack && !p.dash) p.facing = p.x <= opponent.x ? 1 : -1;
  if (p.stun > 0) {
    p.stun--;
    p.pose = 'hurt';
    p.vx *= 0.85;
  } else if (p.attack) {
    const attack = attacks[p.attack];
    p.pose = p.attack;
    p.frame++;
    p.vx = p.y > 0 ? p.move * 110 : 0;
    if (p.attack === 'special' && p.frame === attack.startup) {
      r.projectiles.push({
        id: r.eventID + 1, owner: p.id, x: p.x + p.facing * 65,
        y: p.y + 70, direction: p.facing, ttl: 100, style: p.style
      });
      event(r, 'projectile', p);
    } else if (p.attack !== 'special' && !p.hit && p.frame >= attack.startup
      && p.frame < attack.startup + attack.active) {
      const distance = (opponent.x - p.x) * p.facing;
      const range = attack.range + (p.style === 'vesper' ? 20 : 0);
      if (distance > -35 && distance < range && Math.abs(opponent.y - p.y) < 115) {
        damage(r, p, opponent, attack);
      }
    }
    if (p.frame >= attack.startup + attack.active + attack.recovery) p.attack = '';
  } else if (p.dash > 0) {
    p.dash--;
    p.pose = 'dash';
  } else {
    p.vx = p.guard ? 0 : p.move * (p.y > 0 ? 280 : 310);
    p.pose = p.guard ? 'guard' : p.y > 0 ? 'jump' : p.move ? 'run' : 'idle';
    if (p.move && p.move === p.facing) p.meter = Math.min(100, p.meter + 0.06);
  }
  p.x = Math.max(65, Math.min(1035, p.x + p.vx * DT));
  if (p.dash <= 0 || p.y === 0) p.vy -= 2100 * DT;
  p.y = Math.max(0, p.y + p.vy * DT);
  if (p.y === 0) { p.vy = 0; p.airDash = false; }
}

function finishRound(r) {
  const [a, b] = r.players;
  const winner = a.hp === b.hp ? null : a.hp > b.hp ? a : b;
  if (winner) winner.wins++;
  r.roundWinner = winner?.id || 'draw';
  r.phase = winner?.wins === 2 ? 'result' : 'roundEnd';
  r.countdown = 180;
  if (r.phase === 'result') r.winner = winner.id;
  event(r, 'finish', winner || a, { text: winner ? 'SLASH!' : 'DRAW' });
}

export function step(r) {
  r.tick++;
  if (r.players.length !== 2 || r.paused) return;
  if (r.phase === 'countdown') {
    if (--r.countdown <= 0) { r.phase = 'fight'; event(r, 'start', r.players[0]); }
    return;
  }
  if (r.phase === 'roundEnd') {
    if (--r.countdown <= 0) { r.round++; resetRound(r); }
    return;
  }
  if (r.phase !== 'fight') return;
  r.seconds = Math.max(0, r.seconds - DT);
  const [a, b] = r.players;
  updateFighter(r, a, b);
  updateFighter(r, b, a);
  if (Math.abs(a.y - b.y) < 95 && Math.abs(a.x - b.x) < 65) {
    const mid = (a.x + b.x) / 2;
    const side = a.x <= b.x ? -1 : 1;
    a.x = Math.max(65, Math.min(1035, mid + side * 33));
    b.x = Math.max(65, Math.min(1035, mid - side * 33));
  }
  for (const projectile of r.projectiles) {
    projectile.x += projectile.direction * 650 * DT;
    projectile.ttl--;
    const owner = r.players.find(p => p.id === projectile.owner);
    const target = owner === a ? b : a;
    if (Math.abs(projectile.x - target.x) < 48 && Math.abs(projectile.y - (target.y + 65)) < 85) {
      damage(r, owner, target, attacks.special, true);
      projectile.ttl = 0;
    }
  }
  r.projectiles = r.projectiles.filter(p => p.ttl > 0 && p.x > 0 && p.x < 1100);
  if (a.hp <= 0 || b.hp <= 0 || r.seconds === 0) finishRound(r);
}

export function snapshot(r) {
  return {
    type: 'state', code: r.code, tick: r.tick, phase: r.phase, round: r.round,
    seconds: r.seconds, countdown: r.countdown, winner: r.winner,
    roundWinner: r.roundWinner, paused: r.paused, matches: r.matches,
    players: r.players.map(({ queue, ...p }) => p),
    projectiles: r.projectiles, events: r.events
  };
}
