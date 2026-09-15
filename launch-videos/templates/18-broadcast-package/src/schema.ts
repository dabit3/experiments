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
  blackRaisedAlt: zColor(),
  white: zColor(),
  fontFamily: z.string(),
  monoFontFamily: z.string(),
  fontFaceCss: z
    .string()
    .describe(
      "Optional @font-face CSS; url(\"relative/path\") is resolved against launch-videos/assets",
    ),
  logoLight: z.string().describe("Lockup used on light surfaces"),
  logoDark: z.string().describe("Lockup used on dark surfaces"),
  safeMargin: z.number().int().min(0),
  radius: z.number().min(0),
});
export type Brand = z.infer<typeof brandSchema>;

export const ctaSchema = z.object({ label: z.string(), url: z.string() });

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
export type Content = z.infer<typeof contentSchema>;

export const cropSchema = z.object({
  x: z.number().min(0).max(1),
  y: z.number().min(0).max(1),
  w: z.number().min(0).max(1),
  h: z.number().min(0).max(1),
});
export type Crop = z.infer<typeof cropSchema>;

export const mediaSlotSchema = z.object({
  src: z.string().describe("Path relative to launch-videos/assets, passed to staticFile()"),
  kind: z.enum(["image", "video"]),
  width: z.number().int().positive().describe("Source pixel width"),
  height: z.number().int().positive().describe("Source pixel height"),
  startFrom: z.number().int().min(0).optional(),
  crop: cropSchema.optional(),
  playbackRate: z.number().positive().optional(),
});
export type MediaSlot = z.infer<typeof mediaSlotSchema>;

export const mediaSchema = z.record(z.string(), mediaSlotSchema);
export type Media = z.infer<typeof mediaSchema>;

const sceneBase = {
  id: z.string(),
  durationInFrames: z.number().int().positive(),
};

export const titleSceneSchema = z.object({
  ...sceneBase,
  type: z.literal("title"),
});

export const heroSceneSchema = z.object({
  ...sceneBase,
  type: z.literal("hero"),
  media: z.string().describe("Media slot key"),
  label: z.string().describe("Small caption under the product view"),
});

export const chapterSceneSchema = z.object({
  ...sceneBase,
  type: z.literal("chapter"),
  index: z.number().int().positive(),
  title: z.string(),
});

export const lowerThirdCueSchema = z.object({
  caption: z
    .number()
    .int()
    .min(0)
    .describe("Index into content.captions"),
  from: z.number().int().min(0).describe("Frame offset within the scene"),
  durationInFrames: z.number().int().positive(),
});
export type LowerThirdCue = z.infer<typeof lowerThirdCueSchema>;

export const demoSceneSchema = z.object({
  ...sceneBase,
  type: z.literal("demo"),
  chapter: z.number().int().positive(),
  chapterTitle: z.string(),
  media: z.string(),
  lowerThirds: z.array(lowerThirdCueSchema),
  showSpeedBadge: z.boolean().optional(),
});

export const evidenceSceneSchema = z.object({
  ...sceneBase,
  type: z.literal("evidence"),
  chapter: z.number().int().positive(),
  chapterTitle: z.string(),
  media: z.string(),
  evidence: z.string().describe("Media slot key for the secondary panel"),
  evidenceLabel: z.string(),
  lowerThirds: z.array(lowerThirdCueSchema),
  showSpeedBadge: z.boolean().optional(),
});

export const closingSceneSchema = z.object({
  ...sceneBase,
  type: z.literal("closing"),
});

export const sceneSchema = z.discriminatedUnion("type", [
  titleSceneSchema,
  heroSceneSchema,
  chapterSceneSchema,
  demoSceneSchema,
  evidenceSceneSchema,
  closingSceneSchema,
]);
export type Scene = z.infer<typeof sceneSchema>;

export const motionSchema = z.object({
  wipeFrames: z
    .number()
    .int()
    .min(1)
    .describe("Length of the wipe between scenes, in frames"),
  enterFrames: z.number().int().min(1).describe("Ease-out entrance length"),
  lowerThirdFrames: z
    .number()
    .int()
    .min(1)
    .describe("Lower-third slide in/out length"),
});

export const launchPropsSchema = z.object({
  brand: brandSchema,
  content: contentSchema,
  media: mediaSchema,
  scenes: z.array(sceneSchema),
  motion: motionSchema,
});
export type LaunchProps = z.infer<typeof launchPropsSchema>;

export const totalDuration = (scenes: Scene[]): number =>
  scenes.reduce((sum, s) => sum + s.durationInFrames, 0);
