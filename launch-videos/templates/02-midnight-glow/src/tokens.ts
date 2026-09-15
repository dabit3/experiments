import tokens from "../../../assets/tokens.json";
import { Easing } from "remotion";

export const T = tokens;

export const color = T.color;
export const radius = T.radius;

const [o1, o2, o3, o4] = T.motion.easeOut;
const [i1, i2, i3, i4] = T.motion.easeInOut;

export const easeOut = Easing.bezier(o1, o2, o3, o4);
export const easeInOut = Easing.bezier(i1, i2, i3, i4);
export const easeIn = Easing.in(Easing.cubic);

export const fps = T.video.fps;
export const sec = (s: number) => Math.round(s * fps);

export const MARGIN = T.space.frameMargin1080p;

/** Text glow bloom used on headlines (Midnight Glow signature). */
export const textGlow = (strength = 1) =>
  `0 0 ${24 * strength}px rgba(255,255,255,${0.18 * strength}), 0 0 ${64 * strength}px rgba(34,0,255,${0.35 * strength})`;

export const hairline = "rgba(255,255,255,0.14)";
