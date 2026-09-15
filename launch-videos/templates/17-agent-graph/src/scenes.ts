export const FPS = 30;
export const WIDTH = 1920;
export const HEIGHT = 1080;

const sec = (s: number) => Math.round(s * FPS);

/** Scene order and durations (seconds). Edit here to retime the whole video. */
const ORDER = [
  ["hook", 3.5],
  ["context", 5.5],
  ["plan", 4.0],
  ["build", 6.5], // Clone repo → Build in Xcode
  ["simulator", 7.0], // Boot Simulator → Reproduce bug
  ["fix", 6.0], // Fix → Run UI tests
  ["pr", 5.5], // Open PR
  ["outcome", 5.5],
  ["end", 3.5],
] as const;

export type SceneId = (typeof ORDER)[number][0];
export type Scene = { from: number; dur: number; to: number };

export const SCENES = (() => {
  let cursor = 0;
  const out = {} as Record<SceneId, Scene>;
  for (const [id, seconds] of ORDER) {
    const dur = sec(seconds);
    out[id] = { from: cursor, dur, to: cursor + dur };
    cursor += dur;
  }
  return out;
})();

export const TOTAL_FRAMES = Object.values(SCENES).reduce((n, s) => n + s.dur, 0);

/** The agent's plan. Node order == execution order. */
export const STEPS = [
  { id: "clone", label: "Clone repo" },
  { id: "build", label: "Build in Xcode" },
  { id: "boot", label: "Boot Simulator" },
  { id: "repro", label: "Reproduce bug" },
  { id: "fix", label: "Fix" },
  { id: "test", label: "Run UI tests" },
  { id: "pr", label: "Open PR" },
] as const;

export type StepIndex = 0 | 1 | 2 | 3 | 4 | 5 | 6;

/** Frame at which each step becomes the active node. */
export const STEP_ACTIVATION: Record<StepIndex, number> = {
  0: SCENES.build.from + sec(0.5),
  1: SCENES.build.from + sec(3.4),
  2: SCENES.simulator.from + sec(0.5),
  3: SCENES.simulator.from + sec(3.6),
  4: SCENES.fix.from + sec(0.5),
  5: SCENES.fix.from + sec(3.1),
  6: SCENES.pr.from + sec(0.5),
};

/** Frame at which the last step completes (all nodes lit). */
export const ALL_DONE = SCENES.outcome.from;
