export const HZ = 60;
export const FIGHTERS = {
  rook: { name: 'ROOK', speed: 245, power: 1, special: 'flame', color: '#ff8e3c' },
  vesper: { name: 'VESPER', speed: 270, power: 0.92, special: 'rush', color: '#c68cff' },
  atlas: { name: 'ATLAS', speed: 215, power: 1.18, special: 'upper', color: '#61e6e9' },
  sora: { name: 'SORA', speed: 285, power: 0.9, special: 'upper', color: '#ff5669' },
  kestrel: { name: 'KESTREL', speed: 250, power: 0.96, special: 'flame', color: '#69b9ff' },
  jin: { name: 'JIN', speed: 230, power: 1.12, special: 'rush', color: '#ffcc63' },
};
export const MOVES = {
  punch: { startup: 5, active: 4, recovery: 11, range: 125, damage: 5, stun: 14 },
  kick: { startup: 8, active: 5, recovery: 17, range: 165, damage: 8, stun: 18 },
  heavyPunch: { startup: 11, active: 5, recovery: 20, range: 143, damage: 11, stun: 22 },
  heavyKick: { startup: 14, active: 6, recovery: 23, range: 185, damage: 14, stun: 25 },
  special: { startup: 12, active: 12, recovery: 25, range: 175, damage: 17, stun: 27 },
  super: { startup: 15, active: 16, recovery: 30, range: 230, damage: 36, stun: 42 },
};
const clamp = (value, low, high) => Math.max(low, Math.min(high, value));
export const validRoster = (roster) => Array.isArray(roster) && roster.length === 3
  && new Set(roster).size === 3 && roster.every((key) => Object.hasOwn(FIGHTERS, key));

export function makePeer(id, name, roster) {
  return {
    id, name, roster: roster.map((fighter) => ({ fighter, hp: 100 })),
    connected: true, ready: false, active: 0, meter: 0, x: 0, y: 0, vy: 0,
    face: 1, pose: 'idle', guard: 100, guarding: false, crouch: false,
    combo: 0, comboUntil: 0, stun: 0, roll: 0, attack: null, ack: -1,
    queue: [], held: { move: 0, guard: false, crouch: false, run: false },
    inputTick: 0, rematch: false, damage: 0, knockouts: 0,
  };
}

export class Match {
  constructor(code, emit = () => {}) {
    this.code = code;
    this.peers = [];
    this.phase = 'lobby';
    this.tick = 0;
    this.round = 1;
    this.match = 1;
    this.timer = 60 * HZ;
    this.wait = 0;
    this.winner = '';
    this.projectiles = [];
    this.events = [];
    this.eventID = 0;
    this.emit = emit;
  }

  event(kind, data = {}) {
    const event = { id: ++this.eventID, tick: this.tick, kind, ...data };
    this.events.push(event);
    if (this.events.length > 40) this.events.shift();
    this.emit({ room: this.code, match: this.match, ...event });
  }

  join(peer) {
    if (this.peers.length >= 2) return false;
    this.peers.push(peer);
    this.resetPositions();
    this.event('joined', { player: peer.id, name: peer.name });
    return true;
  }

  resetPositions() {
    this.projectiles = [];
    this.peers.forEach((peer, index) => {
      Object.assign(peer, {
        x: index === 0 ? 370 : 910, y: 0, vy: 0, face: index === 0 ? 1 : -1,
        pose: 'idle', stun: 0, roll: 0, attack: null, guard: 100, guarding: false,
        combo: 0, queue: [], held: { move: 0, guard: false, crouch: false, run: false },
      });
    });
  }

  ready(peer, roster) {
    if (this.phase !== 'lobby' || !validRoster(roster)) return false;
    peer.roster = roster.map((fighter) => ({ fighter, hp: 100 }));
    peer.ready = true;
    this.event('ready', { player: peer.id, roster });
    if (this.peers.length === 2 && this.peers.every((player) => player.ready && player.connected)) {
      this.phase = 'countdown';
      this.wait = 180;
      this.resetPositions();
      this.event('countdown');
    }
    return true;
  }

