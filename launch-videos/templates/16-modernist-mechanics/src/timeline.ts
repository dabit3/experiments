import type {LaunchProps} from './schema';
import {
  buildTimeline,
  lerpRect,
  primaryMediaName,
  sceneGeometry,
  sceneStage,
  type Rect,
  type SceneGeometry,
  type SceneSpan,
} from './geometry';
import {easeInOut} from './motion';

export type FrameState = {
  spans: SceneSpan[];
  geos: SceneGeometry[];
  /** Index of the scene that owns this frame. */
  index: number;
  /** Product frame rectangle at this frame (moves across scene boundaries). */
  rect: Rect;
  /** Continuous stage progress for the rail (-1 = before the first stage). */
  progress: number;
  /** Shutter plane offset as a fraction of the frame width: -1 off-left, 0 covering, 1 off-right; null = idle. */
  shutter: number | null;
  /** Frames since the frame settled in this scene (negative while still moving in). */
  settled: number;
  half: number;
};

export const frameState = (props: LaunchProps, frame: number): FrameState => {
  const spans = buildTimeline(props.scenes);
  const geos = props.scenes.map((s) => sceneGeometry(s, props));
  const T = props.motion.transitionFrames;
  const half = T / 2;

  let index = spans.findIndex((s) => frame >= s.start && frame < s.end);
  if (index < 0) {
    index = spans.length - 1;
  }
  const span = spans[index];

  let rect = geos[index].frames[0];
  let progress = stageAt(props, index);
  let shutter: number | null = null;

  const boundary = (from: number, to: number, B: number) => {
    const t = easeInOut(frame, B - half, T);
    rect = lerpRect(geos[from].frames[0], geos[to].frames[0], t);
    progress = stageAt(props, from) + (stageAt(props, to) - stageAt(props, from)) * t;
    const sameMedia =
      primaryMediaName(props.scenes[from]) !== null &&
      primaryMediaName(props.scenes[from]) === primaryMediaName(props.scenes[to]);
    shutter = sameMedia ? null : -1 + 2 * t;
  };

  if (index > 0 && frame < span.start + half) {
    boundary(index - 1, index, span.start);
  } else if (index < spans.length - 1 && frame >= span.end - half) {
    boundary(index, index + 1, span.end);
  }

  const settled = index === 0 ? frame : frame - (span.start + half);

  return {spans, geos, index, rect, progress, shutter, settled, half};
};

const stageAt = (props: LaunchProps, index: number): number => {
  let fallback = -1;
  for (let i = 0; i <= index; i++) {
    const s = sceneStage(props.scenes[i], fallback);
    if (props.scenes[i].type !== 'outro') {
      fallback = s;
    }
  }
  return sceneStage(props.scenes[index], fallback);
};
