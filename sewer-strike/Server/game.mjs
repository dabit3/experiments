export const STEP = 1 / 30;
export const HEROES = [
  { name: 'Riptide', weapon: 'Twin sabers', damage: 19, reach: 105, cooldown: 0.30, speed: 190 },
  { name: 'Cinder', weapon: 'Chain batons', damage: 15, reach: 95, cooldown: 0.23, speed: 215 },
  { name: 'Circuit', weapon: 'Volt staff', damage: 22, reach: 145, cooldown: 0.40, speed: 175 },
  { name: 'Fang', weapon: 'Twin prongs', damage: 27, reach: 80, cooldown: 0.34, speed: 200 },
];
export const SECTORS = [
  { name: 'NEON BACKSTREET', left: 80, right: 790, gate: 700 },
  { name: 'THE UNDERCURRENT', left: 790, right: 1510, gate: 1420 },
  { name: 'REACTOR ZERO', left: 1510, right: 2270, gate: 2210 },
];
const clamp = (n, a, b) => Math.max(a, Math.min(b, n));
const distance = (a, b) => Math.hypot(a.x - b.x, (a.y - b.y) * 1.6);

export class Game {
  constructor(code) {
    this.code = code;
    this.players = [];
    this.phase = 'lobby';
    this.tick = 0;
    this.match = 0;
    this.sector = 0;
    this.enemies = [];
    this.pickups = [];
    this.events = [];
    this.eventID = 0;
    this.nextID = 0;
    this.defeated = 0;
    this.elapsed = 0;
    this.waveClear = false;
    this.banner = 'ASSEMBLE YOUR CREW';
    this.startAt = 0;
  }
  addPlayer(id, name, hero) {
    if (this.players.length >= 4) throw new Error('Room full (four heroes maximum)');
    if (!Number.isInteger(hero) || !HEROES[hero]) throw new Error('Unknown hero');
    if (this.players.some(p => p.hero === hero)) throw new Error('That hero is already selected');
    if (this.phase !== 'lobby') throw new Error('Match underway — reconnect an existing hero');
    const p = {
      id, name: String(name || 'Guest').trim().slice(0, 16) || 'Guest', hero,
      connected: true, ready: false, rematch: false, x: 220 + hero * 55, y: hero % 2 ? 35 : -35,
      z: 0, vz: 0, face: 1, hp: 100, power: 50, score: 0, hits: 0, combo: 0,
      action: 'idle', actionTime: 0, attackCD: 0, comboTime: 0, invuln: 0,
      down: 0, revive: 0, seq: -1, inputAge: 0, input: { dx: 0, dy: 0 },
      actions: [], stats: { attacks: 0, jumps: 0, specials: 0, damage: 0, revives: 0, distance: 0 },
    };
    this.players.push(p);
    this.event('join', p.x, p.y, name, id);
    return p;
  }
  event(kind, x, y, text = '', player = '') {
    this.events.push({ id: ++this.eventID, tick: this.tick, kind, x, y, text, player });
    this.events = this.events.slice(-40);
  }
  input(id, message) {
    const p = this.players.find(player => player.id === id);
    if (!p || !p.connected || !Number.isSafeInteger(message.seq) || message.seq <= p.seq) return false;
    if (!Number.isFinite(message.dx) || !Number.isFinite(message.dy)) return false;
    p.seq = message.seq;
    p.inputAge = 0;
    const length = Math.max(1, Math.hypot(message.dx, message.dy));
    p.input = { dx: message.dx / length, dy: message.dy / length };
    if (['attack', 'jump', 'special'].includes(message.action) && p.actions.length < 4) p.actions.push(message.action);
    return true;
  }
  ready(id) {
    if (this.phase !== 'lobby') return;
    const p = this.players.find(player => player.id === id);
    if (p?.connected) p.ready = !p.ready;
    if (this.players.filter(player => player.connected).length >= 2 &&
        this.players.every(player => player.connected && player.ready)) this.begin();
  }
  begin() {
    this.phase = 'countdown';
    this.startAt = this.tick + 90;
    this.match++;
    this.elapsed = 0;
    this.sector = 0;
    this.defeated = 0;
    this.enemies = [];
    this.pickups = [];
    this.waveClear = false;
    this.banner = 'CREW ASSEMBLED';
    for (const p of this.players) {
      Object.assign(p, { hp: 100, power: 50, score: 0, hits: 0, x: 230 + p.hero * 45, y: p.hero % 2 ? 40 : -40,
        z: 0, vz: 0, down: 0, revive: 0, invuln: 0, attackCD: 0, comboTime: 0, combo: 0,
        action: 'idle', actionTime: 0, rematch: false, actions: [], input: { dx: 0, dy: 0 },
        stats: { attacks: 0, jumps: 0, specials: 0, damage: 0, revives: 0, distance: 0 } });
    }
    this.event('countdown', 400, 0, '3 • 2 • 1');
  }
  voteRematch(id) {
    if (!['clear', 'gameover'].includes(this.phase)) return;
    const p = this.players.find(player => player.id === id);
    if (p?.connected) p.rematch = true;
    if (this.players.filter(player => player.connected).length >= 2 &&
        this.players.filter(player => player.connected).every(player => player.rematch)) this.begin();
  }
  disconnect(id) {
    const p = this.players.find(player => player.id === id);
    if (p) { p.connected = false; p.ready = false; p.input = { dx: 0, dy: 0 }; p.actions = []; }
  }
  reconnect(id) {
    const p = this.players.find(player => player.id === id);
    if (p) { p.connected = true; p.seq = -1; p.inputAge = 0; }
    return p;
  }
  spawnSector() {
    const base = SECTORS[this.sector].left;
    const kinds = this.sector === 0 ? ['grunt', 'grunt', 'drone', 'grunt', 'brute', 'drone'] :
      this.sector === 1 ? ['drone', 'grunt', 'brute', 'drone', 'grunt', 'brute', 'grunt', 'drone'] :
        ['boss', 'drone', 'drone', 'grunt'];
    this.enemies = kinds.map((kind, i) => {
      const hp = kind === 'boss' ? 680 : kind === 'brute' ? 130 : kind === 'drone' ? 55 : 85;
      return { id: `e${++this.nextID}`, kind, x: base + 300 + (i % 4) * 95, y: (i % 3 - 1) * 65,
        hp, maxHP: hp, face: -1, action: 'walk', timer: 0.7 + i * 0.15, stun: 0, attack: 0,
        targetX: 0, targetY: 0, vx: 0 };
    });
    this.waveClear = false;
    this.banner = this.sector === 2 ? 'IRON MAW • KEEP MOVING!' : `SECTOR ${this.sector + 1} • ${SECTORS[this.sector].name}`;
    this.event('wave', base + 350, 0, this.banner);
  }
  hitEnemy(p, enemy, damage, special = false) {
    const dealt = Math.min(enemy.hp, damage);
    enemy.hp -= dealt;
    enemy.stun = enemy.kind === 'boss' ? 0.08 : 0.30;
    enemy.vx = p.face * (special ? 430 : 210);
    p.score += Math.round(dealt * 10);
    p.stats.damage += dealt;
    p.hits++;
    p.power = clamp(p.power + (special ? 0 : 5), 0, 100);
    this.event(special ? 'specialHit' : 'hit', enemy.x, enemy.y,
      special ? 'SHELLSHOCK!' : ['WHAM!', 'KRAK!', 'BAM!'][p.combo - 1] || 'KRAK!', p.id);
    if (enemy.hp <= 0) {
      this.defeated++;
      p.score += enemy.kind === 'boss' ? 5000 : 250;
      this.event('defeat', enemy.x, enemy.y, enemy.kind === 'boss' ? 'IRON MAW DOWN!' : 'KO!', p.id);
      if (this.defeated % 3 === 0) this.pickups.push({ id: `s${++this.nextID}`, x: enemy.x, y: enemy.y });
    }
  }
  attack(p, special = false) {
    if (p.attackCD > 0 || p.hp <= 0 || (special && p.power < 50)) return;
    const hero = HEROES[p.hero];
    p.combo = p.comboTime > 0 ? p.combo % 3 + 1 : 1;
    p.comboTime = 1.05;
    p.attackCD = special ? 0.85 : hero.cooldown;
    p.actionTime = special ? 0.75 : 0.28;
    p.action = special ? 'special' : p.z > 5 ? 'airkick' : 'attack';
    p.stats[special ? 'specials' : 'attacks']++;
    if (special) {
      p.power -= 50;
      p.invuln = 0.9;
      this.event('power', p.x, p.y, `${hero.name.toUpperCase()} • POWER!`, p.id);
    }
    const reach = special ? (p.hero === 2 ? 240 : 195) : hero.reach;
    for (const enemy of this.enemies.filter(e => e.hp > 0)) {
      const inFront = (enemy.x - p.x) * p.face >= -30;
      if (Math.abs(enemy.x - p.x) < reach && Math.abs(enemy.y - p.y) < (special ? 125 : 47) && (special || inFront)) {
        const bonus = p.combo === 3 ? 1.65 : 1;
        this.hitEnemy(p, enemy, special ? 75 : Math.round(hero.damage * bonus * (p.z > 5 ? 1.3 : 1)), special);
      }
    }
  }
  hurt(p, damage, enemy) {
    if (p.hp <= 0 || p.invuln > 0 || p.z > 22) return;
    p.hp = Math.max(0, p.hp - damage);
    p.invuln = 0.9;
    p.action = 'hurt';
    p.actionTime = 0.3;
    p.x = clamp(p.x + Math.sign(p.x - enemy.x || 1) * 28, SECTORS[this.sector].left, SECTORS[this.sector].right);
    this.event('hurt', p.x, p.y, `−${damage}`, p.id);
    if (!p.hp) { p.down = 18; p.revive = 0; this.event('down', p.x, p.y, 'STAY CLOSE TO REVIVE', p.id); }
  }
  updateEnemy(e, active) {
    e.stun = Math.max(0, e.stun - STEP);
    e.x = clamp(e.x + e.vx * STEP, SECTORS[this.sector].left + 10, SECTORS[this.sector].right - 10);
    e.vx *= 0.78;
    if (e.stun > 0 || !active.length) return;
    e.timer -= STEP;
    if (e.action === 'windup') {
      if (e.timer <= 0) {
        e.action = 'strike';
        e.timer = 0.38;
        e.attack++;
        const radius = e.kind === 'boss' ? 145 : e.kind === 'brute' ? 95 : 65;
        for (const p of active) if (distance(p, { x: e.targetX, y: e.targetY }) < radius) {
          this.hurt(p, e.kind === 'boss' ? 26 : e.kind === 'brute' ? 18 : 10, e);
        }
        this.event('slam', e.targetX, e.targetY, e.kind === 'boss' ? 'CRASH!' : '', e.id);
      }
      return;
    }
    if (e.action === 'strike') {
      if (e.timer <= 0) { e.action = 'walk'; e.timer = e.kind === 'boss' ? 1 : 0.6; }
      return;
    }
    const target = [...active].sort((a, b) => distance(a, e) - distance(b, e))[0];
    e.face = target.x > e.x ? 1 : -1;
    if (distance(target, e) < (e.kind === 'boss' ? 180 : 80) && e.timer <= 0) {
      e.action = 'windup';
      e.timer = e.kind === 'boss' ? 1.15 : 0.65;
      e.targetX = target.x;
      e.targetY = target.y;
      return;
    }
    const dx = target.x - e.x, dy = target.y - e.y;
    const length = Math.max(1, Math.hypot(dx, dy));
    const speed = e.kind === 'drone' ? 110 : e.kind === 'boss' ? 65 : 76;
    if (distance(target, e) > 55) { e.x += dx / length * speed * STEP; e.y += dy / length * speed * STEP; }
  }
  update() {
    this.tick++;
    if (this.phase === 'countdown' && this.tick >= this.startAt) { this.phase = 'playing'; this.spawnSector(); }
    if (this.phase !== 'playing') return;
    if (!this.players.some(p => p.connected)) return;
    this.elapsed += STEP;
    for (const p of this.players) {
      p.inputAge += STEP;
      p.attackCD = Math.max(0, p.attackCD - STEP);
      p.comboTime = Math.max(0, p.comboTime - STEP);
      p.invuln = Math.max(0, p.invuln - STEP);
      p.actionTime = Math.max(0, p.actionTime - STEP);
      if (!p.connected) continue;
      if (!p.hp) {
        const helper = this.players.find(q => q.id !== p.id && q.connected && q.hp > 0 && distance(p, q) < 95);
        p.revive = helper ? p.revive + STEP : Math.max(0, p.revive - STEP);
        p.down = Math.max(0, p.down - STEP);
        if (p.revive >= 2.5 || p.down <= 0) {
          p.hp = 50; p.invuln = 3; p.down = 0; p.revive = 0;
          if (helper) helper.stats.revives++;
          this.event('revive', p.x, p.y, helper ? 'TEAM REVIVE!' : 'BACK IN THE FIGHT!', p.id);
        }
        continue;
      }
      if (p.inputAge > 0.35) p.input = { dx: 0, dy: 0 };
      const dx = p.input.dx * HEROES[p.hero].speed * STEP;
      const dy = p.input.dy * HEROES[p.hero].speed * STEP * 0.7;
      p.stats.distance += Math.hypot(dx, dy);
      p.x = clamp(p.x + dx, SECTORS[this.sector].left, SECTORS[this.sector].right);
      p.y = clamp(p.y + dy, -105, 105);
      if (Math.abs(p.input.dx) > 0.05) p.face = Math.sign(p.input.dx);
      if (p.z > 0 || p.vz > 0) { p.z = Math.max(0, p.z + p.vz * STEP); p.vz -= 580 * STEP; if (p.z === 0) p.vz = 0; }
      for (const action of p.actions.splice(0)) {
        if (action === 'jump' && p.z === 0) { p.vz = 300; p.stats.jumps++; this.event('jump', p.x, p.y, '', p.id); }
        if (action === 'attack') this.attack(p);
        if (action === 'special') this.attack(p, true);
      }
      if (!p.actionTime) p.action = p.z > 0 ? 'jump' : Math.abs(dx) + Math.abs(dy) > 0.1 ? 'walk' : 'idle';
      const slice = this.pickups.find(s => distance(s, p) < 48 && p.hp < 100);
      if (slice) {
        p.hp = Math.min(100, p.hp + 35);
        this.pickups = this.pickups.filter(s => s !== slice);
        this.event('heal', p.x, p.y, '+35 • SLICE!', p.id);
      }
    }
    const active = this.players.filter(p => p.hp > 0 && p.connected);
    for (const e of this.enemies.filter(e => e.hp > 0)) this.updateEnemy(e, active);
    this.enemies = this.enemies.filter(e => e.hp > 0);
    if (!active.length && this.players.some(p => p.connected)) {
      this.phase = 'gameover'; this.banner = 'CREW DOWN • TRY AGAIN'; this.event('gameover', 0, 0, this.banner); return;
    }
    if (!this.enemies.length && !this.waveClear) {
      this.waveClear = true;
      this.banner = this.sector === 2 ? 'STAGE CLEAR • CITY SAVED!' : 'AREA CLEAR • MOVE RIGHT →';
      this.event('gate', SECTORS[this.sector].gate, 0, this.banner);
      if (this.sector === 2) { this.phase = 'clear'; this.event('clear', 1850, 0, this.banner); }
    }
    if (this.waveClear && this.sector < 2 && active.every(p => p.x >= SECTORS[this.sector].gate)) {
      this.sector++;
      for (const p of this.players) { p.x = SECTORS[this.sector].left + 80 + p.hero * 30; p.hp = Math.min(100, p.hp + 20); }
      this.spawnSector();
    }
  }
  snapshot() {
    return { type: 'state', code: this.code, tick: this.tick, match: this.match, phase: this.phase,
      sector: this.sector, sectorName: SECTORS[this.sector].name, gate: SECTORS[this.sector].gate,
      startAt: this.startAt, elapsed: this.elapsed, banner: this.banner, defeated: this.defeated,
      waveClear: this.waveClear, players: this.players.map(({ input, inputAge, actions, ...p }) => p),
      enemies: this.enemies, pickups: this.pickups, events: this.events };
  }
}
