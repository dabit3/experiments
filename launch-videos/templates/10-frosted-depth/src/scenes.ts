import { sec } from "./tokens";

/** Frames two adjacent scenes overlap while one fades out and the next fades in. */
export const TRANSITION = sec(0.5);

export type SceneId =
  | "hook"
  | "context"
  | "featureSession"
  | "featureSimulator"
  | "featureBugfix"
  | "featureMatrix"
  | "outcome"
  | "endCard";

/** Duration of each scene in seconds, in playback order. Retime here. */
const durations: Record<SceneId, number> = {
  hook: 3.6,
  context: 6.2,
  featureSession: 7.4,
  featureSimulator: 6.6,
  featureBugfix: 7.0,
  featureMatrix: 7.0,
  outcome: 5.6,
  endCard: 4.0,
};

export type SceneTiming = { id: SceneId; from: number; durationInFrames: number };

export const scenes: SceneTiming[] = (() => {
  const out: SceneTiming[] = [];
  let cursor = 0;
  for (const id of Object.keys(durations) as SceneId[]) {
    const d = sec(durations[id]);
    out.push({ id, from: cursor, durationInFrames: d + TRANSITION });
    cursor += d;
  }
  return out;
})();

export const TOTAL_FRAMES = scenes[scenes.length - 1].from + scenes[scenes.length - 1].durationInFrames - TRANSITION;
