import { sec } from "./theme";

/**
 * Timing table. Edit the `seconds` values to retime; `from` is derived.
 */
export type SceneId =
  | "hook"
  | "context"
  | "platform"
  | "simulator"
  | "bugToPr"
  | "matrix"
  | "outcome"
  | "end";

const order: { id: SceneId; seconds: number }[] = [
  { id: "hook", seconds: 3.5 },
  { id: "context", seconds: 6 },
  { id: "platform", seconds: 7 },
  { id: "simulator", seconds: 7.5 },
  { id: "bugToPr", seconds: 7.5 },
  { id: "matrix", seconds: 7 },
  { id: "outcome", seconds: 6 },
  { id: "end", seconds: 3.5 },
];

export type SceneTiming = { id: SceneId; from: number; duration: number };

export const scenes: SceneTiming[] = (() => {
  let cursor = 0;
  return order.map(({ id, seconds }) => {
    const duration = sec(seconds);
    const entry = { id, from: cursor, duration };
    cursor += duration;
    return entry;
  });
})();

export const TOTAL_FRAMES = scenes.reduce((n, s) => n + s.duration, 0);

export const timing = (id: SceneId): SceneTiming => {
  const s = scenes.find((x) => x.id === id);
  if (!s) throw new Error(`Unknown scene ${id}`);
  return s;
};
