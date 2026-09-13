import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { charts } from '../server/charts.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../Resources');
fs.writeFileSync(path.join(root, 'charts.json'), JSON.stringify(charts));
const sampleRate = 44100;
const frequency = midi => 440 * 2 ** ((midi - 69) / 12);
for (const chart of charts) {
  const samples = new Float64Array(Math.ceil(chart.duration * sampleRate));
  const beat = 60 / chart.bpm;
  const add = (at, duration, synth) => {
    const start = Math.floor(at * sampleRate);
    for (let i = 0; i < duration * sampleRate && start + i < samples.length; i++) {
      samples[start + i] += synth(i / sampleRate, i);
    }
  };
  const chords = chart.id === 'sugar' ? [60, 57, 65, 67] : [57, 65, 60, 67];
  const melody = [12, 16, 19, 16, 14, 12, 7, 11, 12, 19, 24, 19, 16, 14, 12, 7];
  let seed = 8147;
  const noise = () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 2147483648 - 1; };
  for (let b = 0; b < chart.bars * 4; b++) {
    const at = b * beat;
    const rootNote = chords[Math.floor(Math.max(0, b - 4) / 16) % 4];
    add(at, 0.22, t => 0.52 * Math.sin(2 * Math.PI * (47 * t + 13 * (1 - Math.exp(-t * 30)) / 30)) * Math.exp(-t * 18));
    if (b % 2 === 1) add(at, 0.13, t => (noise() * 0.19 + Math.sin(2 * Math.PI * 180 * t) * 0.08) * Math.exp(-t * 24));
    for (const off of [0, 0.5]) add(at + off * beat, 0.06, t => noise() * 0.065 * Math.exp(-t * 65));
    if (b < 4) {
      add(at, 0.08, t => Math.sin(2 * Math.PI * (b === 3 ? 1320 : 880) * t) * 0.2 * Math.exp(-t * 40));
      continue;
    }
    const bassFreq = frequency(rootNote - 24);
    add(at + beat * 0.06, beat * 0.85, t => 0.14 * (Math.sin(2 * Math.PI * bassFreq * t) +
      0.28 * Math.sin(4 * Math.PI * bassFreq * t)) * Math.min(1, t * 100) * Math.exp(-t * 5));
    if (b % 4 === 0) {
      for (const interval of [0, 4, 7, 11]) {
        const freq = frequency(rootNote + interval);
        add(at, beat * 3.8, t => 0.025 * (Math.sin(2 * Math.PI * freq * t) + 0.3 * Math.sin(2 * Math.PI * freq * 1.003 * t)) *
          Math.min(1, t * 10) * Math.exp(-t * 1.8));
      }
    }
    for (const off of [0, 0.5]) {
      const index = ((b - 4) * 2 + off * 2) % melody.length;
      const freq = frequency(rootNote + melody[index]);
      add(at + off * beat, beat * 0.46, t => 0.10 * (Math.sin(2 * Math.PI * freq * t) +
        0.23 * Math.sin(4 * Math.PI * freq * t)) * Math.min(1, t * 180) * Math.exp(-t * 9));
    }
  }
  const buffer = Buffer.alloc(44 + samples.length * 2);
  buffer.write('RIFF', 0); buffer.writeUInt32LE(buffer.length - 8, 4); buffer.write('WAVEfmt ', 8);
  buffer.writeUInt32LE(16, 16); buffer.writeUInt16LE(1, 20); buffer.writeUInt16LE(1, 22);
  buffer.writeUInt32LE(sampleRate, 24); buffer.writeUInt32LE(sampleRate * 2, 28);
  buffer.writeUInt16LE(2, 32); buffer.writeUInt16LE(16, 34);
  buffer.write('data', 36); buffer.writeUInt32LE(samples.length * 2, 40);
  samples.forEach((sample, i) => buffer.writeInt16LE(Math.round(Math.tanh(sample * 1.3) * 28000), 44 + i * 2));
  fs.writeFileSync(path.join(root, `${chart.id}.wav`), buffer);
  console.log(`${chart.title}: ${chart.notes.length} notes, ${chart.duration.toFixed(2)}s`);
}
