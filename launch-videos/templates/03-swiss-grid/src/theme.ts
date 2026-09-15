import { Easing, interpolate } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";
import tokens from "../../../assets/tokens.json";
import { HEIGHT, WIDTH } from "./scenes";

// Fonts are loaded at module level so they are ready before the first frame renders.
const inter = loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
const geistMono = loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });

export const FONT_SANS = inter.fontFamily;
export const FONT_MONO = geistMono.fontFamily;

export const color = tokens.color;
export const radius = tokens.radius;

// Swiss Grid uses exactly three sizes of the sans face plus one mono label size.
export const type = {
  hero: tokens.type.sizes1080p.hero, // 112
  heading: tokens.type.sizes1080p.h2, // 56
  text: tokens.type.sizes1080p.h3, // 40
  label: tokens.type.sizes1080p.label, // 18, Geist Mono, uppercase
  trackingHero: tokens.type.tracking.hero,
  trackingHeading: tokens.type.tracking.heading,
  trackingBody: tokens.type.tracking.body,
  trackingCaps: tokens.type.tracking.caps,
  leadingTight: tokens.type.leading.tight,
  leadingHeading: tokens.type.leading.heading,
} as const;

// 12-column grid: 120px frame margin, 24px gutter, 118px columns.
export const grid = {
  margin: tokens.space.frameMargin1080p,
  columns: 12,
  gutter: 24,
  get content() {
    return WIDTH - this.margin * 2;
  },
  get column() {
    return (this.content - this.gutter * (this.columns - 1)) / this.columns;
  },
  /** Left x of column `i` (0-based). */
  x(i: number) {
    return this.margin + i * (this.column + this.gutter);
  },
  /** Width of a span of `n` columns. */
  span(n: number) {
    return n * this.column + (n - 1) * this.gutter;
  },
  rowTop: tokens.space.frameMargin1080p,
  rowMid: HEIGHT / 2,
  rowBottom: HEIGHT - tokens.space.frameMargin1080p,
};

export const easeOut = Easing.bezier(...(tokens.motion.easeOut as [number, number, number, number]));
export const easeInOut = Easing.bezier(...(tokens.motion.easeInOut as [number, number, number, number]));
// Ease-in for exits (mirror of the ease-out curve).
export const easeIn = Easing.bezier(0.7, 0, 0.84, 0);

const ms = tokens.motion.durationMs;
export const dur = {
  fast: Math.round((ms.fast / 1000) * tokens.motion.fps),
  base: Math.round((ms.base / 1000) * tokens.motion.fps),
  slow: Math.round((ms.slow / 1000) * tokens.motion.fps),
  hold: Math.round((ms.hold / 1000) * tokens.motion.fps),
};

/** 0→1 progress starting at `from`, lasting `length` frames, clamped. */
export const progress = (
  frame: number,
  from: number,
  length: number,
  easing: (t: number) => number = easeOut,
) =>
  interpolate(frame, [from, from + length], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing,
  });

/** Scene-level fade: ease-out in over `inFrames`, ease-in out over the last `outFrames`. */
export const sceneOpacity = (frame: number, duration: number, inFrames = dur.base, outFrames = dur.fast) => {
  const fadeIn = progress(frame, 0, inFrames);
  const fadeOut = 1 - progress(frame, duration - outFrames, outFrames, easeIn);
  return Math.min(fadeIn, fadeOut);
};
