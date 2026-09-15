import { ms } from "./tokens";

/**
 * Timing table. Durations are in milliseconds and converted to frames once,
 * so the whole film can be retimed from this file alone.
 * Scenes are butted together and each fades through paper (out 500ms, in 800ms)
 * so text from two scenes never shares the frame.
 */
export const overlapMs = 0;

export type SceneId =
  | "hook"
  | "context"
  | "feature-build"
  | "feature-simulator"
  | "feature-fix"
  | "feature-matrix"
  | "outcome"
  | "end";

const table: { id: SceneId; durationMs: number }[] = [
  { id: "hook", durationMs: 3600 },
  { id: "context", durationMs: 6000 },
  { id: "feature-build", durationMs: 7600 },
  { id: "feature-simulator", durationMs: 6400 },
  { id: "feature-fix", durationMs: 6800 },
  { id: "feature-matrix", durationMs: 6400 },
  { id: "outcome", durationMs: 5800 },
  { id: "end", durationMs: 4000 },
];

export type SceneTiming = {
  id: SceneId;
  from: number;
  durationInFrames: number;
};

export const scenes: SceneTiming[] = (() => {
  const overlap = ms(overlapMs);
  let cursor = 0;
  return table.map(({ id, durationMs }, i) => {
    const durationInFrames = ms(durationMs);
    const from = cursor;
    cursor += durationInFrames - (i === table.length - 1 ? 0 : overlap);
    return { id, from, durationInFrames };
  });
})();

export const totalDurationInFrames =
  scenes[scenes.length - 1].from + scenes[scenes.length - 1].durationInFrames;

export const timing = (id: SceneId): SceneTiming => {
  const found = scenes.find((s) => s.id === id);
  if (!found) throw new Error(`Unknown scene ${id}`);
  return found;
};
