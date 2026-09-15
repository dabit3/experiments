import { Easing, interpolate } from "remotion";

export const easeOutCubic = Easing.bezier(0.33, 1, 0.68, 1);
export const easeInOutCubic = Easing.bezier(0.65, 0, 0.35, 1);

const clampOpts = {
  extrapolateLeft: "clamp",
  extrapolateRight: "clamp",
} as const;

/** Entrance: 0 -> 1 with ease-out cubic (brand: 300-500ms). */
export const enter = (frame: number, from: number, durationInFrames: number) =>
  interpolate(frame, [from, from + durationInFrames], [0, 1], {
    ...clampOpts,
    easing: easeOutCubic,
  });

/** Layout move: a -> b with ease-in-out cubic (brand: 500-800ms). */
export const move = (
  frame: number,
  from: number,
  durationInFrames: number,
  a: number,
  b: number,
) =>
  interpolate(frame, [from, from + durationInFrames], [a, b], {
    ...clampOpts,
    easing: easeInOutCubic,
  });

/** Linear, clamped. */
export const linear = (
  frame: number,
  from: number,
  durationInFrames: number,
  a: number,
  b: number,
) => interpolate(frame, [from, from + durationInFrames], [a, b], clampOpts);
