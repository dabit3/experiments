import type {LaunchProps, MediaSlot, Scene} from './schema';

export const CANVAS_W = 1920;
export const CANVAS_H = 1080;

export type Rect = {x: number; y: number; w: number; h: number};

export type SceneGeometry = {
  /** Media rectangles at rest. Index 0 is the product frame. */
  frames: Rect[];
  /** Flat caption plane (demo scenes). */
  plane: Rect | null;
  /** Free text column (outro) or caption line (result). */
  text: Rect | null;
};

export const mediaAspect = (slot: MediaSlot): number => {
  const crop = slot.crop ?? {x: 0, y: 0, w: 1, h: 1};
  return (crop.w * slot.width) / (crop.h * slot.height);
};

export const fitAspect = (aspect: number, maxW: number, maxH: number) => {
  const w = Math.min(maxW, maxH * aspect);
  return {w, h: w / aspect};
};

export const lerpRect = (a: Rect, b: Rect, t: number): Rect => ({
  x: a.x + (b.x - a.x) * t,
  y: a.y + (b.y - a.y) * t,
  w: a.w + (b.w - a.w) * t,
  h: a.h + (b.h - a.h) * t,
});

export type Safe = {
  left: number;
  right: number;
  top: number;
  bottom: number;
  w: number;
  h: number;
};

export const safeArea = (props: LaunchProps): Safe => {
  const {margin} = props.layout;
  const top = margin + 48;
  const bottom = props.shapes.rule.y - 88;
  return {
    left: margin,
    right: CANVAS_W - margin,
    top,
    bottom,
    w: CANVAS_W - margin * 2,
    h: bottom - top,
  };
};

const slotOf = (props: LaunchProps, name: string): MediaSlot => {
  const slot = props.media[name];
  if (!slot) {
    throw new Error(`Unknown media slot "${name}"`);
  }
  return slot;
};

/** The abstract opening plane: a tall rectangle on the right, headline on the left. */
const openGeometry = (safe: Safe): SceneGeometry => {
  const w = Math.round(safe.w * 0.3);
  return {
    frames: [{x: safe.right - w, y: safe.top, w, h: safe.h}],
    plane: null,
    text: {x: safe.left, y: safe.top, w: safe.w - w - 96, h: safe.h},
  };
};

export const sceneGeometry = (scene: Scene, props: LaunchProps): SceneGeometry => {
  const safe = safeArea(props);
  const {gutter, defaultSplit, maxPlaneWidth} = props.layout;

  switch (scene.type) {
    case 'open':
      return openGeometry(safe);

    case 'demo': {
      const split = scene.split ?? defaultSplit;
      const areaW = safe.w * split;
      const planeW = Math.min(maxPlaneWidth, safe.w - areaW - gutter);

      if (scene.composition === 'tiles') {
        const slots = scene.media.map((m) => slotOf(props, m));
        const aspects = slots.map(mediaAspect);
        const sum = aspects.reduce((a, b) => a + b, 0);
        const h = Math.min(safe.h, (areaW - gutter * (slots.length - 1)) / sum);
        const frames: Rect[] = [];
        let x = safe.right;
        for (let i = slots.length - 1; i >= 0; i--) {
          const w = h * aspects[i];
          x -= w;
          frames.unshift({x, y: safe.top, w, h});
          x -= gutter;
        }
        return {
          frames,
          plane: {x: safe.left, y: safe.top, w: planeW, h},
          text: null,
        };
      }

      const fitted = fitAspect(mediaAspect(slotOf(props, scene.media[0])), areaW, safe.h);
      if (scene.composition === 'media-left') {
        const frame = {x: safe.left, y: safe.top, ...fitted};
        return {
          frames: [frame],
          plane: {x: safe.right - planeW, y: safe.top, w: planeW, h: fitted.h},
          text: null,
        };
      }
      if (scene.composition === 'media-wide') {
        const wide = fitAspect(mediaAspect(slotOf(props, scene.media[0])), safe.w, safe.h - 72);
        const frame = {x: safe.left, y: safe.top, ...wide};
        return {
          frames: [frame],
          plane: null,
          text: {x: frame.x, y: frame.y + frame.h + gutter, w: frame.w, h: 48},
        };
      }
      // media-right (default)
      const frame = {x: safe.right - fitted.w, y: safe.top, ...fitted};
      return {
        frames: [frame],
        plane: {x: safe.left, y: safe.top, w: planeW, h: fitted.h},
        text: null,
      };
    }

    case 'result': {
      const fitted = fitAspect(mediaAspect(slotOf(props, scene.media)), safe.w, safe.h - 72);
      const frame = {x: safe.left, y: safe.top, ...fitted};
      return {
        frames: [frame],
        plane: null,
        text: {x: frame.x, y: frame.y + frame.h + gutter, w: frame.w, h: 48},
      };
    }

    case 'outro': {
      const colW = safe.w * 0.54;
      const fitted = fitAspect(mediaAspect(slotOf(props, scene.media)), colW, safe.h);
      const y = safe.top + Math.round((safe.h - fitted.h) / 2);
      const frame = {x: safe.left, y, ...fitted};
      return {
        frames: [frame],
        plane: null,
        text: {x: safe.left + colW + gutter * 2, y, w: safe.w - colW - gutter * 2, h: fitted.h},
      };
    }
  }
};

export type SceneSpan = {scene: Scene; index: number; start: number; end: number};

export const buildTimeline = (scenes: Scene[]): SceneSpan[] => {
  let start = 0;
  return scenes.map((scene, index) => {
    const span = {scene, index, start, end: start + scene.durationInFrames};
    start += scene.durationInFrames;
    return span;
  });
};

export const totalDuration = (scenes: Scene[]) =>
  scenes.reduce((sum, s) => sum + s.durationInFrames, 0);

export const primaryMediaName = (scene: Scene): string | null => {
  switch (scene.type) {
    case 'open':
      return null;
    case 'demo':
      return scene.media[0];
    case 'result':
    case 'outro':
      return scene.media;
  }
};

export const sceneStage = (scene: Scene, fallback: number): number => {
  switch (scene.type) {
    case 'open':
      return -1;
    case 'demo':
    case 'result':
      return scene.stage;
    case 'outro':
      return fallback;
  }
};
