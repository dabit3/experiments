import {Easing} from 'remotion';
import raw from '../../../assets/tokens.json';

type Bezier = [number, number, number, number];

export const tokens = raw;
export const color = raw.color;
export const radius = raw.radius;
export const shadow = raw.shadow;
export const sizes = raw.type.sizes1080p;
export const tracking = raw.type.tracking;

export const MARGIN = raw.space.frameMargin1080p;
export const SAFE = raw.space.safeAreaInset1080p;
export const WIDTH = raw.video.width;
export const HEIGHT = raw.video.height;
export const FPS = raw.video.fps;

const bezier = (v: number[]): Bezier => [v[0], v[1], v[2], v[3]];

export const easeOut = Easing.bezier(...bezier(raw.motion.easeOut));
export const easeInOut = Easing.bezier(...bezier(raw.motion.easeInOut));
// Mirror of the ease-out curve, used for exits.
export const easeIn = Easing.bezier(0.7, 0, 0.84, 0);

export const ms = (milliseconds: number) => Math.round((milliseconds / 1000) * FPS);
export const sec = (seconds: number) => Math.round(seconds * FPS);
