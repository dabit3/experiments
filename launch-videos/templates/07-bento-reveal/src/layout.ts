import { FRAME_MARGIN, HEIGHT, WIDTH } from "./tokens";

export type Rect = { x: number; y: number; w: number; h: number };

export type TileId = "sim" | "build" | "brand" | "pr" | "devices";

const GAP = 24;
const COLS = 4;
const ROWS = 2;
const AREA_W = WIDTH - FRAME_MARGIN * 2;
const AREA_H = HEIGHT - FRAME_MARGIN * 2;
const COL_W = (AREA_W - GAP * (COLS - 1)) / COLS;
const ROW_H = (AREA_H - GAP * (ROWS - 1)) / ROWS;

const cell = (col: number, row: number, colSpan: number, rowSpan: number): Rect => ({
  x: FRAME_MARGIN + col * (COL_W + GAP),
  y: FRAME_MARGIN + row * (ROW_H + GAP),
  w: COL_W * colSpan + GAP * (colSpan - 1),
  h: ROW_H * rowSpan + GAP * (rowSpan - 1),
});

export const tileRects: Record<TileId, Rect> = {
  sim: cell(0, 0, 1, 2),
  build: cell(1, 0, 2, 1),
  brand: cell(3, 0, 1, 1),
  pr: cell(1, 1, 1, 1),
  devices: cell(2, 1, 2, 1),
};

export const FULL_RECT: Rect = { x: 0, y: 0, w: WIDTH, h: HEIGHT };

export const tileOrder: TileId[] = ["sim", "build", "brand", "pr", "devices"];

// Stagger: tiles closest to the frame centre build first.
const dist = (r: Rect) => Math.hypot(r.x + r.w / 2 - WIDTH / 2, r.y + r.h / 2 - HEIGHT / 2);
const maxDist = Math.max(...tileOrder.map((id) => dist(tileRects[id])));
export const tileStagger = (id: TileId) => dist(tileRects[id]) / maxDist;

export const lerpRect = (a: Rect, b: Rect, t: number): Rect => ({
  x: a.x + (b.x - a.x) * t,
  y: a.y + (b.y - a.y) * t,
  w: a.w + (b.w - a.w) * t,
  h: a.h + (b.h - a.h) * t,
});
