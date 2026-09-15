import { Easing, interpolate } from "remotion";
import { motion } from "./tokens";

const [o1, o2, o3, o4] = motion.easeOut;
const [i1, i2, i3, i4] = motion.easeInOut;

export const easeOut = Easing.bezier(o1, o2, o3, o4);
export const easeInOut = Easing.bezier(i1, i2, i3, i4);
export const easeIn = Easing.bezier(0.55, 0, 1, 0.45);

export const FPS = motion.fps;

/** Milliseconds -> frames at the composition fps. */
export const ms = (m: number): number => Math.round((m / 1000) * FPS);

/** 0..1 progress of `frame` across [start, start + dur], clamped, eased. */
export const prog = (
  frame: number,
  start: number,
  dur: number,
  easing: (t: number) => number = easeOut,
): number =>
  interpolate(frame, [start, start + Math.max(1, dur)], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing,
  });

/** Fade in with ease-out, then fade out with ease-in over the last `outDur` frames. */
export const fadeInOut = (
  frame: number,
  start: number,
  end: number,
  inDur = ms(300),
  outDur = ms(300),
): number => {
  const a = prog(frame, start, inDur, easeOut);
  const b = 1 - prog(frame, end - outDur, outDur, easeIn);
  return Math.min(a, b);
};

/** Deterministic pseudo-random generator (mulberry32). */
export const rng = (seed: number) => {
  let s = seed >>> 0;
  return () => {
    s = (s + 0x6d2b79f5) >>> 0;
    let t = s;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
};
