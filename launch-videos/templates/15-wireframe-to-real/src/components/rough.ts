import { rng } from "../anim";

type Pt = { x: number; y: number };

const jitter = (pts: Pt[], amp: number, seed: number): Pt[] => {
  const r = rng(seed);
  return pts.map((p) => ({
    x: p.x + (r() - 0.5) * 2 * amp,
    y: p.y + (r() - 0.5) * 2 * amp,
  }));
};

const toPath = (pts: Pt[], close: boolean): { d: string; len: number } => {
  let len = 0;
  const parts: string[] = [];
  pts.forEach((p, i) => {
    parts.push(`${i === 0 ? "M" : "L"}${p.x.toFixed(2)} ${p.y.toFixed(2)}`);
    if (i > 0) {
      const q = pts[i - 1];
      len += Math.hypot(p.x - q.x, p.y - q.y);
    }
  });
  if (close) {
    const a = pts[pts.length - 1];
    const b = pts[0];
    len += Math.hypot(a.x - b.x, a.y - b.y);
    parts.push("Z");
  }
  return { d: parts.join(" "), len };
};

const sampleSegment = (a: Pt, b: Pt, step: number, out: Pt[]) => {
  const d = Math.hypot(b.x - a.x, b.y - a.y);
  const n = Math.max(1, Math.round(d / step));
  for (let i = 0; i < n; i++) {
    const t = i / n;
    out.push({ x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t });
  }
};

const sampleArc = (
  cx: number,
  cy: number,
  r: number,
  from: number,
  to: number,
  n: number,
  out: Pt[],
) => {
  for (let i = 0; i < n; i++) {
    const t = from + ((to - from) * i) / n;
    out.push({ x: cx + Math.cos(t) * r, y: cy + Math.sin(t) * r });
  }
};

/**
 * A slightly wobbly rounded rectangle, sampled along its perimeter so the
 * stroke reads as hand-drawn rather than vector-perfect.
 */
export const roughRect = (
  x: number,
  y: number,
  w: number,
  h: number,
  r: number,
  seed: number,
  amp = 0.9,
): { d: string; len: number } => {
  const rad = Math.min(r, w / 2, h / 2);
  const step = 28;
  const pts: Pt[] = [];
  const arcN = rad > 0 ? 4 : 0;
  sampleSegment({ x: x + rad, y }, { x: x + w - rad, y }, step, pts);
  if (arcN) sampleArc(x + w - rad, y + rad, rad, -Math.PI / 2, 0, arcN, pts);
  sampleSegment({ x: x + w, y: y + rad }, { x: x + w, y: y + h - rad }, step, pts);
  if (arcN) sampleArc(x + w - rad, y + h - rad, rad, 0, Math.PI / 2, arcN, pts);
  sampleSegment({ x: x + w - rad, y: y + h }, { x: x + rad, y: y + h }, step, pts);
  if (arcN) sampleArc(x + rad, y + h - rad, rad, Math.PI / 2, Math.PI, arcN, pts);
  sampleSegment({ x, y: y + h - rad }, { x, y: y + rad }, step, pts);
  if (arcN) sampleArc(x + rad, y + rad, rad, Math.PI, Math.PI * 1.5, arcN, pts);
  return toPath(jitter(pts, amp, seed), true);
};

export const roughCircle = (
  cx: number,
  cy: number,
  r: number,
  seed: number,
  amp = 0.8,
): { d: string; len: number } => {
  const pts: Pt[] = [];
  sampleArc(cx, cy, r, -Math.PI / 2, Math.PI * 1.5, 22, pts);
  return toPath(jitter(pts, amp, seed), true);
};

export const roughLine = (
  a: Pt,
  b: Pt,
  seed: number,
  amp = 0.8,
): { d: string; len: number } => {
  const pts: Pt[] = [];
  sampleSegment(a, b, 24, pts);
  pts.push(b);
  return toPath(jitter(pts, amp, seed), false);
};
