export const MAZE = [
  '###################',
  '#o.......#.......o#',
  '#.##.###.#.###.##.#',
  '#.................#',
  '#.##.#.#####.#.##.#',
  '#....#...#...#....#',
  '####.###.#.###.####',
  '#....#.......#....#',
  '#.##.#.##.##.#.##.#',
  '#......#   #......#',
  '#.##.#.#   #.#.##.#',
  '#....#.......#....#',
  '#.##.###.#.###.##.#',
  '#........#........#',
  '#.##.###.#.###.##.#',
  '#..#...........#..#',
  '##.#.#.#####.#.#.##',
  '#....#...#...#....#',
  '#.######.#.######.#',
  '#o...............o#',
  '###################',
];
export const DIRS = { up: [0, -1], right: [1, 0], down: [0, 1], left: [-1, 0] };
export const OPPOSITE = { up: 'down', down: 'up', left: 'right', right: 'left' };
const SPAWNS = [[1, 3], [17, 3], [1, 17], [17, 17]];
const POWER_TIME = 7;
const key = (x, y) => `${x},${y}`;
export function walkable(x, y) {
  return MAZE[y]?.[x] !== undefined && MAZE[y][x] !== '#';
}
export function nextDirection(x, y, tx, ty, avoid = null) {
  const seen = new Set([key(x, y)]);
  const queue = [[x, y, null]];
  for (let i = 0; i < queue.length; i++) {
    const [cx, cy, first] = queue[i];
    if (cx === tx && cy === ty) return first;
    for (const [d, [dx, dy]] of Object.entries(DIRS)) {
      const nx = cx + dx, ny = cy + dy, k = key(nx, ny);
      if (!walkable(nx, ny) || seen.has(k) || (!first && d === avoid)) continue;
      seen.add(k);
      queue.push([nx, ny, first || d]);
    }
  }
  return null;
}
export function makePlayer(id, name, color) {
  return {
    id, name, color, connected: true, ready: false, score: 0, crowns: 0,
    x: 1, y: 3, dir: 'right', wanted: 'right', alive: true, power: 0,
    lastSeq: -1, bumpUntil: 0, shield: 0, kills: 0,
  };
}
export class Game {
  constructor(code) {
    this.code = code;
    this.players = [];
    this.phase = 'lobby';
    this.round = 0;
    this.tick = 0;
    this.clock = 0;
    this.remaining = 45;
    this.phaseUntil = 0;
    this.winnerId = null;
    this.winner = null;
    this.roundWinnerId = null;
    this.events = [];
    this.eventId = 0;
    this.pellets = new Set();
    this.powers = [];
    this.ghosts = [];
    this.fruit = false;
    this.pauseReason = '';
  }
  emit(kind, fields = {}) {
    this.events.push({ id: ++this.eventId, kind, tick: this.tick, ...fields });
    this.events = this.events.slice(-24);
  }
  input(id, seq, direction) {
    const player = this.players.find(p => p.id === id);
    if (!player || !Number.isSafeInteger(seq) || seq <= player.lastSeq || !DIRS[direction]) return false;
    player.lastSeq = seq;
    player.wanted = direction;
    return true;
  }
  ready(id) {
    if (!['lobby', 'matchOver'].includes(this.phase)) return;
    const player = this.players.find(p => p.id === id);
    if (player?.connected) player.ready = true;
    if (this.players.length >= 2 && this.players.every(p => p.ready && p.connected)) {
      this.players.forEach(p => { p.crowns = 0; p.score = 0; p.kills = 0; p.ready = false; });
      this.round = 0;
      this.winnerId = null;
      this.winner = null;
      this.startRound();
    }
  }
  refill() {
    this.pellets.clear();
    for (let y = 0; y < MAZE.length; y++) {
      for (let x = 0; x < MAZE[y].length; x++) {
        if (MAZE[y][x] === '.') this.pellets.add(key(x, y));
      }
    }
    this.powers = [[1, 1], [17, 1], [1, 19], [17, 19]]
      .map(([x, y]) => ({ x, y, active: true, respawn: 0 }));
  }
  startRound() {
    this.round++;
    this.remaining = 45;
    this.roundWinnerId = null;
    this.phase = 'countdown';
    this.phaseUntil = this.clock + 3;
    this.fruit = false;
    this.refill();
    this.players.forEach((p, i) => {
      const [x, y] = SPAWNS[i];
      Object.assign(p, { x, y, dir: i % 2 ? 'left' : 'right',
        wanted: i % 2 ? 'left' : 'right', alive: true, power: 0, shield: 2, bumpUntil: 0 });
    });
    this.ghosts = [
      { id: 'g0', x: 8, y: 9, dir: 'down', respawn: 4, color: 0 },
      { id: 'g1', x: 10, y: 9, dir: 'down', respawn: 7, color: 1 },
      { id: 'g2', x: 9, y: 10, dir: 'up', respawn: 10, color: 2 },
    ];
    this.emit('round', { round: this.round });
  }
  endRound(winner, reason) {
    if (this.phase !== 'playing') return;
    this.roundWinnerId = winner?.id || null;
    if (winner) winner.crowns++;
    this.emit('roundEnd', { playerId: winner?.id || '', reason, round: this.round });
    if (winner?.crowns >= 2) {
      this.phase = 'matchOver';
      this.winnerId = winner.id;
      this.winner = { id: winner.id, name: winner.name, color: winner.color };
      this.players.forEach(p => { p.ready = false; });
      this.emit('matchEnd', { playerId: winner.id });
    } else {
      this.phase = 'roundOver';
      this.phaseUntil = this.clock + 4;
    }
  }
  eliminate(p, by, reason) {
    if (!p.alive) return;
    p.alive = false;
    p.power = 0;
    if (by) { by.score += 500; by.kills++; }
    this.emit('eliminated', { playerId: p.id, by: by?.id || '', x: p.x, y: p.y, reason });
  }
  move(actor, distance, choose = null) {
    while (distance > 0.000001) {
      const cx = Math.round(actor.x), cy = Math.round(actor.y);
      const centered = Math.abs(actor.x - cx) < 0.00001 && Math.abs(actor.y - cy) < 0.00001;
      if (centered) {
        actor.x = cx; actor.y = cy;
        if (choose) actor.wanted = choose(actor) || actor.dir;
        const [wx, wy] = DIRS[actor.wanted || actor.dir];
        if (walkable(cx + wx, cy + wy)) actor.dir = actor.wanted || actor.dir;
        const [dx, dy] = DIRS[actor.dir];
        if (!walkable(cx + dx, cy + dy)) break;
      }
      const [dx, dy] = DIRS[actor.dir];
      const axis = dx ? actor.x : actor.y;
      const sign = dx || dy;
      const target = sign > 0 ? Math.floor(axis + 0.00001) + 1 : Math.ceil(axis - 0.00001) - 1;
      const amount = Math.min(distance, Math.abs(target - axis));
      actor.x += dx * amount;
      actor.y += dy * amount;
      distance -= amount;
    }
  }
  step(dt = 1 / 30) {
    this.tick++;
    const disconnected = this.players.filter(p => !p.connected);
    this.pauseReason = disconnected.length ? `Waiting for ${disconnected[0].name} to reconnect` : '';
    if (this.pauseReason) return;
    this.clock += dt;
    if (this.phase === 'countdown' && this.clock >= this.phaseUntil) {
      this.phase = 'playing'; this.emit('go');
    }
    if (this.phase === 'roundOver' && this.clock >= this.phaseUntil) this.startRound();
    if (this.phase !== 'playing') return;
    this.remaining = Math.max(0, this.remaining - dt);
    for (const p of this.players) {
      if (!p.alive) continue;
      p.power = Math.max(0, p.power - dt);
      p.shield = Math.max(0, p.shield - dt);
      if (this.clock >= p.bumpUntil) this.move(p, (p.power > 0 ? 4.7 : 4.1) * dt);
      const x = Math.round(p.x), y = Math.round(p.y), k = key(x, y);
      if (Math.hypot(p.x - x, p.y - y) > 0.32) continue;
      if (this.pellets.delete(k)) { p.score += 10; this.emit('pellet', { playerId: p.id, x, y }); }
      for (const power of this.powers) {
        if (power.active && power.x === x && power.y === y) {
          power.active = false; power.respawn = this.clock + 12;
          p.power = POWER_TIME; p.score += 50;
          this.emit('power', { playerId: p.id, x, y });
        }
      }
      if (this.fruit && x === 9 && y === 7) {
        this.fruit = false; this.refill(); p.score += 100;
        this.emit('fruit', { playerId: p.id, x, y });
      }
    }
    for (const power of this.powers) {
      if (!power.active && this.clock >= power.respawn) power.active = true;
    }
    if (this.pellets.size < 40) this.fruit = true;
    if (!this.pellets.size) this.refill();
    const alive = this.players.filter(p => p.alive);
    for (const ghost of this.ghosts) {
      if (ghost.respawn > 0) {
        ghost.respawn -= dt;
        if (ghost.respawn <= 0) { ghost.x = 9; ghost.y = 7; }
        continue;
      }
      const target = [...alive].sort((a, b) =>
        Math.hypot(a.x - ghost.x, a.y - ghost.y) - Math.hypot(b.x - ghost.x, b.y - ghost.y))[0];
      if (!target) continue;
      const frightened = target.power > 0;
      this.move(ghost, (frightened ? 2.5 : this.remaining < 15 ? 4.0 : 2.8) * dt, g => {
        if (frightened) {
          return Object.entries(DIRS)
            .filter(([d, [dx, dy]]) => d !== OPPOSITE[g.dir] && walkable(g.x + dx, g.y + dy))
            .sort((a, b) => Math.hypot(g.x + b[1][0] - target.x, g.y + b[1][1] - target.y)
              - Math.hypot(g.x + a[1][0] - target.x, g.y + a[1][1] - target.y))[0]?.[0];
        }
        return nextDirection(g.x, g.y, Math.round(target.x), Math.round(target.y));
      });
      for (const p of alive) {
        if (!p.alive || p.shield > 0 || Math.hypot(p.x - ghost.x, p.y - ghost.y) > (p.power > 0 ? 0.95 : 0.6)) continue;
        if (p.power > 0) {
          p.score += 200; ghost.respawn = 5; ghost.x = 9; ghost.y = 9;
          this.emit('ghostEaten', { playerId: p.id, ghostId: ghost.id, x: p.x, y: p.y });
          break;
        }
        this.eliminate(p, null, 'ghost');
      }
    }
    for (let i = 0; i < alive.length; i++) {
      for (let j = i + 1; j < alive.length; j++) {
        const a = alive[i], b = alive[j];
        if (!a.alive || !b.alive || a.shield > 0 || b.shield > 0) continue;
        if (Math.hypot(a.x - b.x, a.y - b.y) > (a.power > 0 || b.power > 0 ? 1 : 0.65)) continue;
        if (a.power > 0 && b.power <= 0) this.eliminate(b, a, 'chomp');
        else if (b.power > 0 && a.power <= 0) this.eliminate(a, b, 'chomp');
        else if (this.clock >= a.bumpUntil && this.clock >= b.bumpUntil) {
          for (const p of [a, b]) {
            p.dir = OPPOSITE[p.dir]; p.wanted = p.dir;
            this.move(p, 0.28); p.bumpUntil = this.clock + 0.3;
          }
          this.emit('bump', { x: a.x, y: a.y });
        }
      }
    }
    const survivors = this.players.filter(p => p.alive);
    if (survivors.length <= 1) this.endRound(survivors[0], 'last standing');
    else if (this.remaining <= 0) {
      const ranked = [...survivors].sort((a, b) => b.score - a.score);
      this.endRound(ranked[0].score === ranked[1].score ? null : ranked[0], 'score tiebreak');
    }
  }
  snapshot() {
    return {
      type: 'state', code: this.code, tick: this.tick, clock: this.clock,
      phase: this.phase, round: this.round, remaining: this.remaining,
      countdown: Math.max(0, this.phaseUntil - this.clock),
      winnerId: this.winnerId, winner: this.winner, roundWinnerId: this.roundWinnerId,
      players: this.players, ghosts: this.ghosts, pellets: [...this.pellets],
      powers: this.powers, fruit: this.fruit, maze: MAZE,
      events: this.events, pauseReason: this.pauseReason,
    };
  }
}
