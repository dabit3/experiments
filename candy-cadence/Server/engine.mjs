export const WINDOWS = Object.freeze({ cool: 45, great: 90, good: 140, bad: 180 });

export function resetPlayer(player) {
  Object.assign(player, {
    ready: false, score: 0, combo: 0, maxCombo: 0, groove: 30,
    counts: { cool: 0, great: 0, good: 0, bad: 0, miss: 0 },
    judged: new Set(), sequence: -1, event: 0, verdict: "", lane: -1, delta: 0,
  });
}

export function judge(player, note, delta, count) {
  if (player.judged.has(note.id)) return false;
  const distance = Math.abs(delta);
  const verdict = Object.keys(WINDOWS).find(key => distance <= WINDOWS[key]) ?? "miss";
  player.judged.add(note.id);
  player.counts[verdict]++;
  const points = { cool: 1, great: 0.8, good: 0.5, bad: 0.1, miss: 0 }[verdict];
  player.score += points * 1_000_000 / count;
  player.combo = points >= 0.5 ? player.combo + 1 : 0;
  player.maxCombo = Math.max(player.maxCombo, player.combo);
  player.groove = Math.max(0, Math.min(100, player.groove + (points >= 0.5 ? 1.5 : -5)));
  Object.assign(player, { verdict: verdict.toUpperCase(), lane: note.lane, delta, event: player.event + 1 });
  return true;
}

export function input(player, song, elapsed, lane, sequence) {
  if (!Number.isInteger(sequence) || sequence <= player.sequence) return false;
  player.sequence = sequence;
  if (!Number.isInteger(lane) || lane < 0 || lane > 8) return false;
  const candidates = song.notes.filter(note => note.lane === lane && !player.judged.has(note.id));
  const note = candidates.reduce((best, next) =>
    !best || Math.abs(next.at - elapsed) < Math.abs(best.at - elapsed) ? next : best, null);
  if (!note || Math.abs(note.at - elapsed) > WINDOWS.bad) return false;
  return judge(player, note, elapsed - note.at, song.notes.length);
}

export function advance(player, song, elapsed) {
  for (const note of song.notes) {
    if (elapsed > note.at + 240 && !player.judged.has(note.id)) {
      judge(player, note, 999, song.notes.length);
    }
  }
}

export function snapshotPlayer(player) {
  return {
    id: player.id, name: player.name, connected: player.connected, ready: player.ready,
    score: Math.round(player.score), combo: player.combo, maxCombo: player.maxCombo,
    groove: Math.round(player.groove), counts: player.counts, judged: [...player.judged],
    event: player.event, verdict: player.verdict, lane: player.lane, delta: player.delta,
    automated: player.automated,
  };
}
