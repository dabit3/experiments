export const DT = 1 / 30;
export const HEALTH = 300;
export const ACTIONS = new Set(['melee', 'shot', 'beam', 'dodge', 'flight', 'lock']);
const clamp = (n, a, b) => Math.max(a, Math.min(b, n));
const length = v => Math.hypot(v.x, v.y, v.z);
const sub = (a, b) => ({ x: a.x - b.x, y: a.y - b.y, z: a.z - b.z });
const unit = v => { const d = length(v) || 1; return { x: v.x / d, y: v.y / d, z: v.z / d }; };
const dot = (a, b) => a.x * b.x + a.y * b.y + a.z * b.z;
const add = (a, b, scale = 1) => { a.x += b.x * scale; a.y += b.y * scale; a.z += b.z * scale; };

export function fighter(id, name, slot) {
  return {
    id, name, slot, connected: true, ready: false, hp: HEALTH, energy: 100,
    pos: { x: slot === 0 ? -5 : 5, y: 0, z: 0 },
    velocity: { x: 0, y: 0, z: 0 }, yaw: slot === 0 ? Math.PI / 2 : -Math.PI / 2,
    flying: false, locked: true, mode: 'idle', combo: 0, comboAt: -100,
    cooldown: 0, stun: 0, invulnerable: 0, beamTime: 0, beamDirection: null,
    input: { x: 0, z: 0, lift: 0, charge: false, boost: false },
    inputAt: 0, seq: -1, queue: [], damage: 0, hits: 0, dodges: 0
  };
}

export class Arena {
  constructor(code, emit = () => {}) {
    this.code = code;
    this.players = [];
    this.phase = 'lobby';
    this.round = 0;
    this.tick = 0;
    this.time = 90;
    this.countdown = 0;
    this.winner = '';
    this.reason = '';
    this.projectiles = [];
    this.effects = [];
    this.eventID = 0;
    this.emit = emit;
  }

  event(type, fields = {}) {
    const e = { event: ++this.eventID, type, tick: this.tick, ...fields };
    this.effects.push(e);
    if (this.effects.length > 48) this.effects.shift();
    this.emit({ room: this.code, round: this.round, ...e });
    return e;
  }

  input(player, msg) {
    if (!Number.isSafeInteger(msg.seq) || msg.seq <= player.seq) return false;
    if (!['x', 'z', 'lift'].every(k => typeof msg[k] === 'number' && Number.isFinite(msg[k]))) return false;
    if (msg.actions !== undefined && (!Array.isArray(msg.actions) || msg.actions.length > 6)) return false;
    player.seq = msg.seq;
    player.inputAt = this.tick;
    player.input = {
      x: clamp(msg.x, -1, 1), z: clamp(msg.z, -1, 1), lift: clamp(msg.lift, -1, 1),
      charge: msg.charge === true, boost: msg.boost === true
    };
    if (this.phase === 'playing') {
      for (const action of msg.actions || []) {
        if (ACTIONS.has(action) && player.queue.length < 12) player.queue.push(action);
      }
    }
    return true;
  }

  ready(player) {
    if (!['lobby', 'result'].includes(this.phase)) return;
    player.ready = true;
    this.event('ready', { player: player.id });
    if (this.players.length === 2 && this.players.every(p => p.ready && p.connected)) {
      this.round++;
      this.players = this.players.map(p => ({ ...fighter(p.id, p.name, p.slot), seq: p.seq, inputAt: this.tick }));
      this.phase = 'countdown';
      this.countdown = 3;
      this.time = 90;
      this.winner = '';
      this.projectiles = [];
      this.event('round', { number: this.round });
    }
  }

  hit(attacker, defender, amount, direction, force, kind) {
    if (defender.invulnerable > 0 || defender.hp <= 0) return false;
    defender.hp = Math.max(0, defender.hp - amount);
    defender.stun = kind === 'melee' ? 0.16 : 0.32;
    add(defender.velocity, direction, force);
    attacker.damage += amount;
    attacker.hits++;
    this.event('hit', { player: attacker.id, target: defender.id, amount, kind, pos: { ...defender.pos } });
    return true;
  }

