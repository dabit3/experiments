import { interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { ease, sec } from "./theme";

type Curve = (t: number) => number;

/** 0→1 over [start, start + duration] frames, clamped. */
export const useProgress = (start: number, duration: number, easing: Curve = ease.out) => {
  const frame = useCurrentFrame();
  return interpolate(frame, [start, start + duration], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing,
  });
};

/** Fade-in at scene start and fade-out at scene end (ease-in exit). */
export const useSceneFade = (inFrames = sec(0.4), outFrames = sec(0.35)) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const fadeIn = interpolate(frame, [0, inFrames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: ease.out,
  });
  const fadeOut = interpolate(frame, [durationInFrames - outFrames, durationInFrames], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: ease.in,
  });
  return Math.min(fadeIn, fadeOut);
};

export const lerp = (a: number, b: number, t: number) => a + (b - a) * t;
