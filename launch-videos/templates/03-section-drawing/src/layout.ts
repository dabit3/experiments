import { Easing, interpolate } from "remotion";
import type { MediaSlot } from "./schema";

export const WIDTH = 1920;
export const HEIGHT = 1080;
export const MARGIN = 96;
export const RAIL_HEIGHT = 44;
export const CAPTION_COLUMN = 440;
export const COLUMN_GAP = 56;

export type Rect = { x: number; y: number; w: number; h: number };

export const CONTENT: Rect = {
  x: MARGIN,
  y: MARGIN,
  w: WIDTH - MARGIN * 2,
  h: HEIGHT - MARGIN * 2,
};

/** Area below the stage rail available for planes and captions in stage scenes. */
export const STAGE_AREA: Rect = {
  x: MARGIN,
  y: MARGIN + RAIL_HEIGHT + 40,
  w: WIDTH - MARGIN * 2,
  h: HEIGHT - MARGIN * 2 - RAIL_HEIGHT - 40 - 32,
};

export const easeOut = Easing.out(Easing.cubic);
export const easeInOut = Easing.inOut(Easing.cubic);

export const clamp = (
  frame: number,
  from: number,
  to: number,
  easing: (t: number) => number = easeOut,
) =>
  interpolate(frame, [from, to], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing,
  });

export const fullCrop = { x: 0, y: 0, w: 1, h: 1 };

export const cropOf = (slot: MediaSlot) => slot.crop ?? fullCrop;

/** Aspect ratio of the visible (cropped) part of a media slot. */
export const slotAspect = (slot: MediaSlot) => {
  const c = cropOf(slot);
  return (slot.width * c.w) / (slot.height * c.h);
};

/** Largest rect with `aspect` that fits inside `box`, aligned inside it. */
export const fitRect = (
  aspect: number,
  box: Rect,
  align: { x: "start" | "center" | "end"; y: "start" | "center" | "end" } = {
    x: "center",
    y: "center",
  },
): Rect => {
  let w = box.w;
  let h = w / aspect;
  if (h > box.h) {
    h = box.h;
    w = h * aspect;
  }
  const x =
    align.x === "start" ? box.x : align.x === "end" ? box.x + box.w - w : box.x + (box.w - w) / 2;
  const y =
    align.y === "start" ? box.y : align.y === "end" ? box.y + box.h - h : box.y + (box.h - h) / 2;
  return { x, y, w, h };
};

export const lerpRect = (a: Rect, b: Rect, t: number): Rect => ({
  x: a.x + (b.x - a.x) * t,
  y: a.y + (b.y - a.y) * t,
  w: a.w + (b.w - a.w) * t,
  h: a.h + (b.h - a.h) * t,
});

/** Point on a plane rect for an anchor given in source-media fractions. */
export const anchorPoint = (slot: MediaSlot, rect: Rect, anchor: { x: number; y: number }) => {
  const c = cropOf(slot);
  return {
    x: rect.x + ((anchor.x - c.x) / c.w) * rect.w,
    y: rect.y + ((anchor.y - c.y) / c.h) * rect.h,
  };
};

export const OVERVIEW_ROW_Y = 372;
export const OVERVIEW_ROW_H = 250;

/**
 * Plane slots for the overview diagram: `count` boxes in a row across the content width.
 * `gap` is animated (planes start abutting as one section, then separate).
 */
export const overviewBoxes = (count: number, gap: number): Rect[] => {
  const totalW = CONTENT.w;
  const w = (totalW - gap * (count - 1)) / count;
  return Array.from({ length: count }, (_, i) => ({
    x: CONTENT.x + i * (w + gap),
    y: OVERVIEW_ROW_Y,
    w,
    h: OVERVIEW_ROW_H,
  }));
};

export const OVERVIEW_GAP_CLOSED = 6;
export const OVERVIEW_GAP_OPEN = 88;

/** The rect a stage's plane occupies in the settled (separated) overview diagram. */
export const overviewPlaneRect = (slot: MediaSlot, index: number, count: number): Rect =>
  fitRect(slotAspect(slot), overviewBoxes(count, OVERVIEW_GAP_OPEN)[index], {
    x: "center",
    y: "end",
  });

/** Region for planes in a stage scene, leaving a caption column on `side`. */
export const planeRegion = (side: "left" | "right"): Rect => {
  const w = STAGE_AREA.w - CAPTION_COLUMN - COLUMN_GAP;
  return {
    x: side === "left" ? STAGE_AREA.x + CAPTION_COLUMN + COLUMN_GAP : STAGE_AREA.x,
    y: STAGE_AREA.y,
    w,
    h: STAGE_AREA.h,
  };
};

/** Caption column rect for a stage scene. */
export const captionColumn = (side: "left" | "right"): Rect => ({
  x: side === "left" ? STAGE_AREA.x : STAGE_AREA.x + STAGE_AREA.w - CAPTION_COLUMN,
  y: STAGE_AREA.y,
  w: CAPTION_COLUMN,
  h: STAGE_AREA.h,
});

/** Two planes side by side inside `region`, sharing one height, packed toward the caption column. */
export const splitRects = (aspects: [number, number], region: Rect, side: "left" | "right"): [Rect, Rect] => {
  const gap = 32;
  const sumAspect = aspects[0] + aspects[1];
  let h = region.h;
  let totalW = h * sumAspect + gap;
  if (totalW > region.w) {
    totalW = region.w;
    h = (totalW - gap) / sumAspect;
  }
  const startX = side === "left" ? region.x : region.x + region.w - totalW;
  const y = region.y + (region.h - h) / 2;
  const w0 = h * aspects[0];
  return [
    { x: startX, y, w: w0, h },
    { x: startX + w0 + gap, y, w: h * aspects[1], h },
  ];
};
