import { sec } from "./tokens";

/**
 * Mesh "moods": which colour dominates the background gradient.
 * The mesh cross-fades between moods at scene boundaries.
 */
export type Mood = "blue" | "indigo" | "green" | "cream" | "neutral";

export type SceneId =
  | "hook"
  | "context"
  | "featureRun"
  | "featureLive"
  | "featureFix"
  | "featureMatrix"
  | "outcome"
  | "endCard";

export type SceneDef = {
  id: SceneId;
  durationInFrames: number;
  mood: Mood;
};

/** Scene timing table — edit durations here to retime the whole film. */
export const scenes: SceneDef[] = [
  { id: "hook", durationInFrames: sec(3.6), mood: "blue" },
  { id: "context", durationInFrames: sec(6.2), mood: "neutral" },
  { id: "featureRun", durationInFrames: sec(7.2), mood: "blue" },
  { id: "featureLive", durationInFrames: sec(7.2), mood: "indigo" },
  { id: "featureFix", durationInFrames: sec(7.2), mood: "green" },
  { id: "featureMatrix", durationInFrames: sec(7.2), mood: "cream" },
  { id: "outcome", durationInFrames: sec(5.6), mood: "indigo" },
  { id: "endCard", durationInFrames: sec(4.0), mood: "blue" },
];

/** Frames each scene spends fading out (ease-in) before the next one fades in over the mesh. */
export const TRANSITION = sec(0.35);

export type SceneTiming = SceneDef & { from: number };

export const timeline: SceneTiming[] = (() => {
  let cursor = 0;
  return scenes.map((s) => {
    const from = cursor;
    cursor += s.durationInFrames;
    return { ...s, from };
  });
})();

const last = timeline[timeline.length - 1];
export const TOTAL_FRAMES = last.from + last.durationInFrames;

export const sceneAt = (id: SceneId): SceneTiming => {
  const s = timeline.find((t) => t.id === id);
  if (!s) throw new Error(`Unknown scene ${id}`);
  return s;
};
