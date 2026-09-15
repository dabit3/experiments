export const clamp01 = (value: number): number => Math.max(0, Math.min(1, value));
export const progress = (frame: number, start: number, duration: number): number =>
  duration <= 0 ? Number(frame >= start) : clamp01((frame - start) / duration);
export const easeInOut = (value: number): number => {
  const t = clamp01(value);
  return t * t * (3 - 2 * t);
};
export const mix = (from: number, to: number, amount: number): number =>
  from + (to - from) * clamp01(amount);
export const fadeInOut = (frame: number, duration: number, enter = 12, exit = 12): number =>
  Math.min(progress(frame, 0, enter), 1 - progress(frame, duration - exit, exit));
export const rectangleReveal = (amount: number, axis: 'x' | 'y' = 'x'): string =>
  axis === 'x' ? `inset(0 ${(1 - clamp01(amount)) * 100}% 0 0)` :
    `inset(0 0 ${(1 - clamp01(amount)) * 100}% 0)`;
