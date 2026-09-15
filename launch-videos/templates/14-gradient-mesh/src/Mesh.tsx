import React from "react";
import { AbsoluteFill, interpolate, interpolateColors, useCurrentFrame } from "remotion";
import { Mood, TRANSITION, timeline } from "./scenes";
import { color, easeInOut } from "./tokens";

/**
 * Animated mesh gradient. Five soft blobs drift slowly over a paper base;
 * their colours cross-fade between per-scene "moods" so each feature
 * transition shifts the dominant hue.
 */

type Palette = [string, string, string, string, string];

// Low-saturation tints of the palette: electric blue, indigo (blue toward
// ink), soft green, cream and neutral grey.
const tint = {
  blue: "#ABA0FF",
  blueDeep: "#9080FF",
  indigo: "#C3B7FF",
  green: "#B4E0C8",
  cream: "#EFE1CB",
  warm: "#E6D5BE",
  grey: "#D9D9D9",
  white: color.white,
};

const palettes: Record<Mood, Palette> = {
  blue: [tint.blue, tint.blueDeep, tint.cream, tint.white, tint.indigo],
  indigo: [tint.indigo, tint.blue, tint.warm, tint.blueDeep, tint.white],
  green: [tint.green, tint.cream, tint.indigo, tint.green, tint.white],
  cream: [tint.cream, tint.warm, tint.blue, tint.white, tint.green],
  neutral: [tint.grey, tint.cream, tint.indigo, tint.white, tint.grey],
};

const useMoodPalette = (frame: number): Palette => {
  // Find the current scene and (if inside the overlap) the next one.
  let current = timeline[0];
  for (const s of timeline) {
    if (frame >= s.from) current = s;
  }
  const idx = timeline.indexOf(current);
  const next = timeline[idx + 1];
  const from = palettes[current.mood];
  if (!next) return from;
  const to = palettes[next.mood];
  // Blend across the second half of the scene so the hue has settled when
  // the next scene's card lands.
  const blendStart = next.from - TRANSITION * 2;
  const blendEnd = next.from + TRANSITION;
  const t = interpolate(frame, [blendStart, blendEnd], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeInOut,
  });
  return from.map((c, i) => interpolateColors(t, [0, 1], [c, to[i]])) as Palette;
};

/** Accepts #rrggbb or rgba(r, g, b, a) and returns rgba with the given alpha. */
const withAlpha = (c: string, alpha: number): string => {
  if (c.startsWith("#")) {
    const r = parseInt(c.slice(1, 3), 16);
    const g = parseInt(c.slice(3, 5), 16);
    const b = parseInt(c.slice(5, 7), 16);
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
  }
  const [r, g, b] = c
    .replace(/rgba?\(/, "")
    .replace(")", "")
    .split(",")
    .map((v) => parseFloat(v));
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
};

type Blob = {
  cx: number;
  cy: number;
  r: number;
  ax: number;
  ay: number;
  speed: number;
  phase: number;
};

const blobs: Blob[] = [
  { cx: 0.18, cy: 0.22, r: 0.62, ax: 0.07, ay: 0.05, speed: 0.0042, phase: 0.0 },
  { cx: 0.82, cy: 0.18, r: 0.58, ax: 0.06, ay: 0.06, speed: 0.0036, phase: 1.7 },
  { cx: 0.72, cy: 0.86, r: 0.66, ax: 0.08, ay: 0.04, speed: 0.0031, phase: 3.1 },
  { cx: 0.24, cy: 0.88, r: 0.54, ax: 0.05, ay: 0.06, speed: 0.0047, phase: 4.4 },
  { cx: 0.5, cy: 0.5, r: 0.5, ax: 0.09, ay: 0.07, speed: 0.0028, phase: 5.6 },
];

export const Mesh: React.FC = () => {
  const frame = useCurrentFrame();
  const palette = useMoodPalette(frame);

  return (
    <AbsoluteFill style={{ backgroundColor: color.paper, overflow: "hidden" }}>
      {blobs.map((b, i) => {
        const x = b.cx + Math.sin(frame * b.speed + b.phase) * b.ax;
        const y = b.cy + Math.cos(frame * b.speed * 0.8 + b.phase) * b.ay;
        const size = b.r * 1920;
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: x * 1920 - size / 2,
              top: y * 1080 - size / 2,
              width: size,
              height: size,
              borderRadius: "50%",
              background: `radial-gradient(circle at center, ${withAlpha(palette[i], 1)} 0%, ${withAlpha(palette[i], 0.8)} 28%, ${withAlpha(palette[i], 0)} 70%)`,
              filter: "blur(48px)",
              opacity: 0.78,
            }}
          />
        );
      })}
    </AbsoluteFill>
  );
};
