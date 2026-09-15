export function newPlayer(id, name) {
  return { id, name, ready: false, connected: true, score: 0, combo: 0, maxCombo: 0, earned: 0, judged: 0,
    counts: { critical: 0, justice: 0, attack: 0, miss: 0 }, resolved: new Set(), pointers: new Map(), seq: -1, last: null };
}

export function units(chart) {
  return chart.notes.flatMap((note) => {
    const result = [{ id: `${note.id}:0`, time: note.time, lane: note.lane, width: note.width, kind: note.kind, head: true }];
    for (let i = 1; i <= Math.round(note.duration / chart.tick); i++) {
      const progress = Math.min(1, i * chart.tick / note.duration);
      result.push({ id: `${note.id}:${i}`, time: note.time + progress * note.duration,
        lane: note.lane + (note.endLane - note.lane) * progress, width: note.width, kind: note.kind, head: false });
    }
    return result;
  }).sort((a, b) => a.time - b.time);
}
export function judge(player, unit, judgment, total) {
  if (player.resolved.has(unit.id)) return;
  player.resolved.add(unit.id);
  player.counts[judgment]++;
  player.judged++;
  const weight = { critical: 1, justice: 0.98, attack: 0.5, miss: 0 }[judgment];
  player.earned += weight;
  player.combo = judgment === 'miss' ? 0 : player.combo + 1;
  player.maxCombo = Math.max(player.maxCombo, player.combo);
  player.score = Math.round(player.earned / total * 1000000);
  player.last = { id: unit.id, judgment, lane: unit.lane, width: unit.width };
}
const covers = (x, unit) => x >= unit.lane && x <= unit.lane + unit.width;

export function advance(player, chartUnits, time) {
  for (const unit of chartUnits) {
    if (player.resolved.has(unit.id)) continue;
    if (unit.head && time > unit.time + (unit.kind === 'air' ? 0.2 : 0.16)) {
      judge(player, unit, 'miss', chartUnits.length);
    } else if (!unit.head && time >= unit.time) {
      const held = [...player.pointers.values()].some((p) => p.down && p.time <= unit.time
        && unit.time - p.time < 0.25 && p.y > 0.72 && covers(p.x, unit));
      judge(player, unit, held ? 'critical' : 'miss', chartUnits.length);
    }
  }
}
export function input(player, chartUnits, event) {
  const old = player.pointers.get(event.pointer);
  if (event.action === 'up') { player.pointers.delete(event.pointer); return; }
  const p = { x: event.x, y: event.y, time: event.time, down: true,
    startY: old?.startY ?? event.y, startTime: old?.startTime ?? event.time, air: old?.air ?? false };
  const isAir = old && !p.air && p.startY - event.y >= 0.09 && event.time - p.startTime < 0.5;
  if (isAir) p.air = true;
  player.pointers.set(event.pointer, p);
  const candidates = chartUnits.filter((u) => u.head && !player.resolved.has(u.id)
    && covers(event.x, u) && Math.abs(u.time - event.time) <= (u.kind === 'air' ? 0.2 : 0.16)
    && (u.kind === 'air' ? isAir : event.y > 0.72 && (event.action === 'down' || (old && Math.floor(old.x) !== Math.floor(event.x)))));
  candidates.sort((a, b) => Math.abs(a.time - event.time) - Math.abs(b.time - event.time));
  const target = candidates[0];
  if (target) {
    const delta = Math.abs(target.time - event.time);
    judge(player, target, delta <= 0.045 ? 'critical' : delta <= 0.09 ? 'justice' : 'attack', chartUnits.length);
  }
}
export function publicPlayer(p) {
  return { id: p.id, name: p.name, connected: p.connected, ready: p.ready, score: p.score, combo: p.combo,
    maxCombo: p.maxCombo, accuracy: p.judged ? p.earned / p.judged * 100 : 100, counts: p.counts, last: p.last };
}
