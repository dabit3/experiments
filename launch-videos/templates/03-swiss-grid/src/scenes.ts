// Timing table. Durations are in frames at 30fps. Retime here; every scene reads
// its own length from `useVideoConfig().durationInFrames`.

export const FPS = 30;
export const WIDTH = 1920;
export const HEIGHT = 1080;

export type SceneId =
  | "hook"
  | "context"
  | "featureRun"
  | "featureWatch"
  | "featureFix"
  | "featureMatrix"
  | "outcome"
  | "endCard";

export type SceneSpec = {
  id: SceneId;
  /** Section number printed on the scene, e.g. "01". */
  number: string;
  durationInFrames: number;
};

const s = (seconds: number) => Math.round(seconds * FPS);

export const SCENES: SceneSpec[] = [
  { id: "hook", number: "01", durationInFrames: s(3.6) },
  { id: "context", number: "02", durationInFrames: s(5.4) },
  { id: "featureRun", number: "03", durationInFrames: s(6.4) },
  { id: "featureWatch", number: "04", durationInFrames: s(6.4) },
  { id: "featureFix", number: "05", durationInFrames: s(6.8) },
  { id: "featureMatrix", number: "06", durationInFrames: s(6.4) },
  { id: "outcome", number: "07", durationInFrames: s(5.6) },
  { id: "endCard", number: "08", durationInFrames: s(3.6) },
];

/** Frames the grid guides stay visible around each scene boundary. */
export const GUIDE_FRAMES = s(0.7);

export const sceneStart = (id: SceneId): number => {
  let acc = 0;
  for (const scene of SCENES) {
    if (scene.id === id) return acc;
    acc += scene.durationInFrames;
  }
  throw new Error(`Unknown scene ${id}`);
};

export const TOTAL_FRAMES = SCENES.reduce((n, sc) => n + sc.durationInFrames, 0);
