import assert from 'node:assert/strict';
import {execFileSync, spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {mkdirSync, readdirSync, readFileSync, writeFileSync} from 'node:fs';
import {dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const mediaDir = resolve(process.argv[2] ?? resolve(root, 'out'));
const folders = readdirSync(resolve(root, 'templates')).filter((name) => /^\d{2}-/.test(name)).sort();
assert.equal(folders.length, 20, 'The collection requires twenty templates');
const probe = (file) => JSON.parse(execFileSync('ffprobe', [
  '-v', 'error', '-show_streams', '-show_format', '-of', 'json', file,
], {encoding: 'utf8'}));
const rows = [];
for (const id of folders) {
  const metadata = JSON.parse(readFileSync(resolve(root, 'templates', id, 'template.json'), 'utf8'));
  const file = resolve(mediaDir, `${id}.mp4`);
  const info = probe(file);
  const videos = info.streams.filter((s) => s.codec_type === 'video');
  assert.equal(videos.length, 1, id);
  const video = videos[0];
  assert.equal(video.codec_name, 'h264', id);
  assert.equal(video.width, 1920, id);
  assert.equal(video.height, 1080, id);
  assert.equal(video.r_frame_rate, '30/1', id);
  assert.equal(video.avg_frame_rate, '30/1', id);
  assert(['yuv420p', 'yuvj420p'].includes(video.pix_fmt), `${id}: expected 8-bit 4:2:0`);
  assert.equal(Number(video.nb_frames), metadata.durationSeconds * 30, id);
  assert(Math.abs(Number(video.duration) - metadata.durationSeconds) < 0.001, `${id}: duration`);
  assert(Number(info.format.duration) >= Number(video.duration) &&
    Number(info.format.duration) - Number(video.duration) <= 0.1, `${id}: excessive container padding`);
  execFileSync('ffmpeg', ['-v', 'error', '-xerror', '-i', file, '-f', 'null', '-'], {stdio: 'pipe'});
  const poster = probe(resolve(mediaDir, `${id}-poster.png`)).streams[0];
  assert.equal(poster.codec_name, 'png', id);
  assert.equal(poster.width, 1920, `${id}: poster width`);
  assert.equal(poster.height, 1080, `${id}: poster height`);
  const audio = info.streams.filter((s) => s.codec_type === 'audio');
  let maximumDb = null;
  if (audio.length) {
    const result = spawnSync('ffmpeg', [
      '-hide_banner', '-i', file, '-vn', '-af', 'volumedetect', '-f', 'null', '-',
    ], {encoding: 'utf8'});
    assert.equal(result.status, 0, result.stderr);
    const match = result.stderr.match(/max_volume: ([\d.-]+) dB/);
    assert(match, `${id}: missing audio measurement`);
    maximumDb = Number(match[1]);
  }
  if (id === '06-kinetic-type') assert(maximumDb !== null && maximumDb > -40, 'Missing original beat');
  else assert(maximumDb === null || maximumDb <= -90, `${id}: expected silence`);
  rows.push({
    id, title: metadata.title, codec: video.codec_name, width: video.width, height: video.height,
    fps: video.avg_frame_rate, frames: Number(video.nb_frames), videoSeconds: Number(video.duration),
    containerSeconds: Number(info.format.duration), pixelFormat: video.pix_fmt,
    audioCodecs: audio.map((s) => s.codec_name), maximumDb,
    sha256: createHash('sha256').update(readFileSync(file)).digest('hex'),
    poster: '1920×1080 PNG', fullDecode: 'passed',
  });
  console.log(`${id}: ${video.duration}s, ${video.nb_frames} frames, decoded successfully`);
}
mkdirSync(resolve(root, 'out'), {recursive: true});
writeFileSync(resolve(root, 'out', 'media-validation.json'), `${JSON.stringify(rows, null, 2)}\n`);
