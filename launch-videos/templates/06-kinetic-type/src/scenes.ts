import { beats } from "./tokens";

/**
 * Timing table. Every scene length is expressed in beats (120 BPM, 1 beat = 15 frames = 0.5 s)
 * so the whole edit can be retimed by changing a single number here.
 */
export const SCENES = [
  { id: "hook", beats: 8 }, // 4.0 s
  { id: "problem", beats: 11 }, // 5.5 s
  { id: "feature-build", beats: 13 }, // 6.5 s
  { id: "feature-live", beats: 14 }, // 7.0 s
  { id: "feature-fix", beats: 13 }, // 6.5 s
  { id: "feature-matrix", beats: 13 }, // 6.5 s
  { id: "outcome", beats: 12 }, // 6.0 s
  { id: "end", beats: 8 }, // 4.0 s
] as const;

export type SceneId = (typeof SCENES)[number]["id"];

export const sceneFrames = (id: SceneId): number =>
  beats(SCENES.find((s) => s.id === id)!.beats);

export const sceneStart = (id: SceneId): number => {
  let f = 0;
  for (const s of SCENES) {
    if (s.id === id) return f;
    f += beats(s.beats);
  }
  return f;
};

export const TOTAL_FRAMES = SCENES.reduce((acc, s) => acc + beats(s.beats), 0);
