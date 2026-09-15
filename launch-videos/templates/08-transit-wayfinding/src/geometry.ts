import { Easing, interpolate } from "remotion";
import type { MediaSlot, Route } from "./schema";

export const WIDTH = 1920;
export const HEIGHT = 1080;
export const SAFE = 96;

// Type scale from brand.md (site values x1.27 for 1920 video).
export const TYPE = {
  display: { size: 89, lineHeight: 1, tracking: -3.4 },
  h3: { size: 34, lineHeight: 1.25, tracking: -0.53 },
  h5: { size: 27, lineHeight: 1.5, tracking: -0.39 },
  body: { size: 20, lineHeight: 1.4, tracking: -0.39 },
  label: { size: 18, lineHeight: 1.4, tracking: -0.19 },
  eyebrow: { size: 14, lineHeight: 1.5, tracking: 0.36 },
} as const;

export const easeOut = Easing.out(Easing.cubic);
export const easeInOut = Easing.inOut(Easing.cubic);

export const lerp = (a: number, b: number, t: number) => a + (b - a) * t;

export const clamp01 = (t: number) => Math.min(1, Math.max(0, t));

export const ramp = (frame: number, start: number, duration: number, easing = easeOut) =>
  interpolate(frame, [start, start + duration], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing,
  });

// Route points: index 0 is the origin terminus, 1..N are the stations.
export const ROUTE_X0 = 144;
export const ROUTE_X1 = WIDTH - 144;

export const routeXs = (route: Route): number[] => {
  const n = route.stations.length;
  return Array.from({ length: n + 1 }, (_, i) => lerp(ROUTE_X0, ROUTE_X1, i / n));
};

export const stationIndex = (route: Route, id: string): number => {
  const i = route.stations.findIndex((s) => s.id === id);
  if (i < 0) {
    throw new Error(`Unknown station "${id}"`);
  }
  return i + 1;
};

// Continuous position along the line, in station units (0 = origin, k = station k).
export const progressToX = (route: Route, progress: number): number => {
  const xs = routeXs(route);
  const p = Math.min(xs.length - 1, Math.max(0, progress));
  const i = Math.floor(p);
  if (i >= xs.length - 1) {
    return xs[xs.length - 1];
  }
  return lerp(xs[i], xs[i + 1], p - i);
};

export type Rect = { x: number; y: number; w: number; h: number };

export const lerpRect = (a: Rect, b: Rect, t: number): Rect => ({
  x: lerp(a.x, b.x, t),
  y: lerp(a.y, b.y, t),
  w: lerp(a.w, b.w, t),
  h: lerp(a.h, b.h, t),
});

// The stage where a recording is shown while a station is active.
export const STAGE: Rect = { x: 224, y: 150, w: 1472, h: 828 };

export const cropPx = (slot: MediaSlot) => {
  const c = slot.crop ?? { x: 0, y: 0, w: 1, h: 1 };
  return {
    x: c.x * slot.sourceWidth,
    y: c.y * slot.sourceHeight,
    w: c.w * slot.sourceWidth,
    h: c.h * slot.sourceHeight,
  };
};

// Fit the (cropped) media inside the stage, preserving aspect, centered.
export const fitToStage = (slot: MediaSlot, stage: Rect = STAGE): Rect => {
  const c = cropPx(slot);
  const aspect = c.w / c.h;
  let w = stage.w;
  let h = w / aspect;
  if (h > stage.h) {
    h = stage.h;
    w = h * aspect;
  }
  return { x: stage.x + (stage.w - w) / 2, y: stage.y + (stage.h - h) / 2, w, h };
};
