import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
const sampleRate = 22050;
const folder = new URL('../Resources/', import.meta.url);
function wav(name, seconds, sample) {
  const count = Math.floor(seconds * sampleRate);
  const buffer = Buffer.alloc(44 + count * 2);
  buffer.write('RIFF'); buffer.writeUInt32LE(buffer.length - 8, 4); buffer.write('WAVEfmt ', 8);
  buffer.writeUInt32LE(16, 16); buffer.writeUInt16LE(1, 20); buffer.writeUInt16LE(1, 22);
  buffer.writeUInt32LE(sampleRate, 24); buffer.writeUInt32LE(sampleRate * 2, 28);
  buffer.writeUInt16LE(2, 32); buffer.writeUInt16LE(16, 34); buffer.write('data', 36);
  buffer.writeUInt32LE(count * 2, 40);
  for (let i = 0; i < count; i++) buffer.writeInt16LE(Math.round(Math.tanh(sample(i / sampleRate, i)) * 27000), 44 + i * 2);
  writeFileSync(fileURLToPath(new URL(`${name}.wav`, folder)), buffer);
}
const hz = note => 440 * 2 ** ((note - 69) / 12);
const sine = (t, frequency) => Math.sin(t * frequency * Math.PI * 2);
const beat = 60 / 124;
const bass = [40, 40, 47, 50, 43, 43, 50, 53, 45, 45, 52, 55, 47, 47, 54, 57];
const melody = [76, 79, 83, 81, 79, 76, 74, 71, 79, 83, 86, 83, 81, 79, 76, 74,
  81, 84, 88, 86, 84, 81, 79, 76, 83, 86, 90, 88, 86, 83, 81, 78];
wav('broadcast', beat * 64, (t, i) => {
  const b = t / beat, eighth = Math.floor(b * 2), local = (b * 2 % 1) * beat / 2;
  const kickT = (b % 1) * beat;
  const kick = sine(kickT, 46 + 75 * Math.exp(-kickT * 35)) * Math.exp(-kickT * 16) * 0.45;
  const noise = Math.sin(i * 112.43) * Math.sin(i * 37.71);
  const snareT = (b % 2) * beat;
  const snare = snareT > beat ? noise * Math.exp(-(snareT - beat) * 24) * 0.24 : 0;
  const hat = noise * Math.exp(-local * 90) * 0.1;
  const root = bass[Math.floor(b / 4) % bass.length];
  const bassLine = (sine(t, hz(root)) + sine(t, hz(root) * 2) * 0.25) * Math.exp(-local * 7) * 0.23;
  const lead = (sine(t, hz(melody[eighth % 32])) + sine(t, hz(melody[eighth % 32]) * 2) * 0.18)
    * Math.sin(Math.min(1, local / 0.025) * Math.PI / 2) * Math.exp(-local * 11) * 0.14;
  const chord = [12, 15, 19, 22].reduce((sum, n) => sum + sine(t, hz(root + n)), 0) * 0.025;
  return kick + snare + hat + bassLine + lead + chord;
});
wav('impact', 0.16, (t, i) => (sine(t, 80 - t * 220) + Math.sin(i * 24.123) * 0.6) * Math.exp(-t * 24));
wav('block', 0.2, t => (sine(t, 1250) + sine(t, 1800) * 0.4) * Math.exp(-t * 23) * 0.6);
wav('summon', 0.6, t => (sine(t, 220 + t * 880) + sine(t, 440 + t * 440) * 0.4) * Math.sin(t / 0.6 * Math.PI) * 0.5);
wav('sting', 0.9, t => [52, 59, 64, 68].reduce((sum, n) => sum + sine(t, hz(n)), 0) * Math.exp(-t * 3) * 0.25);
