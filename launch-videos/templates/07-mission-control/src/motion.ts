import { Easing, interpolate } from "remotion";

/** Ease-out cubic entrance, 0 -> 1 over `frames` starting at `from`. */
export const enter = (frame: number, from: number, frames: number) =>
  interpolate(frame, [from, from + frames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });

/** Ease-in-out cubic layout move, 0 -> 1 over `frames` starting at `from`. */
export const move = (frame: number, from: number, frames: number) =>
  interpolate(frame, [from, from + frames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.inOut(Easing.cubic),
  });

/** Linear fade-out, 1 -> 0 over `frames` starting at `from`. */
export const leave = (frame: number, from: number, frames: number) =>
  interpolate(frame, [from, from + frames], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.inOut(Easing.cubic),
  });
