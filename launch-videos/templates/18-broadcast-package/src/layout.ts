import type { Brand, Crop, MediaSlot } from "./schema";
import { HEIGHT, WIDTH } from "./defaults";

/** Vertical band reserved for the chapter marker (top) and lower third (bottom). */
export const MARKER_BAND = 56;
export const LOWER_THIRD_BAND = 130;
export const LOWER_THIRD_GAP = 36;

export const stageTop = (brand: Brand): number => brand.safeMargin + MARKER_BAND;
export const stageBottom = (brand: Brand): number =>
  HEIGHT - brand.safeMargin - LOWER_THIRD_BAND;
export const stageHeight = (brand: Brand): number =>
  stageBottom(brand) - stageTop(brand);
export const stageWidth = (brand: Brand): number => WIDTH - brand.safeMargin * 2;

export const fullCrop: Crop = { x: 0, y: 0, w: 1, h: 1 };

export const mediaAspect = (m: MediaSlot): number => {
  const c = m.crop ?? fullCrop;
  return (m.width * c.w) / (m.height * c.h);
};

/** Fit a media slot inside a box, preserving the (cropped) aspect ratio. */
export const fitMedia = (
  m: MediaSlot,
  boxW: number,
  boxH: number,
): { width: number; height: number } => {
  const a = mediaAspect(m);
  if (boxW / boxH > a) {
    return { width: Math.round(boxH * a), height: boxH };
  }
  return { width: boxW, height: Math.round(boxW / a) };
};

export const type = {
  display: { fontSize: 88, lineHeight: 1.0, letterSpacing: -3.3, fontWeight: 500 },
  h2: { fontSize: 64, lineHeight: 1.16, letterSpacing: -2.34, fontWeight: 500 },
  h3: { fontSize: 34, lineHeight: 1.25, letterSpacing: -0.55, fontWeight: 500 },
  h5: { fontSize: 27, lineHeight: 1.45, letterSpacing: -0.4, fontWeight: 400 },
  body: { fontSize: 22, lineHeight: 1.4, letterSpacing: -0.3, fontWeight: 400 },
  label: { fontSize: 18, lineHeight: 1.4, letterSpacing: -0.15, fontWeight: 400 },
  eyebrow: {
    fontSize: 15,
    lineHeight: 1.5,
    letterSpacing: 0.9,
    fontWeight: 500,
    textTransform: "uppercase" as const,
  },
};
