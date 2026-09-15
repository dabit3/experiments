import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// Explicit four-bar melodic motifs, bass progression and panel choreography.
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const rate = 44100;
const themes = [
  { id: 'refraction', title: 'REFRACTION', artist: 'PRISM SOUND SYSTEM', bpm: 128,
    tagline: 'Light bends. Rhythm connects.', key: 57,
    melody: [12, 19, 24, 19, 15, 19, 22, 19, 12, 17, 24, 17, 10, 17, 22, 17],
    chords: [0, 5, 3, 7] },
  { id: 'afterglow', title: 'AFTERGLOW', artist: 'PRISM SOUND SYSTEM', bpm: 144,
    tagline: 'One last pulse after midnight.', key: 54,
    melody: [12, 15, 19, 22, 24, 22, 19, 15, 10, 14, 17, 22, 24, 22, 17, 14],
    chords: [0, 3, 8, 5] },
];
const phrases = [
  [0, 5, 10, 15, 3, 6, 9, 12],
  [4, 5, 6, 7, 11, 10, 9, 8],
  [0, 4, 8, 12, 15, 11, 7, 3],
  [1, 2, 6, 5, 9, 10, 14, 13],
  [0, 3, 12, 15, 5, 6, 9, 10],
  [12, 9, 6, 3, 15, 10, 5, 0],
];
const midi = n => 440 * 2 ** ((n - 69) / 12);
const catalog = [];
for (const theme of themes) {
  const beat = 60 / theme.bpm;
  const duration = 96 * beat + 2;
  const samples = new Float32Array(Math.ceil(duration * rate));
  let noiseSeed = 1427;
  const noise = () => {
    noiseSeed = (1664525 * noiseSeed + 1013904223) >>> 0;
    return noiseSeed / 2147483648 - 1;
  };
  function voice(time, length, fn, amplitude) {
    const begin = Math.round(time * rate);
    const count = Math.min(Math.round(length * rate), samples.length - begin);
    for (let i = 0; i < count; i++) {
      const t = i / rate;
      samples[begin + i] += fn(t, i) * amplitude;
    }
  }
  for (let b = 0; b < 96; b++) {
    const section = Math.floor(b / 16);
    const chord = theme.chords[Math.floor(b / 8) % 4];
    const breakSection = section === 3;
    if (!breakSection || b % 2 === 0) {
      voice(b * beat, .3, t => Math.sin(2 * Math.PI * (48 * t + 6 * (1 - Math.exp(-t * 35)))) * Math.exp(-t * 17), .55);
    }
    if (b % 2 === 1 && !breakSection) {
      voice(b * beat, .17, t => (noise() * .7 + Math.sin(2 * Math.PI * 185 * t) * .3) * Math.exp(-t * 25), .28);
    }
    for (let h = 0; h < 2; h++) {
      voice((b + h * .5) * beat, .055, t => noise() * Math.exp(-t * 75), h ? .11 : .055);
    }
    const bass = midi(theme.key - 24 + chord);
    voice(b * beat, beat * .85, t => (Math.sin(2 * Math.PI * bass * t) + .3 * Math.sin(4 * Math.PI * bass * t)) * Math.min(t * 100, 1) * Math.exp(-t * 5), .24);
    const melody = midi(theme.key + theme.melody[b % 16] + (section === 5 ? 12 : 0));
    for (let h = 0; h < 2; h++) {
      const freq = h ? melody * 1.5 : melody;
      const amp = breakSection ? .11 : .18;
      const pluck = t => (Math.sin(2 * Math.PI * freq * t) + .28 * Math.sin(4 * Math.PI * freq * t)) * Math.min(t * 200, 1) * Math.exp(-t * 10);
      voice((b + h * .5) * beat, .5, pluck, amp);
      voice((b + h * .5 + .75) * beat, .5, pluck, amp * .24);
    }
    if (b % 4 === 0) {
      for (const interval of [0, 3, 7, 12]) {
        const f = midi(theme.key + chord + interval);
        voice(b * beat, beat * 4, t => Math.sin(2 * Math.PI * f * t) * Math.sin(Math.PI * t / (beat * 4)), .028);
      }
    }
  }
  let peak = 0;
  for (const value of samples) peak = Math.max(peak, Math.abs(value));
  const wav = Buffer.alloc(44 + samples.length * 2);
  wav.write('RIFF'); wav.writeUInt32LE(wav.length - 8, 4); wav.write('WAVEfmt ', 8);
  wav.writeUInt32LE(16, 16); wav.writeUInt16LE(1, 20); wav.writeUInt16LE(1, 22);
  wav.writeUInt32LE(rate, 24); wav.writeUInt32LE(rate * 2, 28);
  wav.writeUInt16LE(2, 32); wav.writeUInt16LE(16, 34); wav.write('data', 36);
  wav.writeUInt32LE(samples.length * 2, 40);
  for (let i = 0; i < samples.length; i++) {
    const fade = Math.min(1, (samples.length - i) / rate);
    wav.writeInt16LE(Math.round(samples[i] / peak * .88 * fade * 32767), 44 + i * 2);
  }
  fs.writeFileSync(path.join(root, 'Resources', `${theme.id}.wav`), wav);
  const charts = {};
  for (const [difficulty, stride] of [['BASIC', 2], ['ADVANCED', 1], ['EXTREME', .5]]) {
    const notes = [];
    for (let b = 4; b < 94; b += stride) {
      if (b >= 48 && b < 56 && b % 2 !== 0) continue;
      const phrase = phrases[Math.floor(b / 16) % phrases.length];
      const index = Math.floor((b - 4) / stride);
      const cell = phrase[index % 8];
      notes.push({ id: notes.length, cell, time: +(b * beat).toFixed(6) });
      if (b % 8 === 0 || (difficulty !== 'BASIC' && b % 4 === 2)) {
        notes.push({ id: notes.length, cell: 15 - cell, time: +(b * beat).toFixed(6) });
      }
    }
    charts[difficulty] = notes;
  }
  catalog.push({ ...theme, duration, charts });
}
fs.writeFileSync(path.join(root, 'Resources', 'catalog.json'), JSON.stringify(catalog, null, 2) + '\n');
const tapFrames = Math.round(rate * .045);
const tap = Buffer.alloc(44 + tapFrames * 2);
tap.write('RIFF'); tap.writeUInt32LE(tap.length - 8, 4); tap.write('WAVEfmt ', 8);
tap.writeUInt32LE(16, 16); tap.writeUInt16LE(1, 20); tap.writeUInt16LE(1, 22);
tap.writeUInt32LE(rate, 24); tap.writeUInt32LE(rate * 2, 28);
tap.writeUInt16LE(2, 32); tap.writeUInt16LE(16, 34); tap.write('data', 36);
tap.writeUInt32LE(tapFrames * 2, 40);
for (let i = 0; i < tapFrames; i++) {
  const t = i / rate;
  tap.writeInt16LE(Math.round(Math.sin(2 * Math.PI * 1600 * t) * Math.exp(-t * 120) * 16000), 44 + i * 2);
}
fs.writeFileSync(path.join(root, 'Resources', 'tap.wav'), tap);
console.log(`Generated ${catalog.length} original PCM tracks and six synchronized charts.`);
