import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import console from 'node:console';
import {readFileSync} from 'node:fs';
import {dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const dir = dirname(fileURLToPath(import.meta.url));
const root = resolve(dir, '../..');
const manifest = JSON.parse(readFileSync(resolve(dir, 'template.json'), 'utf8'));
const video = resolve(root, 'out', `${manifest.id}.mp4`);
const probe = JSON.parse(execFileSync('ffprobe', [
  '-v', 'error', '-show_streams', '-show_format', '-of', 'json', video,
], {encoding: 'utf8'}));
const stream = probe.streams.find((item) => item.codec_type === 'video');
assert(stream, 'Missing video stream');
assert.equal(stream.codec_name, 'h264');
assert.equal(stream.width, manifest.width);
assert.equal(stream.height, manifest.height);
assert.equal(stream.r_frame_rate, `${manifest.fps}/1`);
assert.equal(stream.avg_frame_rate, `${manifest.fps}/1`);
assert.equal(Number(stream.nb_frames), manifest.durationSeconds * manifest.fps);
assert.equal(Number(stream.duration), manifest.durationSeconds);
assert(Math.abs(Number(probe.format.duration) - manifest.durationSeconds) < 0.1);

const ffmpeg = (args) => execFileSync('ffmpeg', [
  '-hide_banner', '-loglevel', 'error', '-y', '-i', video, ...args,
], {stdio: 'inherit'});

ffmpeg(['-f', 'null', '-']);
ffmpeg([
  '-vf', "select='eq(n,60)'", '-frames:v', '1', '-update', '1',
  resolve(root, 'out', `${manifest.id}-poster.png`),
]);

const frames = [
  0, 60, 134, 135, 141, 195, 254, 255,
  261, 330, 419, 420, 426, 495, 555, 599,
  600, 606, 690, 779, 780, 786, 840, 944,
  945, 951, 1005, 1079, 1080, 1086, 1155, 1199,
];
const selected = frames.map((frame) => `eq(n,${frame})`).join('+');
ffmpeg([
  '-vf', `select='${selected}',scale=480:270,tile=4x8:padding=4:margin=4:color=0x1971c2`,
  '-frames:v', '1', '-update', '1',
  resolve(root, 'out', `${manifest.id}-contact-sheet.png`),
]);
ffmpeg([
  '-vf', "select='eq(n,60)+eq(n,195)+eq(n,330)+eq(n,495)+eq(n,690)+eq(n,840)+eq(n,1005)+eq(n,1155)'",
  '-fps_mode', 'vfr', resolve(root, 'out', `${manifest.id}-scene-%02d.png`),
]);
console.log(JSON.stringify({
  codec: stream.codec_name,
  width: stream.width,
  height: stream.height,
  fps: stream.r_frame_rate,
  frames: Number(stream.nb_frames),
  videoSeconds: Number(stream.duration),
  containerSeconds: Number(probe.format.duration),
  contactSheetFrames: frames,
  decode: 'passed',
}, null, 2));