  input(peer, data) {
    if (!Number.isSafeInteger(data.seq) || data.seq <= peer.ack || data.seq < 0) return false;
    peer.ack = data.seq;
    const input = {
      seq: data.seq,
      move: [-1, 0, 1].includes(data.move) ? data.move : 0,
      guard: data.guard === true, crouch: data.crouch === true, run: data.run === true,
      action: ['hop', 'jump', 'roll', ...Object.keys(MOVES)].includes(data.action) ? data.action : '',
    };
    if (peer.queue.length < 8) peer.queue.push(input);
    return true;
  }

  startAttack(peer, action) {
    const fighter = FIGHTERS[peer.roster[peer.active].fighter];
    if (peer.stun > 0 || peer.roll > 0) return;
    if (action === 'jump' || action === 'hop') {
      if (peer.y === 0 && !peer.attack) {
        peer.vy = action === 'hop' ? 470 : 740;
        peer.pose = action;
        this.event(action, { player: peer.id });
      }
      return;
    }
    if (action === 'roll') {
      if (!peer.attack && peer.y === 0) {
        if (peer.guarding && peer.meter < 100) return;
        if (peer.guarding) peer.meter -= 100;
        peer.roll = 27;
        this.event('roll', { player: peer.id });
      }
      return;
    }
    const move = MOVES[action];
    if (!move) return;
    if (peer.attack) {
      const cancel = peer.attack.hit && ((action === 'special' && !['special', 'super'].includes(peer.attack.name))
        || (action === 'super' && peer.attack.name === 'special'));
      if (!cancel) return;
      this.event('cancel', { player: peer.id, into: action });
    }
    if (action === 'super') {
      if (peer.meter < 200 || peer.y > 0) return;
      peer.meter -= 200;
    }
    peer.attack = { name: action, age: 0, hit: false, spawned: false, air: peer.y > 0,
      low: peer.held.crouch && ['kick', 'heavyKick'].includes(action) };
    peer.guarding = false;
    peer.pose = action;
    this.event('attack', { player: peer.id, action, fighter: fighter.name });
  }

  hit(attacker, defender, move, attack, projectile = false) {
    if (defender.roll > 5 || defender.roster[defender.active].hp <= 0) return false;
    const overhead = attack.air;
    const blocking = defender.guarding && defender.y === 0
      && (attack.low ? defender.crouch : !overhead || !defender.crouch);
    const power = FIGHTERS[attacker.roster[attacker.active].fighter].power;
    if (blocking) {
      defender.guard = Math.max(0, defender.guard - move.damage * 2.4);
      defender.stun = 7;
      defender.pose = 'guard';
      const chip = projectile || ['special', 'super'].includes(attack.name) ? 2 : 0;
      defender.roster[defender.active].hp = Math.max(1, defender.roster[defender.active].hp - chip);
      attacker.meter = clamp(attacker.meter + 7, 0, 300);
      defender.meter = clamp(defender.meter + 5, 0, 300);
      this.event('guard', { player: defender.id, x: defender.x, y: defender.y + 110 });
      if (defender.guard === 0) {
        defender.stun = 85;
        defender.guarding = false;
        defender.pose = 'hurt';
        this.event('guardBreak', { player: defender.id });
      }
    } else {
      attacker.combo = this.tick < attacker.comboUntil ? attacker.combo + 1 : 1;
      attacker.comboUntil = this.tick + move.stun + 35;
      const damage = Math.round(move.damage * power * Math.max(0.55, 1 - (attacker.combo - 1) * 0.08));
      defender.roster[defender.active].hp = Math.max(0, defender.roster[defender.active].hp - damage);
      defender.stun = move.stun;
      defender.attack = null;
      defender.pose = 'hurt';
      defender.x = clamp(defender.x + attacker.face * (attack.name === 'super' ? 75 : 16), 100, 1180);
      if (attack.name === 'super') defender.vy = 300;
      attacker.meter = clamp(attacker.meter + (attack.name === 'super' ? 0 : 17), 0, 300);
      defender.meter = clamp(defender.meter + 10, 0, 300);
      attacker.damage += damage;
      this.event('hit', { player: attacker.id, target: defender.id, damage, combo: attacker.combo,
        action: attack.name, x: defender.x, y: defender.y + 110 });
    }
    return true;
  }

