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
  logoLight: z.string().describe("Lockup used on light surfaces (path under assets/)"),
  logoDark: z.string().describe("Lockup used on dark surfaces (path under assets/)"),
});

export const contentSchema = z.object({
  featureName: z.string(),
  eyebrow: z.string(),
  headline: z.string(),
  headlineAccentWord: z
    .string()
    .optional()
    .describe("A single word of the headline set in the accent color"),
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
  src: z.string().describe("Path under launch-videos/assets/, e.g. recordings/pdf.mp4"),
  kind: z.enum(["image", "video"]),
  width: z.number().describe("Source pixel width (used for pixel-preserving crops)"),
  height: z.number().describe("Source pixel height"),
  startFrom: z.number().optional(),
  crop: cropSchema.optional(),
  playbackRate: z.number().optional(),
});

export const mediaSchema = z.record(z.string(), mediaSlotSchema);

const sceneBase = {
  id: z.string(),
  durationInFrames: z.number().int().positive(),
};

export const titleSceneSchema = z.object({
  ...sceneBase,
  kind: z.literal("title"),
});

export const exhibitSceneSchema = z.object({
  ...sceneBase,
  kind: z.literal("exhibit"),
  numeral: z.string().describe("Exhibit number as printed on the label, e.g. I"),
  stageIndex: z.number().int().min(0).describe("Index into content.stages"),
  useCaseIndex: z.number().int().min(0).describe("Index into content.useCases"),
  captionIndex: z.number().int().min(0).describe("Index into content.captions"),
  still: z.string().describe("media slot shown first (composed screenshot)"),
  motion: z
    .string()
    .optional()
    .describe("media slot that replaces the still (screen recording). Omit for a static work."),
  revealAt: z
    .number()
    .int()
    .min(0)
    .optional()
    .describe("Local frame at which the recording fades in and the display expands"),
  isResult: z.boolean().optional().describe("Marks the final 'delivered result' display"),
});

export const ctaSceneSchema = z.object({
  ...sceneBase,
  kind: z.literal("cta"),
});

export const sceneSchema = z.discriminatedUnion("kind", [
  titleSceneSchema,
  exhibitSceneSchema,
  ctaSceneSchema,
]);

export const gallerySchema = z.object({
  safeMargin: z.number().describe("Outer margin in px (brand: 96)"),
  floorHeight: z.number().describe("Height of the floor band at the bottom of the wall"),
  displayWidthStill: z.number().describe("Display width (px) while the screenshot is the subject"),
  displayWidthDolly: z.number().describe("Display width the slow dolly reaches before the reveal"),
  displayWidthMotion: z.number().describe("Display width (px) once the recording fills the frame"),
  displayCenterY: z.number().describe("Vertical center of the display on the wall"),
  displayRadius: z.number(),
  displayShadow: z.string(),
  labelWidth: z.number(),
  labelGap: z.number().describe("Gap between the display and its label"),
  panFrames: z.number().int().describe("Lateral camera move between exhibits, in frames"),
  expandFrames: z.number().int().describe("Display expansion duration at the reveal"),
  crossfadeFrames: z.number().int().describe("Screenshot -> recording crossfade duration"),
  cutFrames: z.number().int().describe("Fade used for the deliberate cut into the CTA"),
});

export const launchPropsSchema = z.object({
  brand: brandSchema,
  content: contentSchema,
  media: mediaSchema,
  gallery: gallerySchema,
  scenes: z.array(sceneSchema).min(1),
});

export type Brand = z.infer<typeof brandSchema>;
export type Content = z.infer<typeof contentSchema>;
export type MediaSlot = z.infer<typeof mediaSlotSchema>;
export type Crop = z.infer<typeof cropSchema>;
export type Scene = z.infer<typeof sceneSchema>;
export type TitleScene = z.infer<typeof titleSceneSchema>;
export type ExhibitScene = z.infer<typeof exhibitSceneSchema>;
export type CtaScene = z.infer<typeof ctaSceneSchema>;
export type Gallery = z.infer<typeof gallerySchema>;
export type LaunchProps = z.infer<typeof launchPropsSchema>;
