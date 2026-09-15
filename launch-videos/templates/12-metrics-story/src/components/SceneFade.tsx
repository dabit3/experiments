import React from "react";
import { AbsoluteFill, useCurrentFrame, useVideoConfig } from "remotion";
import { easeIn, easeOut, tween } from "../anim";

/**
 * Fades a scene in (ease-out) and out (ease-in) inside its Sequence.
 * Kept to opacity only so scenes can spend their motion budget elsewhere.
 */
export const SceneFade: React.FC<{
  children: React.ReactNode;
  inFrames?: number;
  outFrames?: number;
  background?: string;
}> = ({ children, inFrames = 10, outFrames = 8, background }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const fadeIn = tween(frame, 0, inFrames, easeOut);
  const fadeOut = tween(frame, durationInFrames - outFrames, outFrames, easeIn, 1, 0);
  return (
    <AbsoluteFill style={{ opacity: Math.min(fadeIn, fadeOut), backgroundColor: background }}>
      {children}
    </AbsoluteFill>
  );
};

/** Fade + 24px rise entrance for a block of text. */
export const Rise: React.FC<{
  children: React.ReactNode;
  start: number;
  dur?: number;
  distance?: number;
  style?: React.CSSProperties;
}> = ({ children, start, dur = 18, distance = 24, style }) => {
  const frame = useCurrentFrame();
  const p = tween(frame, start, dur, easeOut);
  return (
    <div
      style={{
        opacity: p,
        transform: `translateY(${(1 - p) * distance}px)`,
        ...style,
      }}
    >
      {children}
    </div>
  );
};

/** Opacity-only entrance. */
export const Fade: React.FC<{
  children: React.ReactNode;
  start: number;
  dur?: number;
  style?: React.CSSProperties;
}> = ({ children, start, dur = 14, style }) => {
  const frame = useCurrentFrame();
  return <div style={{ opacity: tween(frame, start, dur, easeOut), ...style }}>{children}</div>;
};
