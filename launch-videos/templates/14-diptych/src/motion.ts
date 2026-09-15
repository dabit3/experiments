import { Easing, interpolate } from "remotion";

const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

/** Ease-out cubic, for entrances (brand: 300-500ms). */
export const enter = (frame: number, start: number, duration: number) =>
  interpolate(frame, [start, start + duration], [0, 1], {
    ...clamp,
    easing: Easing.out(Easing.cubic),
  });

/** Ease-in-out cubic, for layout moves (brand: 500-800ms). */
export const move = (frame: number, start: number, duration: number) =>
  interpolate(frame, [start, start + duration], [0, 1], {
    ...clamp,
    easing: Easing.inOut(Easing.cubic),
  });

/** Linear fade-out over the last `duration` frames of a scene. */
export const exit = (frame: number, sceneDuration: number, duration: number) =>
  interpolate(frame, [sceneDuration - duration, sceneDuration], [1, 0], clamp);