  action(p, target, action) {
    if (action === 'lock') { p.locked = !p.locked; return; }
    if (action === 'flight') { p.flying = !p.flying; this.event('flight', { player: p.id }); return; }
    if (p.stun > 0 || p.beamTime > 0) return;
    const aim = p.locked ? unit(sub(target.pos, p.pos)) : { x: Math.sin(p.yaw), y: 0, z: Math.cos(p.yaw) };
    if (action === 'dodge' && p.energy >= 18 && p.invulnerable <= 0) {
      p.energy -= 18;
      p.invulnerable = 0.45;
      p.dodges++;
      const sign = p.input.x < 0 ? -1 : 1;
      add(p.velocity, { x: Math.cos(p.yaw) * sign, y: 0.8, z: -Math.sin(p.yaw) * sign }, 22);
      this.event('dodge', { player: p.id, pos: { ...p.pos } });
      return;
    }
    if (p.cooldown > 0) return;
    if (action === 'melee') {
      p.combo = (this.tick - p.comboAt < 34) ? p.combo % 3 + 1 : 1;
      p.comboAt = this.tick;
      p.cooldown = 0.36;
      const gap = length(sub(target.pos, p.pos));
      if (p.locked && gap > 2.8 && gap < 5) add(p.pos, aim, Math.min(1.1, gap - 2.8));
      this.event('melee', { player: p.id, combo: p.combo });
      if (length(sub(target.pos, p.pos)) < 3.7 && dot(aim, unit(sub(target.pos, p.pos))) > 0.25) {
        const landed = this.hit(p, target, p.combo === 3 ? 23 : 12, aim, p.combo === 3 ? 19 : 1, 'melee');
        if (landed && p.combo === 3) target.velocity.y += 6;
      }
    } else if (action === 'shot' && p.energy >= 8) {
      p.energy -= 8;
      p.cooldown = 0.28;
      const pos = { ...p.pos };
      pos.y += 1.55;
      add(pos, aim, 1);
      const e = this.event('shot', { player: p.id, pos: { ...pos } });
      this.projectiles.push({ id: e.event, owner: p.id, pos, dir: aim, life: 2.4 });
    } else if (action === 'beam' && p.energy >= 42) {
      p.energy -= 42;
      p.cooldown = 1.6;
      p.beamTime = 0.8;
      p.beamDirection = aim;
      this.event('beamCharge', { player: p.id, pos: { ...p.pos } });
    }
  }

