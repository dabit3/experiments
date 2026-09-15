import { FPS } from "./tokens";

const s = (seconds: number) => Math.round(seconds * FPS);

/**
 * Timing table. Each scene cross-dissolves into the next over `XFADE` frames,
 * so scene N+1 starts `XFADE` frames before scene N ends.
 */
export const XFADE = s(0.5);

export const SCENE_DURATIONS = {
  hook: s(3.5),
  context: s(5.0),
  choosePlatform: s(6.0),
  buildRun: s(6.0),
  liveSimulator: s(6.5),
  fixAndPr: s(6.5),
  deviceMatrix: s(6.0),
  outcome: s(6.5),
  endCard: s(3.5),
} as const;

export type SceneId = keyof typeof SCENE_DURATIONS;

export const SCENE_ORDER: SceneId[] = [
  "hook",
  "context",
  "choosePlatform",
  "buildRun",
  "liveSimulator",
  "fixAndPr",
  "deviceMatrix",
  "outcome",
  "endCard",
];

export const SCENES = (() => {
  let from = 0;
  return SCENE_ORDER.map((id, i) => {
    const duration = SCENE_DURATIONS[id];
    const entry = { id, from, duration };
    from += duration - (i < SCENE_ORDER.length - 1 ? XFADE : 0);
    return entry;
  });
})();

export const TOTAL_FRAMES = SCENES[SCENES.length - 1].from + SCENES[SCENES.length - 1].duration;
