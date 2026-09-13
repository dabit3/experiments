export const TICK_RATE = 60;
export const MOVES = {
  light: { startup: 5, active: 4, recovery: 13, range: 135, damage: 65, stun: 19, rank: 1 },
  medium: { startup: 9, active: 5, recovery: 18, range: 185, damage: 100, stun: 26, rank: 2 },
  heavy: { startup: 14, active: 7, recovery: 24, range: 210, damage: 145, stun: 34, rank: 3 },
  drive: { startup: 17, active: 6, recovery: 25, range: 230, damage: 110, stun: 30, rank: 4 },
  super: { startup: 18, active: 18, recovery: 30, range: 440, damage: 330, stun: 48, rank: 5 }
};
export function fighter(id, name, character, slot) {
  return {
    id, name, character, slot, connected: true, ready: false, wins: 0,
    x: slot === 0 ? 370 : 830, y: 0, vx: 0, vy: 0, face: slot === 0 ? 1 : -1,
    hp: 1000, heat: 0, barrier: 100, danger: 0, stun: 0, frozen: 0,
    combo: 0, comboDamage: 0, comboTimer: 0, attack: "", attackTick: 0,
    hit: false, jumps: 0, airDashes: 0, dash: 0, dashDirection: 1, guard: false,
    input: { axis: 0, guard: false }, actions: [], lastSeq: -1, lastInput: 0,
    rematch: false, dealt: 0
  };
}
export function room(code) {
  return { code, players: [], phase: "lobby", tick: 0, clock: 90, round: 1,
    phaseTicks: 0, winner: "", roundWinner: "", events: [], eventID: 0,
    projectiles: [], match: 1, pauseTicks: 0 };
}
export function event(r, kind, text, p, extra = {}) {
  r.events.push({ id: ++r.eventID, kind, text, player: p?.id ?? "", tick: r.tick, ...extra });
  if (r.events.length > 14) r.events.shift();
}
export function startRound(r) {
  for (const p of r.players) {
    const fresh = fighter(p.id, p.name, p.character, p.slot);
    Object.assign(p, fresh, { wins: p.wins, connected: p.connected, lastSeq: p.lastSeq });
  }
  r.projectiles = [];
  r.clock = 90;
  r.phase = "countdown";
  r.phaseTicks = 150;
  r.roundWinner = "";
  event(r, "round", `DUEL ${r.round} · REBEL AGAINST FATE`);
}
export function acceptInput(r, p, packet) {
  if (!Number.isSafeInteger(packet.seq) || packet.seq <= p.lastSeq) return false;
  if (typeof packet.axis !== "number" || !Number.isFinite(packet.axis)) return false;
  p.lastSeq = packet.seq;
  p.lastInput = r.tick;
  p.input = { axis: Math.max(-1, Math.min(1, packet.axis)), guard: packet.guard === true };
  if (r.phase === "fight" && typeof packet.action === "string" &&
      (Object.hasOwn(MOVES, packet.action) || ["jump", "dash"].includes(packet.action))) {
    if (p.actions.length < 4) p.actions.push(packet.action);
  }
  return true;
}
function beginAttack(r, p, action) {
  const move = MOVES[action];
  if (!move || p.stun || p.frozen || p.guard) return;
  if (p.attack) {
    const previous = MOVES[p.attack];
    if (!p.hit || move.rank <= previous.rank || p.attackTick < previous.startup) return;
  }
  if (action === "super") {
    if (p.heat < 50) return;
    p.heat -= 50;
    event(r, "super", p.character === "seraph" ? "ECLIPSE REQUIEM" : "CELESTIAL ZERO", p);
  }
  p.attack = action;
  p.attackTick = 0;
  p.hit = false;
  event(r, "attack", action.toUpperCase(), p);
}
function hit(r, p, target, move, sourceX = p.x, projectile = false) {
  if (target.hp <= 0) return;
  const barrier = target.guard && target.barrier > 0 && !target.danger;
  const backing = target.input.axis * target.face < -0.25 && target.y === 0;
  const blocked = !target.stun && !target.attack && (barrier || backing);
  p.heat = Math.min(100, p.heat + (blocked ? 4 : 9));
  target.heat = Math.min(100, target.heat + 4);
  p.hit = true;
  const direction = target.x >= sourceX ? 1 : -1;
  if (blocked) {
    target.barrier = Math.max(0, target.barrier - (barrier ? move.damage / 9 : 0));
    if (barrier && target.barrier === 0) {
      target.danger = 240;
      event(r, "danger", "BARRIER BREAK", target);
    }
    const chip = barrier ? 0 : Math.floor(move.damage * 0.08);
    target.hp = Math.max(1, target.hp - chip);
    target.x = Math.max(60, Math.min(1140, target.x + direction * 26));
    event(r, "block", barrier ? "BARRIER" : "GUARD", target, { x: target.x, y: target.y });
    return;
  }
  const counter = Boolean(target.attack);
  if (target.stun === 0) { p.combo = 0; p.comboDamage = 0; }
  p.combo += 1;
  const scaling = Math.max(0.45, 1 - (p.combo - 1) * 0.09);
  const damage = Math.round(move.damage * scaling * (target.danger ? 1.25 : 1) * (counter ? 1.12 : 1));
  target.hp = Math.max(0, target.hp - damage);
  p.dealt += damage;
  p.comboDamage += damage;
  p.comboTimer = 90;
  target.stun = move.stun;
  target.attack = "";
  target.guard = false;
  target.vx = direction * (p.attack === "heavy" ? 5 : 3);
  if (p.attack === "heavy") { target.vy = 9; target.y += 1; }
  if (p.attack === "drive" && p.character === "seraph") p.hp = Math.min(1000, p.hp + 48);
  if (projectile && p.character === "lyra") target.frozen = 22;
  event(r, "hit", counter ? "COUNTER" : projectile ? "FROST BIND" : `${p.combo} HIT`, p,
    { x: target.x, y: target.y, damage, target: target.id });
}
export function step(r) {
  r.tick++;
  if (r.players.length !== 2) return;
  if (r.players.some(p => !p.connected)) {
    if (["fight", "countdown", "roundEnd"].includes(r.phase)) {
      r.pauseTicks++;
      if (r.pauseTicks >= 60 * 30) {
        const remaining = r.players.find(p => p.connected);
        r.phase = "result";
        r.winner = remaining?.id ?? "draw";
        event(r, "result", "DISCONNECT FORFEIT", remaining);
      }
    }
    return;
  }
  r.pauseTicks = 0;
  if (r.phase === "countdown" || r.phase === "roundEnd") {
    if (--r.phaseTicks <= 0) {
      if (r.phase === "countdown") {
        r.phase = "fight";
        event(r, "start", "ENGAGE");
      } else {
        r.round++;
        startRound(r);
      }
    }
    return;
  }
  if (r.phase !== "fight") return;
  r.clock = Math.max(0, r.clock - 1 / TICK_RATE);
  for (const p of r.players) {
    const target = r.players[1 - p.slot];
    if (r.tick - p.lastInput > 30) p.input = { axis: 0, guard: false };
    if (!p.attack && !p.stun) p.face = p.x <= target.x ? 1 : -1;
    if (p.comboTimer > 0) p.comboTimer--;
    if (p.danger > 0) p.danger--;
    if (p.stun > 0) p.stun--;
    if (p.frozen > 0) p.frozen--;
    p.guard = p.input.guard && !p.attack && !p.stun && !p.danger && p.barrier > 0;
    if (p.guard) {
      p.barrier = Math.max(0, p.barrier - 0.26);
      if (!p.barrier) { p.danger = 240; event(r, "danger", "BARRIER BREAK", p); }
    } else if (!p.danger) p.barrier = Math.min(100, p.barrier + 0.11);
    const action = p.actions.shift();
    if (action && !p.stun && !p.frozen) {
      if (action === "jump" && p.jumps < 2 && !p.attack) {
        p.vy = p.jumps === 0 ? 12 : 10;
        p.jumps++;
        event(r, "jump", p.jumps === 2 ? "DOUBLE JUMP" : "JUMP", p);
      } else if (action === "dash" && !p.attack && (p.y === 0 || p.airDashes < 1)) {
        p.dash = 12;
        p.dashDirection = p.input.axis === 0 ? p.face : Math.sign(p.input.axis);
        if (p.y > 0) { p.airDashes++; p.vy = 0; }
        event(r, "dash", p.y > 0 ? "AIR DASH" : "DASH", p);
      } else beginAttack(r, p, action);
    }
    if (p.dash > 0 && !p.stun) {
      p.dash--;
      p.vx = p.dashDirection * 13;
    } else if (!p.stun && !p.frozen) {
      p.vx = p.guard ? p.input.axis : p.attack ? 0 : p.input.axis * (p.character === "seraph" ? 4.4 : 4);
    } else p.vx *= 0.88;
    p.x = Math.max(60, Math.min(1140, p.x + p.vx));
    if (!p.frozen) {
      p.y += p.vy;
      p.vy -= p.dash > 0 && p.y > 0 ? 0.1 : 0.52;
    }
    if (p.y <= 0) { p.y = 0; p.vy = 0; p.jumps = 0; p.airDashes = 0; }
    if (p.attack) {
      p.attackTick++;
      const move = MOVES[p.attack];
      if (p.attack === "drive" && p.character === "lyra" && p.attackTick === move.startup) {
        r.projectiles.push({ id: r.eventID, owner: p.id, x: p.x + p.face * 60, y: p.y + 70, face: p.face, life: 110 });
      } else if (!p.hit && !(p.attack === "drive" && p.character === "lyra") &&
                 p.attackTick >= move.startup && p.attackTick < move.startup + move.active) {
        const dx = (target.x - p.x) * p.face;
        const reach = move.range + (p.character === "lyra" && p.attack !== "super" ? 22 : 0);
        if (dx >= -25 && dx < reach && Math.abs(target.y - p.y) < (p.attack === "super" ? 260 : 110))
          hit(r, p, target, move);
      }
      if (p.attackTick >= move.startup + move.active + move.recovery) p.attack = "";
    }
  }
  const [a, b] = r.players;
  if (Math.abs(a.x - b.x) < 65 && Math.abs(a.y - b.y) < 90) {
    const direction = a.x <= b.x ? -1 : 1;
    a.x = Math.max(60, Math.min(1140, a.x + direction * 4));
    b.x = Math.max(60, Math.min(1140, b.x - direction * 4));
  }
  for (const shot of r.projectiles) {
    shot.x += shot.face * 8;
    shot.life--;
    const owner = r.players.find(p => p.id === shot.owner);
    const target = r.players.find(p => p.id !== shot.owner);
    if (owner && target && Math.abs(target.x - shot.x) < 48 && Math.abs(target.y + 70 - shot.y) < 80) {
      hit(r, owner, target, MOVES.drive, shot.x - shot.face * 50, true);
      shot.life = 0;
    }
  }
  r.projectiles = r.projectiles.filter(s => s.life > 0 && s.x > 0 && s.x < 1200);
  if (a.hp === 0 || b.hp === 0 || r.clock <= 0) {
    const winner = a.hp === b.hp ? null : a.hp > b.hp ? a : b;
    if (winner) winner.wins++;
    r.roundWinner = winner?.id ?? "draw";
    if (winner && winner.wins >= 2) {
      r.phase = "result";
      r.winner = winner.id;
      event(r, "result", `${winner.name.toUpperCase()} WINS`, winner);
    } else {
      r.phase = "roundEnd";
      r.phaseTicks = 180;
      event(r, "roundEnd", winner ? `${winner.name.toUpperCase()} · ROUND WON` : "DRAW", winner);
    }
  }
}
export function snapshot(r) {
  return {
    type: "state", code: r.code, tick: r.tick, phase: r.phase, clock: Math.ceil(r.clock),
    round: r.round, winner: r.winner, roundWinner: r.roundWinner, match: r.match,
    phaseTicks: r.phaseTicks, paused: r.players.some(p => !p.connected),
    players: r.players.map(({ input, actions, lastInput, ...p }) => p),
    events: r.events, projectiles: r.projectiles
  };
}