  step() {
    this.tick++;
    if (this.phase === 'countdown') {
      if (this.players.some(p => !p.connected)) return;
      this.countdown -= DT;
      if (this.countdown <= 0) {
        this.phase = 'playing';
        this.event('start');
      }
    }
    if (this.phase !== 'playing') return;
    if (this.players.some(p => !p.connected)) return;
    this.time = Math.max(0, this.time - DT);
    for (const p of this.players) {
      const target = this.players.find(other => other.id !== p.id);
      p.cooldown = Math.max(0, p.cooldown - DT);
      p.stun = Math.max(0, p.stun - DT);
      p.invulnerable = Math.max(0, p.invulnerable - DT);
      if (this.tick - p.inputAt > 15) p.input = { x: 0, z: 0, lift: 0, charge: false, boost: false };
      for (const action of p.queue.splice(0)) this.action(p, target, action);
      const input = p.input;
      if (p.locked) p.yaw = Math.atan2(target.pos.x - p.pos.x, target.pos.z - p.pos.z);
      if (p.beamTime > 0) {
        p.beamTime -= DT;
        if (p.beamTime <= 0) {
          const delta = sub(target.pos, p.pos);
          const along = dot(delta, p.beamDirection);
          const perpendicular = length(sub(delta, {
            x: p.beamDirection.x * along, y: p.beamDirection.y * along, z: p.beamDirection.z * along
          }));
          this.event('beam', { player: p.id, pos: { ...p.pos }, dir: p.beamDirection });
          if (along > 0 && along < 45 && perpendicular < 2.5) this.hit(p, target, 52, p.beamDirection, 25, 'beam');
        }
      }
      const charging = input.charge && p.stun === 0 && p.beamTime <= 0 && p.invulnerable === 0;
      const boosting = input.boost && p.energy > 0 && !charging;
      const speed = boosting ? 17 : 7;
      p.mode = p.stun > 0 ? 'hit' : p.beamTime > 0 ? 'beam' : p.invulnerable > 0 ? 'dodge' :
        charging ? 'charge' : boosting ? 'boost' : Math.abs(input.x) + Math.abs(input.z) > 0.1 ? 'move' : 'idle';
      p.energy = clamp(p.energy + (charging ? 25 : boosting ? -13 : 3) * DT, 0, 100);
      if (p.stun === 0 && p.beamTime <= 0 && !charging) {
        const magnitude = Math.max(1, Math.hypot(input.x, input.z));
        const x = input.x / magnitude, z = input.z / magnitude;
        p.pos.x += (Math.cos(p.yaw) * x + Math.sin(p.yaw) * z) * speed * DT;
        p.pos.z += (-Math.sin(p.yaw) * x + Math.cos(p.yaw) * z) * speed * DT;
        if (!p.locked && magnitude > 0 && Math.abs(x) > 0.1) p.yaw += x * DT;
        if (p.flying) p.pos.y += (input.lift * 6 + (p.pos.y < 2 ? 3 : 0)) * DT;
      }
      if (!p.flying) p.velocity.y -= 15 * DT;
      add(p.pos, p.velocity, DT);
      p.velocity.x *= 0.84; p.velocity.z *= 0.84;
      p.velocity.y *= p.flying ? 0.84 : 0.97;
      p.pos.y = clamp(p.pos.y, 0, 18);
      if (p.pos.y === 0) p.velocity.y = 0;
      const radius = Math.hypot(p.pos.x, p.pos.z);
      if (radius > 30) { p.pos.x *= 30 / radius; p.pos.z *= 30 / radius; }
    }
    for (const shot of this.projectiles) {
      const target = this.players.find(p => p.id !== shot.owner);
      const attacker = this.players.find(p => p.id === shot.owner);
      const before = { ...shot.pos };
      add(shot.pos, shot.dir, 30 * DT);
      shot.life -= DT;
      const center = { ...target.pos, y: target.pos.y + 1.55 };
      const traveled = sub(shot.pos, before);
      const t = clamp(dot(sub(center, before), traveled) / (dot(traveled, traveled) || 1), 0, 1);
      const nearest = { ...before }; add(nearest, traveled, t);
      if (length(sub(center, nearest)) < 1.2) {
        this.hit(attacker, target, 10, shot.dir, 4, 'shot');
        shot.life = 0;
      }
    }
    this.projectiles = this.projectiles.filter(p => p.life > 0);
    if (this.players.some(p => p.hp <= 0) || this.time <= 0) {
      const [a, b] = this.players;
      this.finish(a.hp === b.hp ? '' : a.hp > b.hp ? a.id : b.id, this.time <= 0 ? 'TIME' : 'KNOCKOUT');
    }
  }

  finish(winner, reason) {
    this.phase = 'result';
    this.winner = winner;
    this.reason = reason;
    this.players.forEach(p => { p.ready = false; p.queue = []; });
    this.event('result', { winner, reason, health: this.players.map(p => ({ id: p.id, hp: p.hp })) });
  }

  snapshot() {
    return {
      type: 'state', code: this.code, phase: this.phase, round: this.round, tick: this.tick,
      time: this.time, countdown: this.countdown, winner: this.winner, reason: this.reason,
      paused: ['playing', 'countdown'].includes(this.phase) && this.players.some(p => !p.connected),
      players: this.players.map(({ queue, input, beamDirection, inputAt, ...p }) => p),
      projectiles: this.projectiles, effects: this.effects
    };
  }
}
