import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {log} from 'node:console';
import {mkdirSync} from 'node:fs';
import {dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const out = resolve(root, 'out');
const qa = resolve(out, '04-terminal-native-qa');
const video = resolve(out, '04-terminal-native.mp4');
mkdirSync(qa, {recursive: true});

const probe = JSON.parse(execFileSync('ffprobe', [
  '-v', 'error', '-count_frames', '-show_entries',
  'stream=codec_name,width,height,r_frame_rate,nb_read_frames,duration:format=duration',
  '-of', 'json', video,
], {encoding: 'utf8'}));
const stream = probe.streams.find((item) => item.codec_name === 'h264');
assert(stream, 'Expected H.264');
assert.equal(stream.width, 1920);
assert.equal(stream.height, 1080);
assert.equal(stream.r_frame_rate, '30/1');
assert.equal(Number(stream.nb_read_frames), 1260);
assert.equal(Number(stream.duration), 42);
assert(Number(probe.format.duration) >= 42 && Number(probe.format.duration) < 42.1);

const frames = [
  20, 40, 110, 134, 173, 230, 280, 390,
  460, 505, 550, 650, 720, 815, 850, 890,
  912, 949, 1004, 1045, 1120, 1190, 1210, 1259,
];
const select = frames.map((frame) => `eq(n,${frame})`).join('+');
execFileSync('ffmpeg', [
  '-y', '-v', 'error', '-i', video, '-vf', `select='${select}'`,
  '-fps_mode', 'vfr', resolve(qa, 'frame-%02d.png'),
]);
execFileSync('ffmpeg', [
  '-y', '-v', 'error', '-framerate', '1', '-i', resolve(qa, 'frame-%02d.png'),
  '-vf', 'scale=480:270,tile=4x6:padding=12:margin=12:color=0x111111',
  '-frames:v', '1', '-update', '1', resolve(out, '04-terminal-native-contact-sheet.png'),
]);
execFileSync('ffmpeg', [
  '-y', '-v', 'error', '-i', video, '-vf', "select='eq(n,110)'",
  '-frames:v', '1', '-update', '1', resolve(out, '04-terminal-native-poster.png'),
]);
log(JSON.stringify(probe, null, 2));
log('QA frames in contact-sheet order (left to right, top to bottom):');
log(frames.map((frame) => `${frame} / ${(frame / 30).toFixed(2)}s`).join('\n'));
log('Media checks passed. Inspect the contact sheet and full-size frames visually.');
