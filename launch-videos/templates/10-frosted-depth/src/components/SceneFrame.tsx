import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { TRANSITION } from "../scenes";

const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

/**
 * Wraps scene content so it fades in across the shared TRANSITION overlap.
 * `fadeOut` (default true) also fades it out over the last TRANSITION frames. Pass false when the
 * following scene renders the same front-layer card in the same place: the incoming card then
 * dissolves over an opaque outgoing one, so the background never bleeds through mid-transition.
 */
export const SceneFrame: React.FC<{ children: React.ReactNode; fadeOut?: boolean }> = ({ children, fadeOut = true }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const a = interpolate(frame, [0, TRANSITION], [0, 1], clamp);
  const b = fadeOut ? interpolate(frame, [durationInFrames - TRANSITION, durationInFrames], [1, 0], clamp) : 1;
  return <AbsoluteFill style={{ opacity: Math.min(a, b) }}>{children}</AbsoluteFill>;
};
