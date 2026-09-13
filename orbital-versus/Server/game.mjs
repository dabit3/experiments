export const DT = 1 / 30;
export const LIMIT = 44;
export const clamp = (value, min, max) => Math.max(min, Math.min(max, value));
export const distance = (a, b) => Math.hypot(a.x - b.x, a.y - b.y, a.z - b.z);
const neutral = () => ({ x: 0, z: 0, boost: false, guard: false });

export function makeUnit(id, name, team, ai = false) {
  return {
    id, name, team, ai, cost: ai ? 1500 : 2000, maxHP: ai ? 360 : 520,
    hp: ai ? 360 : 520, x: team ? 23 : -23, z: ai ? 12 : -3, y: 0,
    yaw: team ? -Math.PI / 2 : Math.PI / 2, boost: 100, ammo: 7,
    burst: 0, overdrive: 0, cool: 0, reload: 0, melee: 0, combo: 0,
    dodge: 0, invulnerable: 0, respawn: 0, overheated: false,
    target: "", input: neutral(), seq: -1, damage: 0, kills: 0,
    shots: 0, swings: 0, steps: 0, flight: 0, blocking: false,
    connected: true, lastInput: 0, pending: []
  };
}

export class Arena {
  constructor(code, duration = 90) {
    this.code = code;
    this.phase = "lobby";
    this.round = 0;
    this.tick = 0;
    this.time = duration;
    this.duration = duration;
    this.countdown = 0;
    this.costs = [6000, 6000];
    this.units = [];
    this.projectiles = [];
    this.events = [];
    this.eventID = 0;
    this.projectileID = 0;
    this.winner = -1;
    this.reason = "";
    this.ready = new Set();
    this.rematch = new Set();
  }
  emit(kind, unit, extra = {}) {
    this.events.push({ id: ++this.eventID, kind, unit: unit.id, x: unit.x, y: unit.y + 2, z: unit.z, ...extra });
    this.events = this.events.slice(-32);
  }
  add(id, name) {
    if (this.units.filter(unit => !unit.ai).length >= 2) throw new Error("Room is full");
    const team = this.units.filter(unit => !unit.ai).length;
    const unit = makeUnit(id, name, team);
    this.units.push(unit, makeUnit(`wing-${team}`, `AI ${team ? "EMBER" : "NOVA"}`, team, true));
    return unit;
  }
  vote(id, rematch = false) {
    const human = this.units.find(unit => unit.id === id && !unit.ai && unit.connected);
    if (!human || this.phase !== (rematch ? "result" : "lobby")) return;
    (rematch ? this.rematch : this.ready).add(id);
    if (this.units.filter(unit => !unit.ai && unit.connected).length === 2 &&
      (rematch ? this.rematch : this.ready).size === 2) this.start();
  }
  start() {
    this.round++;
    this.units = this.units.map(unit => makeUnit(unit.id, unit.name, unit.team, unit.ai));
    for (const unit of this.units) unit.target = this.units.find(enemy => enemy.team !== unit.team && !enemy.ai).id;
    this.phase = "countdown";
    this.countdown = 3;
    this.time = this.duration;
    this.costs = [6000, 6000];
    this.projectiles = [];
    this.winner = -1;
    this.reason = "";
    this.ready.clear();
    this.rematch.clear();
    this.events = [];
  }
  input(id, msg) {
    const unit = this.units.find(value => value.id === id);
    if (!unit || unit.ai || !unit.connected || !Number.isSafeInteger(msg.seq) || msg.seq <= unit.seq) return false;
    if (!Number.isFinite(msg.x) || !Number.isFinite(msg.z)) return false;
    unit.seq = msg.seq;
    const norm = Math.max(1, Math.hypot(msg.x, msg.z));
    unit.input = { x: clamp(msg.x / norm, -1, 1), z: clamp(msg.z / norm, -1, 1),
      boost: msg.boost === true, guard: msg.guard === true };
    unit.lastInput = this.tick;
    if (Array.isArray(msg.actions)) {
      unit.pending.push(...msg.actions.slice(0, 4).filter(action =>
        ["fire", "melee", "dodge", "lock", "burst"].includes(action)));
      unit.pending = unit.pending.slice(0, 12);
    }
    return true;
  }
  disconnect(id) {
    const unit = this.units.find(value => value.id === id);
    if (unit) { unit.connected = false; unit.input = neutral(); unit.pending = []; }
    this.ready.delete(id);
    this.rematch.delete(id);
  }
  hit(target, attacker, damage) {
    if (target.hp <= 0 || target.invulnerable > 0 || target.dodge > 0) return;
    const amount = Math.round(damage * (attacker.overdrive > 0 ? 1.35 : 1) * (target.blocking ? 0.28 : 1));
    target.hp = Math.max(0, target.hp - amount);
    target.burst = Math.min(100, target.burst + amount * 0.16);
    attacker.burst = Math.min(100, attacker.burst + amount * 0.12);
    attacker.damage += amount;
    this.emit(target.blocking ? "guard" : "hit", target, { amount, attacker: attacker.id });
    if (!target.hp) {
      this.costs[target.team] = Math.max(0, this.costs[target.team] - target.cost);
      target.respawn = 2.5;
      target.input = neutral();
      target.pending = [];
      attacker.kills++;
      this.emit("destroy", target);
      if (!this.costs[target.team]) this.finish(1 - target.team, "TEAM COST DEPLETED");
    }
  }
  finish(winner, reason) {
    this.phase = "result";
    this.winner = winner;
    this.reason = reason;
  }
  action(unit, action) {
    if (unit.hp <= 0 || this.phase !== "playing") return;
    let target = this.units.find(enemy => enemy.id === unit.target);
    if (action === "lock") {
      const enemies = this.units.filter(enemy => enemy.team !== unit.team);
      unit.target = enemies[(enemies.findIndex(enemy => enemy.id === unit.target) + 1) % enemies.length].id;
      return;
    }
    if (action === "burst" && unit.burst >= 50 && !unit.overdrive) {
      unit.burst = 0; unit.overdrive = 7; unit.boost = 100; unit.overheated = false;
      this.emit("burst", unit); return;
    }
    if (action === "dodge" && unit.boost >= 24 && unit.dodge <= 0 && !unit.overheated) {
      unit.boost -= 24; unit.dodge = 0.24; unit.steps++; unit.cool = 0;
      const angle = target ? Math.atan2(target.x - unit.x, target.z - unit.z) : unit.yaw;
      unit.x = clamp(unit.x + Math.cos(angle) * 5, -LIMIT, LIMIT);
      unit.z = clamp(unit.z - Math.sin(angle) * 5, -LIMIT, LIMIT);
      this.emit("dodge", unit); return;
    }
    if (!target || target.hp <= 0 || unit.blocking || unit.cool > 0) return;
    if (action === "fire" && unit.ammo > 0) {
      unit.ammo--; unit.shots++; unit.cool = unit.overdrive > 0 ? 0.22 : 0.42;
      const length = Math.max(0.01, distance(unit, target));
      this.projectiles.push({ id: ++this.projectileID, owner: unit.id, team: unit.team, target: target.id,
        x: unit.x, y: unit.y + 2, z: unit.z,
        vx: (target.x - unit.x) / length * 65, vy: (target.y - unit.y) / length * 65,
        vz: (target.z - unit.z) / length * 65, life: 1.6 });
      this.emit("fire", unit);
    }
    if (action === "melee" && unit.boost >= 8 && distance(unit, target) < 19) {
      unit.boost -= 8; unit.melee = 0.38; unit.combo = unit.combo % 3 + 1; unit.swings++;
      unit.cool = 0.5;
      const length = Math.max(0.01, distance(unit, target));
      const advance = Math.min(10, Math.max(0, length - 3));
      unit.x += (target.x - unit.x) / length * advance;
      unit.z += (target.z - unit.z) / length * advance;
      unit.y += (target.y - unit.y) / length * advance;
      this.emit("saber", unit);
      if (distance(unit, target) < 5) this.hit(target, unit, unit.combo === 3 ? 105 : 70);
    }
  }
  aiInput(unit) {
    const target = this.units.find(enemy => enemy.team !== unit.team && enemy.hp > 0 && !enemy.ai) ||
      this.units.find(enemy => enemy.team !== unit.team && enemy.hp > 0);
    if (!target) return;
    unit.target = target.id;
    const angle = Math.atan2(target.x - unit.x, target.z - unit.z);
    const range = distance(unit, target);
    const strafe = Math.sin(this.tick / 45 + unit.team * 3);
    unit.input = { x: Math.sin(angle) * (range > 23 ? 0.7 : -0.15) + Math.cos(angle) * strafe * 0.4,
      z: Math.cos(angle) * (range > 23 ? 0.7 : -0.15) - Math.sin(angle) * strafe * 0.4,
      boost: this.tick % 190 < 40, guard: false };
    if (this.tick % 35 === unit.team * 5) unit.pending.push(range < 12 ? "melee" : "fire");
    if (unit.burst >= 65) unit.pending.push("burst");
  }
  step() {
    this.tick++;
    if (this.phase === "countdown") {
      this.countdown -= DT;
      if (this.countdown <= 0) this.phase = "playing";
      return;
    }
    if (this.phase !== "playing") return;
    this.time = Math.max(0, this.time - DT);
    for (const unit of this.units) {
      for (const key of ["cool", "melee", "dodge", "invulnerable", "overdrive"]) unit[key] = Math.max(0, unit[key] - DT);
      if (unit.hp <= 0) {
        unit.respawn -= DT;
        if (unit.respawn <= 0) {
          unit.hp = Math.round(unit.maxHP * Math.min(1, this.costs[unit.team] / unit.cost));
          unit.x = unit.team ? 31 : -31; unit.z = unit.ai ? 10 : -6; unit.y = 0;
          unit.boost = 100; unit.ammo = 7; unit.invulnerable = 1.8;
          this.emit("respawn", unit);
        }
        continue;
      }
      if (unit.ai) this.aiInput(unit);
      else if (this.tick - unit.lastInput > 20) unit.input = neutral();
      const input = unit.input;
      unit.blocking = input.guard && unit.boost > 0;
      const boosting = input.boost && unit.boost > 0 && !unit.overheated && !unit.blocking;
      const speed = (boosting ? 24 : 9) * (unit.overdrive > 0 ? 1.25 : 1) * (unit.blocking ? 0.2 : 1);
      unit.x = clamp(unit.x + input.x * speed * DT, -LIMIT, LIMIT);
      unit.z = clamp(unit.z + input.z * speed * DT, -LIMIT, LIMIT);
      if (boosting) {
        unit.y = Math.min(13, unit.y + 8 * DT);
        unit.boost = Math.max(0, unit.boost - 27 * DT);
        unit.flight += DT;
        if (unit.boost === 0) unit.overheated = true;
      } else {
        unit.y = Math.max(0, unit.y - 10 * DT);
        if (unit.y === 0) {
          unit.boost = Math.min(100, unit.boost + (unit.overheated ? 28 : 46) * DT);
          if (unit.boost >= 100) unit.overheated = false;
        }
      }
      if (unit.ammo < 7) {
        unit.reload += DT;
        if (unit.reload >= 1.35) { unit.ammo++; unit.reload = 0; }
      }
      const target = this.units.find(enemy => enemy.id === unit.target);
      if (target) unit.yaw = Math.atan2(target.x - unit.x, target.z - unit.z);
      const actions = unit.pending.splice(0, 4);
      for (const action of actions) this.action(unit, action);
      if (this.phase !== "playing") break;
    }
    if (this.phase !== "playing") return;
    for (const beam of this.projectiles) {
      beam.life -= DT;
      const target = this.units.find(unit => unit.id === beam.target);
      if (target && target.hp > 0 && target.dodge <= 0 && beam.life > 0.5) {
        const len = Math.hypot(target.x - beam.x, target.y + 2 - beam.y, target.z - beam.z) || 1;
        const turn = 0.035;
        beam.vx = beam.vx * (1 - turn) + (target.x - beam.x) / len * 65 * turn;
        beam.vy = beam.vy * (1 - turn) + (target.y + 2 - beam.y) / len * 65 * turn;
        beam.vz = beam.vz * (1 - turn) + (target.z - beam.z) / len * 65 * turn;
      }
      const start = { x: beam.x, y: beam.y, z: beam.z };
      beam.x += beam.vx * DT; beam.y += beam.vy * DT; beam.z += beam.vz * DT;
      for (const enemy of this.units.filter(unit => unit.team !== beam.team && unit.hp > 0)) {
        const dx = beam.x - start.x, dy = beam.y - start.y, dz = beam.z - start.z;
        const t = clamp(((enemy.x - start.x) * dx + (enemy.y + 2 - start.y) * dy +
          (enemy.z - start.z) * dz) / (dx * dx + dy * dy + dz * dz || 1), 0, 1);
        if (Math.hypot(enemy.x - start.x - t * dx, enemy.y + 2 - start.y - t * dy,
          enemy.z - start.z - t * dz) < 2.1) {
          this.hit(enemy, this.units.find(unit => unit.id === beam.owner), 65); beam.life = 0; break;
        }
      }
      if (this.phase !== "playing") break;
    }
    this.projectiles = this.projectiles.filter(beam => beam.life > 0);
    if (this.time <= 0 && this.phase === "playing") {
      const scores = [0, 1].map(team => this.costs[team] +
        this.units.filter(unit => unit.team === team).reduce((sum, unit) => sum + unit.hp, 0));
      this.finish(scores[0] === scores[1] ? -1 : scores[0] > scores[1] ? 0 : 1, "TIME LIMIT · COST + ARMOR");
    }
  }
  snapshot() {
    return { type: "state", code: this.code, phase: this.phase, round: this.round,
      tick: this.tick, time: this.time, countdown: this.countdown, costs: this.costs,
      winner: this.winner, reason: this.reason, ready: [...this.ready], rematch: [...this.rematch],
      units: this.units.map(({ input, pending, lastInput, ...unit }) => unit),
      projectiles: this.projectiles, events: this.events };
  }
}
