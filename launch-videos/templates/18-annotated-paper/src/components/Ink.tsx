import React, { useContext } from "react";
import { useProgress } from "../anim";
import { color, ease, sec } from "../theme";
import { FigureContext } from "./FigureContext";

export type Pt = { x: number; y: number };

/* ---------- deterministic hand jitter ---------- */

const hash = (n: number) => {
  const s = Math.sin(n * 12.9898 + 78.233) * 43758.5453;
  return s - Math.floor(s);
};

/** Catmull-Rom → cubic Bézier path through points. */
const smoothPath = (pts: Pt[], closed = false) => {
  if (pts.length < 2) return "";
  const p = closed ? [pts[pts.length - 1], ...pts, pts[0], pts[1]] : [pts[0], ...pts, pts[pts.length - 1]];
  let d = `M ${p[1].x.toFixed(2)} ${p[1].y.toFixed(2)}`;
  for (let i = 1; i < p.length - 2; i++) {
    const p0 = p[i - 1];
    const p1 = p[i];
    const p2 = p[i + 1];
    const p3 = p[i + 2];
    const c1 = { x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6 };
    const c2 = { x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6 };
    d += ` C ${c1.x.toFixed(2)} ${c1.y.toFixed(2)}, ${c2.x.toFixed(2)} ${c2.y.toFixed(2)}, ${p2.x.toFixed(2)} ${p2.y.toFixed(2)}`;
  }
  return d;
};

const ellipsePath = (cx: number, cy: number, rx: number, ry: number, seed: number) => {
  const pts: Pt[] = [];
  const n = 28;
  const turns = 1.12;
  for (let i = 0; i <= n; i++) {
    const a = -0.5 + (i / n) * Math.PI * 2 * turns;
    const j = 1 + (hash(seed + i) - 0.5) * 0.045;
    const drift = (i / n) * 4; // pen drifts slightly outward as it laps
    pts.push({ x: cx + Math.cos(a) * (rx * j + drift), y: cy + Math.sin(a) * (ry * j + drift * 0.6) });
  }
  return smoothPath(pts);
};

const wavyLine = (a: Pt, b: Pt, seed: number, amp = 1.6) => {
  const pts: Pt[] = [];
  const n = 8;
  for (let i = 0; i <= n; i++) {
    const t = i / n;
    const j = (hash(seed + i) - 0.5) * amp * 2;
    pts.push({ x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t + j });
  }
  return smoothPath(pts);
};

const curvePath = (a: Pt, b: Pt, bend: number) => {
  const mx = (a.x + b.x) / 2;
  const my = (a.y + b.y) / 2;
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  const len = Math.hypot(dx, dy) || 1;
  const nx = -dy / len;
  const ny = dx / len;
  const c = { x: mx + nx * bend, y: my + ny * bend };
  return { d: `M ${a.x} ${a.y} Q ${c.x} ${c.y} ${b.x} ${b.y}`, ctrl: c };
};

/* ---------- primitives ---------- */

const useMap = () => {
  const fig = useContext(FigureContext);
  return (p: Pt): Pt => (fig ? fig.toPx(p.x, p.y) : p);
};

type StrokeProps = {
  d: string;
  progress: number;
  width: number;
  stroke?: string;
  opacity?: number;
  blend?: React.CSSProperties["mixBlendMode"];
  cap?: "round" | "butt";
};

const Stroke: React.FC<StrokeProps> = ({ d, progress, width, stroke = color.accent, opacity = 1, blend, cap = "round" }) => (
  <path
    d={d}
    pathLength={1}
    fill="none"
    stroke={stroke}
    strokeWidth={width}
    strokeLinecap={cap}
    strokeLinejoin="round"
    strokeDasharray="1"
    strokeDashoffset={1 - progress}
    style={{ opacity: progress <= 0 ? 0 : opacity, mixBlendMode: blend }}
  />
);

const Layer: React.FC<{ children: React.ReactNode; blend?: React.CSSProperties["mixBlendMode"] }> = ({
  children,
  blend,
}) => (
  <svg
    style={{
      position: "absolute",
      inset: 0,
      width: "100%",
      height: "100%",
      overflow: "visible",
      pointerEvents: "none",
      mixBlendMode: blend,
    }}
  >
    {children}
  </svg>
);

type Timed = { at: number; duration?: number; seed?: number };

/** Hand-drawn loop around a point. Coordinates are figure-normalised inside <Figure>, px outside. */
export const Circle: React.FC<Timed & { center: Pt; rx: number; ry: number; width?: number }> = ({
  center,
  rx,
  ry,
  at,
  duration = sec(0.6),
  seed = 1,
  width = 3.5,
}) => {
  const map = useMap();
  const c = map(center);
  const p = useProgress(at, duration, ease.inOut);
  return (
    <Layer>
      <Stroke d={ellipsePath(c.x, c.y, rx, ry, seed)} progress={p} width={width} />
    </Layer>
  );
};

