import React from "react";
import { AbsoluteFill } from "remotion";
import { Dimension, Leader } from "../components/Annotations";
import { Cursor, CursorStop } from "../components/Cursor";
import { useDraw, useExit } from "../components/Draw";
import { Figure, MotionKey, Region, Shot, project, useMotion } from "../components/Figure";
import { FIG } from "../components/Shell";
import { Line, Narration } from "../components/Text";
import { HEIGHT, WIDTH } from "../theme";

export type Callout = {
  /** Image-fraction target; tracks the Ken Burns motion. */
  u: number;
  v: number;
  side: "left" | "right";
  /** Vertical position of the label shelf, composition px. */
  ly: number;
  label: string;
  sub?: string;
  at: number;
  until?: number;
};

type Props = {
  shots: Shot[];
  motion: MotionKey[];
  dimension: string;
  callouts: Callout[];
  regions?: Region[];
  lines: Line[];
  cursor?: { stops: CursorStop[]; hideAt?: number };
  /** Frame at which the exploded layers begin to assemble. */
  assembleAt?: number;
};

const LEFT_X = 365;
const RIGHT_X = 1555;

/** One product-in-action moment: figure + dimension + leaders + narration. */
export const Feature: React.FC<Props> = ({
  shots,
  motion,
  dimension,
  callouts,
  regions,
  lines,
  cursor,
  assembleAt = 8,
}) => {
  const m = useMotion(motion);
  const assembled = assembleAt + 30;
  const dim = useDraw(assembled);
  const cursorNode = cursor ? (
    <Cursor
      stops={cursor.stops.map((s) => ({ ...s, x: s.x * FIG.w, y: s.y * FIG.h }))}
      hideAt={cursor.hideAt}
    />
  ) : null;
  return (
    <AbsoluteFill>
      <Figure {...FIG} shots={shots} motion={motion} assemble={{ at: assembleAt }} regions={regions} tracked={cursorNode} />
      <svg width={WIDTH} height={HEIGHT} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
        <Dimension x1={FIG.x} y1={FIG.y - 40} x2={FIG.x + FIG.w} y2={FIG.y - 40} label={dimension} progress={dim} />
        {callouts.map((c) => (
          <CalloutLeader key={c.label} c={c} m={m} />
        ))}
      </svg>
      <Narration lines={lines} />
    </AbsoluteFill>
  );
};

const CalloutLeader: React.FC<{ c: Callout; m: MotionKey }> = ({ c, m }) => {
  const draw = useDraw(c.at);
  const exit = useExit(c.until ?? Number.MAX_SAFE_INTEGER);
  if (draw <= 0 || exit <= 0) return null;
  const t = project(FIG, m, c.u, c.v);
  // Keep the target inside the frame so leaders never point at cropped-away content.
  const tx = Math.min(FIG.x + FIG.w - 8, Math.max(FIG.x + 8, t.x));
  const ty = Math.min(FIG.y + FIG.h - 8, Math.max(FIG.y + 8, t.y));
  const lx = c.side === "left" ? LEFT_X : RIGHT_X;
  return (
    <g opacity={exit}>
      <Leader tx={tx} ty={ty} lx={lx} ly={c.ly} side={c.side} label={c.label} sub={c.sub} progress={draw} />
    </g>
  );
};
