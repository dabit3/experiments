import {sec} from './tokens';

// Page-turn wipe between consecutive scenes. TransitionSeries overlaps the
// scenes by this many frames, so the total is sum(durations) - (n-1) * TURN.
export const TURN = sec(0.65);

export const scenes = {
  hook: {page: 1, duration: sec(4.0)},
  context: {page: 2, duration: sec(6.5)},
  choose: {page: 3, duration: sec(7.5)},
  live: {page: 4, duration: sec(7.0)},
  fix: {page: 5, duration: sec(7.0)},
  matrix: {page: 6, duration: sec(7.0)},
  outcome: {page: 7, duration: sec(6.5)},
  end: {page: 8, duration: sec(4.0)},
} as const;

export type SceneId = keyof typeof scenes;

export const sceneOrder: SceneId[] = ['hook', 'context', 'choose', 'live', 'fix', 'matrix', 'outcome', 'end'];
export const PAGE_COUNT = sceneOrder.length;

export const totalDuration =
  sceneOrder.reduce((sum, id) => sum + scenes[id].duration, 0) - TURN * (sceneOrder.length - 1);

// Scene-local frame at which content should start animating: the incoming
// page is only fully revealed once the wipe has finished.
export const REVEAL = Math.round(TURN * 0.6);
