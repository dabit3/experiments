import { secondsToFrames as f } from "./theme";

/**
 * Timing table. Every scene is a <Sequence> in Main.tsx; retime here.
 * `elapsed` is the agent's simulated wall-clock (seconds) shown on the top timeline
 * at the START of each scene. The readout interpolates linearly between scenes.
 */
export const scenes = {
  hook: { from: 0, duration: f(3.0) },
  context: { from: f(3.0), duration: f(6.0) },
  build: { from: f(9.0), duration: f(7.0), elapsed: 0 },
  drive: { from: f(16.0), duration: f(7.0), elapsed: 58 },
  fix: { from: f(23.0), duration: f(7.0), elapsed: 112 },
  qa: { from: f(30.0), duration: f(7.0), elapsed: 190 },
  outcome: { from: f(37.0), duration: f(6.0) },
  end: { from: f(43.0), duration: f(4.0) },
} as const;

/** Final elapsed value the timeline lands on (04:12). */
export const ELAPSED_END = 252;

export const TOTAL_FRAMES = scenes.end.from + scenes.end.duration;

/** Frames the persistent chrome (timeline + panels) is visible. */
export const chrome = {
  fadeIn: scenes.context.from,
  fadeOut: scenes.end.from,
  splitFadeOut: scenes.outcome.from,
};

/** Phase label shown at the right end of the timeline for each feature scene. */
export const phases: { from: number; label: string }[] = [
  { from: scenes.build.from, label: "Building" },
  { from: scenes.drive.from, label: "Testing" },
  { from: scenes.fix.from, label: "Fixing" },
  { from: scenes.qa.from, label: "QA" },
];
