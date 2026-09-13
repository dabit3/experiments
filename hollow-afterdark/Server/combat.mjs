export const FPS = 60;
export const CYCLE = 720;
export const MOVES = {
  light: { startup: 6, active: 4, recovery: 14, range: 110, damage: 55, stun: 19, cost: 0 },
  heavy: { startup: 14, active: 5, recovery: 22, range: 163, damage: 105, stun: 27, cost: 0 },
  special: { startup: 17, active: 3, recovery: 29, range: 135, damage: 140, stun: 31, cost: 25 },
  ex: { startup: 11, active: 7, recovery: 30, range: 205, damage: 225, stun: 36, cost: 100 },
  throw: { startup: 7, active: 3, recovery: 27, range: 72, damage: 125, stun: 34, cost: 0 },
};
const clamp = (value, low, high) => Math.max(low, Math.min(high, value));

export function fighter(id, name, slot) {
  return {
    id, name, slot, connected: true, ready: false, wins: 0,
    x: slot === 0 ? 360 : 840, y: 0, vy: 0, face: slot === 0 ? 1 : -1,
    hp: 1000, meter: 35, grd: 0, ascend: false, broken: 0,
    held: { left: false, right: false, guard: false, shield: false },
    action: "idle", move: "", frame: 0, hit: false, stun: 0, combo: 0,
    comboTimer: 0, lastSeq: -1, lastInputTick: 0,
    stats: { hits: 0, blocks: 0, shields: 0, jumps: 0, specials: 0, shifts: 0, throws: 0 },
  };
}
export function match() {
  return {
    phase: "lobby", tick: 0, fightTick: 0, round: 1, remaining: 75,
    countdown: 0, cycle: CYCLE, cycleNumber: 0, players: [], projectiles: [],
    events: [], eventID: 0, winner: "", roundWinner: "", message: "AWAITING TWO SIGNALS",
    matchNumber: 0,
  };
}
export function event(game, type, owner, x, y, text = "") {
  game.events.push({ id: ++game.eventID, tick: game.tick, type, owner, x, y, text });
  if (game.events.length > 30) game.events.shift();
}
function resetRound(game) {
  for (const player of game.players) {
    const fresh = fighter(player.id, player.name, player.slot);
    Object.assign(player, fresh, { wins: player.wins, stats: player.stats, lastSeq: player.lastSeq });
  }
  game.fightTick = 0;
  game.remaining = 75;
  game.projectiles = [];
  game.cycle = CYCLE;
  game.roundWinner = "";
  game.phase = "countdown";
  game.countdown = 150;
  game.message = `ROUND ${game.round}`;
}
export function ready(game, id) {
  if (!["lobby", "result"].includes(game.phase)) return;
  const player = game.players.find((p) => p.id === id);
  if (!player) return;
  player.ready = true;
  if (game.players.length === 2 && game.players.every((p) => p.ready && p.connected)) {
    game.round = 1;
    game.winner = "";
    game.matchNumber++;
    for (const p of game.players) {
      p.wins = 0;
      p.stats = fighter(p.id, p.name, p.slot).stats;
    }
    resetRound(game);
  }
}
export function input(game, id, packet) {
  const p = game.players.find((player) => player.id === id);
  if (!p || !Number.isSafeInteger(packet.seq) || packet.seq <= p.lastSeq) return false;
  p.lastSeq = packet.seq;
  p.lastInputTick = game.tick;
  if (packet.held && typeof packet.held === "object") {
    for (const key of ["left", "right", "guard", "shield"]) p.held[key] = packet.held[key] === true;
  }
  if (game.phase !== "fight" || !game.players.every((peer) => peer.connected)) return true;
  const button = packet.press;
  if (button === "shift" && p.ascend && !p.broken) {
    p.ascend = false;
    p.meter = clamp(p.meter + 45 + p.grd * 4, 0, 200);
    p.grd = 0;
    p.move = "";
    p.stun = 0;
    p.stats.shifts++;
    event(game, "shift", p.id, p.x, p.y + 100, "CHAIN / SHIFT");
    return true;
  }
  if (p.stun > 0) {
    if (button === "throw" && p.stun >= 27 && p.action === "thrown") {
      p.stun = 0;
      event(game, "break", p.id, p.x, 90, "THROW BREAK");
    }
    return true;
  }
  if (button === "jump" && p.y === 0 && !p.move) {
    p.vy = 13;
    p.y = 1;
    p.stats.jumps++;
    p.grd = clamp(p.grd + 0.18, 0, 6);
    event(game, "jump", p.id, p.x, 0);
  }
  if (typeof button !== "string" || !Object.hasOwn(MOVES, button)) return true;
  const move = MOVES[button];
  const canCancel = p.hit && (
    (p.move === "light" && ["heavy", "special", "ex"].includes(button)) ||
    (p.move === "heavy" && ["special", "ex"].includes(button)));
  if ((p.move && !canCancel) || p.meter < move.cost) return true;
  p.move = button;
  p.action = button;
  p.frame = 0;
  p.hit = false;
  p.meter -= move.cost;
  p.held.guard = false;
  p.held.shield = false;
  if (["special", "ex"].includes(button)) p.stats.specials++;
  event(game, "attack", p.id, p.x, p.y + 90, button);
  return true;
}
function impact(game, attacker, defender, kind, projectile = false) {
  const move = MOVES[kind];
  if (defender.hp <= 0) return;
  const facing = defender.face === Math.sign(attacker.x - defender.x);
  const guarding = defender.held.guard || defender.held.shield;
  const shield = defender.held.shield && defender.meter > 0 && !defender.broken;
  if (kind !== "throw" && guarding && facing && !defender.move && defender.y === 0) {
    defender.hp = Math.max(1, defender.hp - (shield ? 0 : Math.floor(move.damage * 0.07)));
    defender.stun = shield ? 8 : 12;
    defender.action = "block";
    defender.grd = clamp(defender.grd + (shield ? 0.65 : 0.22), 0, 6);
    attacker.grd = clamp(attacker.grd - (shield ? 0.5 : 0), 0, 6);
    defender.meter = clamp(defender.meter + (shield ? -3 : 3), 0, 200);
    defender.stats[shield ? "shields" : "blocks"]++;
    defender.x = clamp(defender.x + attacker.face * (shield ? 36 : 22), 55, 1145);
    event(game, shield ? "shield" : "block", defender.id, defender.x, defender.y + 90);
    return;
  }
  if (kind === "throw" && defender.y > 15) return;
  if (kind === "throw" && shield) {
    defender.broken = CYCLE;
    defender.grd = 0;
    defender.ascend = false;
    event(game, "break", defender.id, defender.x, 120, "UNDERTOW BREAK");
  }
  const scale = Math.max(0.45, 1 - attacker.combo * 0.12);
  const damage = Math.floor(move.damage * scale * (attacker.ascend ? 1.1 : 1));
  defender.hp = Math.max(0, defender.hp - damage);
  defender.stun = move.stun;
  defender.move = "";
  defender.action = kind === "throw" ? "thrown" : "hurt";
  defender.x = clamp(defender.x + attacker.face * (kind === "heavy" ? 48 : 26), 55, 1145);
  defender.grd = clamp(defender.grd - 0.45, 0, 6);
  defender.meter = clamp(defender.meter + 5, 0, 200);
  attacker.grd = clamp(attacker.grd + 0.6, 0, 6);
  attacker.meter = clamp(attacker.meter + (projectile ? 3 : 9), 0, 200);
  attacker.hit = true;
  attacker.combo++;
  attacker.comboTimer = move.stun + 30;
  attacker.stats.hits++;
  if (kind === "throw") attacker.stats.throws++;
  event(game, "hit", attacker.id, defender.x, defender.y + 95, `${damage}`);
}
function finishRound(game) {
  const [a, b] = game.players;
  const winner = a.hp === b.hp ? null : a.hp > b.hp ? a : b;
  if (winner) winner.wins++;
  game.roundWinner = winner?.id ?? "";
  game.message = winner ? `${winner.name.toUpperCase()} / ROUND` : "DOUBLE DOWN";
  event(game, "round", winner?.id ?? "", 600, 180, game.message);
  game.phase = "roundEnd";
  game.countdown = 160;
  if (winner?.wins >= 2) {
    game.winner = winner.id;
    game.phase = "result";
    game.message = `${winner.name.toUpperCase()} WINS`;
    for (const p of game.players) p.ready = false;
    event(game, "result", winner.id, 600, 180, game.message);
  }
}
export function step(game) {
  game.tick++;
  if (game.players.length !== 2 || !game.players.every((p) => p.connected)) return;
  if (["countdown", "roundEnd"].includes(game.phase)) {
    if (--game.countdown <= 0) {
      if (game.phase === "roundEnd") {
        game.round++;
        resetRound(game);
      } else {
        game.phase = "fight";
        game.message = "BREAK THE STILLNESS";
        event(game, "start", "", 600, 180, game.message);
      }
    }
    return;
  }
  if (game.phase !== "fight") return;
  game.fightTick++;
  game.remaining = Math.max(0, 75 - Math.floor(game.fightTick / FPS));
  for (const p of game.players) {
    const opponent = game.players[1 - p.slot];
    if (game.tick - p.lastInputTick > 90) {
      p.held = { left: false, right: false, guard: false, shield: false };
    }
    p.face = opponent.x >= p.x ? 1 : -1;
    p.broken = Math.max(0, p.broken - 1);
    p.comboTimer = Math.max(0, p.comboTimer - 1);
    if (!p.comboTimer) p.combo = 0;
    if (p.y > 0 || p.vy > 0) {
      p.vy -= 0.55;
      p.y = Math.max(0, p.y + p.vy);
      if (p.y === 0) p.vy = 0;
    }
    if (p.stun > 0) { p.stun--; continue; }
    if (p.move) {
      const move = MOVES[p.move];
      p.frame++;
      if (p.frame === move.startup && p.move === "special") {
        game.projectiles.push({
          id: `${p.id}-${game.tick}`, owner: p.id, x: p.x + p.face * 50,
          y: p.y + 72, vx: p.face * 11, life: 90,
        });
      }
      if (p.move !== "special" && !p.hit && p.frame >= move.startup &&
          p.frame < move.startup + move.active &&
          Math.abs(p.x - opponent.x) < move.range &&
          Math.abs(p.y - opponent.y) < 110) {
        impact(game, p, opponent, p.move);
        p.hit = true;
      }
      if (p.frame >= move.startup + move.active + move.recovery) p.move = "";
    } else {
      const shielding = p.held.shield && p.meter > 0 && !p.broken;
      const defending = p.held.guard || shielding;
      const direction = Number(p.held.right) - Number(p.held.left);
      p.action = p.y > 0 ? "jump" : shielding ? "shield" : defending ? "guard" : direction ? "walk" : "idle";
      if (!defending || p.y > 0) {
        p.x = clamp(p.x + direction * (p.y > 0 ? 3.4 : 4.2), 55, 1145);
        if (direction) p.grd = clamp(p.grd + (direction === p.face ? 0.006 : -0.008), 0, 6);
      }
      if (shielding) p.meter = Math.max(0, p.meter - 0.08);
    }
  }
  const [a, b] = game.players;
  if (Math.abs(a.x - b.x) < 55 && Math.abs(a.y - b.y) < 85) {
    const midpoint = (a.x + b.x) / 2;
    const direction = a.x <= b.x ? -1 : 1;
    a.x = clamp(midpoint + direction * 27.5, 55, 1145);
    b.x = clamp(midpoint - direction * 27.5, 55, 1145);
  }
  game.projectiles = game.projectiles.filter((orb) => {
    orb.x += orb.vx;
    orb.life--;
    const owner = game.players.find((p) => p.id === orb.owner);
    const target = game.players.find((p) => p.id !== orb.owner);
    if (Math.abs(orb.x - target.x) < 48 && Math.abs(orb.y - (target.y + 70)) < 70) {
      impact(game, owner, target, "special", true);
      return false;
    }
    return orb.life > 0 && orb.x > 0 && orb.x < 1200;
  });
  if (--game.cycle <= 0) {
    game.cycle = CYCLE;
    game.cycleNumber++;
    for (const p of game.players) p.ascend = false;
    if (Math.abs(a.grd - b.grd) > 0.05) {
      const leader = a.grd > b.grd ? a : b;
      if (!leader.broken) {
        leader.ascend = true;
        event(game, "ascend", leader.id, leader.x, 170, "ASCEND / +10%");
      }
    } else event(game, "cycle", "", 600, 170, "UNDERTOW / EVEN");
  }
  if (a.hp === 0 || b.hp === 0 || game.remaining === 0) finishRound(game);
}
export function snapshot(game) {
  return {
    type: "state", tick: game.tick, phase: game.phase, round: game.round,
    remaining: game.remaining, countdown: game.countdown, cycle: game.cycle,
    cycleNumber: game.cycleNumber, winner: game.winner, roundWinner: game.roundWinner,
    message: game.message, matchNumber: game.matchNumber,
    players: game.players.map(({ held, ...publicPlayer }) => publicPlayer),
    projectiles: game.projectiles, events: game.events,
  };
}
