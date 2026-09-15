import { Easing, interpolate } from "remotion";

const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

/** Entrance: ease-out cubic, 0 -> 1 over `frames`, starting at `start`. */
export const easeOut = (frame: number, start: number, frames: number) =>
  interpolate(frame, [start, start + frames], [0, 1], {
    ...clamp,
    easing: Easing.out(Easing.cubic),
  });

/** Layout move: ease-in-out cubic, 0 -> 1 over `frames`, starting at `start`. */
export const easeInOut = (frame: number, start: number, frames: number) =>
  interpolate(frame, [start, start + frames], [0, 1], {
    ...clamp,
    easing: Easing.inOut(Easing.cubic),
  });

/** Linear 0 -> 1 fade used for cross-dissolves. */
export const linear = (frame: number, start: number, frames: number) =>
  interpolate(frame, [start, start + frames], [0, 1], clamp);

/** 1 while inside [openAt, closeAt], with an eased ramp in and out. */
export const presence = (
  frame: number,
  openAt: number,
  closeAt: number,
  inFrames: number,
  outFrames: number,
) => {
  const enter = easeOut(frame, openAt, inFrames);
  const exit = 1 - easeInOut(frame, closeAt - outFrames, outFrames);
  return Math.min(enter, exit);
};
