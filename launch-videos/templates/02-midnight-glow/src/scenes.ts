import { sec } from "./tokens";

/**
 * Timing table. Durations in seconds; `overlap` is how many seconds the scene
 * begins before the previous one ends (0 = dip through the dark background,
 * which keeps headlines from ever overlapping). Retime here only.
 */
export const SCENES = [
  { id: "hook", duration: 3.6, overlap: 0 },
  { id: "context", duration: 6.2, overlap: 0 },
  { id: "feature-macos", duration: 7.2, overlap: 0 },
  { id: "feature-simulator", duration: 7.6, overlap: 0 },
  { id: "feature-fix-pr", duration: 7.0, overlap: 0 },
  { id: "feature-matrix", duration: 7.4, overlap: 0 },
  { id: "outcome", duration: 6.0, overlap: 0 },
  { id: "end", duration: 4.0, overlap: 0 },
] as const;

export type SceneId = (typeof SCENES)[number]["id"];

export type SceneTiming = { id: SceneId; from: number; durationInFrames: number };

export const timings: SceneTiming[] = (() => {
  let cursor = 0;
  return SCENES.map((s) => {
    const from = Math.max(0, cursor - sec(s.overlap));
    const durationInFrames = sec(s.duration);
    cursor = from + durationInFrames;
    return { id: s.id, from, durationInFrames };
  });
})();

export const TOTAL_FRAMES = timings[timings.length - 1].from + timings[timings.length - 1].durationInFrames;
