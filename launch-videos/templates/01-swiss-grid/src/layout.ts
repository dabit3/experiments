import { Easing, interpolate } from "remotion";
import { HEIGHT, WIDTH } from "./defaults";
import type { Grid, Span } from "./schema";

export type Rect = { x: number; y: number; w: number; h: number };

export const columnWidth = (grid: Grid) =>
  (WIDTH - grid.margin * 2 - grid.gutter * (grid.columns - 1)) / grid.columns;

export const columnX = (grid: Grid, column: number) =>
  grid.margin + (column - 1) * (columnWidth(grid) + grid.gutter);

export const spanWidth = (grid: Grid, span: Span) =>
  columnWidth(grid) * span.span + grid.gutter * (span.span - 1);

export const spanRect = (grid: Grid, span: Span): Rect => ({
  x: columnX(grid, span.start),
  y: contentTop(grid),
  w: spanWidth(grid, span),
  h: contentHeight(grid),
});

export const contentTop = (grid: Grid) => grid.margin + grid.railHeight + grid.gutter;
export const contentBottom = (grid: Grid) =>
  HEIGHT - grid.margin - grid.railHeight - grid.gutter;
export const contentHeight = (grid: Grid) => contentBottom(grid) - contentTop(grid);

export const easeOut = Easing.bezier(0.33, 1, 0.68, 1);
export const easeInOut = Easing.bezier(0.65, 0, 0.35, 1);

export const ENTER = 15;
export const EXIT = 12;

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

export const exitProgress = (frame: number, duration: number, length = EXIT) =>
  progress(frame, duration - length, length, easeInOut);
