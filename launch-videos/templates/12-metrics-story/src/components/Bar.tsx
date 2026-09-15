import React from "react";
import { useCurrentFrame } from "remotion";
import { easeOut, tween } from "../anim";
import { color, radius } from "../tokens";

/** Horizontal bar that grows from 0 to `fraction` of its track. */
export const Bar: React.FC<{
  fraction: number;
  start: number;
  dur?: number;
  height?: number;
  fill?: string;
  track?: string;
  width: number;
}> = ({ fraction, start, dur = 40, height = 28, fill = color.accent, track = color.surface, width }) => {
  const frame = useCurrentFrame();
  const p = tween(frame, start, dur, easeOut);
  return (
    <div
      style={{
        width,
        height,
        backgroundColor: track,
        borderRadius: radius.button,
        overflow: "hidden",
        position: "relative",
      }}
    >
      <div
        style={{
          position: "absolute",
          left: 0,
          top: 0,
          height,
          width: width * fraction * p,
          backgroundColor: fill,
          borderRadius: radius.button,
        }}
      />
    </div>
  );
};

/** Stacked segment bar (e.g. passed / failed / untested). */
export const SegmentBar: React.FC<{
  segments: { value: number; color: string }[];
  start: number;
  dur?: number;
  width: number;
  height?: number;
  gap?: number;
}> = ({ segments, start, dur = 45, width, height = 12, gap = 4 }) => {
  const frame = useCurrentFrame();
  const total = segments.reduce((n, s) => n + s.value, 0);
  const usable = width - gap * (segments.length - 1);
  let acc = 0;
  return (
    <div style={{ display: "flex", gap, width, height }}>
      {segments.map((s, i) => {
        const w = (s.value / total) * usable;
        const p = tween(frame, start + acc, dur * (s.value / total) + 8, easeOut);
        acc += dur * (s.value / total);
        return (
          <div
            key={i}
            style={{
              width: w,
              height,
              borderRadius: radius.button,
              backgroundColor: color.surface,
              overflow: "hidden",
              position: "relative",
            }}
          >
            <div
              style={{
                position: "absolute",
                inset: 0,
                width: w * p,
                backgroundColor: s.color,
                borderRadius: radius.button,
              }}
            />
          </div>
        );
      })}
    </div>
  );
};
