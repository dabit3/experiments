import { FPS } from "./tokens";

const s = (seconds: number) => Math.round(seconds * FPS);

/**
 * Timing table. Durations are in seconds; `from` is derived, so a scene can be
 * retimed by editing one number. Scenes are hard cuts that hand off identical
 * window state (see HANDOFF in ./handoff.ts), so the recording feels continuous.
 */
const table = [
  { id: "hook", seconds: 3.4 },
  { id: "context", seconds: 5.2 },
  { id: "choosePlatform", seconds: 7.2 },
  { id: "prompt", seconds: 7.0 },
  { id: "simulator", seconds: 8.0 },
  { id: "pullRequest", seconds: 6.6 },
  { id: "outcome", seconds: 6.4 },
  { id: "endCard", seconds: 3.8 },
] as const;

export type SceneId = (typeof table)[number]["id"];
export type Scene = { id: SceneId; from: number; duration: number };

let cursor = 0;
export const scenes = Object.fromEntries(
  table.map((row) => {
    const from = cursor;
    const duration = s(row.seconds);
    cursor += duration;
    return [row.id, { id: row.id, from, duration }];
  }),
) as Record<SceneId, Scene>;

export const TOTAL_FRAMES = cursor;
