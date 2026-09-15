import {makeTimeline, type ImageSelection, type VideoSelection} from '../../shared';
import type {CinemaConfig} from './config';

type ShotBase = {
  index: number;
  from: number;
  durationInFrames: number;
  caption: string;
};
export type Shot = ShotBase & (
  {kind: 'still'; media: ImageSelection} |
  {kind: 'video'; media: VideoSelection; indexFrame: number; freezeFrame: number}
);
export type IndexTransition = {
  from: number;
  duration: number;
  outgoing: Shot;
  incoming: Shot;
};

export const createEdit = (config: CinemaConfig, fps: number) => {
  const scenes = makeTimeline(config.durations, fps);
  const [opening, environment, agent, iphone, webQa, ipad, closing] = scenes;
  if (iphone.durationInFrames < 2) throw new Error('The two iPhone stills need at least two frames');
  if (config.motion.iphoneSplit <= 0 || config.motion.iphoneSplit >= 1) {
    throw new Error('motion.iphoneSplit must be between 0 and 1');
  }
  const split = Math.max(1, Math.min(iphone.durationInFrames - 1,
    Math.round(iphone.durationInFrames * config.motion.iphoneSplit)));
  const shots: Shot[] = [
    {...environment, index: 0, kind: 'still', media: config.media.environment, caption: config.copy.environment},
    {...agent, index: 1, kind: 'video', media: config.media.agent, caption: config.copy.agent,
      indexFrame: config.archive.agentIndexFrame, freezeFrame: config.archive.agentFreezeFrame},
    {...iphone, durationInFrames: split, index: 2, kind: 'still', media: config.media.iphone[0], caption: config.copy.iphone},
    {...iphone, from: iphone.from + split, durationInFrames: iphone.durationInFrames - split,
      index: 3, kind: 'still', media: config.media.iphone[1], caption: config.copy.iphone},
    {...webQa, index: 4, kind: 'video', media: config.media.webQa, caption: config.copy.webQa,
      indexFrame: config.archive.webQaIndexFrame, freezeFrame: config.archive.webQaFreezeFrame},
    {...ipad, index: 5, kind: 'still', media: config.media.ipad, caption: config.copy.ipad},
  ];
  for (const shot of shots) {
    if (shot.kind !== 'video') continue;
    for (const frame of [shot.indexFrame, shot.freezeFrame]) {
      if (!Number.isInteger(frame) || frame < -1 || frame >= shot.durationInFrames) {
        throw new Error(`Archive frame for shot ${shot.index + 1} is outside its selected clip`);
      }
    }
  }
  const requested = config.motion.returnFrames + config.motion.indexHoldFrames + config.motion.expandFrames;
  if ([config.motion.returnFrames, config.motion.indexHoldFrames,
    config.motion.expandFrames, config.motion.openingExpandFrames].some((value) => !Number.isFinite(value) || value < 0)) {
    throw new Error('Transition frame counts must be finite and nonnegative');
  }
  const transitions: IndexTransition[] = shots.slice(1).map((incoming, index) => {
    const outgoing = shots[index];
    const afterCut = outgoing.kind === 'video';
    const duration = Math.min(requested, Math.floor(
      (afterCut ? incoming.durationInFrames : outgoing.durationInFrames) * 0.3,
    ));
    return {
      from: afterCut ? incoming.from : incoming.from - duration,
      duration, outgoing, incoming,
    };
  });
  return {opening, closing, shots, transitions, requested};
};

export const frozenFrame = (shot: Extract<Shot, {kind: 'video'}>, completed: boolean) => {
  const selected = completed ? shot.freezeFrame : shot.indexFrame;
  return selected === -1 ? shot.durationInFrames - 1 : selected;
};
