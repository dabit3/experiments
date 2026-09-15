import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { PICTURE_HEIGHT, tokens, WIDTH } from "../tokens";

/** Animated fine grain over the picture area. */
export const Grain: React.FC<{ opacity?: number }> = ({ opacity = 0.09 }) => {
  const frame = useCurrentFrame();
  return (
    <svg
      width={WIDTH}
      height={PICTURE_HEIGHT}
      style={{ position: "absolute", inset: 0, opacity, mixBlendMode: "overlay", pointerEvents: "none" }}
    >
      <filter id="grain" x="0" y="0" width="100%" height="100%">
        <feTurbulence
          type="fractalNoise"
          baseFrequency="0.85"
          numOctaves="2"
          seed={frame}
          stitchTiles="stitch"
        />
        <feColorMatrix type="saturate" values="0" />
      </filter>
      <rect width={WIDTH} height={PICTURE_HEIGHT} filter="url(#grain)" />
    </svg>
  );
};

type StreakProps = {
  y: number;
  /** Horizontal drift in output px over the whole video. */
  driftFrom: number;
  driftTo: number;
  totalFrames: number;
  width?: number;
  opacity?: number;
};

/** Anamorphic-style horizontal light streak; screen-blended so it only reads over darker pixels. */
export const Streak: React.FC<StreakProps> = ({
  y,
  driftFrom,
  driftTo,
  totalFrames,
  width = 1100,
  opacity = 0.55,
}) => {
  const frame = useCurrentFrame();
  const x = interpolate(frame, [0, totalFrames], [driftFrom, driftTo]);
  const pulse = 0.85 + 0.15 * Math.sin(frame / 37);
  const core = `linear-gradient(90deg, transparent 0%, ${tokens.color.accent} 35%, #DCD8FF 50%, ${tokens.color.accent} 65%, transparent 100%)`;
  return (
    <div style={{ position: "absolute", inset: 0, mixBlendMode: "screen", pointerEvents: "none", opacity: opacity * pulse }}>
      <div
        style={{
          position: "absolute",
          left: x,
          top: y - 18,
          width,
          height: 36,
          background: core,
          filter: "blur(28px)",
          opacity: 0.6,
        }}
      />
      <div
        style={{
          position: "absolute",
          left: x + width * 0.1,
          top: y - 1.5,
          width: width * 0.8,
          height: 3,
          background: core,
          filter: "blur(2.5px)",
        }}
      />
    </div>
  );
};

/** Vignette + bottom scrim so lower-thirds stay legible over light UI. */
export const Grade: React.FC = () => (
  <>
    <div
      style={{
        position: "absolute",
        inset: 0,
        background:
          "radial-gradient(120% 140% at 50% 45%, rgba(0,0,0,0) 45%, rgba(0,0,0,0.42) 100%)",
        pointerEvents: "none",
      }}
    />
    <div
      style={{
        position: "absolute",
        left: 0,
        right: 0,
        bottom: 0,
        height: 300,
        background: "linear-gradient(180deg, rgba(18,17,17,0) 0%, rgba(18,17,17,0.55) 60%, rgba(18,17,17,0.78) 100%)",
        pointerEvents: "none",
      }}
    />
  </>
);
