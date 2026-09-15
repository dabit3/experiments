import React, { useContext } from "react";
import { useCurrentFrame } from "remotion";
import { useProgress } from "../anim";
import { color, ease, sec } from "../theme";
import { FigureContext } from "./FigureContext";
import type { Pt } from "./Ink";

type CursorProps = {
  /** Waypoints in figure-normalised coords (inside <Figure>) or px. */
  path: Pt[];
  /** Frame at which the cursor appears and starts moving. */
  at: number;
  /** Frames spent on each leg of the path. */
  legFrames?: number;
  /** Frame (relative) of a click; a small ring pulses at the current point. */
  clickAt?: number;
  size?: number;
};

/** macOS-style pointer gliding between waypoints with ease-in-out. */
export const Cursor: React.FC<CursorProps> = ({ path, at, legFrames = sec(0.7), clickAt, size = 26 }) => {
  const fig = useContext(FigureContext);
  const frame = useCurrentFrame();
  const map = (p: Pt) => (fig ? fig.toPx(p.x, p.y) : p);
  const appear = useProgress(at, sec(0.25), ease.out);

  const legs = Math.max(1, path.length - 1);
  const local = frame - at;
  const legIndex = Math.min(legs - 1, Math.max(0, Math.floor(local / legFrames)));
  const a = map(path[legIndex]);
  const b = map(path[Math.min(path.length - 1, legIndex + 1)]);
  const raw = Math.min(1, Math.max(0, (local - legIndex * legFrames) / legFrames));
  const t = ease.inOut(raw);
  const x = a.x + (b.x - a.x) * t;
  const y = a.y + (b.y - a.y) * t;

  const clickProgress = useProgress(clickAt ?? 0, sec(0.45), ease.out);
  const click = clickAt === undefined ? 0 : clickProgress;
  const ringR = 6 + click * 22;

  return (
    <svg
      style={{ position: "absolute", inset: 0, width: "100%", height: "100%", overflow: "visible", pointerEvents: "none" }}
    >
      {clickAt !== undefined && click > 0 && click < 1 ? (
        <circle cx={x} cy={y} r={ringR} fill="none" stroke={color.accent} strokeWidth={2} opacity={1 - click} />
      ) : null}
      <g transform={`translate(${x} ${y}) scale(${size / 26})`} opacity={appear}>
        <path
          d="M0 0 L0 20.5 L5.2 15.6 L9 24 L12.6 22.4 L8.8 14.2 L15.6 14.2 Z"
          fill={color.ink}
          stroke={color.white}
          strokeWidth={1.6}
          strokeLinejoin="round"
        />
      </g>
    </svg>
  );
};
