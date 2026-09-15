import { Easing, interpolate } from "remotion";
import { tokens } from "./tokens";

const [o1, o2, o3, o4] = tokens.motion.easeOut;
const [i1, i2, i3, i4] = tokens.motion.easeInOut;

export const easeOut = Easing.bezier(o1, o2, o3, o4);
export const easeInOut = Easing.bezier(i1, i2, i3, i4);
export const easeIn = Easing.bezier(0.7, 0, 0.84, 0);

export type EasingFn = (t: number) => number;

/** Clamped interpolation from `start` over `dur` frames. */
export const tween = (
  frame: number,
  start: number,
  dur: number,
  easing: EasingFn = easeOut,
  from = 0,
  to = 1,
): number =>
  interpolate(frame, [start, start + dur], [from, to], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing,
  });

/** Frames for a duration in ms at 30fps. */
export const ms = (m: number): number => Math.round((m / 1000) * tokens.motion.fps);

export const FAST = ms(tokens.motion.durationMs.fast);
export const BASE = ms(tokens.motion.durationMs.base);
export const SLOW = ms(tokens.motion.durationMs.slow);

/** Whole-number counter that eases from `from` to `to`. */
export const count = (
  frame: number,
  start: number,
  dur: number,
  to: number,
  from = 0,
  easing: EasingFn = easeOut,
): number => Math.round(tween(frame, start, dur, easing, from, to));

export const pad2 = (n: number): string => n.toString().padStart(2, "0");

/** m:ss from total seconds. */
export const clock = (totalSeconds: number): string => {
  const s = Math.max(0, Math.floor(totalSeconds));
  return `${Math.floor(s / 60)}:${pad2(s % 60)}`;
};
