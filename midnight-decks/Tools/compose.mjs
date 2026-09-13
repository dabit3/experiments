import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const rate = 44100, bpm = 128, beat = 60 / bpm, duration = 64;
const samples = new Float64Array(rate * duration);
let seed = 317;
const noise = () => {
  seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
  return seed / 2147483648 - 1;
};
function voice(start, length, fn, gain = 1) {
  const offset = Math.round(start * rate);
  for (let i = 0; i < length * rate && offset + i < samples.length; i++) {
    samples[offset + i] += gain * fn(i / rate);
  }
}
const hz = midi => 440 * 2 ** ((midi - 69) / 12);
const roots = [33, 33, 36, 31, 33, 40, 36, 31];
const melody = [0, 7, 12, 7, 3, 10, 15, 10, 0, 7, 12, 19, 10, 7, 3, 7];
for (let b = 0; b < 128; b++) {
  const t = 2 + b * beat;
  const section = Math.floor(b / 16);
  const breakdown = section === 4;
  if (!breakdown || b % 4 === 0) {
    voice(t, .42, s => Math.sin(2 * Math.PI * (48 * s + 8 * (1 - Math.exp(-s * 35)))) * Math.exp(-s * 13), .65);
  }
  if (b % 2 === 1 && section !== 0) {
    voice(t, .18, s => noise() * Math.exp(-s * 28) * (.65 + .35 * Math.sin(s * 2200)), .22);
  }
  for (let half = 0; half < 2; half++) {
    voice(t + half * beat / 2, .07, s => noise() * Math.exp(-s * 65), half ? .10 : .06);
  }
  const rootNote = roots[Math.floor(b / 16)];
  if (!breakdown) {
    voice(t + beat / 2, beat * .43, s => {
      const f = hz(rootNote);
      return (Math.sin(s * f * Math.PI * 2) + .3 * Math.sin(s * f * Math.PI * 4)) * Math.min(1, s * 300) * Math.exp(-s * 10);
    }, .27);
  }
  for (let eighth = 0; eighth < 2; eighth++) {
    const note = rootNote + 24 + melody[(b * 2 + eighth) % melody.length];
    voice(t + eighth * beat / 2, .35, s => {
      const f = hz(note);
      return (Math.sin(2 * Math.PI * f * s) + .22 * Math.sin(4 * Math.PI * f * s)) * Math.min(1, s * 180) * Math.exp(-s * 11);
    }, section < 2 ? .09 : .15);
  }
  if (b % 8 === 0) {
    for (const interval of [0, 3, 7]) {
      voice(t, beat * 7.9, s => Math.sin(2 * Math.PI * hz(rootNote + 24 + interval) * s) * Math.sin(Math.PI * s / (beat * 8)), .026);
    }
  }
}
const pcm = Buffer.alloc(samples.length * 2);
for (let i = 0; i < samples.length; i++) {
  const fade = Math.min(1, i / rate / .02, (duration - i / rate) / 2);
  pcm.writeInt16LE(Math.round(Math.tanh(samples[i]) * fade * 29000), i * 2);
}
const header = Buffer.alloc(44);
header.write('RIFF'); header.writeUInt32LE(pcm.length + 36, 4); header.write('WAVEfmt ', 8);
header.writeUInt32LE(16, 16); header.writeUInt16LE(1, 20); header.writeUInt16LE(1, 22);
header.writeUInt32LE(rate, 24); header.writeUInt32LE(rate * 2, 28);
header.writeUInt16LE(2, 32); header.writeUInt16LE(16, 34); header.write('data', 36);
header.writeUInt32LE(pcm.length, 40);
fs.writeFileSync(path.join(root, 'Resources/afterimage.wav'), Buffer.concat([header, pcm]));

const notes = [];
const add = (b, lane, hold = 0) => notes.push({
  id: notes.length, lane, time: Math.round((2 + b * beat) * 1000),
  duration: Math.round(hold * beat * 1000),
});
const motif = [1, 3, 5, 7, 2, 4, 6, 3, 1, 5, 7, 4, 2, 6, 5, 3];
for (let b = 0; b < 128; b++) {
  const section = Math.floor(b / 16);
  if (section === 4) {
    if (b % 4 === 0) add(b, [1, 3, 5, 7][(b / 4) % 4], 2);
    if (b % 4 === 3) add(b, 0);
  } else {
    const lane = motif[b % 16];
    add(b, lane, b % 16 === 14 ? .5 : 0);
    if (b % 8 === 3 || b % 8 === 7) add(b + .5, 0);
    if (section >= 2 && b % 4 === 1) add(b, lane <= 3 ? lane + 4 : lane - 3);
    if (section >= 5 && b % 4 === 2) add(b + .5, lane % 7 + 1);
  }
}
notes.sort((a, b) => a.time - b.time || a.lane - b.lane);
notes.forEach((n, i) => { n.id = i; });
const chart = {
  id: 'afterimage-normal-v1', title: 'AFTERIMAGE', subtitle: '03:17 / MIDNIGHT SYSTEM',
  bpm, duration: duration * 1000, difficulty: 'NORMAL 04', notes,
  sections: ['WARM UP', 'IGNITION', 'PHASE SHIFT', 'FULL FREQUENCY', 'SUSPENSION', 'RE-ENTRY', 'AFTERBURN', 'LAST LIGHT'],
};
fs.writeFileSync(path.join(root, 'Resources/chart.json'), JSON.stringify(chart, null, 2) + '\n');
console.log(`Authored ${duration}s track, ${notes.length} notes, ${notes.filter(n => n.duration).length} charge notes.`);
