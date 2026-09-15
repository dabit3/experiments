import { interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { easeIn, easeInOut, easeOut } from "../tokens";
import { TRANSITION } from "../scenes";

const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

/** 0→1 ease-out entrance starting at `from`, lasting `duration` frames. */
export const enter = (frame: number, from: number, duration: number) =>
  interpolate(frame, [from, from + duration], [0, 1], { ...clamp, easing: easeOut });

/** 1→0 ease-in exit starting at `from`. */
export const exit = (frame: number, from: number, duration: number) =>
  interpolate(frame, [from, from + duration], [1, 0], { ...clamp, easing: easeIn });

/** Ease-in-out move between two values across [from, to]. */
export const move = (frame: number, from: number, to: number, a: number, b: number) =>
  interpolate(frame, [from, to], [a, b], { ...clamp, easing: easeInOut });

/** Linear 0→1 across [from, to]. */
export const linear = (frame: number, from: number, to: number) =>
  interpolate(frame, [from, to], [0, 1], clamp);

/** Opacity for a scene that fades in over TRANSITION frames and out over the last TRANSITION frames. */
export const useSceneOpacity = () => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const fadeIn = interpolate(frame, [0, TRANSITION], [0, 1], clamp);
  const fadeOut = interpolate(frame, [durationInFrames - TRANSITION, durationInFrames], [1, 0], clamp);
  return Math.min(fadeIn, fadeOut);
};

/**
 * Slow global parallax. Uses the absolute frame (scene offset added by callers via
 * useCurrentFrame + Sequence `from`) so every depth layer keeps drifting continuously across scene cuts.
 * depth: 0 = far background (barely moves), 1 = front layer.
 */
export const parallax = (absFrame: number, depth: number) => {
  const t = absFrame / 30;
  const amp = 8 + depth * 22;
  return {
    x: Math.sin(t / 7.5) * amp,
    y: Math.cos(t / 9.5) * amp * 0.55,
  };
};
