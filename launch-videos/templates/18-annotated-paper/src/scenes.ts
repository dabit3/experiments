import { sec } from "./theme";

export const SCENES = {
  hook: { from: 0, durationInFrames: sec(3.5) },
  context: { from: sec(3.5), durationInFrames: sec(6.5) },
  buildRun: { from: sec(10), durationInFrames: sec(7) },
  liveSimulator: { from: sec(17), durationInFrames: sec(8) },
  reproFixPr: { from: sec(25), durationInFrames: sec(7) },
  everyScreen: { from: sec(32), durationInFrames: sec(7) },
  outcome: { from: sec(39), durationInFrames: sec(6) },
  endCard: { from: sec(45), durationInFrames: sec(4) },
} as const;

export type SceneName = keyof typeof SCENES;

export const TOTAL_FRAMES = Object.values(SCENES).reduce(
  (max, s) => Math.max(max, s.from + s.durationInFrames),
  0,
);
