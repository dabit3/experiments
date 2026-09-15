import { writeFileSync, mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { SONGS, chartFor } from '../server/game.mjs';

const output = fileURLToPath(new URL('../Resources/', import.meta.url));
mkdirSync(output, { recursive: true });
const rate = 44100;
let seed = 772;
function noise() {
  seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
  return seed / 2147483648 - 1;
}
function voice(buffer, at, duration, kind, frequency = 220, volume = 0.3) {
  const start = Math.round(at * rate);
  for (let frame = 0; frame < duration * rate && start + frame < buffer.length; frame++) {
    if (start + frame < 0) continue;
    const time = frame / rate;
    let sample = 0;
    if (kind === 'don') {
      const phase = 2 * Math.PI * (70 * time + 85 * 0.035 * (1 - Math.exp(-time / 0.035)));
      sample = Math.sin(phase) * Math.exp(-time * 12) + noise() * Math.exp(-time * 85) * 0.25;
    } else if (kind === 'ka') {
      sample = (Math.sin(time * 2 * Math.PI * 1200) * 0.6 + noise() * 0.4) * Math.exp(-time * 65);
    } else if (kind === 'shaker') {
      sample = noise() * Math.exp(-time * 70) * 0.3;
    } else if (kind === 'bass') {
      sample = (Math.sin(time * 2 * Math.PI * frequency) + 0.2 * Math.sin(time * 4 * Math.PI * frequency)) *
        Math.min(1, time * 100) * Math.exp(-time * 5);
    } else {
      const envelope = Math.min(1, time * 120) * Math.exp(-time * 5);
      sample = (Math.sin(time * 2 * Math.PI * frequency) + 0.22 * Math.sin(time * 4 * Math.PI * frequency)) * envelope;
    }
    buffer[start + frame] += sample * volume;
  }
}
function save(name, samples) {
  const header = Buffer.alloc(44);
  header.write('RIFF'); header.writeUInt32LE(samples.length * 2 + 36, 4);
  header.write('WAVEfmt ', 8); header.writeUInt32LE(16, 16); header.writeUInt16LE(1, 20);
  header.writeUInt16LE(1, 22); header.writeUInt32LE(rate, 24); header.writeUInt32LE(rate * 2, 28);
  header.writeUInt16LE(2, 32); header.writeUInt16LE(16, 34); header.write('data', 36);
  header.writeUInt32LE(samples.length * 2, 40);
  const pcm = Buffer.alloc(samples.length * 2);
  for (let index = 0; index < samples.length; index++) {
    pcm.writeInt16LE(Math.round(Math.tanh(samples[index]) * 29000), index * 2);
  }
  writeFileSync(`${output}/${name}.wav`, Buffer.concat([header, pcm]));
}

const melody = [
  [0, 2, 4, 7, 9, 7, 4, 2], [4, 7, 9, 12, 9, 7, 4, 7],
  [9, 7, 4, 2, 0, 2, 4, 7], [4, 2, 0, -3, 0, 4, 2, 0],
];
for (const song of SONGS) {
  const chart = chartFor(song.id);
  const buffer = new Float32Array(Math.ceil(chart.duration / 1000 * rate));
  const beat = 60 / song.bpm;
  for (let index = 0; index < 4; index++) voice(buffer, 0.25 + index * 0.4, 0.12, 'ka', 220, 0.22);
  for (let bar = 0; bar < song.bars; bar++) {
    const start = 2 + bar * 4 * beat;
    const section = Math.floor(bar / 4) % 4;
    const root = song.id === 'moon' ? 220 : 261.6256;
    for (let cell = 0; cell < 8; cell++) {
      const at = start + cell * beat / 2;
      voice(buffer, at, 0.1, 'shaker', 220, cell % 2 ? 0.16 : 0.3);
      voice(buffer, at, beat * 0.8, 'bell', root * 2 ** (melody[section][cell] / 12), 0.14);
      if (cell % 2 === 0) voice(buffer, at, beat, 'bass', root / (section === 2 ? 2.67 : 2), 0.2);
    }
    voice(buffer, start, 0.5, 'don', 220, 0.45);
    voice(buffer, start + beat * 2, 0.5, 'don', 220, 0.4);
    voice(buffer, start + beat, 0.1, 'ka', 220, 0.23);
    voice(buffer, start + beat * 3, 0.1, 'ka', 220, 0.23);
    if (bar % 4 === 3) {
      for (let index = 0; index < 4; index++) voice(buffer, start + beat * (3 + index / 4), 0.2, 'don', 220, 0.19 + index * 0.03);
    }
  }
  for (const note of chart.notes.filter(note => note.big)) voice(buffer, note.at / 1000, 0.6, 'bell', 1046.5, 0.1);
  save(song.id, buffer);
  for (const difficulty of ['easy', 'festival']) {
    writeFileSync(`${output}/${song.id}-${difficulty}.json`, JSON.stringify(chartFor(song.id, difficulty)));
  }
}
for (const kind of ['don', 'ka']) {
  const buffer = new Float32Array(rate * 0.4);
  voice(buffer, 0, 0.4, kind, 220, 0.65);
  save(kind, buffer);
}
const fanfare = new Float32Array(rate * 3);
[0, 4, 7, 12, 7, 12].forEach((note, index) => voice(fanfare, index * 0.22, 0.9, 'bell', 523.25 * 2 ** (note / 12), 0.3));
save('fanfare', fanfare);
console.log('Composed two original songs, four fixed charts, drum samples and result fanfare.');
