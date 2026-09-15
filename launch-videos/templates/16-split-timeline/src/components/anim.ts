import { interpolate } from "remotion";
import { ease } from "../theme";

const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

/** 0→1 entrance progress with ease-out. */
export const enter = (frame: number, at: number, duration = 18) =>
  interpolate(frame, [at, at + duration], [0, 1], { ...clamp, easing: ease.out });

/** 1→0 exit progress with ease-in. */
export const exit = (frame: number, at: number, duration = 12) =>
  interpolate(frame, [at, at + duration], [1, 0], { ...clamp, easing: ease.in });

/** 0→1 move progress with ease-in-out. */
export const move = (frame: number, at: number, duration: number) =>
  interpolate(frame, [at, at + duration], [0, 1], { ...clamp, easing: ease.inOut });

/** Opacity that fades in at `at` and (optionally) out at `until`. */
export const lifetime = (frame: number, at: number, until?: number, inDur = 18, outDur = 12) => {
  const a = enter(frame, at, inDur);
  const b = until === undefined ? 1 : exit(frame, until - outDur, outDur);
  return Math.min(a, b);
};

export const lerp = (a: number, b: number, t: number) => a + (b - a) * t;
