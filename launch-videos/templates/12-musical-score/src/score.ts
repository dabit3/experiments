import { Easing, interpolate } from "remotion";
import type { Cue, Scene } from "./schema";

export type TimedScene = Scene & {
  from: number;
  span: { start: number; end: number };
};

export type PlayheadKeyframe = { frame: number; x: number };

export const easeOut = Easing.bezier(0.33, 1, 0.68, 1);
export const easeInOut = Easing.bezier(0.65, 0, 0.35, 1);

export const clamp = (v: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, v));

export const progress = (
  frame: number,
  from: number,
  duration: number,
  easing: (t: number) => number = easeOut,
) =>
  interpolate(frame, [from, from + duration], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing,
  });

/** Assigns absolute start frames and default (equal, sequential) score spans. */
export const buildTimeline = (scenes: Scene[]): TimedScene[] => {
  const stageCount = scenes.filter((s) => s.kind === "stage").length;
  let from = 0;
  let stageIndex = 0;
  return scenes.map((scene) => {
    const timed: TimedScene = {
      ...scene,
      from,
      span:
        scene.kind === "stage"
          ? (scene.span ?? {
              start: stageIndex / stageCount,
              end: (stageIndex + 1) / stageCount,
            })
          : { start: 0, end: 0 },
    };
    if (scene.kind === "stage") stageIndex += 1;
    from += scene.durationInFrames;
    return timed;
  });
};

export const totalDuration = (scenes: Scene[]) =>
  scenes.reduce((sum, s) => sum + s.durationInFrames, 0);

/** Horizontal position (0-1) of a cue on its stage's bar, spaced evenly by order. */
export const cueX = (stage: TimedScene, index: number) => {
  const cues = stage.cues ?? [];
  const t = (index + 1) / (cues.length + 1);
  return stage.span.start + (stage.span.end - stage.span.start) * t;
};

/** The playhead steps: to a stage's bar start when it arrives, then to each cue as it lands. */
export const playheadKeyframes = (timeline: TimedScene[]): PlayheadKeyframe[] => {
  const keys: PlayheadKeyframe[] = [{ frame: 0, x: 0 }];
  let last: TimedScene | undefined;
  for (const scene of timeline) {
    if (scene.kind === "stage") {
      keys.push({ frame: scene.from, x: scene.span.start });
      (scene.cues ?? []).forEach((cue, i) => {
        keys.push({ frame: scene.from + cue.at, x: cueX(scene, i) });
      });
      last = scene;
    } else if (scene.kind === "outro" && last) {
      keys.push({ frame: scene.from, x: last.span.end });
    }
  }
  return keys.sort((a, b) => a.frame - b.frame);
};

export const playheadX = (frame: number, keys: PlayheadKeyframe[], easeFrames: number) => {
  let x = keys[0]?.x ?? 0;
  for (let i = 1; i < keys.length; i++) {
    const k = keys[i]!;
    if (frame < k.frame) break;
    const prev = x;
    x = prev + (k.x - prev) * progress(frame, k.frame, easeFrames, easeInOut);
  }
  return x;
};

/** Index of the caption / media slot in force at `local` frames into a stage. */
export const activeCueIndex = (cues: Cue[] | undefined, local: number) => {
  if (!cues) return -1;
  let idx = -1;
  cues.forEach((c, i) => {
    if (local >= c.at) idx = i;
  });
  return idx;
};

export const resolveAt = <K extends "mediaSlot" | "captionIndex">(
  stage: Scene,
  key: K,
  local: number,
): Scene[K] => {
  let value = stage[key];
  (stage.cues ?? []).forEach((c) => {
    if (local >= c.at && c[key] !== undefined) value = c[key] as Scene[K];
  });
  return value;
};
