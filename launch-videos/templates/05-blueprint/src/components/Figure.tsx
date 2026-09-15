import React from "react";
import { Img, interpolate, staticFile, useCurrentFrame } from "remotion";
import { DUR, bp, color, easeInOut, easeOut, radius } from "../theme";
import { Brackets } from "./Annotations";
import { Crosshair, DrawRect } from "./Draw";

export type Shot = {
  /** Path under the shared assets dir, e.g. "screens/devin-web-10.png". */
  src: string;
  /** Local frame at which this shot cross-fades in (over DUR.base). The first shot's `from` is ignored. */
  from: number;
};

/** Ken Burns keyframe: zoom and focal point (fractions of the image) at local frame `at`. */
export type MotionKey = { at: number; scale: number; fx: number; fy: number };

export type Region = {
  /** Fractions of the image; tracks the Ken Burns motion. */
  x: number;
  y: number;
  w: number;
  h: number;
  at: number;
  until?: number;
};

export type FigureBox = { x: number; y: number; w: number; h: number };

type Props = FigureBox & {
  shots: Shot[];
  motion: MotionKey[];
  /** Exploded → assembled. Assembly starts at `at`, lasts `dur`. Omit to render flat from frame 0. */
  assemble?: { at: number; dur?: number };
  regions?: Region[];
  /** Overlays that should track the screenshot (cursor, typed text). Positioned in frame px. */
  tracked?: React.ReactNode;
};

const EXPLODE_Z = 150;

/** Keeps the pushed-in image covering the whole figure box (no plate showing through). */
const cover = (k: MotionKey): MotionKey => {
  const scale = Math.max(1, k.scale);
  const lim = 1 / (2 * scale);
  const clamp = (v: number) => Math.min(1 - lim, Math.max(lim, v));
  return { at: k.at, scale, fx: clamp(k.fx), fy: clamp(k.fy) };
};

export const useMotion = (keys: MotionKey[]) => {
  const frame = useCurrentFrame();
  if (keys.length === 1) return cover(keys[0]);
  let i = 0;
  while (i < keys.length - 2 && frame >= keys[i + 1].at) i++;
  const a = keys[i];
  const b = keys[i + 1];
  const t = interpolate(frame, [a.at, b.at], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeInOut,
  });
  return cover({
    at: frame,
    scale: a.scale + (b.scale - a.scale) * t,
    fx: a.fx + (b.fx - a.fx) * t,
    fy: a.fy + (b.fy - a.fy) * t,
  });
};

/** Maps an image-fraction point to composition px for a figure box under the current motion. */
export const project = (box: FigureBox, m: MotionKey, u: number, v: number) => ({
  x: box.x + box.w / 2 + (u - m.fx) * box.w * m.scale,
  y: box.y + box.h / 2 + (v - m.fy) * box.h * m.scale,
});

/**
 * Schematic figure: a drawn plate, the screenshot "screen" layer and an annotation layer,
 * stacked in an exploded isometric view that collapses into a flat, assembled frame in
 * which the screenshot plays (push-in / cross-fade).
 */
