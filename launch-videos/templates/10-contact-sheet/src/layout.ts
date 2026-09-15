import { Easing, interpolate } from "remotion";
import type { ClipScene, Scene, SheetLayout } from "./schema";
import { HEIGHT, WIDTH } from "./defaults";

export type Rect = { x: number; y: number; w: number; h: number };

export const MARGIN = 96;

/** Large product view used while a frame is enlarged (77% of frame width). */
export const STAGE: Rect = { x: 216, y: 72, w: 1488, h: 837 };

/** Final hero frame in the outro; text lives to its right. */
export const HERO: Rect = { x: MARGIN, y: 222, w: 1104, h: 621 };

export const easeOut = Easing.bezier(0.33, 1, 0.68, 1);
export const easeInOut = Easing.bezier(0.65, 0, 0.35, 1);

export const lerpRect = (a: Rect, b: Rect, t: number): Rect => ({
  x: a.x + (b.x - a.x) * t,
  y: a.y + (b.y - a.y) * t,
  w: a.w + (b.w - a.w) * t,
  h: a.h + (b.h - a.h) * t,
});

export const clamp01 = (v: number) => Math.min(1, Math.max(0, v));

export const fade = (frame: number, from: number, to: number, reverse = false) => {
  const v = interpolate(frame, [from, to], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
  return reverse ? 1 - v : v;
};

export type IndexFrame = { index: number; label: string; media: string };

/** The clips, in index order, define the frames printed on the contact sheet. */
export const indexFramesFromScenes = (scenes: Scene[]): IndexFrame[] =>
  scenes
    .filter((s): s is ClipScene => s.kind === "clip")
    .sort((a, b) => a.frameIndex - b.frameIndex)
    .map((s) => ({ index: s.frameIndex, label: s.label, media: s.media }));

export const ROW_GAP = 72;

export const cellRect = (sheet: SheetLayout, count: number, index: number): Rect => {
  const cols = Math.min(sheet.columns, count);
  const cellH = Math.round((sheet.cellWidth * 9) / 16);
  const rowW = cols * sheet.cellWidth + (cols - 1) * sheet.gap;
  const left = Math.round((WIDTH - rowW) / 2);
  const col = index % cols;
  const row = Math.floor(index / cols);
  return {
    x: left + col * (sheet.cellWidth + sheet.gap),
    y: sheet.top + row * (cellH + ROW_GAP),
    w: sheet.cellWidth,
    h: cellH,
  };
};

export const pad2 = (n: number) => String(n).padStart(2, "0");

export const sheetBottom = (sheet: SheetLayout, count: number) => {
  const last = cellRect(sheet, count, count - 1);
  return Math.min(HEIGHT - MARGIN, last.y + last.h);
};
