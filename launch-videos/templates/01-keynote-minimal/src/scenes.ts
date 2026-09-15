import { sec } from "./tokens";

/**
 * Timing table. Every scene is `[start, duration]` in frames; edit the seconds
 * here to retime the whole film. Scenes overlap by CROSSFADE frames.
 */
export const CROSSFADE = sec(0.6);

const durations = {
  hook: sec(3.4),
  context: sec(6.2),
  featureMac: sec(8.6),
  featureSimulator: sec(7.4),
  featurePr: sec(7.2),
  featureMatrix: sec(7.0),
  metrics: sec(7.0),
  endCard: sec(4.0),
} as const;

export type SceneId = keyof typeof durations;

const order: SceneId[] = [
  "hook",
  "context",
  "featureMac",
  "featureSimulator",
  "featurePr",
  "featureMatrix",
  "metrics",
  "endCard",
];

export type SceneTiming = { id: SceneId; from: number; duration: number };

export const scenes: SceneTiming[] = (() => {
  let cursor = 0;
  return order.map((id, index) => {
    const from = cursor;
    const duration = durations[id];
    cursor += duration - (index < order.length - 1 ? CROSSFADE : 0);
    return { id, from, duration };
  });
})();

export const TOTAL_FRAMES = scenes[scenes.length - 1].from + scenes[scenes.length - 1].duration;
