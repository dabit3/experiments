import {easeInOut, progress} from '../../shared/motion';

export const selectorDefaults = {enabled: true, holdFrames: 36, moveFrames: 24};

export const selectorState = (
  frame: number, duration: number, settings: typeof selectorDefaults,
) => {
  const budget = Math.max(0, Math.floor((duration - 1) / 3));
  const hold = Math.max(0, Math.min(settings.holdFrames, budget));
  const move = Math.max(0, Math.min(settings.moveFrames, budget));
  const position = easeInOut(progress(frame, hold, move));
  return {position, selected: position === 1 ? 'macOS' : 'Ubuntu'};
};
