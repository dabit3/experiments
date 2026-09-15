import {easeInOut, progress} from '../../shared';
import type {NoirConfig} from './config';

export const openingAmount = (frame: number, duration: number): number =>
  easeInOut(progress(frame, 0, duration));

export const shutterClip = (
  amount: number,
  width: number,
  height: number,
  motion: NoirConfig['motion'],
): string => {
  const horizontal = motion.shutterAxis === 'horizontal';
  const run = easeInOut(progress(amount, 0, motion.slitPhase));
  const spread = easeInOut(progress(amount, motion.slitPhase, 1 - motion.slitPhase));
  const slit = Math.min(1, motion.slitSize / (horizontal ? height : width));
  const across = slit + (1 - slit) * spread;
  const x = (1 - (horizontal ? run : across)) * 50;
  const y = (1 - (horizontal ? across : run)) * 50;
  return `inset(${y}% ${x}% ${y}% ${x}%)`;
};

export const splitStillFrames = (duration: number, fraction: number): number =>
  Math.max(1, Math.min(duration - 1, Math.round(duration * fraction)));

export const boundedTransition = (requested: number, hold: number): number =>
  Math.min(Math.max(0, requested), Math.floor(hold / 4));
