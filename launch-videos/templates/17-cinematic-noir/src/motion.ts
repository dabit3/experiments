import { Easing, interpolate } from "remotion";

export const easeOutCubic = Easing.bezier(0.33, 1, 0.68, 1);
export const easeInOutCubic = Easing.bezier(0.65, 0, 0.35, 1);

export const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

/** 0 -> 1 over [start, start + duration] with an ease-out cubic (entrances). */
export const enter = (frame: number, start: number, duration: number) =>
  interpolate(frame, [start, start + duration], [0, 1], { ...clamp, easing: easeOutCubic });

/** 1 -> 0 over the last `duration` frames of a scene of `total` frames. */
export const exit = (frame: number, total: number, duration: number) =>
  interpolate(frame, [total - duration, total], [1, 0], clamp);

/** 0 -> 1 with ease-in-out (layout moves, shutters). */
export const move = (frame: number, start: number, duration: number) =>
  interpolate(frame, [start, start + duration], [0, 1], { ...clamp, easing: easeInOutCubic });
