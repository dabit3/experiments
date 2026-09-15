export const sceneIds = ['opening', 'environment', 'agent', 'iphone', 'webQa', 'ipad', 'closing'] as const;
export type SceneId = (typeof sceneIds)[number];
export type SceneDurations = Record<SceneId, number>;
export type SceneTiming = {id: SceneId; from: number; durationInFrames: number};

export const sampleDurations: SceneDurations = {
  opening: 4, environment: 5, agent: 4, iphone: 9, webQa: 7, ipad: 6, closing: 5,
};

export const sampleCopy = {
  featureName: 'Devin on Mac',
  opening: 'Devin now runs on Mac.',
  benefit: 'Build, run, and test iOS apps in the cloud.',
  environment: 'Choose a hosted Mac environment.',
  agent: 'Choose your agent.',
  iphone: 'See your app in the iPhone Simulator.',
  webQa: 'Review recorded test steps and results.',
  ipad: 'Check iPhone and iPad layouts.',
  closing: 'Same pricing as Linux cloud sessions.',
  cta: 'Start a Mac session with Devin.',
  url: 'https://app.devin.ai',
};
export type LaunchCopy = typeof sampleCopy;

export const frames = (seconds: number, fps: number): number => {
  if (!Number.isFinite(seconds) || seconds < 0 || !Number.isFinite(fps) || fps <= 0) {
    throw new Error('Seconds must be nonnegative and fps must be positive');
  }
  return Math.round(seconds * fps);
};

export const makeTimeline = (durations: SceneDurations, fps = 30): SceneTiming[] => {
  let from = 0;
  return sceneIds.map((id) => {
    const durationInFrames = frames(durations[id], fps);
    if (durationInFrames < 1) throw new Error(`${id} must last at least one frame`);
    const scene = {id, from, durationInFrames};
    from += durationInFrames;
    return scene;
  });
};

export const timelineDuration = (durations: SceneDurations, fps = 30): number =>
  makeTimeline(durations, fps).reduce((sum, scene) => sum + scene.durationInFrames, 0);
