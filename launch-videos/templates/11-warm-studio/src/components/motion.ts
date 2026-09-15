import { interpolate } from "remotion";
import { dur, easeIn, easeInOut, easeOut } from "../tokens";

const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

/** 0→1 over `length` frames starting at `start`, ease-out (entrances). */
export const fadeIn = (frame: number, start = 0, length = dur.slow): number =>
  interpolate(frame, [start, start + length], [0, 1], { ...clamp, easing: easeOut });

/** 1→0 over the last `length` frames of a scene of `total` frames, ease-in (exits). */
export const fadeOut = (frame: number, total: number, length = dur.slow): number =>
  interpolate(frame, [total - length, total], [1, 0], { ...clamp, easing: easeIn });

/** Scene-level opacity: in at the start, out at the end. */
export const sceneOpacity = (frame: number, total: number): number =>
  Math.min(fadeIn(frame, 0, dur.slow), fadeOut(frame, total, dur.base));

/** Gentle upward drift that settles, paired with fadeIn for text entrances. */
export const rise = (frame: number, start = 0, length = dur.slow, distance = 24): number =>
  interpolate(frame, [start, start + length], [distance, 0], { ...clamp, easing: easeOut });

/** Linear-in-time slow move (Ken Burns), ease-in-out. */
export const drift = (
  frame: number,
  total: number,
  from: number,
  to: number,
): number => interpolate(frame, [0, total], [from, to], { ...clamp, easing: easeInOut });

/** Cross-fade weight between two images: 0 = first, 1 = second. */
export const crossfade = (frame: number, at: number, length = dur.slow): number =>
  interpolate(frame, [at, at + length], [0, 1], { ...clamp, easing: easeInOut });