export const Figure: React.FC<Props> = ({ x, y, w, h, shots, motion, assemble, regions = [], tracked }) => {
  const frame = useCurrentFrame();
  const p = assemble
    ? interpolate(frame, [assemble.at, assemble.at + (assemble.dur ?? 27)], [0, 1], {
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
        easing: easeInOut,
      })
    : 1;
  const q = 1 - p;
  const plateDraw = interpolate(frame, [0, DUR.draw], [0, 1], { extrapolateRight: "clamp", easing: easeOut });
  const screenIn = interpolate(frame, [4, 4 + DUR.base], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
  const z = q * EXPLODE_Z;
  const group: React.CSSProperties = {
    position: "absolute",
    inset: 0,
    transformStyle: "preserve-3d",
    transform: `rotateX(${q * 52}deg) rotateZ(${q * -26}deg) scale(${0.74 + p * 0.26})`,
  };
  const layer = (tz: number): React.CSSProperties => ({
    position: "absolute",
    inset: 0,
    transform: `translateZ(${tz}px)`,
    backfaceVisibility: "hidden",
  });

  const m = useMotion(motion);
  const tx = (0.5 - m.fx) * w * m.scale;
  const ty = (0.5 - m.fy) * h * m.scale;
  const trackedTransform: React.CSSProperties = {
    position: "absolute",
    inset: 0,
    transform: `translate(${tx}px, ${ty}px) scale(${m.scale})`,
    transformOrigin: "50% 50%",
  };

  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        width: w,
        height: h,
        perspective: 2600,
        perspectiveOrigin: "50% 40%",
      }}
    >
      <div style={group}>
        {/* Plate */}
        <svg
          width={w + 80}
          height={h + 80}
          style={{ ...layer(-z), left: -40, top: -40, width: w + 80, height: h + 80, overflow: "visible" }}
        >
          <DrawRect x={40} y={40} w={w} h={h} progress={plateDraw} width={1.5} />
          <Crosshair x={40} y={40} opacity={Math.min(1, plateDraw * 4)} />
          <Crosshair x={40 + w} y={40} opacity={Math.max(0, (plateDraw - 0.25) * 4)} />
          <Crosshair x={40 + w} y={40 + h} opacity={Math.max(0, (plateDraw - 0.5) * 4)} />
          <Crosshair x={40} y={40 + h} opacity={Math.max(0, (plateDraw - 0.75) * 4)} />
        </svg>

        {/* Screen */}
        <div
          style={{
            ...layer(0),
            opacity: screenIn,
            borderRadius: radius.md,
            overflow: "hidden",
            backgroundColor: color.darkSurface,
            boxShadow: `0 0 0 1px ${bp.frameBorder}`,
          }}
        >
          {shots.map((s, i) => {
            const next = shots[i + 1];
            const fadeIn =
              i === 0
                ? 1
                : interpolate(frame, [s.from, s.from + DUR.base], [0, 1], {
                    extrapolateLeft: "clamp",
                    extrapolateRight: "clamp",
                    easing: easeInOut,
                  });
            const visible = next ? frame < next.from + DUR.base : true;
            if (!visible || fadeIn <= 0) return null;
            return (
              <Img
                key={s.src}
                src={staticFile(s.src)}
                style={{
                  ...trackedTransform,
                  width: "100%",
                  height: "100%",
                  objectFit: "cover",
                  opacity: fadeIn,
                }}
              />
            );
          })}
        </div>

        {/* Annotation layer */}
        <div style={layer(z)}>
          {q > 0.02 ? (
            <svg width={w} height={h} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
              <rect
                x={0.75}
                y={0.75}
                width={w - 1.5}
                height={h - 1.5}
                fill="none"
                stroke={bp.lineSoft}
                strokeWidth={1}
                strokeDasharray="6 6"
                opacity={q}
              />
            </svg>
          ) : null}
          <div style={{ position: "absolute", inset: 0, overflow: "hidden" }}>
          <div style={trackedTransform}>
            <svg width={w} height={h} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
              {regions.map((r, i) => {
                const rp = interpolate(frame, [r.at, r.at + DUR.draw], [0, 1], {
                  extrapolateLeft: "clamp",
                  extrapolateRight: "clamp",
                  easing: easeOut,
                });
                const out =
                  r.until === undefined
                    ? 1
                    : interpolate(frame, [r.until - DUR.fast, r.until], [1, 0], {
                        extrapolateLeft: "clamp",
                        extrapolateRight: "clamp",
                      });
                if (out <= 0) return null;
                return (
                  <g key={i} opacity={out}>
                    <Brackets x={r.x * w} y={r.y * h} w={r.w * w} h={r.h * h} progress={rp} />
                  </g>
                );
              })}
            </svg>
            {tracked}
          </div>
          </div>
        </div>
      </div>
    </div>
  );
};
