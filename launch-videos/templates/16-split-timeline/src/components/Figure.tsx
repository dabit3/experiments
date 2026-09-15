import React from "react";
import { AbsoluteFill, Img, staticFile, useCurrentFrame } from "remotion";
import { color, layout, radius, shadow } from "../theme";
import { lerp, lifetime, move } from "./anim";

/** Camera position over a screenshot: zoom factor and focal point (0–100%). */
export type Cam = { scale: number; x: number; y: number };

export type Shot = {
  src: string;
  /** Frame (relative to the scene) at which this shot is fully visible. */
  from: number;
  /** Frame at which the next shot has fully replaced this one (undefined = scene end). */
  until?: number;
  cam: { from: Cam; to: Cam };
};

const XFADE = 16;

const ShotLayer: React.FC<{ shot: Shot; sceneDuration: number }> = ({ shot, sceneDuration }) => {
  const frame = useCurrentFrame();
  const until = shot.until ?? sceneDuration;
  const opacity = lifetime(frame, shot.from - XFADE, until + XFADE, XFADE, XFADE);
  if (opacity <= 0) return null;
  const t = move(frame, shot.from - XFADE, until - shot.from + XFADE);
  const scale = lerp(shot.cam.from.scale, shot.cam.to.scale, t);
  const x = lerp(shot.cam.from.x, shot.cam.to.x, t);
  const y = lerp(shot.cam.from.y, shot.cam.to.y, t);
  return (
    <Img
      src={staticFile(shot.src)}
      style={{
        position: "absolute",
        inset: 0,
        width: "100%",
        height: "100%",
        objectFit: "cover",
        opacity,
        transform: `scale(${scale})`,
        transformOrigin: `${x}% ${y}%`,
      }}
    />
  );
};

/**
 * Screenshot figure in the right panel. Crossfades between `shots`, each with a slow camera move.
 */
export const Figure: React.FC<{
  shots: Shot[];
  sceneDuration: number;
  children?: React.ReactNode;
}> = ({ shots, sceneDuration, children }) => {
  const frame = useCurrentFrame();
  const { w, h } = layout.figure;
  const opacity = lifetime(frame, 0, sceneDuration, 14, 10);
  return (
    <AbsoluteFill style={{ opacity }}>
      <div
        style={{
          position: "absolute",
          left: layout.right.x,
          top: layout.contentTop + (layout.contentBottom - layout.contentTop - h) / 2,
          width: w,
          height: h,
          borderRadius: radius.md,
          overflow: "hidden",
          background: color.white,
          border: `1px solid ${color.border}`,
          boxShadow: shadow.soft,
        }}
      >
        {shots.map((s) => (
          <ShotLayer key={s.src + s.from} shot={s} sceneDuration={sceneDuration} />
        ))}
        {children}
      </div>
    </AbsoluteFill>
  );
};
