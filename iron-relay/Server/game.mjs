export const FPS = 60;
export const ROSTER = ['KADE', 'NYX', 'ATLAS', 'SORA'];
export const MOVES = {
  punch: { start: 9, end: 25, range: 1.8, width: 0.54, damage: 11, stun: 18 },
  cross: { start: 12, end: 32, range: 1.95, width: 0.56, damage: 15, stun: 23 },
  kick: { start: 19, end: 43, range: 2.45, width: 1.05, damage: 20, stun: 29 },
  finisher: { start: 18, end: 42, range: 2.5, width: 0.8, damage: 25, stun: 33 },
  launch: { start: 18, end: 36, range: 1.8, width: 0.48, damage: 16, stun: 40 },
};
const clamp = (n, min, max) => Math.max(min, Math.min(max, n));
export function player(id, name, team = [0, 1]) {
  return { id, name, team, online: true, ready: false, rematch: false, wins: 0,
    health: [150, 150], red: [150, 150], active: 0, x: 0, z: 0, y: 0,
    vx: 0, vz: 0, vy: 0, guard: false, stun: 0, attack: '', age: 0,
    cooldown: 0, tagCooldown: 0, tagFlash: 0, seq: -1, chain: 0, chainAt: -100,
    combo: 0, comboDamage: 0, airHits: 0, lastInput: 0, aimZ: 0, facing: 1 };
}
export class Game {
  constructor(code) {
    this.code = code;
    this.players = [];
    this.tick = 0;
    this.phase = 'lobby';
    this.round = 1;
    this.remaining = 60 * FPS;
    this.countdown = 0;
    this.winner = '';
    this.roundWinner = '';
    this.events = [];
    this.eventID = 0;
  }
  event(kind, actor = '', target = '', value = 0) {
    this.events.push({ id: ++this.eventID, tick: this.tick, kind, actor, target, value });
    if (this.events.length > 24) this.events.shift();
  }
  resetRound() {
    this.players.forEach((p, i) => Object.assign(p, { health: [150, 150], red: [150, 150],
      x: i === 0 ? -1.25 : 1.25, z: 0, y: 0, vy: 0, active: 0, guard: false,
      vx: 0, vz: 0, stun: 0, attack: '', age: 0, cooldown: 0, tagCooldown: 0,
      combo: 0, comboDamage: 0, airHits: 0, chain: 0, facing: i === 0 ? 1 : -1 }));
    this.remaining = 60 * FPS;
    this.countdown = 150;
    this.phase = 'countdown';
    this.roundWinner = '';
    this.event('round', '', '', this.round);
  }
  ready(p) {
    if (this.phase !== 'lobby') return;
    p.ready = true;
    if (this.players.length === 2 && this.players.every(peer => peer.ready && peer.online)) this.resetRound();
  }
  rematch(p) {
    if (this.phase !== 'result') return;
    p.rematch = true;
    if (this.players.every(peer => peer.rematch && peer.online)) {
      this.players.forEach(peer => { peer.wins = 0; peer.rematch = false; });
      this.round = 1;
      this.winner = '';
      this.resetRound();
      this.event('rematch');
    }
  }
  input(p, data) {
    if (!Number.isSafeInteger(data.seq) || data.seq <= p.seq) return;
    p.seq = data.seq;
    if (this.phase !== 'fight' || !this.players.every(peer => peer.online)) return;
    p.lastInput = this.tick;
    if (data.action === 'move') {
      if (!Number.isFinite(data.x) || !Number.isFinite(data.z)) return;
      p.vx = clamp(data.x, -1, 1);
      p.vz = clamp(data.z, -1, 1);
    } else if (data.action === 'guard') {
      p.guard = data.down === true;
    } else if (data.action === 'tag') {
      const relay = p.attack === 'launch' && p.age >= MOVES.launch.start;
      if (p.tagCooldown || p.stun || p.y > 0 || (p.attack && !relay)) return;
      p.active = 1 - p.active;
      p.tagCooldown = 240;
      p.tagFlash = 40;
      p.cooldown = relay ? 8 : 24;
      p.attack = '';
      p.guard = false;
      this.event('tag', p.id);
    } else if (['punch', 'kick', 'launch'].includes(data.action)) {
      if (p.stun || p.cooldown || p.y > 0 || p.attack) return;
      let move = data.action;
      if (this.tick - p.chainAt > 75) p.chain = 0;
      if (move === 'punch') {
        move = p.chain === 1 ? 'cross' : 'punch';
        p.chain = move === 'cross' ? 2 : 1;
      } else {
        if (move === 'kick' && p.chain === 2) move = 'finisher';
        p.chain = 0;
      }
      p.attack = move;
      p.age = 0;
      p.aimZ = this.players.find(peer => peer !== p)?.z ?? 0;
      p.chainAt = this.tick;
      p.guard = false;
      this.event('attack', p.id, '', Object.keys(MOVES).indexOf(move));
    }
  }
  hit(p, target) {
    const move = MOVES[p.attack];
    if (Math.abs(p.x - target.x) > move.range || Math.abs(p.aimZ - target.z) > move.width) return;
    if (target.y > 2.8 || (target.y > 0 && target.airHits >= 3)) return;
    if (target.guard && target.y === 0 && !target.attack) {
      target.health[target.active] = Math.max(1, target.health[target.active] - 2);
      target.stun = 9;
      p.cooldown = 10;
      this.event('block', p.id, target.id, 2);
      return;
    }
    const aerial = target.y > 0;
    const style = p.team[p.active] === 2 ? 1.12 : p.team[p.active] === 1 ? 0.96 : 1;
    const damage = Math.round(move.damage * style * (aerial ? 0.72 : 1));
    target.health[target.active] = Math.max(0, target.health[target.active] - damage);
    target.red[target.active] = Math.max(target.health[target.active], target.red[target.active] - damage * 0.55);
    target.stun = move.stun;
    target.attack = '';
    target.cooldown = move.stun;
    p.combo += 1;
    p.comboDamage += damage;
    if (p.attack === 'launch' && !aerial) {
      target.y = 0.05;
      target.vy = 0.205;
      target.airHits = 0;
      this.event('launch', p.id, target.id, damage);
    } else {
      if (aerial) {
        target.vy = 0.10;
        target.airHits += 1;
      }
      this.event(aerial ? 'juggle' : 'hit', p.id, target.id, damage);
    }
    const push = p.attack === 'finisher' ? 0.6 : 0.15;
    target.x = clamp(target.x + p.facing * push, -4.4, 4.4);
    if (Math.abs(target.x) >= 4.4) this.event('wall', p.id, target.id);
    if (target.health[target.active] <= 0) this.endRound(p);
  }
  endRound(winner) {
    if (this.phase !== 'fight') return;
    this.roundWinner = winner?.id ?? 'draw';
    if (winner) winner.wins++;
    this.phase = 'roundEnd';
    this.countdown = 180;
    this.event('ko', winner?.id ?? '');
  }
  step() {
    this.tick++;
    if (this.players.length !== 2 || !this.players.every(p => p.online)) return;
    if (this.phase === 'countdown' || this.phase === 'roundEnd') {
      if (--this.countdown > 0) return;
      if (this.phase === 'countdown') {
        this.phase = 'fight';
        this.event('fight');
      } else {
        const winner = this.players.find(p => p.wins >= 2);
        if (winner) {
          this.phase = 'result';
          this.winner = winner.id;
          this.event('victory', winner.id);
        } else {
          this.round++;
          this.resetRound();
        }
      }
      return;
    }
    if (this.phase !== 'fight') return;
    if (--this.remaining <= 0) {
      const [a, b] = this.players;
      const ha = a.health.reduce((x, y) => x + y, 0);
      const hb = b.health.reduce((x, y) => x + y, 0);
      this.endRound(ha === hb ? null : ha > hb ? a : b);
      return;
    }
    for (const p of this.players) {
      const opponent = this.players.find(peer => peer !== p);
      if (p.cooldown > 0) p.cooldown--;
      if (p.stun > 0) p.stun--;
      if (p.tagCooldown > 0) p.tagCooldown--;
      if (p.tagFlash > 0) p.tagFlash--;
      if (this.tick - p.lastInput > 24) { p.vx = 0; p.vz = 0; p.guard = false; }
      if (p.y > 0) {
        p.y = Math.max(0, p.y + p.vy);
        p.vy -= 0.009;
        if (p.y === 0) { p.vy = 0; p.stun = 18; p.airHits = 0; this.event('land', p.id); }
      }
      if (!p.stun && p.y === 0) {
        p.facing = opponent.x > p.x ? 1 : -1;
        if (!p.attack && !p.cooldown) {
          const speed = p.guard ? 0.012 : 0.045;
          const next = clamp(p.x + p.vx * speed, -4.4, 4.4);
          if (Math.abs(next - opponent.x) > 0.85 || Math.abs(p.z - opponent.z) > 0.8) p.x = next;
          p.z = clamp(p.z + p.vz * speed, -2.0, 2.0);
        }
      }
      const rest = 1 - p.active;
      p.health[rest] = Math.min(p.red[rest], p.health[rest] + 0.04);
      if (!opponent.stun && opponent.y === 0) { p.combo = 0; p.comboDamage = 0; }
      if (p.attack) {
        const move = MOVES[p.attack];
        if (++p.age === move.start) this.hit(p, opponent);
        if (this.phase !== 'fight') break;
        if (p.age >= move.end) { p.attack = ''; p.age = 0; }
      }
    }
  }
  snapshot() {
    return { type: 'state', code: this.code, tick: this.tick, phase: this.phase,
      paused: this.players.some(p => !p.online), round: this.round, remaining: this.remaining,
      countdown: this.countdown, winner: this.winner, roundWinner: this.roundWinner,
      players: this.players, events: this.events };
  }
}
