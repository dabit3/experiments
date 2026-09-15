import { Easing, interpolate } from "remotion";
import type { Rect, Scene, ScenePanel, Storyboard } from "./schema";

export const easeOut = Easing.out(Easing.cubic);
export const easeInOut = Easing.inOut(Easing.cubic);

export const sceneStarts = (scenes: Scene[]): number[] => {
  const starts: number[] = [];
  let acc = 0;
  for (const s of scenes) {
    starts.push(acc);
    acc += s.durationInFrames;
  }
  return starts;
};

export const totalDuration = (scenes: Scene[]) =>
  scenes.reduce((sum, s) => sum + s.durationInFrames, 0);

export const sceneAt = (scenes: Scene[], starts: number[], frame: number) => {
  let i = 0;
  for (let k = 0; k < scenes.length; k++) {
    if (frame >= starts[k]) i = k;
  }
  return { index: i, scene: scenes[i], local: frame - starts[i] };
};

/** A contiguous run of scenes in which a panel (slot) is on the page. */
export type PanelRun = {
  slot: string;
  /** Panel number in reading order (1-based, by first appearance). */
  number: number;
  fromScene: number;
  toScene: number;
  /** Absolute frame the panel mounts (start of reveal). */
  mountFrame: number;
  /** Absolute frame the panel unmounts (after exit fade). */
  unmountFrame: number;
};

export const panelRuns = (scenes: Scene[], sb: Storyboard): PanelRun[] => {
  const starts = sceneStarts(scenes);
  const total = totalDuration(scenes);
  const runs: PanelRun[] = [];
  const numbers = new Map<string, number>();
  const open = new Map<string, PanelRun>();

  scenes.forEach((scene, i) => {
    const present = new Set(scene.panels.map((p) => p.slot));
    for (const p of scene.panels) {
      if (!open.has(p.slot)) {
        if (!numbers.has(p.slot)) numbers.set(p.slot, numbers.size + 1);
        const run: PanelRun = {
          slot: p.slot,
          number: numbers.get(p.slot) as number,
          fromScene: i,
          toScene: i,
          mountFrame: starts[i] + (p.revealDelay ?? 0),
          unmountFrame: total,
        };
        open.set(p.slot, run);
        runs.push(run);
      } else {
        (open.get(p.slot) as PanelRun).toScene = i;
      }
    }
    for (const [slot, run] of Array.from(open.entries())) {
      if (!present.has(slot)) {
        run.unmountFrame = Math.min(total, starts[i] + sb.exitFrames);
        open.delete(slot);
      }
    }
  });
  return runs;
};

const lerp = (a: number, b: number, t: number) => a + (b - a) * t;
export const lerpRect = (a: Rect, b: Rect, t: number): Rect => ({
  x: lerp(a.x, b.x, t),
  y: lerp(a.y, b.y, t),
  w: lerp(a.w, b.w, t),
  h: lerp(a.h, b.h, t),
});

export type PanelState = {
  rect: Rect;
  /** 0..1 dim level between context and active. */
  activeness: number;
  /** 0..1 boundary reveal progress (1 = fully open). */
  reveal: number;
  /** 0..1 exit fade (1 = fully visible). */
  presence: number;
  role: ScenePanel["role"];
};

const findPanel = (scene: Scene | undefined, slot: string) =>
  scene?.panels.find((p) => p.slot === slot);

/**
 * Where a panel is at an absolute frame within a run: moving between the
 * previous and current scene's rects, revealing, holding, or fading out.
 */
export const panelStateAt = (
  scenes: Scene[],
  starts: number[],
  run: PanelRun,
  frame: number,
  sb: Storyboard,
): PanelState | null => {
  const { index, scene, local } = sceneAt(scenes, starts, frame);
  const here = findPanel(scene, run.slot);
  const prevScene = index > 0 ? scenes[index - 1] : undefined;
  const before =
    index - 1 >= run.fromScene ? findPanel(prevScene, run.slot) : undefined;

  if (here && index >= run.fromScene && index <= run.toScene) {
    const roleValue = here.role === "active" ? 1 : 0;
    if (before) {
      const t = interpolate(local, [0, sb.moveFrames], [0, 1], {
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
        easing: easeInOut,
      });
      const prevRole = before.role === "active" ? 1 : 0;
      return {
        rect: lerpRect(before.rect, here.rect, t),
        activeness: lerp(prevRole, roleValue, t),
        reveal: 1,
        presence: 1,
        role: here.role,
      };
    }
    const delay = here.revealDelay ?? 0;
    const reveal = interpolate(
      local,
      [delay, delay + sb.revealFrames],
      [0, 1],
      {
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
        easing: easeOut,
      },
    );
    return {
      rect: here.rect,
      activeness: roleValue,
      reveal,
      presence: 1,
      role: here.role,
    };
  }

  if (before && index === run.toScene + 1) {
    const presence = interpolate(local, [0, sb.exitFrames], [1, 0], {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
    });
    return {
      rect: before.rect,
      activeness: before.role === "active" ? 1 : 0,
      reveal: 1,
      presence,
      role: before.role,
    };
  }
  return null;
};

/** Frame-local progress helper for fades: 0..1 over `frames` starting at `from`. */
export const fadeIn = (local: number, from: number, frames: number) =>
  interpolate(local, [from, from + frames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
