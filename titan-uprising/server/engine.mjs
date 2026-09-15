export const TICK_MS = 50;
export const HEROES = [
  { id: 0, name: 'Helion', hp: 125, quick: 8, strong: 19, speed: 1, faction: 'dawn' },
  { id: 1, name: 'Nocturne', hp: 105, quick: 9, strong: 16, speed: 0.85, faction: 'dawn' },
  { id: 2, name: 'Tempest', hp: 100, quick: 7, strong: 18, speed: 0.75, faction: 'dawn' },
  { id: 3, name: 'Monolith', hp: 150, quick: 8, strong: 24, speed: 1.25, faction: 'eclipse' },
  { id: 4, name: 'Hex', hp: 110, quick: 8, strong: 18, speed: 1, faction: 'eclipse' },
  { id: 5, name: 'Wraith', hp: 105, quick: 10, strong: 17, speed: 0.85, faction: 'eclipse' }
];

export function validTeam(team) {
  return Array.isArray(team) && team.length === 3 && new Set(team).size === 3
    && team.every(id => Number.isInteger(id) && id >= 0 && id < HEROES.length);
}

export function player(id, name, team) {
  return {
    id, name, team, connected: true, ready: false, rematch: false, active: 0,
    hp: team.map(h => HEROES[h].hp), power: [0, 0, 0], blocking: false,
    blockAt: -10000, guardUntil: 0, action: 'idle', actionAt: 0, actionUntil: 0,
    attack: null, lastSeq: 0, lastTag: -10000, combo: 0, lastHit: -10000,
    damage: 0, hits: 0, blocks: 0, specials: 0, tags: 0
  };
}

export function createRoom(code) {
  return { code, phase: 'lobby', tick: 0, time: 0, round: 0, players: [],
    events: [], eventID: 0, winner: '', remaining: 120, startedAt: 0 };
}

function event(room, type, source = '', target = '', amount = 0, label = '') {
  const e = { id: ++room.eventID, tick: room.tick, type, source, target, amount, label };
  room.events.push(e);
  room.events = room.events.slice(-24);
  return e;
}

export function start(room) {
  room.round++;
  room.phase = 'countdown';
  room.winner = '';
  room.remaining = 120;
  room.startedAt = room.time + 3000;
  room.players = room.players.map(p => ({ ...player(p.id, p.name, p.team), lastSeq: p.lastSeq }));
  event(room, 'round', '', '', room.round, 'THE CITY NEEDS A CHAMPION');
}

export function input(room, p, msg) {
  if (!Number.isSafeInteger(msg.seq) || msg.seq <= p.lastSeq) return false;
  p.lastSeq = msg.seq;
  if (room.phase === 'lobby') {
    if (msg.action === 'team' && validTeam(msg.team) && !p.ready) {
      p.team = msg.team;
      p.hp = p.team.map(h => HEROES[h].hp);
    }
    if (msg.action === 'ready') p.ready = !p.ready;
    if (room.players.length === 2 && room.players.every(peer => peer.ready && peer.connected)) start(room);
    return true;
  }
  if (room.phase === 'result') {
    if (msg.action === 'rematch') p.rematch = true;
    if (room.players.length === 2 && room.players.every(peer => peer.rematch && peer.connected)) start(room);
    return true;
  }
  if (room.phase !== 'fight' || room.players.some(peer => !peer.connected)) return false;
  const now = room.time;
  const hero = HEROES[p.team[p.active]];
  if (msg.action === 'block') {
    if (msg.down === false) {
      p.blocking = false;
      if (p.action === 'block') p.action = 'idle';
    } else if (!p.attack && now >= p.actionUntil) {
      if (!p.blocking) p.blockAt = now;
      p.blocking = true;
      p.guardUntil = now + 1200;
      p.action = 'block';
    }
    return true;
  }
  if (msg.action === 'special' && p.attack?.kind === 'special' && now < p.attack.impact) {
    if (now - p.attack.lastMash >= 90) {
      p.attack.mash = Math.min(10, p.attack.mash + 1);
      p.attack.lastMash = now;
    }
    return true;
  }
  if (p.attack || now < p.actionUntil) return false;
  if (msg.action === 'tag') {
    const slot = msg.slot;
    if (!Number.isInteger(slot) || slot < 0 || slot > 2 || slot === p.active
      || p.hp[slot] <= 0 || now - p.lastTag < 5000) return false;
    p.active = slot;
    p.tags++;
    p.lastTag = now;
    p.blocking = false;
    p.action = 'tag';
    p.actionAt = now;
    p.actionUntil = now + 600;
    event(room, 'tag', p.id, '', slot, HEROES[p.team[slot]].name);
    return true;
  }
  if (!['quick', 'strong', 'special'].includes(msg.action)) return false;
  const kind = msg.action;
  const tier = Math.floor(p.power[p.active] / 100);
  if (kind === 'special' && tier === 0) return false;
  p.blocking = false;
  const windup = kind === 'quick' ? 160 * hero.speed : kind === 'strong' ? 500 * hero.speed : 1600;
  const recovery = kind === 'quick' ? 250 : kind === 'strong' ? 450 : 750;
  p.action = kind;
  p.actionAt = now;
  p.actionUntil = now + windup + recovery;
  p.attack = { kind, impact: now + windup, tier, mash: 0, lastMash: now };
  if (kind === 'special') {
    p.power[p.active] -= tier * 100;
    p.specials++;
    event(room, 'super', p.id, '', tier, ['','POWER SURGE','CATACLYSM','TITAN UPRISING'][tier]);
  }
  return true;
}

