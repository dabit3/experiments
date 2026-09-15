import { Easing, interpolate } from "remotion";
import type { Brand, Layout, MediaSlot, Scene, Surface } from "./schema";

export const WIDTH = 1920;
export const HEIGHT = 1080;

// Deliberate, mechanical motion: ease-out for entrances, ease-in-out for layout moves.
export const easeOut = Easing.bezier(0.33, 1, 0.68, 1);
export const easeInOut = Easing.bezier(0.65, 0, 0.35, 1);

export const progress = (
  frame: number,
  from: number,
  to: number,
  easing: (t: number) => number = easeInOut,
) =>
  interpolate(frame, [from, to], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing,
  });

export type Box = { x: number; y: number; w: number; h: number };

/** The flat presentation area between the header row and the caption strip. */
export const stageBox = (layout: Layout): Box => {
  const top = layout.margin + layout.headerHeight;
  const bottom = HEIGHT - layout.margin - layout.captionStripHeight - layout.gap;
  return {
    x: layout.margin,
    y: top,
    w: WIDTH - layout.margin * 2,
    h: bottom - top,
  };
};

export const captionBox = (layout: Layout): Box => ({
  x: layout.margin,
  y: HEIGHT - layout.margin - layout.captionStripHeight,
  w: WIDTH - layout.margin * 2,
  h: layout.captionStripHeight,
});

export const mediaAspect = (slot: MediaSlot) => {
  const base = slot.aspect ?? 16 / 9;
  if (!slot.crop) return base;
  return (base * slot.crop.w) / slot.crop.h;
};

/** Plate (media + matte padding) fitted and centred inside `within`. */
export const fitPlate = (aspect: number, padding: number, within: Box): Box => {
  const maxW = within.w - padding * 2;
  const maxH = within.h - padding * 2;
  let w = maxW;
  let h = w / aspect;
  if (h > maxH) {
    h = maxH;
    w = h * aspect;
  }
  const pw = w + padding * 2;
  const ph = h + padding * 2;
  return {
    x: within.x + (within.w - pw) / 2,
    y: within.y + (within.h - ph) / 2,
    w: pw,
    h: ph,
  };
};

export const lerpBox = (a: Box, b: Box, t: number): Box => ({
  x: a.x + (b.x - a.x) * t,
  y: a.y + (b.y - a.y) * t,
  w: a.w + (b.w - a.w) * t,
  h: a.h + (b.h - a.h) * t,
});

/**
 * Brand shadow for product surfaces on paper, scaled by `surface.shadowStrength`
 * and an `elevation` multiplier (1 = resting, >1 = lifted).
 */
export const plateShadow = (surface: Surface, elevation = 1) => {
  const s = surface.shadowStrength;
  if (s === 0) return "none";
  const e = elevation;
  return `0 ${4 * e}px ${8 * e}px rgba(0,0,0,${(0.22 * s) / Math.sqrt(e)}), 0 ${1 * e}px ${1.5 * e}px rgba(0,0,0,${(0.14 * s) / Math.sqrt(e)})`;
};

export const softShadow = (surface: Surface, brand: Brand) =>
  surface.shadowStrength === 0 ? "none" : `0 0 8px ${brand.line}`;

export type ScheduledScene = { scene: Scene; start: number; end: number };

export const scheduleScenes = (scenes: Scene[]): ScheduledScene[] => {
  let cursor = 0;
  return scenes.map((scene) => {
    const start = cursor;
    cursor += scene.durationInFrames;
    return { scene, start, end: cursor };
  });
};

export const totalDuration = (scenes: Scene[]) =>
  scenes.reduce((sum, s) => sum + s.durationInFrames, 0);
