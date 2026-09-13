export const DT = 1 / 30;
export const WIDTH = 960;
export const PLATFORMS = [
  { x: 0, w: 960, y: 65 },
  { x: 25, w: 175, y: 150 }, { x: 760, w: 175, y: 150 },
  { x: 345, w: 270, y: 145 },
  { x: 145, w: 170, y: 235 }, { x: 645, w: 170, y: 235 },
  { x: 420, w: 120, y: 230 },
  { x: 260, w: 160, y: 315 }, { x: 540, w: 160, y: 315 },
  { x: 330, w: 300, y: 395 },
  { x: 0, w: 100, y: 320 }, { x: 860, w: 100, y: 320 },
];
const HOMES = [385, 575];
const PILES = [
  [80, 65], [880, 65], [305, 65], [655, 65], [480, 145],
  [80, 150], [880, 150],
];
const emptyInput = () => ({ move: 0, jump: false, action: false, dive: false });
const clamp = (x, low, high) => Math.max(low, Math.min(high, x));
const sign = x => Math.abs(x) < 6 ? 0 : Math.sign(x);
const distance = (a, b) => Math.hypot(a.x - b.x, a.y - b.y);

export function createGame() {
  const game = {
    tick: 0, time: 0, phase: 'playing', winner: -1, victory: '',
    score: [0, 0], lives: [3, 3], orders: ['economy', 'snail'],
    snail: { x: 480, y: 65, rider: '', team: -1 },
    units: [], berries: [], gates: [
      { x: 280, y: 235, kind: 'warrior', team: -1 },
      { x: 680, y: 235, kind: 'warrior', team: -1 },
      { x: 480, y: 230, kind: 'warrior', team: -1 },
      { x: 105, y: 150, kind: 'speed', team: -1 },
      { x: 855, y: 150, kind: 'speed', team: -1 },
    ],
    events: [], nextEvent: 0, deposits: [0, 0], kills: [0, 0],
  };
  for (let team = 0; team < 2; team++) {
    for (let slot = 0; slot < 5; slot++) {
      game.units.push({
        id: `${team}-${slot}`, team, slot, role: slot === 0 ? 'queen' : 'worker',
        x: HOMES[team] + (slot - 2) * 13, y: 395, vx: 0, vy: 0,
        facing: team === 0 ? -1 : 1, grounded: true, berry: false, speed: false,
        dead: 0, invulnerable: 5, cooldown: 0, gateProgress: 0,
        human: false, input: emptyInput(), lastJump: false, diving: false,
      });
    }
  }
  PILES.forEach(([x, y], pile) => {
    for (let i = 0; i < 8; i++) {
      game.berries.push({ id: `${pile}-${i}`, x: x + (i % 3 - 1) * 8, y, active: true });
    }
  });
  return game;
}

function event(game, kind, team, x, y, detail = '') {
  game.events.push({ id: ++game.nextEvent, kind, team, x, y, detail, tick: game.tick });
  if (game.events.length > 24) game.events.shift();
}

function finish(game, team, victory) {
  if (game.phase !== 'playing') return;
  game.phase = 'result';
  game.winner = team;
  game.victory = victory;
  event(game, 'victory', team, HOMES[team], 450, victory);
}

function platformFor(unit) {
  let nearest = 0;
  let best = Infinity;
  PLATFORMS.forEach((p, i) => {
    const d = Math.abs(unit.y - p.y) * 3 + Math.max(p.x - unit.x, unit.x - p.x - p.w, 0);
    if (d < best) { best = d; nearest = i; }
  });
  return nearest;
}

export function hiveTarget(game, team) {
  const hole = Math.min(game.score[team], 11);
  return { x: (team === 0 ? 343 : 503) + 26 + hole % 4 * 19, y: 456 - Math.floor(hole / 4) * 13 };
}

function route(start, end, target) {
  const queue = [[start]];
  const seen = new Set([start]);
  while (queue.length) {
    const path = queue.shift();
    const last = path.at(-1);
    if (last === end) return path;
    PLATFORMS.map((p, i) => ({ ...p, i }))
      .sort((a, b) => Math.abs(a.x + a.w / 2 - target.x) - Math.abs(b.x + b.w / 2 - target.x))
      .forEach((p) => {
      const i = p.i;
      if (seen.has(i)) return;
      const a = PLATFORMS[last];
      const gap = Math.max(p.x - (a.x + a.w), a.x - (p.x + p.w), 0);
      if (p.y - a.y <= 95 && p.y - a.y >= -180 && gap <= 90) {
        seen.add(i);
        queue.push([...path, i]);
      }
    });
  }
  return [start, end];
}

