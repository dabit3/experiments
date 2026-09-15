import type { Crop, Layout, MediaSlot } from "./schema";

export const WIDTH = 1920;
export const HEIGHT = 1080;

export type Rect = { x: number; y: number; w: number; h: number };

/** Vertical bands shared by every diptych scene (px from the top of the frame). */
export const bands = (layout: Layout) => {
  const top = layout.margin;
  const labelY = top + 56;
  const panelTop = labelY + 40;
  const captionY = HEIGHT - layout.margin - 40;
  const panelBottom = captionY - 44;
  return { top, labelY, panelTop, panelBottom, captionY };
};

/**
 * The two slots of the diptych for a given action-panel ratio. The action panel
 * is always on the left; the divider sits in the middle of the gutter.
 */
export const diptychSlots = (ratio: number, layout: Layout) => {
  const { panelTop, panelBottom } = bands(layout);
  const contentX = layout.margin;
  const contentW = WIDTH - layout.margin * 2;
  const usable = contentW - layout.gutter;
  const leftW = Math.round(usable * ratio);
  const rightW = usable - leftW;
  const left: Rect = { x: contentX, y: panelTop, w: leftW, h: panelBottom - panelTop };
  const right: Rect = {
    x: contentX + leftW + layout.gutter,
    y: panelTop,
    w: rightW,
    h: panelBottom - panelTop,
  };
  const dividerX = contentX + leftW + layout.gutter / 2;
  return { left, right, dividerX };
};

export const fullFrame: Rect = { x: 0, y: 0, w: WIDTH, h: HEIGHT };

const defaultCrop: Crop = { x: 0, y: 0, w: 1, h: 1 };

export const cropOf = (slot: MediaSlot): Crop => slot.crop ?? defaultCrop;

/** Aspect ratio (w/h) of the visible (cropped) part of a media slot. */
export const croppedAspect = (slot: MediaSlot) => {
  const c = cropOf(slot);
  return (c.w * slot.srcWidth) / (c.h * slot.srcHeight);
};

/** Fit a box of the given aspect into a slot, centered. */
export const fitRect = (
  slot: Rect,
  aspect: number,
  mode: "contain" | "cover",
): Rect => {
  const slotAspect = slot.w / slot.h;
  const wide = mode === "contain" ? aspect > slotAspect : aspect < slotAspect;
  const w = wide ? slot.w : slot.h * aspect;
  const h = wide ? slot.w / aspect : slot.h;
  return { x: slot.x + (slot.w - w) / 2, y: slot.y + (slot.h - h) / 2, w, h };
};

export const lerpRect = (a: Rect, b: Rect, t: number): Rect => ({
  x: a.x + (b.x - a.x) * t,
  y: a.y + (b.y - a.y) * t,
  w: a.w + (b.w - a.w) * t,
  h: a.h + (b.h - a.h) * t,
});