  advancePeer(peer, opponent) {
    if (peer.active >= 3 || opponent.active >= 3) return;
    let action = '';
    while (peer.queue.length) {
      const input = peer.queue.shift();
      peer.held = input;
      peer.inputTick = this.tick;
      if (input.action) { action = input.action; break; }
    }
    if (this.tick - peer.inputTick > 30) peer.held = { move: 0, guard: false, crouch: false, run: false };
    const fighter = FIGHTERS[peer.roster[peer.active].fighter];
    peer.face = opponent.x >= peer.x ? 1 : -1;
    if (peer.comboUntil < this.tick) peer.combo = 0;
    peer.crouch = peer.held.crouch && peer.y === 0;
    peer.guarding = peer.held.guard && !peer.attack && peer.stun < 8 && peer.roll === 0;
    if (action) this.startAttack(peer, action);
    if (peer.y > 0 || peer.vy !== 0) {
      peer.y = Math.max(0, peer.y + peer.vy / HZ);
      peer.vy -= 1900 / HZ;
      if (peer.y === 0) peer.vy = 0;
    }
    if (peer.stun > 0) {
      peer.stun--;
      return;
    }
    if (peer.roll > 0) {
      peer.roll--;
      peer.x += (peer.held.move || peer.face) * 480 / HZ;
      peer.pose = 'roll';
    } else if (peer.attack) {
      const attack = peer.attack;
      const move = MOVES[attack.name];
      attack.age++;
      peer.pose = attack.name;
      const projectile = (fighter.special === 'flame' && attack.name === 'special') || attack.name === 'super';
      if (attack.age >= move.startup && attack.age < move.startup + move.active) {
        if (projectile && !attack.spawned) {
          attack.spawned = true;
          this.projectiles.push({
            id: `${peer.id}-${this.tick}`, owner: peer.id, x: peer.x + peer.face * 75,
            y: peer.y + 90, direction: peer.face, life: 120,
            super: attack.name === 'super', fighter: peer.roster[peer.active].fighter,
          });
        } else if (!projectile) {
          if (fighter.special === 'rush' && attack.name === 'special') peer.x += peer.face * 12;
          if (fighter.special === 'upper' && attack.name === 'special' && attack.age === move.startup) peer.vy = 560;
          const distance = Math.abs(peer.x - opponent.x);
          const verticalRange = fighter.special === 'upper' && attack.name === 'special' ? 240 : 125;
          if (!attack.hit && distance < move.range
            && Math.abs(peer.y - opponent.y) < verticalRange) {
            attack.hit = this.hit(peer, opponent, move, attack);
          }
        }
      }
      if (attack.age >= move.startup + move.active + move.recovery) peer.attack = null;
    } else {
      const speed = fighter.speed * (peer.held.run ? 1.5 : 1);
      if (!peer.guarding && !peer.crouch) peer.x += peer.held.move * speed / HZ;
      peer.pose = peer.y > 0 ? 'jump' : peer.guarding ? 'guard' : peer.crouch ? 'crouch' : peer.held.move ? 'walk' : 'idle';
      if (!peer.guarding) peer.guard = Math.min(100, peer.guard + 0.18);
    }
    peer.x = clamp(peer.x, 100, 1180);
  }

  finishRound() {
    const knocked = this.peers.filter((peer) => peer.roster[peer.active].hp <= 0);
    if (!knocked.length) return;
    for (const peer of knocked) {
      peer.pose = 'ko';
      const opponent = this.peers.find((candidate) => candidate !== peer);
      opponent.knockouts++;
      this.event('ko', { player: peer.id, member: peer.active, fighter: peer.roster[peer.active].fighter });
    }
    this.phase = 'transition';
    this.wait = 140;
    this.projectiles = [];
  }

