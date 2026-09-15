import { Easing } from "remotion";
import tokens from "../../../assets/tokens.json";

export const color = tokens.color;
export const type = tokens.type;
export const radius = tokens.radius;
export const shadow = tokens.shadow;
export const space = tokens.space;

export const FPS = tokens.video.fps;
export const WIDTH = tokens.video.width;
export const HEIGHT = tokens.video.height;

const [o1, o2, o3, o4] = tokens.motion.easeOut;
const [i1, i2, i3, i4] = tokens.motion.easeInOut;

export const easeOut = Easing.bezier(o1, o2, o3, o4);
export const easeInOut = Easing.bezier(i1, i2, i3, i4);
// Exits mirror the entrance curve.
export const easeIn = Easing.in(Easing.cubic);

export const sec = (s: number): number => Math.round(s * FPS);
