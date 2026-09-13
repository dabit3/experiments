import { randomBytes } from 'node:crypto';

export const TIMING = Object.freeze({ good: 45, ok: 100, miss: 140, grace: 250, pair: 75 });
export const SONGS = [
  { id: 'lantern', title: 'Lantern Parade', subtitle: 'A little joy down every street', bpm: 112, bars: 16, color: 'coral' },
  { id: 'moon', title: 'Moonlit Matsuri', subtitle: 'Under a sky full of fireworks', bpm: 136, bars: 24, color: 'indigo' },
];

// Every phrase is a four-beat bar: D/K = accented two-hand notes, r = one-beat roll.
const PHRASES = [
  ['d...d...k...d...', 'd...k...d.d.k...', 'd.d.k.d.d...K...', 'd...d.k.D...r...'],
  ['d.d.k.d.d.k.k...', 'd.k.d.k.D.k.K...', 'd.d.k.k.d.d.k...', 'D...d.k.K...r...'],
  ['d.k.d.d.k.d.k...', 'D...k.d.d.k.K...', 'd.d.k.k.d.k.d.k.', 'd.k.D...r.......'],
  ['D...k.d.d.d.K...', 'd.k.d.k.d.d.k...', 'd.d.k...D...K...', 'D...K...r.......'],
];

export function chartFor(songID, difficulty = 'festival') {
  const song = SONGS.find(item => item.id === songID) ?? SONGS[0];
  const step = 60000 / song.bpm / 4;
  const notes = [];
  for (let bar = 0; bar < song.bars; bar++) {
    const section = Math.floor(bar / 4) % PHRASES.length;
    const phrase = PHRASES[section][bar % 4];
    for (let cell = 0; cell < phrase.length; cell++) {
      const symbol = phrase[cell];
      if (symbol === '.' || (difficulty === 'easy' && cell % 4 !== 0)) continue;
      notes.push({
        id: notes.length, at: Math.round((bar * 16 + cell) * step + 2000),
        kind: symbol.toLowerCase() === 'k' ? 'ka' : symbol === 'r' ? 'roll' : 'don',
        big: symbol === 'D' || symbol === 'K',
        duration: symbol === 'r' ? Math.round(step * (cell === 8 ? 7 : 3)) : 0,
      });
    }
  }
  return { ...song, difficulty, duration: Math.round(song.bars * 16 * step + 4000), notes };
}

export function newPlayer(name, id = randomBytes(8).toString('hex')) {
  return {
    id, token: randomBytes(24).toString('hex'), name: String(name || 'Guest').trim().slice(0, 18) || 'Guest',
    connected: true, ready: false, score: 0, combo: 0, maxCombo: 0,
    good: 0, ok: 0, bad: 0, rolls: 0, bigHits: 0, gauge: 0,
    consumed: new Set(), pendingBig: new Map(), lastSeq: -1, lastHit: -Infinity,
    judgment: '', delta: 0, event: 0, lastKind: 'don', lastHand: 'left', inputCount: 0,
  };
}

export function resetPlayer(player) {
  const fresh = newPlayer(player.name, player.id);
  Object.assign(player, fresh, { token: player.token, connected: player.connected });
}

function judge(player, label, delta = 0) {
  player.judgment = label;
  player.delta = Math.round(delta);
  player.event++;
}

export function applyHit(room, player, input, now) {
  if (room.phase !== 'playing' || !player.connected || !Number.isInteger(input.seq) ||
      input.seq <= player.lastSeq || !Number.isFinite(input.at) ||
      !['don', 'ka'].includes(input.kind) || !['left', 'right'].includes(input.hand)) return false;
  player.lastSeq = input.seq;
  if (input.at > now + 100 || input.at < now - 250 || input.at < player.lastHit - 5 ||
      now < room.startAt - 100 || now > room.startAt + room.chart.duration) return false;
  player.lastHit = input.at;
  player.inputCount++;
  player.lastKind = input.kind;
  player.lastHand = input.hand;
  const elapsed = input.at - room.startAt;
  const roll = room.chart.notes.find(note => note.kind === 'roll' && elapsed >= note.at && elapsed <= note.at + note.duration);
  if (roll) {
    if (player.lastRollAt !== undefined && input.at - player.lastRollAt < 35) return false;
    player.lastRollAt = input.at;
    player.score += 120;
    player.rolls++;
    judge(player, 'ROLL!');
    return true;
  }
  for (const [id, first] of player.pendingBig) {
    if (input.at - first.at > TIMING.pair) { player.pendingBig.delete(id); continue; }
    if (first.kind === input.kind && first.hand !== input.hand && input.at >= first.at) {
      player.score += first.points;
      player.bigHits++;
      player.pendingBig.delete(id);
      judge(player, 'BIG!', first.delta);
      return true;
    }
  }
  const candidates = room.chart.notes.filter(note => note.kind !== 'roll' && !player.consumed.has(note.id) &&
    Math.abs(note.at - elapsed) <= TIMING.miss);
  candidates.sort((one, two) => Math.abs(one.at - elapsed) - Math.abs(two.at - elapsed));
  const note = candidates[0];
  if (!note) { judge(player, ''); return true; }
  const delta = elapsed - note.at;
  player.consumed.add(note.id);
  if (note.kind !== input.kind || Math.abs(delta) > TIMING.ok) {
    player.bad++;
    player.combo = 0;
    player.gauge = Math.max(0, player.gauge - 4);
    judge(player, 'BAD', delta);
    return true;
  }
  const good = Math.abs(delta) <= TIMING.good;
  player[good ? 'good' : 'ok']++;
  player.combo++;
  player.maxCombo = Math.max(player.maxCombo, player.combo);
  const points = (good ? 1000 : 500) + Math.min(10, Math.floor(player.combo / 10)) * 100;
  player.score += points;
  player.gauge = Math.min(100, player.gauge + (good ? 2 : 1));
  if (note.big) player.pendingBig.set(note.id, { at: input.at, kind: input.kind, hand: input.hand, points, delta });
  judge(player, good ? 'GOOD' : 'OK', delta);
  return true;
}

export function advanceRoom(room, now) {
  if (room.phase !== 'playing') return;
  for (const player of room.players) {
    for (const note of room.chart.notes) {
      if (note.kind !== 'roll' && !player.consumed.has(note.id) && now - room.startAt > note.at + TIMING.miss + TIMING.grace) {
        player.consumed.add(note.id);
        player.bad++;
        player.combo = 0;
        player.gauge = Math.max(0, player.gauge - 4);
        judge(player, 'MISS');
      }
    }
  }
  if (now >= room.startAt + room.chart.duration + TIMING.grace) {
    room.phase = 'results';
    room.winner = room.players[0].score === room.players[1].score ? 'draw' :
      [...room.players].sort((one, two) => two.score - one.score)[0].id;
    room.players.forEach(player => { player.ready = false; });
  }
}

export function publicRoom(room) {
  return {
    code: room.code, phase: room.phase, host: room.players[0].id, song: room.song,
    difficulty: room.difficulty, startAt: room.startAt, round: room.round, winner: room.winner,
    players: room.players.map(({ token, pendingBig, consumed, lastRollAt, ...player }) => ({
      ...player, consumed: [...consumed], lastHit: Number.isFinite(player.lastHit) ? player.lastHit : 0,
    })),
  };
}
