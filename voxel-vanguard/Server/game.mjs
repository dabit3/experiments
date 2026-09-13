export const DT = 0.05;
export const AREAS = [
  { x: 0, z: 0, w: 18, d: 16 },
  { x: 12, z: 0, w: 6, d: 4 },
  { x: 24, z: 0, w: 18, d: 16 },
  { x: 36, z: 0, w: 6, d: 4 },
  { x: 48, z: 0, w: 18, d: 18 },
];
export const BLOCKS = [
  { x: -2, z: -3, w: 2, d: 2 }, { x: 3, z: 4, w: 2, d: 2 },
  { x: 21, z: 3, w: 2, d: 2 }, { x: 26, z: -3, w: 2, d: 2 },
  { x: 43, z: -5, w: 2, d: 2 }, { x: 52, z: 5, w: 2, d: 2 },
];
const dist = (a, b) => Math.hypot(a.x - b.x, a.z - b.z);
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));
export function walkable(x, z, stage = 3) {
  if (!AREAS.some(a => Math.abs(x - a.x) <= a.w / 2 &&
    Math.abs(z - a.z) <= a.d / 2 - 0.35)) return false;
  if (stage === 1 && x > 8.5 || stage === 2 && x > 32.5) return false;
  return !BLOCKS.some(b => Math.abs(x - b.x) < b.w / 2 + 0.3 &&
    Math.abs(z - b.z) < b.d / 2 + 0.3);
}
export class Game {
  constructor(code) {
    this.code = code;
    this.players = [];
    this.phase = 'lobby';
    this.stage = 1;
    this.tick = 0;
    this.round = 0;
    this.enemies = [];
    this.loot = [];
    this.projectiles = [];
    this.events = [];
    this.counter = 0;
    this.completedStages = 0;
    this.objective = 'Two heroes. One expedition.';
  }
  event(kind, x, z, text = '') {
    this.events.push({ id: ++this.counter, kind, x, z, text, tick: this.tick });
  }
  add(id, name) {
    if (this.players.length >= 2 || this.phase !== 'lobby') return null;
    const slot = this.players.some(p => p.slot === 0) ? 1 : 0;
    const p = {
      id, name: name.slice(0, 16), slot, connected: true,
      ready: false, x: -6, z: this.players.length * 2 - 1, hp: 100,
      maxHP: 100, angle: 0, score: 0, gems: 0, kills: 0, charge: 0,
      weapon: 'iron', bow: 'oak', armor: 'scout', down: false, revive: 0,
      attack: 0, shot: 0, dodge: 0, potion: 0, invincible: 0,
      seq: -1, input: { x: 0, z: 0 }, action: 'idle', actionUntil: 0,
      lastInput: 0, stats: { melee: 0, ranged: 0, dodge: 0, heal: 0, revive: 0, hits: 0, equipment: 0 },
    };
    this.players.push(p);
    return p;
  }
  reset() {
    this.phase = 'playing';
    this.stage = 1;
    this.round++;
    this.startedTick = this.tick;
    this.completedStages = 0;
    this.enemies = []; this.loot = []; this.projectiles = [];
    for (const p of this.players) {
      Object.assign(p, { hp: 100, maxHP: 100, x: -6, z: p.slot * 2 - 1,
        down: false, ready: false, score: 0, gems: 0, kills: 0, charge: 0,
        weapon: 'iron', bow: 'oak', armor: 'scout', revive: 0, potion: 0,
        input: { x: 0, z: 0 }, attack: 0, shot: 0, dodge: 0, invincible: 0 });
      p.stats = { melee: 0, ranged: 0, dodge: 0, heal: 0, revive: 0, hits: 0, equipment: 0 };
    }
    this.spawnStage();
    this.event('start', -6, 0, 'The Hollowwood calls');
  }
  ready(id) {
    if (!['lobby', 'victory', 'defeat'].includes(this.phase)) return;
    const p = this.players.find(p => p.id === id);
    if (!p) return;
    p.ready = !p.ready;
    if (this.players.length === 2 && this.players.every(p => p.ready && p.connected)) this.reset();
  }
  spawnStage() {
    const center = (this.stage - 1) * 24;
    const specs = this.stage === 1 ? ['husk', 'husk', 'archer', 'husk', 'brute']
      : this.stage === 2 ? ['archer', 'brute', 'husk', 'archer', 'husk', 'brute']
        : ['boss', 'husk', 'archer'];
    this.enemies = specs.map((kind, i) => ({
      id: `e${++this.counter}`, kind, x: center + 2 + i % 3 * 1.8,
      z: (i % 2 ? -1 : 1) * (2 + Math.floor(i / 3) * 2),
      hp: kind === 'boss' ? 650 : kind === 'brute' ? 125 : kind === 'archer' ? 58 : 72,
      maxHP: kind === 'boss' ? 650 : kind === 'brute' ? 125 : kind === 'archer' ? 58 : 72,
      attack: this.tick + 25 + i * 5, angle: 0, action: 'idle', telegraph: 0,
    }));
    this.objective = ['Clear the Mossgate • 5 guardians', 'Cross the bridge • Break the crypt seal',
      'Defeat the Hollow Warden'][this.stage - 1];
  }
  move(entity, x, z, speed) {
    const mag = Math.hypot(x, z);
    if (mag > 1) { x /= mag; z /= mag; }
    const nx = entity.x + x * speed * DT, nz = entity.z + z * speed * DT;
    const openStage = this.stage + (this.completedStages === this.stage ? 1 : 0);
    if (walkable(nx, entity.z, openStage)) entity.x = nx;
    if (walkable(entity.x, nz, openStage)) entity.z = nz;
    if (mag > 0.05) entity.angle = Math.atan2(x, z);
  }
  input(id, message) {
    const p = this.players.find(p => p.id === id);
    if (!p || !p.connected || this.phase !== 'playing' || !Number.isSafeInteger(message.seq) ||
      message.seq <= p.seq) return false;
    p.seq = message.seq;
    const x = Number(message.x), z = Number(message.z);
    if (!Number.isFinite(x) || !Number.isFinite(z)) return false;
    p.input = { x: clamp(x, -1, 1), z: clamp(z, -1, 1) };
    p.lastInput = this.tick;
    if (!p.down && typeof message.action === 'string') this.action(p, message.action, message.choice);
    return true;
  }
  damage(enemy, amount, p) {
    if (enemy.hp <= 0) return;
    enemy.hp = Math.max(0, enemy.hp - amount);
    p.stats.hits++;
    p.score += amount * 2;
    p.charge = Math.min(100, p.charge + 3);
    this.event('hit', enemy.x, enemy.z, `${amount}`);
    if (!enemy.hp) {
      p.kills++; p.score += enemy.kind === 'boss' ? 1000 : 100;
      this.event('burst', enemy.x, enemy.z);
      this.loot.push({ id: `l${++this.counter}`, kind: 'gem', x: enemy.x, z: enemy.z });
    }
  }
  hurt(p, amount) {
    if (p.down || p.invincible > this.tick) return;
    p.hp = Math.max(0, p.hp - (p.armor === 'guardian' ? Math.ceil(amount * 0.65) : amount));
    p.invincible = this.tick + 10;
    this.event('hurt', p.x, p.z);
    if (!p.hp) {
      p.down = true; p.revive = 0;
      this.event('down', p.x, p.z, `${p.name} needs revival`);
    }
  }
  action(p, action, choice) {
    const nearby = this.enemies.filter(e => e.hp > 0).sort((a, b) => dist(p, a) - dist(p, b));
    const target = nearby[0];
    if (action === 'melee' && p.attack <= this.tick) {
      p.attack = this.tick + (p.weapon === 'storm' ? 8 : 11);
      p.action = 'melee'; p.actionUntil = this.tick + 6; p.stats.melee++;
      if (target) p.angle = Math.atan2(target.x - p.x, target.z - p.z);
      this.event('slash', p.x, p.z);
      for (const e of nearby) if (dist(p, e) < (e.kind === 'boss' ? 3.2 : 2.5)) {
        this.damage(e, p.weapon === 'cleaver' ? 36 : p.weapon === 'storm' ? 24 : 22, p);
      }
    }
    if (action === 'ranged' && p.shot <= this.tick) {
      p.shot = this.tick + (p.bow === 'swift' ? 11 : 18);
      p.action = 'ranged'; p.actionUntil = this.tick + 6; p.stats.ranged++;
      const angle = target ? Math.atan2(target.x - p.x, target.z - p.z) : p.angle;
      p.angle = angle;
      this.projectiles.push({ id: `a${++this.counter}`, owner: p.id, x: p.x, z: p.z,
        vx: Math.sin(angle) * 15, vz: Math.cos(angle) * 15, life: 28, damage: p.bow === 'ember' ? 38 : 24 });
      this.event('bow', p.x, p.z);
    }
    if (action === 'dodge' && p.dodge <= this.tick) {
      p.dodge = this.tick + 44; p.invincible = this.tick + 9; p.rollUntil = this.tick + 7;
      p.rollX = Math.hypot(p.input.x, p.input.z) > 0.1 ? p.input.x : Math.sin(p.angle);
      p.rollZ = Math.hypot(p.input.x, p.input.z) > 0.1 ? p.input.z : Math.cos(p.angle);
      p.action = 'dodge'; p.actionUntil = this.tick + 7; p.stats.dodge++;
      this.event('dodge', p.x, p.z);
    }
    if (action === 'heal' && p.potion <= this.tick && p.hp < p.maxHP) {
      p.hp = Math.min(p.maxHP, p.hp + 48); p.potion = this.tick + 300; p.stats.heal++;
      this.event('heal', p.x, p.z, '+48');
    }
    if (action === 'artifact' && p.charge >= 100) {
      p.charge = 0; this.event('artifact', p.x, p.z, 'THUNDER RELIC');
      for (const e of nearby) if (dist(p, e) < 8) this.damage(e, 80, p);
    }
    if (action === 'revive') p.revivingUntil = this.tick + 5;
    if (action === 'equip' && ['cleaver', 'storm', 'swift', 'ember', 'guardian'].includes(choice)) {
      const chest = this.loot.find(l => l.kind === 'chest' && dist(p, l) < 3 && !l.claimed.includes(p.id));
      if (!chest) return;
      chest.claimed.push(p.id);
      if (['cleaver', 'storm'].includes(choice)) p.weapon = choice;
      if (['swift', 'ember'].includes(choice)) p.bow = choice;
      if (choice === 'guardian') { p.armor = choice; p.maxHP = 120; p.hp = Math.min(120, p.hp + 20); }
      p.stats.equipment++;
      this.event('equip', p.x, p.z, choice.toUpperCase());
    }
  }
  update() {
    this.tick++;
    this.events = this.events.filter(e => this.tick - e.tick < 30);
    if (this.phase !== 'playing' || !this.players.every(p => p.connected)) return;
    for (const p of this.players) {
      if (p.down) {
        const help = this.players.find(q => q.id !== p.id && !q.down && dist(p, q) < 2.8 &&
          q.revivingUntil >= this.tick);
        p.revive = help ? p.revive + DT / 2.5 : Math.max(0, p.revive - DT / 5);
        if (p.revive >= 1) {
          p.hp = 55; p.down = false; p.revive = 0; p.invincible = this.tick + 50;
          help.stats.revive++; this.event('heal', p.x, p.z, 'REVIVED');
        }
        continue;
      }
      if (this.tick - p.lastInput > 8) p.input = { x: 0, z: 0 };
      if (p.rollUntil > this.tick) this.move(p, p.rollX, p.rollZ, 13);
      else this.move(p, p.input.x, p.input.z, 4.6);
      if (p.actionUntil < this.tick) p.action = Math.hypot(p.input.x, p.input.z) > 0.05 ? 'walk' : 'idle';
      for (const l of this.loot) if (l.kind === 'gem' && !l.taken && dist(p, l) < 1.5) {
        l.taken = true; p.gems += 5; p.score += 50; p.charge = Math.min(100, p.charge + 18);
        this.event('gem', p.x, p.z, '+5');
      }
    }
    this.loot = this.loot.filter(l => !l.taken);
    for (const e of this.enemies) {
      if (e.hp <= 0) continue;
      const targets = this.players.filter(p => !p.down).sort((a, b) => dist(e, a) - dist(e, b));
      const p = targets[0];
      if (!p) continue;
      if (dist(e, p) > 17) continue;
      if (e.telegraph > 0) {
        if (this.tick >= e.telegraph) {
          for (const hero of this.players) if (dist(e, hero) < 5) this.hurt(hero, 30);
          this.event('slam', e.x, e.z); e.telegraph = 0; e.attack = this.tick + 65;
        }
        continue;
      }
      const range = e.kind === 'archer' ? 7 : e.kind === 'boss' ? 3.4 : 1.7;
      if (dist(e, p) > range) {
        let dx = p.x - e.x, dz = p.z - e.z;
        const m = Math.hypot(dx, dz); dx /= m; dz /= m;
        const old = { x: e.x, z: e.z };
        this.move(e, dx, dz, e.kind === 'boss' ? 1.7 : 2.1);
        if (dist(old, e) < 0.02) this.move(e, -dz, dx, 2.1);
        e.action = 'walk';
      } else {
        e.action = 'idle';
        if (this.tick >= e.attack) {
          e.angle = Math.atan2(p.x - e.x, p.z - e.z);
          if (e.kind === 'boss') {
            e.telegraph = this.tick + 28;
            this.event('warning', e.x, e.z, 'WARDEN SLAM');
          } else if (e.kind === 'archer') {
            this.projectiles.push({ id: `a${++this.counter}`, owner: e.id, x: e.x, z: e.z,
              vx: Math.sin(e.angle) * 8, vz: Math.cos(e.angle) * 8, life: 40, damage: 9 });
          } else {
            this.hurt(p, e.kind === 'brute' ? 14 : 9);
            this.event('claw', e.x, e.z);
          }
          e.attack = this.tick + (e.kind === 'archer' ? 45 : 28);
        }
      }
    }
    for (const a of this.projectiles) {
      a.x += a.vx * DT; a.z += a.vz * DT; a.life--;
      if (!walkable(a.x, a.z, this.stage + (this.completedStages === this.stage ? 1 : 0))) {
        a.life = 0; continue;
      }
      const owner = this.players.find(p => p.id === a.owner);
      if (owner) {
        const e = this.enemies.find(e => e.hp > 0 && dist(e, a) < (e.kind === 'boss' ? 1.5 : 0.85));
        if (e) { this.damage(e, a.damage, owner); a.life = 0; }
      } else {
        const p = this.players.find(p => !p.down && dist(p, a) < 0.7);
        if (p) { this.hurt(p, a.damage); a.life = 0; }
      }
    }
    this.projectiles = this.projectiles.filter(a => a.life > 0);
    if (this.players.every(p => p.down)) {
      this.phase = 'defeat'; this.objective = 'The expedition fell. Rise together.';
      this.event('defeat', 0, 0); return;
    }
    if (this.enemies.every(e => e.hp <= 0)) {
      if (this.completedStages < this.stage) {
        this.completedStages = this.stage;
        this.loot.push({ id: `c${++this.counter}`, kind: 'chest', x: (this.stage - 1) * 24 + 6, z: 0, claimed: [] });
        this.event('clear', (this.stage - 1) * 24 + 6, 0, 'SEAL BROKEN');
        if (this.stage === 3) {
          this.phase = 'victory'; this.objective = 'Hollowwood restored';
          this.event('victory', 48, 0); return;
        }
        this.objective = 'Claim a gear card • Follow the golden trail';
      }
      // The completed seal opens the gate; the next encounter activates beyond the bridge.
      const nextX = this.stage * 24 - 6;
      if (this.players.some(p => p.x > nextX)) {
        this.stage++; this.spawnStage();
      }
    }
  }
  snapshot() {
    return {
      type: 'state', code: this.code, phase: this.phase, stage: this.stage, round: this.round,
      tick: this.tick, completedStages: this.completedStages, objective: this.objective,
      paused: this.phase === 'playing' && !this.players.every(p => p.connected),
      players: this.players, enemies: this.enemies.filter(e => e.hp > 0),
      loot: this.loot, projectiles: this.projectiles, events: this.events,
    };
  }
}
