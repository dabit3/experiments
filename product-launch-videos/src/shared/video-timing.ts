import {frames} from './timeline';

export type VideoTiming = {
  sourceStartSeconds: number;
  durationInFrames: number;
};

export const videoTrim = (
  timing: VideoTiming,
  fps: number,
  sourceDurationSeconds: number,
) => {
  const trimBefore = frames(timing.sourceStartSeconds, fps);
  if (!Number.isInteger(timing.durationInFrames) || timing.durationInFrames < 1) {
    throw new Error('Video duration must be a positive integer frame count');
  }
  const trimAfter = trimBefore + timing.durationInFrames;
  if (trimAfter > Math.floor(sourceDurationSeconds * fps + 0.001)) {
    throw new Error('Requested trim exceeds the actual source video; shorten the scene or change its trim');
  }
  return {trimBefore, trimAfter};
};
