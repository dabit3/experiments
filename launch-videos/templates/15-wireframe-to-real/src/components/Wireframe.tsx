import React, { useMemo } from "react";
import { easeOut, prog } from "../anim";
import { color } from "../tokens";
import { roughCircle, roughLine, roughRect } from "./rough";

/**
 * Wireframe primitives, in a 1000 x 543 viewBox (the aspect of the product
 * screenshots). `rect` is an outlined box, `bar` is a filled text placeholder,
 * `fill` is a filled block (image / button), `circle` and `x` are glyphs.
 */
export type Prim =
  | { t: "rect"; x: number; y: number; w: number; h: number; r?: number; fill?: Fill }
  | { t: "bar"; x: number; y: number; w: number; h?: number; tone?: Tone }
  | { t: "fill"; x: number; y: number; w: number; h: number; r?: number; tone?: Tone }
  | { t: "circle"; cx: number; cy: number; r: number; tone?: Tone | "none" }
  | { t: "x"; x: number; y: number; s: number }
  | { t: "vline"; x: number; y1: number; y2: number };

type Fill = "none" | "light";
type Tone = "light" | "mid" | "dark";

export const VB_W = 1000;
export const VB_H = 543;

const toneColor: Record<Tone, string> = {
  light: color.surface,
  mid: color.gray300,
  dark: color.gray400,
};

type Props = {
  prims: Prim[];
  /** 0..1: how far the drawing has progressed (strokes draw on, fills fade in) */
  progress: number;
  seed?: number;
};

export const Wireframe: React.FC<Props> = ({ prims, progress, seed = 7 }) => {
  const paths = useMemo(
    () =>
      prims.map((p, i) => {
        const s = seed * 131 + i * 17;
        switch (p.t) {
          case "rect":
            return {
              kind: "stroke" as const,
              ...roughRect(p.x, p.y, p.w, p.h, p.r ?? 0, s),
              fill: p.fill === "light" ? color.white : "none",
            };
          case "circle":
            return {
              kind: "stroke" as const,
              ...roughCircle(p.cx, p.cy, p.r, s),
              fill: p.tone && p.tone !== "none" ? toneColor[p.tone] : "none",
            };
          case "vline":
            return {
              kind: "stroke" as const,
              ...roughLine({ x: p.x, y: p.y1 }, { x: p.x, y: p.y2 }, s),
              fill: "none",
            };
          case "x": {
            const a = roughLine({ x: p.x, y: p.y }, { x: p.x + p.s, y: p.y + p.s }, s);
            const b = roughLine({ x: p.x + p.s, y: p.y }, { x: p.x, y: p.y + p.s }, s + 1);
            return { kind: "stroke" as const, d: `${a.d} ${b.d}`, len: a.len + b.len, fill: "none" };
          }
          case "bar":
            return {
              kind: "fill" as const,
              x: p.x,
              y: p.y,
              w: p.w,
              h: p.h ?? 7,
              r: (p.h ?? 7) / 2,
              color: toneColor[p.tone ?? "mid"],
            };
          case "fill":
            return {
              kind: "fill" as const,
              x: p.x,
              y: p.y,
              w: p.w,
              h: p.h,
              r: p.r ?? 0,
              color: toneColor[p.tone ?? "light"],
            };
        }
      }),
    [prims, seed],
  );

  const n = prims.length;
  // Each primitive draws over a window; windows are staggered across ~65% of
  // the total so the last strokes finish as progress reaches 1.
  const window = 0.35;

  return (
    <svg
      viewBox={`0 0 ${VB_W} ${VB_H}`}
      width="100%"
      height="100%"
      style={{ position: "absolute", inset: 0, overflow: "visible" }}
    >
      {paths.map((p, i) => {
        const start = (i / Math.max(1, n)) * (1 - window);
        const local = prog(progress, start, window, easeOut);
        if (local <= 0) return null;
        if (p.kind === "fill") {
          return (
            <rect
              key={i}
              x={p.x}
              y={p.y}
              width={p.w}
              height={p.h}
              rx={p.r}
              fill={p.color}
              opacity={local}
            />
          );
        }
        return (
          <g key={i}>
            {p.fill !== "none" ? (
              <path d={p.d} fill={p.fill} stroke="none" opacity={local} />
            ) : null}
            <path
              d={p.d}
              fill="none"
              stroke={color.gray400}
              strokeWidth={1.6}
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeDasharray={p.len}
              strokeDashoffset={p.len * (1 - local)}
            />
          </g>
        );
      })}
    </svg>
  );
};
