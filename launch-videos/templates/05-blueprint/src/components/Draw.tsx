import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { DUR, bp, easeIn, easeOut } from "../theme";

/** 0→1 draw-on progress starting at `at` (local frames), lasting `dur`. */
export const useDraw = (at: number, dur = DUR.draw) => {
  const frame = useCurrentFrame();
  return interpolate(frame, [at, at + dur], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
};

/** Opacity for entrances (fade + optional rise) with ease-out. */
export const useEnter = (at: number, dur = DUR.base) => {
  const frame = useCurrentFrame();
  return interpolate(frame, [at, at + dur], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
};

/** 1→0 exit with ease-in, beginning at `at`. */
export const useExit = (at: number, dur = DUR.fast) => {
  const frame = useCurrentFrame();
  return interpolate(frame, [at, at + dur], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeIn,
  });
};

type PathProps = {
  d: string;
  progress: number;
  stroke?: string;
  width?: number;
  dash?: string;
};

/** SVG path that draws on from its start using the pathLength trick. */
export const DrawPath: React.FC<PathProps> = ({ d, progress, stroke = bp.line, width = 1.5, dash }) => {
  if (progress <= 0) return null;
  return (
    <path
      d={d}
      fill="none"
      stroke={stroke}
      strokeWidth={width}
      strokeLinecap="butt"
      pathLength={1}
      strokeDasharray={dash ?? "1"}
      strokeDashoffset={dash ? undefined : 1 - progress}
      style={dash ? { clipPath: `inset(0 ${(1 - progress) * 100}% 0 0)` } : undefined}
    />
  );
};

type RectProps = {
  x: number;
  y: number;
  w: number;
  h: number;
  progress: number;
  stroke?: string;
  width?: number;
  r?: number;
};

/** Rectangle outline drawn clockwise from the top-left corner. */
export const DrawRect: React.FC<RectProps> = ({ x, y, w, h, progress, stroke, width, r = 0 }) => {
  const d =
    r > 0
      ? `M${x + r},${y} H${x + w - r} A${r},${r} 0 0 1 ${x + w},${y + r} V${y + h - r} A${r},${r} 0 0 1 ${x + w - r},${y + h} H${x + r} A${r},${r} 0 0 1 ${x},${y + h - r} V${y + r} A${r},${r} 0 0 1 ${x + r},${y}`
      : `M${x},${y} H${x + w} V${y + h} H${x} Z`;
  return <DrawPath d={d} progress={progress} stroke={stroke} width={width} />;
};

/** Small crosshair used as a registration mark. */
export const Crosshair: React.FC<{ x: number; y: number; size?: number; opacity?: number }> = ({
  x,
  y,
  size = 10,
  opacity = 1,
}) => (
  <g stroke={bp.line} strokeWidth={1} opacity={opacity}>
    <line x1={x - size} y1={y} x2={x + size} y2={y} />
    <line x1={x} y1={y - size} x2={x} y2={y + size} />
    <circle cx={x} cy={y} r={size * 0.55} fill="none" />
  </g>
);