export function navigate(unit, target) {
  const input = emptyInput();
  if (!unit.grounded && unit.navigation) {
    input.move = sign(unit.navigation.x - unit.x);
    return input;
  }
  const from = platformFor(unit);
  const dest = platformFor(target);
  const path = route(from, dest, target);
  if (from === dest) {
    input.move = sign(target.x - unit.x);
    input.jump = target.y > unit.y + 10 && unit.cooldown <= 0;
    unit.navigation = { x: target.x };
    return input;
  }
  const p = PLATFORMS[path[1]];
  if (p.y > unit.y + 10) {
    const tx = clamp(unit.x, p.x + 20, p.x + p.w - 20);
    input.move = sign(tx - unit.x);
    input.jump = Math.abs(tx - unit.x) < 115 && unit.cooldown <= 0;
    unit.navigation = { x: tx };
  } else {
    const a = PLATFORMS[from];
    const left = a.x - 18;
    const right = a.x + a.w + 18;
    const center = clamp(target.x, p.x + 20, p.x + p.w - 20);
    const exit = Math.abs(center - left) < Math.abs(center - right) ? left : right;
    input.move = sign(exit - unit.x);
    unit.navigation = { x: exit };
  }
  return input;
}

export function botInput(game, unit) {
  const order = game.orders[unit.team];
  const foe = game.units.find(u => u.team !== unit.team && u.role === 'queen' && u.dead <= 0);
  if (unit.role !== 'worker') {
    const gate = game.gates[unit.team];
    const aggressive = order === 'military' || unit.role === 'warrior';
    let target = aggressive && foe ? { x: foe.x, y: foe.y + 25 } :
      { x: gate.x + Math.sin(game.time * 0.6) * 90, y: gate.y + 65 };
    if (unit.role === 'queen' && gate.team !== unit.team) {
      target = gate;
      if (unit.y > gate.y + 25) {
        if (unit.grounded) return navigate(unit, gate);
        if (unit.navigation) return { ...emptyInput(), move: sign(unit.navigation.x - unit.x) };
      }
    }
    const threat = game.units.find(u => u.team !== unit.team && u.dead <= 0 && distance(u, unit) < 100);
    if (threat && unit.y > threat.y + 15) target = threat;
    return {
      move: sign(target.x - unit.x),
      jump: unit.y < target.y + 15 && unit.cooldown <= 0,
      action: false,
      dive: unit.role === 'queen' && !!threat && Math.abs(unit.x - threat.x) < 20 && unit.y > threat.y + 25,
    };
  }
  const snailDuty = order === 'snail' && unit.slot === 1;
  if (snailDuty) {
    const input = navigate(unit, game.snail);
    if (Math.abs(unit.x - game.snail.x) < 26 && Math.abs(unit.y - 65) < 25) {
      input.move = 0;
      input.action = true;
    }
    return input;
  }
  if (unit.berry) {
    const transform = order === 'military' && unit.slot <= 3;
    const gates = game.gates.filter(g => g.kind === 'warrior' && (g.team < 0 || g.team === unit.team));
    const target = transform && gates.length ?
      gates.reduce((a, b) => distance(unit, a) < distance(unit, b) ? a : b) :
      hiveTarget(game, unit.team);
    const input = navigate(unit, target);
    if (transform && distance(unit, target) < 23) { input.move = 0; input.action = true; }
    return input;
  }
  const candidates = game.berries.filter(b => b.active);
  if (!candidates.length) return emptyInput();
  const berry = candidates.reduce((a, b) => {
    const cost = c => distance(unit, c) + (c.x < 480 !== (unit.team === 0) ? 140 : 0);
    return cost(a) < cost(b) ? a : b;
  });
  return navigate(unit, berry);
}

function kill(game, victim, attacker) {
  if (victim.dead > 0 || victim.invulnerable > 0) return;
  if (victim.berry) {
    game.berries.push({ id: `drop-${game.tick}-${victim.id}`, x: victim.x, y: victim.y, active: true, falling: true });
  }
  event(game, 'hit', attacker.team, victim.x, victim.y + 14, victim.role);
  game.kills[attacker.team]++;
  if (victim.role === 'queen') {
    game.lives[victim.team]--;
    if (!game.lives[victim.team]) finish(game, attacker.team, 'MILITARY');
  }
  victim.dead = victim.role === 'queen' ? 2.8 : 2;
  victim.berry = false;
  victim.speed = false;
  victim.gateProgress = 0;
  victim.role = victim.slot === 0 ? 'queen' : 'worker';
  if (game.snail.rider === victim.id) game.snail.rider = '';
}

