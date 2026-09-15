import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {mkdirSync, writeFileSync} from 'node:fs';
import {dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {log} from 'node:console';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const output = resolve(root, 'out');
const qa = resolve(output, '11-warm-studio-qa');
mkdirSync(qa, {recursive: true});
const video = resolve(output, '11-warm-studio.mp4');
const probe = JSON.parse(execFileSync('ffprobe', [
  '-v', 'error', '-show_entries',
  'stream=codec_name,width,height,r_frame_rate,pix_fmt,nb_frames,color_space,color_range:format=duration',
  '-of', 'json', video,
], {encoding: 'utf8'}));
const stream = probe.streams[0];
assert.equal(probe.streams.length, 1);
assert.equal(stream.codec_name, 'h264');
assert.equal(stream.width, 1920);
assert.equal(stream.height, 1080);
assert.equal(stream.r_frame_rate, '30/1');
assert.equal(stream.pix_fmt, 'yuv420p');
assert.equal(stream.color_space, 'bt709');
assert.equal(stream.color_range, 'tv');
assert.equal(Number(stream.nb_frames), 1260);
assert.equal(Number(probe.format.duration), 42);
writeFileSync(resolve(qa, 'ffprobe.json'), JSON.stringify(probe, null, 2));

const frames = [
  0, 90, 150, 162,
  210, 270, 282, 360,
  435, 447, 480, 540,
  600, 615, 627, 705,
  780, 792, 870, 960,
  972, 1035, 1122, 1259,
];
const selection = frames.map((frame) => `eq(n\\,${frame})`).join('+');
const run = (args) => execFileSync('ffmpeg', ['-y', '-hide_banner', '-loglevel', 'error', ...args], {stdio: 'inherit'});
run(['-i', video, '-vf', 'select=eq(n\\,90)', '-frames:v', '1',
  resolve(output, '11-warm-studio-poster.png')]);
run(['-i', video, '-vf', `select=${selection}`, '-fps_mode', 'vfr',
  resolve(qa, 'frame-%02d.png')]);
run(['-i', video, '-vf', `select=${selection},scale=640:360,tile=4x6:padding=12:margin=20:color=0xF4F1EA`,
  '-frames:v', '1', resolve(output, '11-warm-studio-contact-sheet.png')]);
writeFileSync(resolve(qa, 'frame-map.json'), JSON.stringify(
  frames.map((frame, i) => ({image: `frame-${String(i + 1).padStart(2, '0')}.png`, frame, seconds: frame / 30})),
  null, 2,
));
log('Verified H.264 / 1920×1080 / 30fps / 42s / 1260 frames.');
log('Poster, 24 full-frame QA samples, and 4×6 contact sheet extracted.');
