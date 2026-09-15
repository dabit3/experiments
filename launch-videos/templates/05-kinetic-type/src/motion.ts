import { interpolate } from "remotion";

export const easeOutCubic = (t: number) => 1 - Math.pow(1 - t, 3);
export const easeInOutCubic = (t: number) =>
  t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;

const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

/** 0 -> 1 over [start, start + duration], ease-out (entrances). */
export const enter = (frame: number, start: number, duration: number) =>
  interpolate(frame, [start, start + duration], [0, 1], {
    ...clamp,
    easing: easeOutCubic,
  });

/** 1 -> 0 over [start, start + duration], ease-in (exits). */
export const leave = (frame: number, start: number, duration: number) =>
  interpolate(frame, [start, start + duration], [1, 0], {
    ...clamp,
    easing: (t) => t * t * t,
  });

/** 0 -> 1 over [start, start + duration], ease-in-out (layout moves). */
export const move = (frame: number, start: number, duration: number) =>
  interpolate(frame, [start, start + duration], [0, 1], {
    ...clamp,
    easing: easeInOutCubic,
  });

export const mix = (a: number, b: number, t: number) => a + (b - a) * t;
