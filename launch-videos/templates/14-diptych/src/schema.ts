import { z } from "zod";
import { zColor } from "@remotion/zod-types";

export const brandSchema = z.object({
  paper: zColor(),
  surface: zColor(),
  surfaceAlt: zColor(),
  line: zColor(),
  ink: zColor(),
  inkMuted: zColor(),
  inkSubtle: zColor(),
  accent: zColor(),
  black: zColor(),
  blackRaised: zColor(),
  white: zColor(),
  fontFamily: z.string(),
  monoFontFamily: z.string(),
  logoLight: z.string().describe("Logo lockup for light backgrounds"),
  logoDark: z.string().describe("Logo lockup for dark backgrounds"),
});

export const ctaSchema = z.object({
  label: z.string(),
  url: z.string(),
});

export const contentSchema = z.object({
  featureName: z.string(),
  eyebrow: z.string(),
  headline: z.string(),
  headlineAccent: z
    .string()
    .describe("Substring of headline set in the accent color (empty = none)"),
  subhead: z.string(),
  captions: z.array(z.string()),
  useCases: z.array(z.string()),
  stages: z.array(z.string()),
  cta: ctaSchema,
  outroLine: z.string(),
  speedBadge: z.string(),
});

export const cropSchema = z.object({
  x: z.number().min(0).max(1),
  y: z.number().min(0).max(1),
  w: z.number().min(0).max(1),
  h: z.number().min(0).max(1),
});

export const mediaSlotSchema = z.object({
  src: z.string().describe("Path relative to launch-videos/assets"),
  kind: z.enum(["image", "video"]),
  srcWidth: z.number().describe("Source pixel width (for crop aspect)"),
  srcHeight: z.number().describe("Source pixel height (for crop aspect)"),
  startFrom: z.number().optional(),
  crop: cropSchema.optional(),
  playbackRate: z.number().optional(),
});

export const panelSplitSchema = z.object({
  active: z
    .number()
    .min(0.3)
    .max(0.8)
    .describe("Fraction of width given to the action panel while it is active"),
  balanced: z
    .number()
    .min(0.3)
    .max(0.8)
    .describe("Fraction of width for the action panel once both views are compared"),
});

export const syncSchema = z.object({
  revealAt: z
    .number()
    .describe("Frame (within the scene) at which the result panel appears"),
  balanceAt: z
    .number()
    .describe("Frame (within the scene) at which the divider moves to the balanced ratio"),
});

const sceneBase = {
  id: z.string(),
  durationInFrames: z.number().int().positive(),
};

export const titleSceneSchema = z.object({
  ...sceneBase,
  kind: z.literal("title"),
});

export const pairSceneSchema = z.object({
  ...sceneBase,
  kind: z.literal("pair"),
  actionMedia: z.string().describe("Key in media"),
  resultMedia: z.string().describe("Key in media"),
  actionLabel: z.string(),
  resultLabel: z.string(),
  captionIndex: z.number().int().min(0).describe("Index into content.captions"),
  split: panelSplitSchema,
  sync: syncSchema,
});

export const resultSceneSchema = z.object({
  ...sceneBase,
  kind: z.literal("result"),
  media: z.string().describe("Key in media; grows from the result panel to the full frame"),
  label: z.string(),
  expandAt: z.number().describe("Frame (within the scene) at which the panel starts to fill the frame"),
});

export const outroSceneSchema = z.object({
  ...sceneBase,
  kind: z.literal("outro"),
});

export const sceneSchema = z.discriminatedUnion("kind", [
  titleSceneSchema,
  pairSceneSchema,
  resultSceneSchema,
  outroSceneSchema,
]);

export const layoutSchema = z.object({
  margin: z.number().describe("Safe margin in px"),
  gutter: z.number().describe("Gap between the two panels in px"),
  panelRadius: z.number(),
  moveDuration: z.number().describe("Frames for divider moves (ease-in-out)"),
  enterDuration: z.number().describe("Frames for entrances (ease-out)"),
});

export const launchPropsSchema = z.object({
  brand: brandSchema,
  content: contentSchema,
  media: z.record(mediaSlotSchema),
  scenes: z.array(sceneSchema),
  layout: layoutSchema,
});

export type Brand = z.infer<typeof brandSchema>;
export type Content = z.infer<typeof contentSchema>;
export type MediaSlot = z.infer<typeof mediaSlotSchema>;
export type Crop = z.infer<typeof cropSchema>;
export type Scene = z.infer<typeof sceneSchema>;
export type PairScene = z.infer<typeof pairSceneSchema>;
export type ResultScene = z.infer<typeof resultSceneSchema>;
export type Layout = z.infer<typeof layoutSchema>;
export type LaunchProps = z.infer<typeof launchPropsSchema>;
