import { Easing, interpolate } from "remotion";
import { EASE_IN, EASE_IN_OUT, EASE_OUT } from "./tokens";

const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

export const easeOut = Easing.bezier(...EASE_OUT);
export const easeInOut = Easing.bezier(...EASE_IN_OUT);
export const easeIn = Easing.bezier(...EASE_IN);

/** Progress 0→1 between two frames with the given easing (clamped). */
export const progress = (
  frame: number,
  from: number,
  to: number,
  easing: (t: number) => number = easeInOut,
) => interpolate(frame, [from, to], [0, 1], { ...clamp, easing });

export const lerp = (a: number, b: number, t: number) => a + (b - a) * t;

/** Fade in over `inDur` frames from `start`, hold, fade out over `outDur` frames ending at `end`. */
export const fadeInOut = (
  frame: number,
  start: number,
  end: number,
  inDur: number,
  outDur: number,
) => {
  const i = progress(frame, start, start + inDur, easeOut);
  const o = 1 - progress(frame, end - outDur, end, easeIn);
  return Math.min(i, o);
};
