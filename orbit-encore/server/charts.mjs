export function target(lane, radius = 0.82) {
  const angle = Math.PI / 2 - (lane + 0.5) * Math.PI / 4;
  return { x: Math.cos(angle) * radius, y: Math.sin(angle) * radius };
}

function makeChart(id, title, bpm, bars, difficulty, level) {
  const beat = 60 / bpm;
  const notes = [];
  const add = (b, lane, kind = 'tap', duration = 0, path = []) => {
    notes.push({ id: notes.length, time: +(b * beat).toFixed(6), lane, kind,
      duration: +(duration * beat).toFixed(6), path });
  };
  // Four count-in beats, then six/eight deliberate four-bar musical phrases.
  for (let bar = 1; bar < bars; bar++) {
    const b = bar * 4;
    const phrase = (bar - 1) % 6;
    const lane = (bar * 3) % 8;
    if (phrase === 0) {
      [0, 1, 2, 3].forEach((offset, i) => add(b + offset, (lane + i) % 8));
    } else if (phrase === 1) {
      add(b, lane, 'hold', 2);
      add(b + 1, (lane + 4) % 8);
      add(b + 3, (lane + 2) % 8, 'break');
    } else if (phrase === 2) {
      const end = (lane + 3) % 8;
      const start = target(lane);
      const finish = target(end);
      const path = [start, { x: start.x * 0.48, y: start.y * 0.48 },
        { x: finish.x * 0.48, y: finish.y * 0.48 }, finish];
      add(b, lane, 'slide', 2, path);
      add(b + 3, (lane + 5) % 8);
    } else if (phrase === 3) {
      add(b, lane, 'each');
      add(b, (lane + 4) % 8, 'each');
      add(b + 2, (lane + 1) % 8, 'each');
      add(b + 2, (lane + 5) % 8, 'each');
    } else if (phrase === 4) {
      const path = Array.from({ length: 5 }, (_, i) => target((lane + i * 0.75) % 8, 0.82));
      add(b, lane, 'slide', 2.5, path);
      add(b + 3.5, (lane + 5) % 8, 'break');
    } else {
      const offsets = level > 5 ? [0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5] : [0, 1, 2, 2.5, 3];
      offsets.forEach((offset, i) => add(b + offset, (lane - i + 16) % 8));
    }
  }
  notes.sort((a, b) => a.time - b.time || a.id - b.id);
  notes.forEach((n, id) => { n.id = id; });
  return { id, title, artist: 'ORBIT SOUND SYSTEM', bpm, bars, difficulty, level,
    duration: (bars * 4 + 4) * beat, notes };
}

export const charts = [
  makeChart('sugar', 'Sugar Satellite', 128, 24, 'ADVANCED', 5),
  makeChart('neon', 'Neon Perihelion', 150, 32, 'EXPERT', 8),
];
