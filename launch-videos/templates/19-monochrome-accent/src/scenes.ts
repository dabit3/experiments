import { sec } from "./theme";

export type WipeDirection = "left" | "right" | "down" | "up";

export type SceneSpec = {
  id: "hook" | "context" | "chooseMac" | "simulator" | "fixAndShip" | "matrix" | "outcome" | "end";
  duration: number;
  /** How the scene wipes in over the previous one. */
  wipe: WipeDirection;
};

/** Frames the incoming scene's wipe takes to cover the frame. */
export const WIPE = 16;

export const scenes: SceneSpec[] = [
  { id: "hook", duration: sec(3.2), wipe: "right" },
  { id: "context", duration: sec(6.4), wipe: "right" },
  { id: "chooseMac", duration: sec(7.4), wipe: "down" },
  { id: "simulator", duration: sec(7.2), wipe: "right" },
  { id: "fixAndShip", duration: sec(7.2), wipe: "up" },
  { id: "matrix", duration: sec(7.2), wipe: "left" },
  { id: "outcome", duration: sec(6.0), wipe: "right" },
  { id: "end", duration: sec(4.0), wipe: "down" },
];

export type SceneTiming = SceneSpec & { from: number };

/** Scenes overlap by WIPE frames so the incoming wipe covers the outgoing scene. */
export const timeline: SceneTiming[] = scenes.reduce<SceneTiming[]>((acc, s, i) => {
  const from = i === 0 ? 0 : acc[i - 1].from + acc[i - 1].duration - WIPE;
  acc.push({ ...s, from });
  return acc;
}, []);

export const TOTAL_FRAMES = timeline[timeline.length - 1].from + timeline[timeline.length - 1].duration;
