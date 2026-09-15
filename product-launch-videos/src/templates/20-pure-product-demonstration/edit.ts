import {assets, makeTimeline, type Framing} from '../../shared';
import type {PureProductConfig} from './config';

export const iphoneSplit = (durationInFrames: number, fraction: number) => {
  if (durationInFrames < 2 || !Number.isFinite(fraction) || fraction <= 0 || fraction >= 1) {
    throw new Error('The iPhone scene needs two frames and a split strictly between 0 and 1.');
  }
  return Math.max(1, Math.min(durationInFrames - 1, Math.round(durationInFrames * fraction)));
};

export const environmentFraming = (
  config: PureProductConfig, frame: number, durationInFrames: number, fps: number,
): Framing => {
  const {framing, asset} = config.media.environment;
  const source = assets[asset];
  const crop = framing.crop ?? {x: 0, y: 0, width: source.width, height: source.height};
  const {environmentZoom: zoom, environmentAnchorX: x, environmentAnchorY: y,
    environmentContextSeconds: context, environmentMoveSeconds: move} = config.motion;
  if (!Number.isFinite(zoom) || zoom < 1 || zoom > 2 ||
    [x, y].some((n) => !Number.isFinite(n) || n < 0 || n > 1) ||
    [context, move].some((n) => !Number.isFinite(n) || n < 0)) {
    throw new Error('Environment framing needs zoom 1–2, anchors 0–1, and nonnegative times.');
  }
  const start = Math.min(context * fps, durationInFrames * 0.25);
  const travel = Math.min(move * fps, durationInFrames * 0.25);
  const progress = travel === 0 ? Number(frame >= start) :
    Math.max(0, Math.min(1, (frame - start) / travel));
  const eased = progress * progress * (3 - 2 * progress);
  const scale = 1 + (zoom - 1) * eased;
  const width = crop.width / scale;
  const height = crop.height / scale;
  return {
    ...framing,
    crop: {
      x: crop.x + (crop.width - width) * x,
      y: crop.y + (crop.height - height) * y,
      width,
      height,
    },
  };
};

export const editTimeline = (config: PureProductConfig, fps: number) => {
  const timeline = makeTimeline(config.durations, fps);
  const iphone = timeline.find((scene) => scene.id === 'iphone');
  if (!iphone) throw new Error('The launch edit requires an iPhone scene.');
  iphoneSplit(iphone.durationInFrames, config.motion.iphoneFirstFraction);
  return timeline;
};
