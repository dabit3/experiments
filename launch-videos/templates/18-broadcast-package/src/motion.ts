import { Easing, interpolate } from "remotion";

export const easeOutCubic = Easing.bezier(0.33, 1, 0.68, 1);
export const easeInOutCubic = Easing.bezier(0.65, 0, 0.35, 1);

/** 0 → 1 ease-out progress starting at `from`, lasting `length` frames. */
export const enter = (frame: number, from: number, length: number): number =>
  interpolate(frame, [from, from + length], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOutCubic,
  });

/** 1 → 0 ease-in-out progress ending exactly at `end`. */
export const exit = (frame: number, end: number, length: number): number =>
  interpolate(frame, [end - length, end], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeInOutCubic,
  });

/** Combined in/out envelope for an element living from `from` for `duration` frames. */
export const envelope = (
  frame: number,
  from: number,
  duration: number,
  length: number,
): number =>
  Math.min(enter(frame, from, length), exit(frame, from + duration, length));
