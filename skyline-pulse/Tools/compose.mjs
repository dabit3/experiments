import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const rate = 44100;
const songs = [
  { id: 'neon', title: 'NEON ASCENT', artist: 'SKYLINE SOUND SYSTEM', bpm: 128, level: '05', color: 'cyan', bars: 24, root: 57 },
  { id: 'aurora', title: 'AURORA CIRCUIT', artist: 'SKYLINE SOUND SYSTEM', bpm: 144, level: '08', color: 'pink', bars: 28, root: 62 },
];
// Four eight-beat phrases: call, sustain, answer, ascending release.
const phrases = [
  [[0, 2, 'tap'], [1, 10, 'tap'], [2, 5, 'tap'], [3, 12, 'air'], [4, 1, 'hold', 2], [4.5, 11, 'tap'], [5.5, 9, 'tap'], [6.5, 5, 'tap'], [7, 11, 'tap']],
  [[0, 2, 'slide', 3, 10], [1, 13, 'tap'], [3.5, 10, 'air'], [4, 12, 'hold', 2], [4.5, 2, 'tap'], [5.5, 5, 'tap'], [6.5, 9, 'tap'], [7, 3, 'air']],
  [[0, 1, 'tap'], [0.5, 5, 'tap'], [1, 10, 'tap'], [2, 10, 'slide', 3, 2], [3, 1, 'tap'], [5.5, 2, 'air'], [6, 11, 'tap'], [7, 5, 'tap']],
  [[0, 2, 'hold', 2], [0, 11, 'hold', 2], [2.5, 3, 'air'], [3, 10, 'air'], [4, 2, 'tap'], [5, 5, 'tap'], [6, 8, 'tap'], [7, 11, 'air']],
];
const charts = songs.map((song) => {
  const beat = 60 / song.bpm;
  const notes = [];
  for (let phrase = 0; phrase < song.bars / 2; phrase++) {
    const pattern = phrases[phrase % phrases.length];
    for (const [b, lane, kind, duration = 0, end = lane] of pattern) {
      notes.push({
        id: notes.length, kind, time: +( (4 + phrase * 8 + b) * beat).toFixed(6),
        lane, width: kind === 'air' ? 4 : 3,
        endLane: end, duration: +(duration * beat).toFixed(6),
      });
    }
    if (song.id === 'aurora' && phrase % 4 === 0) {
      for (const [b, lane] of [[1.5, 5], [2.5, 9], [6, 12]]) {
        notes.push({ id: notes.length, kind: 'tap', time: (4 + phrase * 8 + b) * beat, lane, width: 2, endLane: lane, duration: 0 });
      }
    }
  }
  return { ...song, duration: (song.bars * 4 + 8) * beat, tick: beat / 2, notes };
});
fs.writeFileSync(path.join(root, 'Assets/charts.json'), JSON.stringify(charts, null, 2));

function render(song) {
  const count = Math.ceil(song.duration * rate);
  const left = new Float32Array(count);
  const right = new Float32Array(count);
  let seed = 991;
  const noise = () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 2147483648 - 1; };
  const beat = 60 / song.bpm;
  function voice(start, length, amplitude, pan, synth) {
    const offset = Math.floor(start * rate);
    const n = Math.floor(length * rate);
    for (let i = 0; i < n && offset + i < count; i++) {
      const t = i / rate;
      const fade = Math.min(1, i / 140) * Math.min(1, (n - i) / 500);
      const v = amplitude * fade * synth(t, i / n);
      left[offset + i] += v * (0.7 - pan * 0.25);
      right[offset + i] += v * (0.7 + pan * 0.25);
    }
  }
  const hz = (midi) => 440 * 2 ** ((midi - 69) / 12);
  const melody = [0, 7, 12, 14, 12, 7, 3, 7, 0, 3, 10, 12, 15, 14, 10, 7];
  const progression = [0, -5, -2, -7];
  for (let bar = 0; bar < song.bars + 2; bar++) {
    const start = bar * 4 * beat;
    const chord = song.root + progression[Math.floor(bar / 2) % 4];
    for (const interval of [0, 3, 7, 14]) {
      const f = hz(chord + interval);
      voice(start, 4 * beat, 0.052, interval / 14 - 0.5,
        (t, p) => Math.sin(Math.PI * p) * (Math.sin(2 * Math.PI * f * t) + 0.3 * Math.sin(2 * Math.PI * f * 1.003 * t)));
    }
    for (let b = 0; b < 4; b++) {
      const s = start + b * beat;
      voice(s, 0.28, 0.48, 0, (t) => Math.sin(2 * Math.PI * (47 * t + 9 * (1 - Math.exp(-t * 35)))) * Math.exp(-t * 15));
      const bass = hz(chord - 12 + (b === 3 ? 7 : 0));
      voice(s + 0.02, beat * 0.7, 0.18, 0, (t) => Math.exp(-t * 6) * (Math.sin(2 * Math.PI * bass * t) + 0.2 * Math.sin(4 * Math.PI * bass * t)));
      if (b % 2 === 1) voice(s, 0.19, 0.14, 0.2, (t) => noise() * Math.exp(-t * 23));
      for (let h = 0; h < 2; h++) voice(s + h * beat / 2, 0.07, h ? 0.07 : 0.045, h ? 0.7 : -0.7, (t) => noise() * Math.exp(-t * 55));
      if (bar >= 1 && bar <= song.bars) {
        for (let h = 0; h < 2; h++) {
          const note = song.root + 12 + melody[(bar * 8 + b * 2 + h) % melody.length];
          const f = hz(note);
          voice(s + h * beat / 2, beat * 0.75, 0.12, Math.sin(bar + b),
            (t) => Math.exp(-t * 8) * (Math.sin(2 * Math.PI * f * t) + 0.25 * Math.sin(4 * Math.PI * f * t)));
          voice(s + h * beat / 2 + beat * 0.75, beat / 2, 0.025, -0.8,
            (t) => Math.exp(-t * 10) * Math.sin(2 * Math.PI * f * t));
        }
      }
    }
  }
  const pcm = Buffer.alloc(count * 4 + 44);
  pcm.write('RIFF'); pcm.writeUInt32LE(pcm.length - 8, 4); pcm.write('WAVEfmt ', 8);
  pcm.writeUInt32LE(16, 16); pcm.writeUInt16LE(1, 20); pcm.writeUInt16LE(2, 22);
  pcm.writeUInt32LE(rate, 24); pcm.writeUInt32LE(rate * 4, 28); pcm.writeUInt16LE(4, 32);
  pcm.writeUInt16LE(16, 34); pcm.write('data', 36); pcm.writeUInt32LE(count * 4, 40);
  for (let i = 0; i < count; i++) {
    const fade = Math.min(1, (count - i) / (rate * 1.2));
    pcm.writeInt16LE(Math.round(Math.tanh(left[i] * 1.3) * 28000 * fade), 44 + i * 4);
    pcm.writeInt16LE(Math.round(Math.tanh(right[i] * 1.3) * 28000 * fade), 46 + i * 4);
  }
  fs.writeFileSync(path.join(root, `Assets/${song.id}.wav`), pcm);
}
charts.forEach(render);
console.log(charts.map((s) => `${s.title}: ${s.notes.length} notes, ${s.duration.toFixed(2)}s`).join('\n'));
