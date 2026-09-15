import {Easing, interpolate} from 'remotion';

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

/** Ease-out cubic entrance (300-500ms). */
export const easeOut = (frame: number, from: number, length: number) =>
  interpolate(frame, [from, from + length], [0, 1], {
    ...clamp,
    easing: Easing.out(Easing.cubic),
  });

/** Ease-in-out cubic layout move (500-800ms). */
export const easeInOut = (frame: number, from: number, length: number) =>
  interpolate(frame, [from, from + length], [0, 1], {
    ...clamp,
    easing: Easing.inOut(Easing.cubic),
  });

export const linear = (frame: number, from: number, length: number) =>
  interpolate(frame, [from, from + length], [0, 1], clamp);

/** Style for an element that slides in by `distance` px along an axis and fades in. */
export const enterStyle = (
  t: number,
  distance: number,
  axis: 'x' | 'y' = 'y',
): React.CSSProperties => {
  const offset = (1 - t) * distance;
  return {
    opacity: t,
    transform: axis === 'y' ? `translateY(${offset}px)` : `translateX(${offset}px)`,
  };
};
