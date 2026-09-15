import { z } from "zod";
import { zColor } from "@remotion/zod-types";

export const brandSchema = z.object({
  paper: zColor(),
  surface: zColor(),
  line: zColor(),
  ink: zColor(),
  inkMuted: zColor(),
  inkSubtle: zColor(),
  accent: zColor(),
  white: zColor(),
  fontFamily: z.string(),
  monoFontFamily: z.string(),
  logoLight: z.string(),
  logoDark: z.string(),
});

export const contentSchema = z.object({
  featureName: z.string(),
  eyebrow: z.string(),
  headline: z.string(),
  /** Word(s) inside `headline` set in the accent color. Empty = none. */
  headlineAccent: z.string(),
  subhead: z.string(),
  captions: z.array(z.string()),
  useCases: z.array(z.string()),
  stages: z.array(z.string()),
  cta: z.object({ label: z.string(), url: z.string() }),
  outroLine: z.string(),
  speedBadge: z.string(),
});

/** Fractions (0-1) of the source media. */
export const cropSchema = z.object({
  x: z.number().min(0).max(1),
  y: z.number().min(0).max(1),
  w: z.number().min(0).max(1),
  h: z.number().min(0).max(1),
});

export const mediaSchema = z.object({
  src: z.string(),
  kind: z.enum(["image", "video"]),
  /** Intrinsic width / height of the source. Needed for pixel-exact crops. */
  aspect: z.number().positive(),
  startFrom: z.number().int().min(0).optional(),
  /** Source length in frames (30fps). Video freezes on its last frame after this. */
  durationInFrames: z.number().int().positive().optional(),
  crop: cropSchema.optional(),
  playbackRate: z.number().positive().optional(),
});

/** Absolute pixels on the 1920x1080 frame. */
export const rectSchema = z.object({
  x: z.number(),
  y: z.number(),
  w: z.number(),
  h: z.number(),
});

export const scenePanelSchema = z.object({
  /** Key into `media`. Also the panel's identity across scenes. */
  slot: z.string(),
  rect: rectSchema,
  role: z.enum(["active", "context"]),
  /** Frames after the scene starts before this panel's boundary reveal begins. */
  revealDelay: z.number().int().min(0).optional(),
});

export const sceneSchema = z.object({
  id: z.string(),
  durationInFrames: z.number().int().positive(),
  kind: z.enum(["title", "storyboard", "outro"]),
  panels: z.array(scenePanelSchema),
  /** Index into content.captions, or null for no caption. */
  captionIndex: z.number().int().min(0).nullable(),
  /** "bottom": in the bottom margin under the active panel. "beside": in the margin right of it. */
  captionPlacement: z.enum(["bottom", "beside"]),
  /** Index into content.stages highlighted in the header, or null. */
  stage: z.number().int().min(0).nullable(),
  showHeader: z.boolean(),
});

export const storyboardSchema = z.object({
  margin: z.number(),
  gutter: z.number(),
  panelRadius: z.number(),
  /** Opacity of non-active (context) panels. */
  contextOpacity: z.number().min(0).max(1),
  /** Boundary reveal length for new panels (frames). */
  revealFrames: z.number().int().positive(),
  /** Layout move length when a panel changes size/position (frames). */
  moveFrames: z.number().int().positive(),
  /** Fade-out length for panels leaving the page (frames). */
  exitFrames: z.number().int().positive(),
  captionFadeFrames: z.number().int().positive(),
  showPanelNumbers: z.boolean(),
});

export const launchPropsSchema = z.object({
  brand: brandSchema,
  content: contentSchema,
  media: z.record(z.string(), mediaSchema),
  scenes: z.array(sceneSchema),
  storyboard: storyboardSchema,
});

export type Brand = z.infer<typeof brandSchema>;
export type Content = z.infer<typeof contentSchema>;
export type Media = z.infer<typeof mediaSchema>;
export type Rect = z.infer<typeof rectSchema>;
export type ScenePanel = z.infer<typeof scenePanelSchema>;
export type Scene = z.infer<typeof sceneSchema>;
export type Storyboard = z.infer<typeof storyboardSchema>;
export type LaunchProps = z.infer<typeof launchPropsSchema>;
