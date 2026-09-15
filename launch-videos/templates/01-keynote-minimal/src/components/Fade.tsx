import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { easeIn, easeOut } from "../tokens";
import { CROSSFADE } from "../scenes";

type Props = {
  duration: number;
  fadeIn?: number;
  fadeOut?: number;
  children: React.ReactNode;
};

/** Crossfade wrapper for a whole scene: fades in over `fadeIn` frames, out over the last `fadeOut`. */
export const SceneFade: React.FC<Props> = ({ duration, fadeIn = CROSSFADE, fadeOut = CROSSFADE, children }) => {
  const frame = useCurrentFrame();
  const enter =
    fadeIn <= 0
      ? 1
      : interpolate(frame, [0, fadeIn], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: easeOut,
        });
  const exit =
    fadeOut <= 0
      ? 1
      : interpolate(frame, [duration - fadeOut, duration], [1, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: easeIn,
        });
  return <AbsoluteFill style={{ opacity: Math.min(enter, exit) }}>{children}</AbsoluteFill>;
};

/** Opacity of an element that appears at `from`, holds, then leaves at `until` (frames relative to the scene). */
export const useWindowOpacity = (from: number, until: number, inFrames = 18, outFrames = 14): number => {
  const frame = useCurrentFrame();
  const enter = interpolate(frame, [from, from + inFrames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
  const exit = Number.isFinite(until)
    ? interpolate(frame, [until - outFrames, until], [1, 0], {
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
        easing: easeIn,
      })
    : 1;
  return Math.min(enter, exit);
};