export function step(game, dt = DT) {
  if (game.phase !== 'playing') return;
  game.tick++;
  game.time += dt;
  for (const berry of game.berries) {
    if (!berry.active || !berry.falling) continue;
    const old = berry.y;
    berry.y -= 200 * dt;
    for (const p of PLATFORMS) {
      if (berry.x >= p.x && berry.x <= p.x + p.w && old >= p.y && berry.y <= p.y) {
        berry.y = p.y;
        berry.falling = false;
      }
    }
  }
  for (const u of game.units) {
    u.cooldown = Math.max(0, u.cooldown - dt);
    u.invulnerable = Math.max(0, u.invulnerable - dt);
    if (u.dead > 0) {
      u.dead -= dt;
      if (u.dead <= 0) {
        u.x = HOMES[u.team]; u.y = 395; u.vx = 0; u.vy = 0;
        u.invulnerable = 3; u.grounded = true;
        event(game, 'spawn', u.team, u.x, u.y);
      }
      continue;
    }
    const input = u.human ? u.input : botInput(game, u);
    const riding = game.snail.rider === u.id;
    if (riding && (input.move !== 0 || input.jump || !input.action)) game.snail.rider = '';
    u.vx = clamp(input.move, -1, 1) * (u.role === 'worker' ? 155 : 185) * (u.speed ? 1.33 : 1);
    if (input.move) u.facing = Math.sign(input.move);
    if (input.jump && u.cooldown <= 0 && (u.grounded || u.role !== 'worker')) {
      u.vy = u.role === 'worker' ? 470 : 290;
      u.grounded = false;
      u.cooldown = u.role === 'worker' ? 0.25 : 0.2;
    }
    u.diving = u.role === 'queen' && input.dive && !u.grounded;
    if (u.diving) u.vy = -540;
    const oldY = u.y;
    u.vy -= 800 * dt;
    u.x += u.vx * dt;
    u.y += u.vy * dt;
    if (u.x < -8) u.x = WIDTH + 8;
    if (u.x > WIDTH + 8) u.x = -8;
    if (u.y > 464) { u.y = 464; u.vy = 0; }
    u.grounded = false;
    if (u.vy <= 0) {
      for (const p of [...PLATFORMS].sort((a, b) => b.y - a.y)) {
        if (u.x >= p.x - 4 && u.x <= p.x + p.w + 4 && oldY >= p.y - 1 && u.y <= p.y) {
          u.y = p.y; u.vy = 0; u.grounded = true; break;
        }
      }
    }
    if (u.y < 65) { u.y = 65; u.vy = 0; u.grounded = true; }
    if (u.role === 'queen') {
      for (const g of game.gates) {
        if (distance(u, g) < 27 && g.team !== u.team) {
          g.team = u.team;
          event(game, 'claim', u.team, g.x, g.y, g.kind);
        }
      }
    }
    if (u.role !== 'worker') continue;
    if (!u.berry) {
      const b = game.berries.find(b => b.active && distance(u, b) < 19);
      if (b) { b.active = false; u.berry = true; event(game, 'berry', u.team, u.x, u.y); }
    }
    if (u.berry && distance(u, hiveTarget(game, u.team)) < 16) {
      u.berry = false;
      game.score[u.team]++;
      game.deposits[u.team]++;
      event(game, 'deposit', u.team, u.x, u.y, `${game.score[u.team]}/12`);
      if (game.score[u.team] >= 12) finish(game, u.team, 'ECONOMIC');
    }
    const gate = game.gates.find(g => distance(u, g) < 24 && (g.team === -1 || g.team === u.team));
    if (u.berry && gate && input.action && input.move === 0 && u.grounded && !(gate.kind === 'speed' && u.speed)) {
      u.gateProgress += dt;
      if (u.gateProgress >= 1) {
        u.berry = false; u.gateProgress = 0;
        if (gate.kind === 'warrior') u.role = 'warrior';
        else u.speed = true;
        event(game, 'transform', u.team, u.x, u.y, gate.kind);
      }
    } else u.gateProgress = 0;
    if (input.action && !input.move && Math.abs(u.x - game.snail.x) < 28 && Math.abs(u.y - 65) < 20 && !game.snail.rider) {
      game.snail.rider = u.id;
    }
  }
  for (let i = 0; i < game.units.length; i++) {
    for (let j = i + 1; j < game.units.length; j++) {
      const a = game.units[i], b = game.units[j];
      if (a.team === b.team || a.dead > 0 || b.dead > 0 || Math.abs(a.x - b.x) > 22 || Math.abs(a.y - b.y) > 26) continue;
      const armedA = a.role !== 'worker', armedB = b.role !== 'worker';
      if (!armedA && !armedB) continue;
      if (armedA && !armedB) kill(game, b, a);
      else if (armedB && !armedA) kill(game, a, b);
      else if (a.diving || a.y > b.y + 5) kill(game, b, a);
      else if (b.diving || b.y > a.y + 5) kill(game, a, b);
      else { a.x -= a.facing * 14; b.x -= b.facing * 14; }
    }
  }
  const rider = game.units.find(u => u.id === game.snail.rider && u.dead <= 0 && u.role === 'worker');
  if (rider) {
    game.snail.team = rider.team;
    game.snail.x += (rider.team === 0 ? -1 : 1) * 16 * dt;
    rider.x = game.snail.x;
    rider.y = 77;
    rider.vx = 0; rider.vy = 0;
    if (game.snail.x < 47 || game.snail.x > 913) finish(game, rider.team, 'SNAIL');
  } else { game.snail.rider = ''; game.snail.team = -1; }
}

export function snapshot(game) {
  return {
    ...game,
    units: game.units.map(({ input, lastJump, navigation, ...unit }) => unit),
    berries: game.berries.filter(b => b.active),
    platforms: PLATFORMS,
  };
}
