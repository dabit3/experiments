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
  black: zColor(),
  white: zColor(),
  fontFamily: z.string(),
  monoFontFamily: z.string(),
  logoLight: z.string().describe("Lockup shown on light backgrounds"),
  logoDark: z.string().describe("Lockup shown on dark backgrounds"),
});

export const cropSchema = z.object({
  x: z.number().min(0).max(1),
  y: z.number().min(0).max(1),
  w: z.number().min(0).max(1),
  h: z.number().min(0).max(1),
});

export const mediaSlotSchema = z.object({
  src: z.string().describe("Path under launch-videos/assets, e.g. recordings/androidios.mp4"),
  kind: z.enum(["image", "video"]),
  startFrom: z.number().int().min(0).optional().describe("Video only: first source frame"),
  crop: cropSchema.optional().describe("Fractions of the source frame to keep"),
  playbackRate: z.number().positive().optional(),
  sourceAspect: z
    .number()
    .positive()
    .optional()
    .describe("width / height of the source file; resolved automatically when omitted"),
});

export const contentSchema = z.object({
  featureName: z.string(),
  eyebrow: z.string(),
  headline: z.string(),
  headlineAccentWord: z
    .string()
    .optional()
    .describe("Word in the headline set in brand.accent (exact match)"),
  subhead: z.string(),
  captions: z.array(z.string()),
  useCases: z.array(z.string()),
  stages: z.array(z.string()),
  cta: z.object({ label: z.string(), url: z.string() }),
  outroLine: z.string(),
  speedBadge: z.string(),
});

export const cursorSchema = z.object({
  glyph: z.enum(["block", "bar", "underscore"]),
  blinkFrames: z.number().int().min(2).describe("Full on/off cycle length"),
  charsPerFrame: z.number().positive().describe("Typing speed"),
  color: z.enum(["accent", "ink"]),
});

export const openSceneSchema = z.object({
  id: z.string(),
  type: z.literal("open"),
  durationInFrames: z.number().int().min(30),
});

export const demoSceneSchema = z.object({
  id: z.string(),
  type: z.literal("demo"),
  durationInFrames: z.number().int().min(90),
  captionIndex: z.number().int().min(0).describe("Index into content.captions"),
  label: z.string().describe("Section label the typed line settles into"),
  media: z.string().describe("Key in media"),
  captionPlacement: z.enum(["top", "bottom"]),
});

export const outroSceneSchema = z.object({
  id: z.string(),
  type: z.literal("outro"),
  durationInFrames: z.number().int().min(30),
});

export const sceneSchema = z.discriminatedUnion("type", [
  openSceneSchema,
  demoSceneSchema,
  outroSceneSchema,
]);

export const launchPropsSchema = z.object({
  brand: brandSchema,
  content: contentSchema,
  media: z.record(mediaSlotSchema),
  scenes: z.array(sceneSchema),
  cursor: cursorSchema,
  layout: z.object({
    safeMargin: z.number().int().min(0),
    statementSize: z.number().min(24).describe("Typed statement font size (px)"),
    labelSize: z.number().min(12).describe("Settled section label size (px)"),
    frameRadius: z.number().min(0),
  }),
  timing: z.object({
    holdAfterType: z.number().int().min(0).describe("Frames the finished line holds before settling"),
    settle: z.number().int().min(1).describe("Frames for the line to settle into a label"),
    rule: z.number().int().min(1).describe("Frames for the baseline to extend across"),
    expand: z.number().int().min(1).describe("Frames for the baseline to expand into the frame"),
    exitFade: z.number().int().min(0),
  }),
});

export type Brand = z.infer<typeof brandSchema>;
export type Crop = z.infer<typeof cropSchema>;
export type MediaSlot = z.infer<typeof mediaSlotSchema>;
export type Content = z.infer<typeof contentSchema>;
export type Cursor = z.infer<typeof cursorSchema>;
export type Scene = z.infer<typeof sceneSchema>;
export type DemoScene = z.infer<typeof demoSceneSchema>;
export type LaunchProps = z.infer<typeof launchPropsSchema>;
