import tokens from "../../../assets/tokens.json";
import { Easing } from "remotion";

export const color = tokens.color;
export const type = tokens.type;
export const space = tokens.space;
export const radius = tokens.radius;
export const shadow = tokens.shadow;

export const FPS = tokens.video.fps;
export const WIDTH = tokens.video.width;
export const HEIGHT = tokens.video.height;
export const MARGIN = tokens.space.frameMargin1080p;

const [o1, o2, o3, o4] = tokens.motion.easeOut;
const [i1, i2, i3, i4] = tokens.motion.easeInOut;

export const easeOut = Easing.bezier(o1, o2, o3, o4);
export const easeInOut = Easing.bezier(i1, i2, i3, i4);
export const easeIn = Easing.bezier(0.7, 0, 0.84, 0);

export const ms = (milliseconds: number) => Math.round((milliseconds / 1000) * FPS);
export const sec = (seconds: number) => Math.round(seconds * FPS);

export const dur = {
  fast: ms(tokens.motion.durationMs.fast),
  base: ms(tokens.motion.durationMs.base),
  slow: ms(tokens.motion.durationMs.slow),
  hold: ms(tokens.motion.durationMs.hold),
};
