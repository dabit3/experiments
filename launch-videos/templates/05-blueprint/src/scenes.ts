/**
 * Timing table. Edit `seconds` to retime; frame offsets are derived.
 * Scenes overlap by TRANSITION frames (cross-dissolve).
 */
import { FPS } from "./theme";

export const TRANSITION = 12;

const table = [
  { id: "hook", seconds: 3.4, sheet: "01", title: "DEVIN ON MACOS" },
  { id: "context", seconds: 6.0, sheet: "02", title: "PRIOR ART — MANUAL QA" },
  { id: "build", seconds: 7.6, sheet: "03", title: "FIG. 03 — BUILD & RUN" },
  { id: "simulator", seconds: 7.8, sheet: "04", title: "FIG. 04 — LIVE SIMULATOR" },
  { id: "fix", seconds: 7.4, sheet: "05", title: "FIG. 05 — REPRO · FIX · PR" },
  { id: "matrix", seconds: 7.4, sheet: "06", title: "FIG. 06 — DEVICE MATRIX" },
  { id: "outcome", seconds: 6.0, sheet: "07", title: "SPECIFICATIONS" },
  { id: "end", seconds: 3.8, sheet: "08", title: "DEVIN.AI" },
] as const;

export type SceneId = (typeof table)[number]["id"];

export type SceneTiming = {
  id: SceneId;
  from: number;
  duration: number;
  sheet: string;
  title: string;
};

let cursor = 0;
export const SCENES: SceneTiming[] = table.map((s, i) => {
  const duration = Math.round(s.seconds * FPS) + (i < table.length - 1 ? TRANSITION : 0);
  const from = cursor;
  cursor += Math.round(s.seconds * FPS);
  return { id: s.id, from, duration, sheet: s.sheet, title: s.title };
});

export const SHEET_COUNT = table.length;
export const TOTAL_FRAMES = cursor;
export const scene = (id: SceneId): SceneTiming => {
  const s = SCENES.find((x) => x.id === id);
  if (!s) throw new Error(`unknown scene ${id}`);
  return s;
};
