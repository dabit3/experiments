import React from "react";
import { FONT_MONO, bp, type } from "../theme";
import { DrawPath } from "./Draw";

const TICK = 8;

type DimProps = {
  /** Start and end of the measured span. */
  x1: number;
  y1: number;
  x2: number;
  y2: number;
  label: string;
  progress: number;
  /** Offset of the label from the line, perpendicular. */
  labelOffset?: number;
};

/** Engineering dimension line: extension ticks, line, centred mono label. */
export const Dimension: React.FC<DimProps> = ({ x1, y1, x2, y2, label, progress, labelOffset = -14 }) => {
  const horizontal = Math.abs(y2 - y1) < Math.abs(x2 - x1);
  const mx = (x1 + x2) / 2;
  const my = (y1 + y2) / 2;
  const tick1 = horizontal ? `M${x1},${y1 - TICK} V${y1 + TICK}` : `M${x1 - TICK},${y1} H${x1 + TICK}`;
  const tick2 = horizontal ? `M${x2},${y2 - TICK} V${y2 + TICK}` : `M${x2 - TICK},${y2} H${x2 + TICK}`;
  const textOpacity = Math.max(0, (progress - 0.6) / 0.4);
  const labelStyle: React.CSSProperties = {
    fontFamily: FONT_MONO,
    fontSize: 15,
    letterSpacing: type.tracking.caps,
    textTransform: "uppercase",
    fill: bp.textDim,
  };
  return (
    <g>
      <DrawPath d={tick1} progress={Math.min(1, progress * 3)} width={1} />
      <DrawPath d={`M${x1},${y1} L${x2},${y2}`} progress={progress} width={1} />
      <DrawPath d={tick2} progress={Math.max(0, (progress - 0.66) * 3)} width={1} />
      {horizontal ? (
        <text x={mx} y={my + labelOffset} textAnchor="middle" style={{ ...labelStyle, opacity: textOpacity }}>
          {label}
        </text>
      ) : (
        <text
          x={mx + labelOffset}
          y={my}
          textAnchor="middle"
          transform={`rotate(-90 ${mx + labelOffset} ${my})`}
          style={{ ...labelStyle, opacity: textOpacity }}
        >
          {label}
        </text>
      )}
    </g>
  );
};

type LeaderProps = {
  /** Target point on the drawing. */
  tx: number;
  ty: number;
  /** Elbow and label anchor. Label sits at (lx, ly) extending in `side` direction. */
  lx: number;
  ly: number;
  side: "left" | "right";
  label: string;
  sub?: string;
  progress: number;
};

/** Leader annotation: dot on the target, elbow line, short horizontal shelf, label. */
export const Leader: React.FC<LeaderProps> = ({ tx, ty, lx, ly, side, label, sub, progress }) => {
  const shelf = 120;
  const ex = side === "right" ? lx + shelf : lx - shelf;
  const d = `M${tx},${ty} L${lx},${ly} L${ex},${ly}`;
  const textOpacity = Math.max(0, (progress - 0.7) / 0.3);
  const anchor = side === "right" ? "start" : "end";
  const textX = side === "right" ? lx : lx;
  return (
    <g>
      <circle cx={tx} cy={ty} r={4} fill={bp.line} opacity={Math.min(1, progress * 4)} />
      <circle cx={tx} cy={ty} r={9} fill="none" stroke={bp.line} strokeWidth={1} opacity={Math.min(1, progress * 4) * 0.6} />
      <DrawPath d={d} progress={progress} width={1.25} />
      <text
        x={textX}
        y={ly - 10}
        textAnchor={anchor}
        style={{
          fontFamily: FONT_MONO,
          fontSize: type.sizes1080p.label,
          fontWeight: 500,
          letterSpacing: type.tracking.caps,
          textTransform: "uppercase",
          fill: bp.text,
          opacity: textOpacity,
        }}
      >
        {label}
      </text>
      {sub ? (
        <text
          x={textX}
          y={ly + 22}
          textAnchor={anchor}
          style={{
            fontFamily: FONT_MONO,
            fontSize: 15,
            letterSpacing: type.tracking.caps,
            textTransform: "uppercase",
            fill: bp.textDim,
            opacity: textOpacity,
          }}
        >
          {sub}
        </text>
      ) : null}
    </g>
  );
};

/** Corner brackets marking a region of interest on a drawing. */
export const Brackets: React.FC<{
  x: number;
  y: number;
  w: number;
  h: number;
  progress: number;
  size?: number;
  stroke?: string;
}> = ({ x, y, w, h, progress, size = 18, stroke = bp.lineBright }) => {
  const s = size;
  const corners = [
    `M${x},${y + s} V${y} H${x + s}`,
    `M${x + w - s},${y} H${x + w} V${y + s}`,
    `M${x + w},${y + h - s} V${y + h} H${x + w - s}`,
    `M${x + s},${y + h} H${x} V${y + h - s}`,
  ];
  return (
    <g>
      {corners.map((d, i) => (
        <DrawPath key={i} d={d} progress={progress} stroke={stroke} width={2} />
      ))}
    </g>
  );
};
