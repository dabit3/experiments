import { easeInOut, lerp, progress } from "./anim";
import { Zoom } from "./layout";

/** Ease from zoom `a` to zoom `b` between two local frames (clamped). */
export const zoomBetween = (frame: number, from: number, to: number, a: Zoom, b: Zoom): Zoom => {
  const t = progress(frame, from, to, easeInOut);
  return { scale: lerp(a.scale, b.scale, t), x: lerp(a.x, b.x, t), y: lerp(a.y, b.y, t) };
};

/** Piecewise zoom timeline: segments are applied in order; the last matching wins. */
export type ZoomSegment = { from: number; to: number; a: Zoom; b: Zoom };

export const zoomTimeline = (frame: number, segments: ZoomSegment[]): Zoom => {
  let z = segments[0].a;
  for (const seg of segments) {
    if (frame >= seg.from) z = zoomBetween(frame, seg.from, seg.to, seg.a, seg.b);
  }
  return z;
};
