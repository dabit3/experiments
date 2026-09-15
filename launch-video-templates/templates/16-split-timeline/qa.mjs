import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {readFileSync} from 'node:fs';
import {dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import console from 'node:console';

const folder = dirname(fileURLToPath(import.meta.url));
const root = resolve(folder, '../..');
const manifest = JSON.parse(readFileSync(resolve(folder, 'template.json'), 'utf8'));
const video = resolve(root, 'out', `${manifest.id}.mp4`);
const probe = JSON.parse(execFileSync('ffprobe', [
  '-v', 'error', '-show_streams', '-show_format', '-of', 'json', video,
], {encoding: 'utf8'}));
const stream = probe.streams.find((entry) => entry.codec_type === 'video');
assert(stream, 'Missing video stream');
assert.equal(stream.codec_name, 'h264');
assert.equal(stream.width, manifest.width);
assert.equal(stream.height, manifest.height);
assert.equal(stream.r_frame_rate, `${manifest.fps}/1`);
assert.equal(Number(stream.nb_frames), manifest.fps * manifest.durationSeconds);
assert.equal(Number(stream.duration), manifest.durationSeconds);

const poster = resolve(root, 'out', `${manifest.id}-poster.png`);
execFileSync('ffmpeg', [
  '-y', '-hide_banner', '-loglevel', 'error', '-i', video,
  '-vf', 'select=eq(n\\,75)', '-frames:v', '1', poster,
]);

const sceneFrames = [75, 201, 330, 435, 495, 555, 651, 810, 1035, 1155];
const boundaries = [120, 240, 390, 570, 750, 930, 1080];
const frames = [...sceneFrames, ...boundaries.flatMap((frame) => [frame, frame + 12])].sort((a, b) => a - b);
const sheet = resolve(root, 'out', `${manifest.id}-contact-sheet.png`);
const selection = frames.map((frame) => `eq(n\\,${frame})`).join('+');
execFileSync('ffmpeg', [
  '-y', '-hide_banner', '-loglevel', 'error', '-i', video,
  '-vf', `select=${selection},scale=640:360,tile=3x8:padding=12:margin=12:color=0x102229`,
  '-frames:v', '1', sheet,
]);
console.log(JSON.stringify({
  codec: stream.codec_name,
  resolution: [stream.width, stream.height],
  fps: stream.r_frame_rate,
  frames: stream.nb_frames,
  videoDuration: stream.duration,
  containerDuration: probe.format.duration,
  poster,
  contactSheet: sheet,
  contactSheetFrameOrder: frames,
}, null, 2));