/** Curved arrow with a small open head. */
export const Arrow: React.FC<Timed & { from: Pt; to: Pt; bend?: number; width?: number }> = ({
  from,
  to,
  bend = 40,
  at,
  duration = sec(0.55),
  width = 3.5,
}) => {
  const map = useMap();
  const a = map(from);
  const b = map(to);
  const { d, ctrl } = curvePath(a, b, bend);
  const p = useProgress(at, duration, ease.inOut);
  const shaft = Math.min(1, p / 0.8);
  const head = Math.max(0, (p - 0.8) / 0.2);
  const ang = Math.atan2(b.y - ctrl.y, b.x - ctrl.x);
  const size = 14;
  const h1 = { x: b.x - Math.cos(ang - 0.5) * size, y: b.y - Math.sin(ang - 0.5) * size };
  const h2 = { x: b.x - Math.cos(ang + 0.5) * size, y: b.y - Math.sin(ang + 0.5) * size };
  return (
    <Layer>
      <Stroke d={d} progress={shaft} width={width} />
      <Stroke d={`M ${h1.x} ${h1.y} L ${b.x} ${b.y} L ${h2.x} ${h2.y}`} progress={head} width={width} />
    </Layer>
  );
};

/** Wavy pen underline. */
export const Underline: React.FC<Timed & { from: Pt; to: Pt; width?: number; stroke?: string }> = ({
  from,
  to,
  at,
  duration = sec(0.5),
  seed = 3,
  width = 4,
  stroke,
}) => {
  const map = useMap();
  const p = useProgress(at, duration, ease.inOut);
  return (
    <Layer>
      <Stroke d={wavyLine(map(from), map(to), seed)} progress={p} width={width} stroke={stroke} />
    </Layer>
  );
};

/** Translucent highlighter swipe over a line of UI text. */
export const Highlight: React.FC<Timed & { from: Pt; to: Pt; height: number }> = ({
  from,
  to,
  height,
  at,
  duration = sec(0.5),
  seed = 5,
}) => {
  const map = useMap();
  const p = useProgress(at, duration, ease.inOut);
  return (
    <Layer blend="multiply">
      <Stroke
        d={wavyLine(map(from), map(to), seed, 0.8)}
        progress={p}
        width={height}
        stroke={color.accent}
        opacity={0.2}
        cap="butt"
      />
    </Layer>
  );
};

/** Quick tick mark. */
export const Check: React.FC<Timed & { at_: Pt; size?: number; width?: number; stroke?: string }> = ({
  at_,
  size = 22,
  at,
  duration = sec(0.35),
  width = 3.5,
  stroke,
}) => {
  const map = useMap();
  const c = map(at_);
  const p = useProgress(at, duration, ease.inOut);
  const d = smoothPath([
    { x: c.x - size * 0.5, y: c.y + size * 0.05 },
    { x: c.x - size * 0.15, y: c.y + size * 0.42 },
    { x: c.x + size * 0.55, y: c.y - size * 0.45 },
  ]);
  return (
    <Layer>
      <Stroke d={d} progress={p} width={width} stroke={stroke} />
    </Layer>
  );
};

/** Hand-drawn box, used to mark a "live" region of the print. */
export const Box: React.FC<Timed & { from: Pt; to: Pt; width?: number }> = ({
  from,
  to,
  at,
  duration = sec(0.8),
  seed = 7,
  width = 3,
}) => {
  const map = useMap();
  const a = map(from);
  const b = map(to);
  const p = useProgress(at, duration, ease.inOut);
  const corners: Pt[] = [
    { x: a.x, y: a.y },
    { x: b.x, y: a.y },
    { x: b.x, y: b.y },
    { x: a.x, y: b.y },
    { x: a.x, y: a.y },
  ].map((q, i) => ({ x: q.x + (hash(seed + i) - 0.5) * 5, y: q.y + (hash(seed + i + 9) - 0.5) * 5 }));
  // slight overshoot past the starting corner, like a real pen closing a box
  corners.push({ x: corners[4].x + 14, y: corners[4].y + 1.5 });
  const d = corners.map((q, i) => `${i === 0 ? "M" : "L"} ${q.x.toFixed(1)} ${q.y.toFixed(1)}`).join(" ");
  return (
    <Layer>
      <Stroke d={d} progress={p} width={width} />
    </Layer>
  );
};