  step() {
    this.tick++;
    if (this.peers.length < 2 || !this.peers.every((peer) => peer.connected)) return;
    if (['countdown', 'transition'].includes(this.phase)) {
      if (--this.wait > 0) return;
      if (this.phase === 'transition') {
        for (const peer of this.peers) {
          if (peer.roster[peer.active].hp <= 0) {
            peer.active++;
          } else {
            peer.roster[peer.active].hp = Math.min(100, peer.roster[peer.active].hp + 12);
          }
        }
        if (this.peers.some((peer) => peer.active >= 3)) {
          this.phase = 'result';
          this.winner = this.peers.every((peer) => peer.active >= 3) ? 'draw' : this.peers.find((peer) => peer.active < 3).id;
          this.event('result', { winner: this.winner, health: this.peers.map((peer) => peer.roster.map((member) => member.hp)) });
          return;
        }
        this.round++;
        this.phase = 'countdown';
        this.wait = 110;
        this.timer = 60 * HZ;
        this.resetPositions();
        this.event('replacement', { active: this.peers.map((peer) => peer.active) });
      } else {
        this.phase = 'fight';
        this.event('fight', { round: this.round });
      }
      return;
    }
    if (this.phase !== 'fight') return;
    this.timer--;
    // Alternate update priority to avoid giving one connection a permanent trade advantage.
    const order = this.tick % 2 === 0 ? [0, 1] : [1, 0];
    for (const index of order) this.advancePeer(this.peers[index], this.peers[1 - index]);
    const [left, right] = this.peers;
    if (Math.abs(left.x - right.x) < 80 && Math.abs(left.y - right.y) < 130 && !left.roll && !right.roll) {
      const middle = (left.x + right.x) / 2;
      const sign = left.x <= right.x ? 1 : -1;
      left.x = clamp(middle - sign * 40, 100, 1180);
      right.x = clamp(middle + sign * 40, 100, 1180);
    }
    for (const projectile of this.projectiles) {
      projectile.x += projectile.direction * (projectile.super ? 850 : 610) / HZ;
      projectile.life--;
      const attacker = this.peers.find((peer) => peer.id === projectile.owner);
      const defender = this.peers.find((peer) => peer.id !== projectile.owner);
      if (Math.abs(projectile.x - defender.x) < (projectile.super ? 90 : 60)
        && Math.abs(projectile.y - (defender.y + 80)) < (projectile.super ? 160 : 85)) {
        const name = projectile.super ? 'super' : 'special';
        if (this.hit(attacker, defender, MOVES[name], { name, air: false, low: false }, true)) {
          projectile.life = 0;
          if (attacker.attack?.name === name) attacker.attack.hit = true;
        }
      }
    }
    this.projectiles = this.projectiles.filter((projectile) => projectile.life > 0 && projectile.x > 0 && projectile.x < 1280);
    if (this.timer <= 0) {
      const hp = this.peers.map((peer) => peer.roster[peer.active].hp);
      this.peers.forEach((peer, index) => {
        if (hp[index] <= hp[1 - index]) peer.roster[peer.active].hp = 0;
      });
      this.event('timeout');
    }
    this.finishRound();
  }

  rematch(peer) {
    if (this.phase !== 'result') return false;
    peer.rematch = true;
    this.event('rematchVote', { player: peer.id });
    if (this.peers.every((player) => player.rematch)) {
      this.match++;
      this.round = 1;
      this.winner = '';
      this.timer = 60 * HZ;
      this.phase = 'countdown';
      this.wait = 180;
      for (const player of this.peers) {
        Object.assign(player, { active: 0, meter: 0, rematch: false, damage: 0, knockouts: 0 });
        player.roster.forEach((member) => { member.hp = 100; });
      }
      this.resetPositions();
      this.event('rematch');
    }
    return true;
  }

  snapshot() {
    return {
      type: 'state', code: this.code, tick: this.tick, phase: this.phase,
      match: this.match, round: this.round, timer: Math.ceil(this.timer / HZ),
      wait: this.wait, winner: this.winner, paused: this.peers.some((peer) => !peer.connected),
      peers: this.peers.map((peer) => ({
        id: peer.id, name: peer.name, roster: peer.roster, connected: peer.connected,
        ready: peer.ready, active: peer.active, meter: Math.floor(peer.meter), x: peer.x, y: peer.y,
        face: peer.face, pose: peer.pose, guard: Math.floor(peer.guard), guarding: peer.guarding,
        crouch: peer.crouch, combo: peer.combo, ack: peer.ack, rematch: peer.rematch,
        damage: peer.damage, knockouts: peer.knockouts,
      })), projectiles: this.projectiles, events: this.events,
    };
  }
}
