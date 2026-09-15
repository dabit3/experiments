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
  blackRaisedAlt: zColor(),
  white: zColor(),
  fontFamily: z.string(),
  monoFontFamily: z.string(),
  logoLight: z.string().describe("Lockup for light backgrounds (staticFile path)"),
  logoDark: z.string().describe("Lockup for dark backgrounds (staticFile path)"),
});

export const contentSchema = z.object({
  featureName: z.string(),
  eyebrow: z.string(),
  headline: z.string(),
  headlineAccentWord: z
    .string()
    .describe("Word of the headline set in the accent color (leave empty for none)"),
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
  src: z.string().describe("Path relative to launch-videos/assets, e.g. recordings/x.mp4"),
  kind: z.enum(["image", "video"]),
  startFrom: z.number().int().min(0).optional().describe("Video start offset in frames"),
  crop: cropSchema.optional().describe("Fractional crop of the source (0-1)"),
  playbackRate: z.number().positive().optional(),
  aspect: z
    .number()
    .positive()
    .optional()
    .describe("Source width / height before cropping (defaults to 16/9)"),
});

export const mediaSchema = z.record(z.string(), mediaSlotSchema);

export const maskSchema = z.object({
  kind: z.enum(["shutter-horizontal", "shutter-vertical", "iris", "none"]),
  durationInFrames: z.number().int().min(0),
  delayInFrames: z.number().int().min(0).default(0),
  slit: z
    .boolean()
    .default(true)
    .describe("Show a thin light slit at the shutter edge while it opens"),
});

export const lightingSchema = z.object({
  edgeGlow: z
    .number()
    .min(0)
    .max(1)
    .describe("Strength of the soft white rim light behind the media frame (0 = off)"),
  keyLine: z
    .boolean()
    .describe("Draw a 1px accent hairline along the top of the caption band"),
  vignette: z
    .number()
    .min(0)
    .max(1)
    .describe("Darkening of the frame corners, applied outside the media only"),
});

const sceneBase = {
  id: z.string(),
  durationInFrames: z.number().int().min(1),
};

export const sceneSchema = z.discriminatedUnion("type", [
  z.object({
    ...sceneBase,
    type: z.literal("statement"),
    eyebrow: z.string().optional(),
    headline: z.string().optional().describe("Defaults to content.headline"),
    subhead: z.string().optional(),
    showLogo: z.boolean().default(false),
  }),
  z.object({
    ...sceneBase,
    type: z.literal("title"),
    index: z.string().optional().describe("Small mono label above the title, e.g. 01"),
    text: z.string(),
  }),
  z.object({
    ...sceneBase,
    type: z.literal("product"),
    media: z.string().describe("Key of a media slot"),
    caption: z.string(),
    captionIndex: z.string().optional().describe("Small mono label left of the caption"),
    layout: z.enum(["full", "split"]).default("full"),
    mask: maskSchema.optional(),
    holdOutFrames: z
      .number()
      .int()
      .min(0)
      .default(0)
      .describe("Frames at the end where the caption stays but nothing else moves"),
    speedBadge: z.boolean().default(false),
  }),
  z.object({
    ...sceneBase,
    type: z.literal("outro"),
  }),
]);

export const launchPropsSchema = z.object({
  brand: brandSchema,
  content: contentSchema,
  media: mediaSchema,
  scenes: z.array(sceneSchema),
  mask: maskSchema.describe("Default mask for product scenes without their own"),
  lighting: lightingSchema,
  layout: z.object({
    safeMargin: z.number().int().min(0),
    mediaWidth: z.number().int().min(960).describe("Width of a full-layout media frame (px)"),
    mediaTop: z.number().int().min(0),
    radius: z.number().min(0),
    captionSize: z.number().min(12),
  }),
});

export type LaunchProps = z.infer<typeof launchPropsSchema>;
export type Brand = z.infer<typeof brandSchema>;
export type Content = z.infer<typeof contentSchema>;
export type MediaSlot = z.infer<typeof mediaSlotSchema>;
export type Mask = z.infer<typeof maskSchema>;
export type Lighting = z.infer<typeof lightingSchema>;
export type Scene = z.infer<typeof sceneSchema>;
export type ProductScene = Extract<Scene, { type: "product" }>;
export type StatementScene = Extract<Scene, { type: "statement" }>;
export type TitleScene = Extract<Scene, { type: "title" }>;
export type LayoutSettings = LaunchProps["layout"];
