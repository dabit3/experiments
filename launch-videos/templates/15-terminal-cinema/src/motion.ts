import { Easing, interpolate } from "remotion";

export const easeOut = Easing.bezier(0.33, 1, 0.68, 1);
export const easeInOut = Easing.bezier(0.65, 0, 0.35, 1);

export const progress = (
  frame: number,
  start: number,
  duration: number,
  easing: (t: number) => number = easeInOut,
) =>
  interpolate(frame, [start, start + duration], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing,
  });

export const typedLength = (text: string, frame: number, charsPerFrame: number) =>
  Math.max(0, Math.min(text.length, Math.floor(frame * charsPerFrame)));

export const typingFrames = (text: string, charsPerFrame: number) =>
  Math.ceil(text.length / charsPerFrame);
