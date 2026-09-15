import type { FractionRect, Inspection, MediaSlot } from "./schema";

export type PxRect = { x: number; y: number; w: number; h: number };

export const FULL_CROP: FractionRect = { x: 0, y: 0, w: 1, h: 1 };

/** Aspect ratio (w / h) of the visible part of a media slot. */
export const visibleAspect = (slot: MediaSlot): number => {
  const crop = slot.crop ?? FULL_CROP;
  return (crop.w * slot.width) / (crop.h * slot.height);
};

/** Stage box for a media slot: fixed width, height from the visible aspect, vertically centred. */
export const stageRectFor = (
  slot: MediaSlot | undefined,
  stageX: number,
  stageW: number,
  frameH: number,
): PxRect => {
  const aspect = slot ? visibleAspect(slot) : 16 / 9;
  const h = Math.round(stageW / aspect);
  return { x: stageX, y: Math.round((frameH - h) / 2), w: stageW, h };
};

export type LensGeometry = {
  /** Focus rectangle in stage-local pixels. */
  focus: PxRect;
  /** Inspection window rectangle in stage-local pixels. */
  window: PxRect;
  /** Display pixels per stage pixel inside the window. */
  magnification: number;
  /** Scale applied to the stage-sized media inside the window. */
  zoom: number;
};

/**
 * Resolve an inspection into pixel rectangles. The window keeps the focus aspect ratio
 * and its width is capped at the number of source pixels in the focus region so a
 * source pixel is never enlarged past one output pixel. The window is also kept inside
 * the stage.
 */
export const resolveLens = (
  inspection: Inspection,
  slot: MediaSlot,
  stage: PxRect,
): LensGeometry => {
  const crop = slot.crop ?? FULL_CROP;
  const f = inspection.focus;
  const focus: PxRect = {
    x: f.x * stage.w,
    y: f.y * stage.h,
    w: f.w * stage.w,
    h: f.h * stage.h,
  };
  const sourcePxAcross = f.w * crop.w * slot.width;
  let w = Math.min(inspection.window.w * stage.w, sourcePxAcross, stage.w);
  let h = w * (focus.h / focus.w);
  if (h > stage.h) {
    h = stage.h;
    w = h * (focus.w / focus.h);
  }
  const x = Math.min(Math.max(0, inspection.window.x * stage.w), stage.w - w);
  const y = Math.min(Math.max(0, inspection.window.y * stage.h), stage.h - h);
  const zoom = w / focus.w;
  return {
    focus,
    window: { x, y, w, h },
    magnification: zoom,
    zoom,
  };
};

const center = (r: PxRect) => ({ x: r.x + r.w / 2, y: r.y + r.h / 2 });

/** Point where the ray from a rect's centre towards (dx, dy) exits the rect. */
const exitPoint = (r: PxRect, dx: number, dy: number) => {
  const c = center(r);
  const hw = r.w / 2;
  const hh = r.h / 2;
  const tx = dx === 0 ? Infinity : hw / Math.abs(dx);
  const ty = dy === 0 ? Infinity : hh / Math.abs(dy);
  const t = Math.min(tx, ty);
  return { x: c.x + dx * t, y: c.y + dy * t };
};

/** Straight hairline from the focus edge to the window edge. */
export const connector = (focus: PxRect, win: PxRect) => {
  const a = center(focus);
  const b = center(win);
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  const len = Math.hypot(dx, dy) || 1;
  const ux = dx / len;
  const uy = dy / len;
  const from = exitPoint(focus, ux, uy);
  const to = exitPoint(win, -ux, -uy);
  return { from, to, length: Math.hypot(to.x - from.x, to.y - from.y) };
};
