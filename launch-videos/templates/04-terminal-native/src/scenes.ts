export const FPS = 30;
const sec = (s: number) => Math.round(s * FPS);

/** Scene order and durations. Edit the seconds here to retime the whole video. */
const durations = {
  hook: sec(4),
  context: sec(5.5),
  buildRun: sec(7),
  liveSimulator: sec(7),
  fixShip: sec(7),
  everyScreen: sec(7),
  outcome: sec(6),
  endCard: sec(3.5),
} as const;

export type SceneId = keyof typeof durations;

let cursor = 0;
export const scenes = (Object.keys(durations) as SceneId[]).reduce(
  (acc, id) => {
    acc[id] = { from: cursor, duration: durations[id] };
    cursor += durations[id];
    return acc;
  },
  {} as Record<SceneId, { from: number; duration: number }>,
);

export const TOTAL_FRAMES = cursor;

/** Characters per second for typed commands. */
export const TYPING_CPS = 32;
export const typeFrames = (text: string, cps = TYPING_CPS) => Math.ceil((text.length / cps) * FPS);
