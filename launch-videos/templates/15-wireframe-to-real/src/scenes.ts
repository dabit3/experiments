import { ms } from "./anim";

export const FPS = 30;
export const WIDTH = 1920;
export const HEIGHT = 1080;

/**
 * Timing table. Durations are in frames (30fps). Retime a scene here and every
 * <Sequence> shifts accordingly.
 */
const durations = {
  hook: ms(3200),
  context: ms(5600),
  feature1: ms(7600),
  feature2: ms(7000),
  feature3: ms(7000),
  feature4: ms(7000),
  outcome: ms(5600),
  end: ms(3600),
} as const;

export type SceneId = keyof typeof durations;

export type SceneTiming = { id: SceneId; from: number; duration: number };

const build = (): Record<SceneId, SceneTiming> => {
  let cursor = 0;
  const out = {} as Record<SceneId, SceneTiming>;
  (Object.keys(durations) as SceneId[]).forEach((id) => {
    out[id] = { id, from: cursor, duration: durations[id] };
    cursor += durations[id];
  });
  return out;
};

export const scenes = build();

export const TOTAL_FRAMES = Object.values(scenes).reduce(
  (acc, s) => acc + s.duration,
  0,
);

/** Shared beats inside a feature scene (relative frames). */
export const featureBeats = {
  /** wireframe strokes draw on */
  drawDuration: ms(1200),
  /** wireframe -> real screenshot cross-resolve */
  resolveDuration: ms(600),
  /** exit fade */
  exitDuration: ms(300),
};