function resolveAttack(room, attacker, defender, attack) {
  const now = room.time;
  const hero = HEROES[attacker.team[attacker.active]];
  let damage = attack.kind === 'quick' ? hero.quick : attack.kind === 'strong' ? hero.strong
    : 22 + 18 * attack.tier + attack.mash * 2;
  const synergy = attacker.team.every(id => HEROES[id].faction === hero.faction);
  if (synergy) damage *= 1.06;
  if (hero.id === 4 && attack.kind === 'special') damage *= 1.1;
  const parry = defender.blocking && now - defender.blockAt <= 200 && attack.kind !== 'special';
  const blocked = defender.blocking;
  if (parry) {
    damage = 0;
    attacker.action = 'stun';
    attacker.actionUntil = now + 650;
    defender.power[defender.active] = Math.min(300, defender.power[defender.active] + 20);
  } else if (blocked) damage *= defender.team[defender.active] === 3 ? 0.16 : 0.25;
  damage = Math.round(damage);
  defender.hp[defender.active] = Math.max(0, defender.hp[defender.active] - damage);
  attacker.damage += damage;
  attacker.hits++;
  attacker.combo = now - attacker.lastHit < 1400 && !blocked ? attacker.combo + 1 : 1;
  attacker.lastHit = now;
  attacker.power[attacker.active] = Math.min(300, attacker.power[attacker.active] + (attack.kind === 'special' ? 0 : 24));
  defender.power[defender.active] = Math.min(300, defender.power[defender.active] + Math.round(damage * 1.2));
  if (blocked) defender.blocks++;
  if (!blocked) {
    if (defender.attack?.kind !== 'special') {
      defender.attack = null;
      defender.action = 'hit';
      defender.actionAt = now;
      defender.actionUntil = now + (attack.kind === 'strong' ? 420 : 150);
    }
  }
  event(room, parry ? 'parry' : blocked ? 'block' : 'hit', attacker.id, defender.id, damage,
    parry ? 'PERFECT GUARD' : blocked ? 'BLOCKED' : attack.kind === 'special' ? 'DEVASTATION' :
      attacker.combo >= 3 ? `${attacker.combo} HIT COMBO` : attack.kind === 'strong' ? 'CRUSH' : 'STRIKE');
  if (defender.hp[defender.active] === 0) {
    event(room, 'ko', attacker.id, defender.id, defender.active, 'HERO FALLEN');
    const next = defender.hp.findIndex(hp => hp > 0);
    defender.attack = null;
    defender.blocking = false;
    if (next < 0) finish(room, attacker.id, 'TEAM ELIMINATED');
    else {
      defender.active = next;
      defender.action = 'tag';
      defender.actionAt = now;
      defender.actionUntil = now + 1000;
    }
  }
}

function finish(room, winner, label) {
  room.phase = 'result';
  room.winner = winner;
  room.players.forEach(p => { p.attack = null; p.blocking = false; p.action = 'idle'; p.rematch = false; });
  event(room, 'result', winner, '', room.round, label);
}

export function advance(room) {
  room.tick++;
  if (room.players.length !== 2 || room.players.some(p => !p.connected)) return;
  room.time += TICK_MS;
  if (room.phase === 'countdown' && room.time >= room.startedAt) {
    room.phase = 'fight';
    event(room, 'fight', '', '', 0, 'FIGHT');
  }
  if (room.phase !== 'fight') return;
  room.remaining = Math.max(0, 120 - (room.time - room.startedAt) / 1000);
  for (const p of room.players) {
    if (p.blocking && room.time > p.guardUntil) { p.blocking = false; p.action = 'idle'; }
    if (p.actionUntil <= room.time && !p.blocking && !p.attack) p.action = 'idle';
  }
  // Alternate tie priority each tick; all input is processed in WebSocket arrival order.
  const order = room.tick % 2 ? [0, 1] : [1, 0];
  for (const i of order) {
    const p = room.players[i];
    if (p.attack && p.attack.impact <= room.time) {
      const attack = p.attack;
      p.attack = null;
      resolveAttack(room, p, room.players[1 - i], attack);
      if (room.phase === 'result') return;
    }
  }
  if (room.remaining <= 0) {
    const health = room.players.map(p => p.hp.reduce((sum, hp, i) => sum + hp / HEROES[p.team[i]].hp, 0));
    finish(room, health[0] === health[1] ? 'draw' : room.players[health[0] > health[1] ? 0 : 1].id, 'TIME EXPIRED');
  }
}
