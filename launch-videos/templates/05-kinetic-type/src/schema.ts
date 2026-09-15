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
  blackRaised: zColor(),
  white: zColor(),
  fontFamily: z.string(),
  monoFontFamily: z.string(),
  logoLight: z.string().describe("Lockup used on light backgrounds"),
  logoDark: z.string().describe("Lockup used on dark backgrounds"),
});

export const contentSchema = z.object({
  featureName: z.string(),
  eyebrow: z.string(),
  headline: z.string(),
  accentWord: z
    .string()
    .describe("Word or phrase inside `headline` that is set in the accent color"),
  subhead: z.string(),
  captions: z.array(z.string()),
  useCases: z.array(z.string()),
  stages: z.array(z.string()),
  cta: z.object({ label: z.string(), url: z.string() }),
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
  src: z.string().describe("Path relative to launch-videos/assets, passed to staticFile()"),
  kind: z.enum(["image", "video"]),
  naturalWidth: z.number().describe("Pixel width of the source file"),
  naturalHeight: z.number().describe("Pixel height of the source file"),
  crop: cropSchema.optional().describe("Fraction of the source to show (0-1)"),
  startFrom: z.number().optional(),
  playbackRate: z.number().optional(),
  align: z
    .enum(["top", "center", "bottom"])
    .optional()
    .describe("Which edge of the cropped source to keep when cover-fitting"),
});

export const layoutSchema = z.enum(["top", "left", "right", "bottom"]);

export const titleSceneSchema = z.object({
  kind: z.literal("title"),
  id: z.string(),
  durationInFrames: z.number().int().min(30),
});

export const beatSceneSchema = z.object({
  kind: z.literal("beat"),
  id: z.string(),
  durationInFrames: z.number().int().min(90),
  captionIndex: z.number().int().min(0).describe("Index into content.captions"),
  media: z.array(z.string()).min(1).describe("Media slot names shown in order"),
  layout: layoutSchema,
  index: z.string().optional().describe("Small mono index label, e.g. 01"),
});

export const endSceneSchema = z.object({
  kind: z.literal("end"),
  id: z.string(),
  durationInFrames: z.number().int().min(90),
});

export const sceneSchema = z.discriminatedUnion("kind", [
  titleSceneSchema,
  beatSceneSchema,
  endSceneSchema,
]);

export const timingSchema = z.object({
  phraseHoldFrames: z.number().int().describe("How long the phrase stands alone"),
  morphFrames: z.number().int().describe("Phrase -> caption move duration"),
  mediaInFrames: z.number().int().describe("Media fade/rise duration"),
  dissolveFrames: z.number().int().describe("Crossfade between media in one beat"),
  exitFrames: z.number().int().describe("Beat exit duration"),
});

export const typographySchema = z.object({
  phraseSize: z.number().describe("Font size of a phrase when it stands alone"),
  captionSize: z.number().describe("Font size once it has settled into the margin"),
  displaySize: z.number().describe("Title headline size"),
  margin: z.number().describe("Safe margin in px"),
  frameRadius: z.number(),
});

export const launchPropsSchema = z.object({
  brand: brandSchema,
  content: contentSchema,
  media: z.record(z.string(), mediaSlotSchema),
  scenes: z.array(sceneSchema),
  timing: timingSchema,
  typography: typographySchema,
});

export type Brand = z.infer<typeof brandSchema>;
export type Content = z.infer<typeof contentSchema>;
export type Crop = z.infer<typeof cropSchema>;
export type MediaSlot = z.infer<typeof mediaSlotSchema>;
export type Layout = z.infer<typeof layoutSchema>;
export type TitleScene = z.infer<typeof titleSceneSchema>;
export type BeatScene = z.infer<typeof beatSceneSchema>;
export type EndScene = z.infer<typeof endSceneSchema>;
export type Scene = z.infer<typeof sceneSchema>;
export type Timing = z.infer<typeof timingSchema>;
export type Typography = z.infer<typeof typographySchema>;
export type LaunchProps = z.infer<typeof launchPropsSchema>;
