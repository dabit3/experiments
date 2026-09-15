import type { Layout } from "./schema";

export type Rect = { x: number; y: number; w: number; h: number };

export type ConsoleGeometry = {
  content: Rect;
  header: Rect;
  primary: Rect;
  bays: Rect[];
  caption: Rect;
  /** Primary display after the closing consolidation (fills the area below the header). */
  primaryExpanded: Rect;
};

export const computeGeometry = (
  layout: Layout,
  width: number,
  height: number,
  bayCount: number,
): ConsoleGeometry => {
  const m = layout.safeMargin;
  const g = layout.gutter;
  const content: Rect = { x: m, y: m, w: width - 2 * m, h: height - 2 * m };

  const header: Rect = { x: content.x, y: content.y, w: content.w, h: layout.headerHeight };

  const stageTop = header.y + header.h + g;
  const stageH = content.h - layout.headerHeight - g - g - layout.captionHeight;

  const primaryW = Math.round(content.w * layout.primaryFraction);
  const baysW = content.w - primaryW - g;

  const primaryX = layout.baysSide === "right" ? content.x : content.x + baysW + g;
  const baysX = layout.baysSide === "right" ? content.x + primaryW + g : content.x;

  const primary: Rect = { x: primaryX, y: stageTop, w: primaryW, h: stageH };

  const bayH = Math.floor((stageH - g * (bayCount - 1)) / bayCount);
  const bays: Rect[] = Array.from({ length: bayCount }, (_, i) => ({
    x: baysX,
    y: stageTop + i * (bayH + g),
    w: baysW,
    h: i === bayCount - 1 ? stageH - i * (bayH + g) : bayH,
  }));

  const caption: Rect = {
    x: primaryX,
    y: stageTop + stageH + g,
    w: primaryW,
    h: layout.captionHeight,
  };

  const primaryExpanded: Rect = {
    x: content.x,
    y: stageTop,
    w: content.w,
    h: content.h - layout.headerHeight - g,
  };

  return { content, header, primary, bays, caption, primaryExpanded };
};

export const lerpRect = (a: Rect, b: Rect, t: number): Rect => ({
  x: a.x + (b.x - a.x) * t,
  y: a.y + (b.y - a.y) * t,
  w: a.w + (b.w - a.w) * t,
  h: a.h + (b.h - a.h) * t,
});
