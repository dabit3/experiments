/**
 * Timing table. Durations are in frames at 30fps.
 * Change a duration here and every <Sequence> in Main.tsx retimes.
 */
export const FPS = 30;

export const scenes = {
  hook: 105, //   3.5s  "3 platforms → Devin now runs on Mac."
  problem: 180, // 6.0s  20:00 CI timer, then "0 agents"
  build: 195, //  6.5s  Feature 1: pick macOS, build + run
  live: 195, //   6.5s  Feature 2: live Simulator timecode
  tests: 210, //  7.0s  Feature 3: 12 / 3 / 2 test results, PR
  screens: 195, // 6.5s  Feature 4: 6 screens, iPhone + iPad, dark
  outcome: 180, // 6.0s  Metrics: minutes vs 20+, 0%, 1, 3
  end: 105, //    3.5s  Logo end card
} as const;

export type SceneKey = keyof typeof scenes;

const order: SceneKey[] = [
  "hook",
  "problem",
  "build",
  "live",
  "tests",
  "screens",
  "outcome",
  "end",
];

export const sceneStarts: Record<SceneKey, number> = order.reduce(
  (acc, key, i) => {
    acc[key] = i === 0 ? 0 : acc[order[i - 1]] + scenes[order[i - 1]];
    return acc;
  },
  {} as Record<SceneKey, number>,
);

export const totalFrames = order.reduce((n, k) => n + scenes[k], 0);
export const sceneOrder = order;
